import 'package:flutter/material.dart';

class Prodotto {
  final String titolo;
  final String minsan;
  final String imagePath;
  final String description;
  final String ingredients;
  final String howToTake;
  final bool consentito;
  final ValueNotifier<int> pezzi; // 👈 diventa osservabile

  Prodotto({
    required this.titolo,
    required this.minsan,
    required this.imagePath,
    required int pezzi,
    required this.consentito,
    required this.description,
    required this.ingredients,
    required this.howToTake,
  }) : pezzi = ValueNotifier<int>(pezzi);
}
