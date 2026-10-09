import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import '../models/prodotto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pharma_box/firebase/liste_repository.dart';
import 'package:pharma_box/data/constants.dart';

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
      aggiornati[item.minsan] = prodotto;
    }
    _perMinsan
      ..clear()
      ..addAll(aggiornati);
    prodotti.value = _perMinsan.values.toList();
  }

  /// Aggiunge [quantita] pezzi (default 1) con un incremento atomico
  void aggiungiProdotto(Prodotto prodotto, {int quantita = 1}) {
    final uid = _uid;
    final idLista = _idLista;
    if (uid == null || idLista == null || prodotto.minsan.isEmpty) return;

    final esistente = _perMinsan[prodotto.minsan];
    if (esistente != null) {
      esistente.pezzi.value += quantita;
    } else {
      _perMinsan[prodotto.minsan] = _copia(prodotto, quantita);
    }
    prodotti.value = _perMinsan.values.toList();

    ListeRepository.instance
        .incrementa(
          uid,
          idLista,
          minsan: prodotto.minsan,
          titolo: prodotto.nome,
          delta: quantita,
        )
        .catchError((e) => _logger.e('Errore salvataggio lettura: $e'));
  }

  void svuotaLista() {
    final uid = _uid;
    final idLista = _idLista;
    _perMinsan.clear();
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
