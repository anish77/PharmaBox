import '../models/prodotto.dart';

class Carrello {
  Carrello._privateConstructor();
  static final Carrello instance = Carrello._privateConstructor();

  final List<Prodotto> prodotti = [];

  void aggiungiProdotto(Prodotto prodotto) {
    // Se esiste già, somma i pezzi
    final index = prodotti.indexWhere((p) => p.minsan == prodotto.minsan);
    if (index >= 0) {
      prodotti[index].pezzi += prodotto.pezzi;
    } else {
      prodotti.add(prodotto);
    }
  }

  void aggiornaQuantita(Prodotto prodotto, int newQuantity) {
    final index = prodotti.indexWhere((p) => p.minsan == prodotto.minsan);
    if (index >= 0) {
      if (newQuantity <= 0) {
        prodotti.removeAt(index);
      } else {
        prodotti[index].pezzi = newQuantity;
      }
    }
  }
}
