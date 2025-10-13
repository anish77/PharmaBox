import 'package:flutter/material.dart';

class Prodotto {
  final int id;
  final String nome;
  final String minsan;
  final String? tipoProdotto;
  final String? tipoProdottoDettaglio;
  final String immagine;
  final String description;
  final String ingredients;
  final String howToTake;
  int vendibile;
  final String codice;
  final List<String> rendibile; // Array di 3 stringhe
  final ValueNotifier<int> pezzi; // 👈 diventa osservabile

  Prodotto({
    required this.id,
    required this.nome,
    required this.minsan,
    this.tipoProdotto,
    this.tipoProdottoDettaglio,
    required this.immagine,
    required int pezzi,
    required this.vendibile,
    required this.description,
    required this.ingredients,
    required this.howToTake,
    required this.codice,
    this.rendibile = const ['', '', ''],
  }) : pezzi = ValueNotifier<int>(pezzi);

  Prodotto toogleCompletion() {
  return Prodotto(
    id: id,
    nome: nome,
    minsan: minsan,
    tipoProdotto: tipoProdotto,
    tipoProdottoDettaglio: tipoProdottoDettaglio,
    immagine: immagine,
    pezzi: pezzi.value,
    vendibile: vendibile,
    description: description,
    ingredients: ingredients,
    howToTake: howToTake,
    codice: codice,
    rendibile: List<String>.from(rendibile),
  );
}

}
