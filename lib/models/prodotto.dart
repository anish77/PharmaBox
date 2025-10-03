import 'package:flutter/material.dart';

class Prodotto {
  final String nome;
  final String minsan;
  final String? tipoProdotto;
  final String? tipoProdottoDettaglio;
  final String immagine;
  final String description;
  final String ingredients;
  final String howToTake;
  final bool consentito;
  final String codice;
  final List<String> rendibile; // Array di 3 stringhe
  final ValueNotifier<int> pezzi; // 👈 diventa osservabile

  Prodotto({
    required this.nome,
    required this.minsan,
    this.tipoProdotto,
    this.tipoProdottoDettaglio,
    required this.immagine,
    required int pezzi,
    required this.consentito,
    required this.description,
    required this.ingredients,
    required this.howToTake,
    required this.codice,
    this.rendibile = const ['', '', ''],
  }) : pezzi = ValueNotifier<int>(pezzi);
}
