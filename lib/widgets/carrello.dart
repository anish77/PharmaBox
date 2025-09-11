import 'package:flutter/material.dart';
import '../models/prodotto.dart';

class Carrello {
  Carrello._privateConstructor();
  static final Carrello instance = Carrello._privateConstructor();

  /// Lista osservabile di prodotti
  final ValueNotifier<List<Prodotto>> prodotti = ValueNotifier([]);

  void aggiungiProdotto(Prodotto prodotto) {
    final list = List<Prodotto>.from(prodotti.value);
    final index = list.indexWhere((p) => p.minsan == prodotto.minsan);

    if (index >= 0) {
      list[index].pezzi.value += prodotto.pezzi.value;
    } else {
      list.add(prodotto);
    }
    prodotti.value = list; // 🔄 notifica cambiamento
  }

  void aggiornaQuantita(Prodotto prodotto, int newQuantity) {
    final list = List<Prodotto>.from(prodotti.value);
    final index = list.indexWhere((p) => p.minsan == prodotto.minsan);

    if (index >= 0) {
      if (newQuantity <= 0) {
        list.removeAt(index);
      } else {
        list[index].pezzi.value = newQuantity;
      }
      prodotti.value = list; // 🔄 notifica cambiamento
    }
  }
}
