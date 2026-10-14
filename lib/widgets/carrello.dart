import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import '../models/prodotto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pharma_box/firebase/liste_repository.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/include/gs1_datamatrix.dart';
import 'package:pharma_box/models/lotto_confezione.dart';

/// Specchio locale della lista aperta, sincronizzato in tempo reale con
/// Firestore: le letture fatte da altri telefoni sullo stesso account
/// compaiono qui automaticamente.
class Carrello {
  Carrello._privateConstructor();
  static final Carrello instance = Carrello._privateConstructor();

  final Logger _logger = Logger(printer: PrettyPrinter());

  /// Prodotti della lista corrente
  final ValueNotifier<List<Prodotto>> prodotti = ValueNotifier([]);

  final Map<String, Prodotto> _perMinsan = {};
  // Seriali delle confezioni già contate, per MINSAN
  final Map<String, Set<String>> _seriali = {};
  String? _uid;
  String? _idLista;
  StreamSubscription<List<ItemLista>>? _sub;

  /// Imposta la lista corrente e ne ascolta i prodotti su Firestore
  void usaLista(String idLista) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == _uid && idLista == _idLista && _sub != null) return;

    _sub?.cancel();
    _sub = null;
    _uid = uid;
    _idLista = idLista;
    _perMinsan.clear();
    _seriali.clear();
    prodotti.value = [];
    if (uid == null) return;

    _sub = ListeRepository.instance
        .streamItems(uid, idLista)
        .listen(
          _applicaSnapshot,
          onError: (e) => _logger.e('Errore sincronizzazione lista: $e'),
        );
  }

  void _applicaSnapshot(List<ItemLista> items) {
    final aggiornati = <String, Prodotto>{};
    for (final item in items) {
      // Riusa l'oggetto esistente: mantiene i dati della ricerca e lo stato
      // delle celle che lo osservano
      final prodotto = _perMinsan[item.minsan] ?? _daItem(item);
      if (prodotto.pezzi.value != item.quantity) {
        prodotto.pezzi.value = item.quantity;
      }
      prodotto.lotti.value = item.lotti;
      aggiornati[item.minsan] = prodotto;
    }
    _perMinsan
      ..clear()
      ..addAll(aggiornati);
    _seriali
      ..clear()
      ..addAll({
        for (final item in items) item.minsan: {...item.seriali},
      });
    prodotti.value = _perMinsan.values.toList();
  }

  /// true se la confezione con questo seriale è già nella lista
  bool giaContata(String minsan, ConfezioneGs1? confezione) {
    final seriale = confezione?.seriale;
    return seriale != null && (_seriali[minsan]?.contains(seriale) ?? false);
  }

  /// Aggiunge [quantita] pezzi (default 1) con un incremento atomico.
  /// Con una [confezione] letta da DataMatrix registra lotto e scadenza; se
  /// il seriale è già in lista non aggiunge nulla e restituisce false, a
  /// meno di [forza].
  bool aggiungiProdotto(
    Prodotto prodotto, {
    int quantita = 1,
    ConfezioneGs1? confezione,
    bool forza = false,
  }) {
    final uid = _uid;
    final idLista = _idLista;
    if (uid == null || idLista == null || prodotto.minsan.isEmpty) {
      return false;
    }
    if (!forza && giaContata(prodotto.minsan, confezione)) return false;

    final esistente = _perMinsan[prodotto.minsan];
    final inLista = esistente ?? _copia(prodotto, 0);
    inLista.pezzi.value += quantita;
    _perMinsan[prodotto.minsan] = inLista;
    if (confezione != null) _registraConfezione(inLista, confezione, quantita);
    prodotti.value = _perMinsan.values.toList();

    ListeRepository.instance
        .incrementa(
          uid,
          idLista,
          minsan: prodotto.minsan,
          titolo: prodotto.nome,
          delta: quantita,
          confezione: confezione,
        )
        .catchError((e) => _logger.e('Errore salvataggio lettura: $e'));
    return true;
  }

  /// Aggiornamento locale immediato; lo snapshot di Firestore lo conferma
  void _registraConfezione(
    Prodotto prodotto,
    ConfezioneGs1 confezione,
    int quantita,
  ) {
    final seriale = confezione.seriale;
    if (seriale != null) {
      _seriali.putIfAbsent(prodotto.minsan, () => {}).add(seriale);
    }
    if (confezione.lotto == null && confezione.scadenza == null) return;
    final lotto = confezione.lotto ?? '';
    final lotti = List<LottoConfezione>.of(prodotto.lotti.value);
    final i = lotti.indexWhere(
      (l) => l.lotto == lotto && l.scadenza == confezione.scadenza,
    );
    final precedente = i == -1 ? 0 : lotti[i].quantity;
    final aggiornato = LottoConfezione(
      lotto: lotto,
      scadenza: confezione.scadenza,
      quantity: precedente + quantita,
    );
    if (i == -1) {
      lotti.add(aggiornato);
    } else {
      lotti[i] = aggiornato;
    }
    prodotto.lotti.value = lotti;
  }

  void svuotaLista() {
    final uid = _uid;
    final idLista = _idLista;
    _perMinsan.clear();
    _seriali.clear();
    prodotti.value = [];
    if (uid == null || idLista == null) return;

    ListeRepository.instance
        .svuotaLista(uid, idLista)
        .catchError((e) => _logger.e('Errore svuotamento lista: $e'));
  }

  /// Imposta la quantità esatta; a 0 il prodotto resta in lista
  void aggiornaQuantita(Prodotto prodotto, int newQuantity) {
    final uid = _uid;
    final idLista = _idLista;
    final esistente = _perMinsan[prodotto.minsan];
    if (uid == null || idLista == null || esistente == null) return;

    final nuova = newQuantity < 0 ? 0 : newQuantity;
    final attuale = esistente.pezzi.value;
    // Alcuni widget notificano la stessa modifica due volte: la seconda
    // chiamata non deve alterare il totale della lista
    if (nuova == attuale) return;

    esistente.pezzi.value = nuova;
    if (nuova == 0) {
      esistente.lotti.value = const [];
      _seriali.remove(prodotto.minsan);
    }
    prodotti.value = _perMinsan.values.toList();

    ListeRepository.instance
        .impostaQuantita(
          uid,
          idLista,
          minsan: prodotto.minsan,
          titolo: esistente.nome,
          quantity: nuova,
          delta: nuova - attuale,
        )
        .catchError((e) => _logger.e('Errore salvataggio quantità: $e'));
  }

  /// Elimina il prodotto dalla lista, qualunque sia la quantità
  void rimuoviProdotto(Prodotto prodotto) {
    final uid = _uid;
    final idLista = _idLista;
    if (uid == null || idLista == null) return;
    final esistente = _perMinsan.remove(prodotto.minsan);
    if (esistente == null) return;
    _seriali.remove(prodotto.minsan);
    prodotti.value = _perMinsan.values.toList();

    ListeRepository.instance
        .rimuoviItem(
          uid,
          idLista,
          minsan: prodotto.minsan,
          quantity: esistente.pezzi.value,
        )
        .catchError((e) => _logger.e('Errore rimozione prodotto: $e'));
  }

  Prodotto _copia(Prodotto p, int pezzi) => Prodotto(
    nome: p.nome,
    minsan: p.minsan,
    tipoProdotto: p.tipoProdotto,
    tipoProdottoDettaglio: p.tipoProdottoDettaglio,
    immagine: p.immagine,
    pezzi: pezzi,
    vendibile: p.vendibile,
    description: p.description,
    ingredients: p.ingredients,
    howToTake: p.howToTake,
    codice: p.codice,
    rendibile: p.rendibile,
  );

  Prodotto _daItem(ItemLista item) => Prodotto(
    nome: item.titolo.isNotEmpty ? item.titolo : item.minsan,
    minsan: item.minsan,
    immagine: kNoImage,
    pezzi: item.quantity,
    vendibile: 0,
    description: '',
    ingredients: '',
    howToTake: '',
    codice: '',
  );
}
