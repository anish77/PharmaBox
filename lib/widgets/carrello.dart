import 'package:flutter/material.dart';
import '../models/prodotto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pharma_box/firebase/firebase_logic.dart';
import 'package:pharma_box/data/constants.dart';

class Carrello {
  Carrello._privateConstructor();
  static final Carrello instance = Carrello._privateConstructor();

  final Map<String, ValueNotifier<List<Prodotto>>> _liste = {};
  String _listaCorrente = '_default';

  /// Imposta la lista corrente (crea se non esiste)
  void usaLista(String nomeLista) {
    _listaCorrente = nomeLista;
    _liste.putIfAbsent(nomeLista, () => ValueNotifier<List<Prodotto>>([]));
  }

  /// Restituisce il ValueNotifier della lista corrente
  ValueNotifier<List<Prodotto>> get prodotti {
    _liste.putIfAbsent(
      _listaCorrente,
      () => ValueNotifier<List<Prodotto>>([]),
    );
    return _liste[_listaCorrente]!;
  }

  void aggiungiProdotto(Prodotto prodotto) {
    final notifier = prodotti;
    final list = List<Prodotto>.from(notifier.value);
    final index = list.indexWhere((p) => p.minsan == prodotto.minsan);

    if (index >= 0) {
      list[index].pezzi.value += prodotto.pezzi.value;
    } else {
      list.add(prodotto);
    }
    notifier.value = list; // 🔄 notifica cambiamento

    // Persisti su Firestore
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final qty = list.firstWhere((p) => p.minsan == prodotto.minsan).pezzi.value;
      FirebaseLogic.instance.upsertItemLista(
        uid: uid,
        nomeLista: _listaCorrente,
        item: {
          'minsan': prodotto.minsan,
          'titolo': prodotto.titolo,
          'quantity': qty,
          // opzionale: altri campi utili
        },
      );
    }
  }

  void aggiornaQuantita(Prodotto prodotto, int newQuantity) {
    final notifier = prodotti;
    final list = List<Prodotto>.from(notifier.value);
    final index = list.indexWhere((p) => p.minsan == prodotto.minsan);

    if (index >= 0) {
      if (newQuantity <= 0) {
        list.removeAt(index);
      } else {
        list[index].pezzi.value = newQuantity;
      }
      notifier.value = list; // 🔄 notifica cambiamento

      // Persisti su Firestore
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        FirebaseLogic.instance.aggiornaQuantitaItemLista(
          uid: uid,
          nomeLista: _listaCorrente,
          minsan: prodotto.minsan,
          quantity: newQuantity,
        );
      }
    }
  }

  // Sostituisce completamente i prodotti della lista corrente
  void sostituisciProdottiCorrenti(List<Prodotto> nuovi) {
    prodotti.value = List<Prodotto>.from(nuovi);
  }

  // Carica da Firestore gli items della lista corrente
  Future<void> caricaListaDaCloud(String uid) async {
    final items = await FirebaseLogic.instance.leggiItemsLista(
      uid: uid,
      nomeLista: _listaCorrente,
    );
    final prodottiCaricati = items.map((e) {
      final qty = (e['quantity'] ?? 0) as int;
      return Prodotto(
        titolo: (e['titolo'] ?? '') as String,
        minsan: (e['minsan'] ?? '') as String,
        imagePath: kNoImage,
        pezzi: qty,
        consentito: false,
        description: '',
        ingredients: '',
        howToTake: '',
      );
    }).toList();
    sostituisciProdottiCorrenti(prodottiCaricati);
  }
}
