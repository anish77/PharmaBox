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
  // Per MINSAN: chiave del lotto -> seriali letti, dal più vecchio
  final Map<String, Map<String, List<String>>> _serialiPerLotto = {};
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
    _serialiPerLotto.clear();
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
    _serialiPerLotto
      ..clear()
      ..addAll({
        for (final item in items)
          item.minsan: {
            for (final MapEntry(:key, :value) in item.serialiPerLotto.entries)
              key: [...value],
          },
      });
    prodotti.value = _perMinsan.values.toList();
  }

  /// Il prodotto come è nella lista aperta (con pezzi e lotti), se c'è
  Prodotto? inLista(String minsan) => _perMinsan[minsan];

  /// true se il prodotto in lista ha pezzi attribuiti a un lotto: le sue
  /// quantità si modificano dal pannello dei lotti
  bool haLotti(String minsan) =>
      _perMinsan[minsan]?.lotti.value.any((l) => l.quantity > 0) ?? false;

  /// Pezzi del prodotto non attribuiti a un lotto (bollino o a mano)
  static int pezziSenzaLotto(Prodotto prodotto) {
    final conLotto = prodotto.lotti.value.fold<int>(
      0,
      (somma, l) => somma + (l.quantity > 0 ? l.quantity : 0),
    );
    final senza = prodotto.pezzi.value - conLotto;
    return senza > 0 ? senza : 0;
  }

  /// Aggiunge o toglie [delta] pezzi di un lotto preciso. Togliendo, libera
  /// l'ultimo seriale letto di quel lotto: la confezione si può rileggere.
  void modificaLotto(Prodotto prodotto, LottoConfezione lotto, int delta) {
    final uid = _uid;
    final idLista = _idLista;
    final esistente = _perMinsan[prodotto.minsan];
    if (uid == null || idLista == null || esistente == null || delta == 0) {
      return;
    }

    final lotti = List<LottoConfezione>.of(esistente.lotti.value);
    final i = lotti.indexWhere(
      (l) => l.lotto == lotto.lotto && l.scadenza == lotto.scadenza,
    );
    final precedente = i == -1 ? 0 : lotti[i].quantity;
    final nuova = precedente + delta;
    if (nuova < 0) return;
    final effettivo = nuova - precedente;

    final aggiornato = LottoConfezione(
      lotto: lotto.lotto,
      scadenza: lotto.scadenza,
      quantity: nuova,
    );
    if (i == -1) {
      lotti.add(aggiornato);
    } else if (nuova == 0) {
      lotti.removeAt(i);
    } else {
      lotti[i] = aggiornato;
    }

    String? seriale;
    if (effettivo < 0) {
      final letti =
          _serialiPerLotto[prodotto.minsan]?[chiaveLotto(
            lotto.lotto,
            lotto.scadenza,
          )];
      if (letti != null && letti.isNotEmpty) {
        seriale = letti.removeLast();
        _seriali[prodotto.minsan]?.remove(seriale);
      }
    }

    esistente.lotti.value = lotti;
    esistente.pezzi.value += effettivo;
    prodotti.value = _perMinsan.values.toList();

    ListeRepository.instance
        .modificaLotto(
          uid,
          idLista,
          minsan: prodotto.minsan,
          titolo: esistente.nome,
          lotto: lotto,
          delta: effettivo,
          quantitaLotto: nuova,
          serialeDaLiberare: seriale,
        )
        .catchError((e) => _logger.e('Errore modifica lotto: $e'));
  }

  /// Toglie un pezzo senza chiedere il lotto: prima dai pezzi senza scadenza,
  /// poi dal lotto che scade prima (scaduti per primi, senza data per ultimi).
  /// Restituisce da dove l'ha tolto, null se non c'era nulla da togliere.
  String? togliUnPezzo(Prodotto prodotto) {
    final esistente = _perMinsan[prodotto.minsan];
    if (esistente == null || esistente.pezzi.value <= 0) return null;
    if (pezziSenzaLotto(esistente) > 0) {
      modificaSenzaLotto(esistente, -1);
      return 'Tolto 1 pezzo senza scadenza';
    }
    final lotto = lottoDaTogliere(esistente.lotti.value);
    if (lotto == null) return null;
    modificaLotto(esistente, lotto, -1);
    final nome = lotto.lotto.isEmpty ? 'senza numero' : lotto.lotto;
    final scadenza =
        lotto.scadenza == null
            ? ''
            : ', scad. ${formattaScadenza(lotto.scadenza!)}';
    return 'Tolto 1 pezzo dal lotto $nome$scadenza';
  }

  /// Aggiunge o toglie pezzi senza lotto: il totale non scende mai sotto i
  /// pezzi attribuiti ai lotti.
  void modificaSenzaLotto(Prodotto prodotto, int delta) {
    final esistente = _perMinsan[prodotto.minsan];
    if (esistente == null) return;
    final senza = pezziSenzaLotto(esistente);
    if (senza + delta < 0) return;
    aggiornaQuantita(esistente, esistente.pezzi.value + delta);
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
    if (seriale != null) {
      _serialiPerLotto
          .putIfAbsent(prodotto.minsan, () => {})
          .putIfAbsent(chiaveLotto(lotto, confezione.scadenza), () => [])
          .add(seriale);
    }
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
    _serialiPerLotto.clear();
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
      _serialiPerLotto.remove(prodotto.minsan);
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
    _serialiPerLotto.remove(prodotto.minsan);
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
