import 'package:flutter/material.dart';

class Prodotto {
  final String nome;
  final String minsan;
  final String? tipo_prodotto;
  final String? tipo_prodotto_dettaglio;
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
    this.tipo_prodotto,
    this.tipo_prodotto_dettaglio,
    required this.immagine,
    required int pezzi,
    required this.consentito,
    required this.description,
    required this.ingredients,
    required this.howToTake,
    required this.codice,
    List<String> rendibile = const ['', '', ''],
  })  : rendibile = rendibile,
        pezzi = ValueNotifier<int>(pezzi);
}
