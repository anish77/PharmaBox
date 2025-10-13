import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:pharma_box/domain/models/prodotto.dart';

part 'prodotto_isar.g.dart';

@collection
class ProdottoIsar {
  Id id = Isar.autoIncrement; // ID autoincrementale

  late String nome;
  late String minsan;
  String? tipoProdotto;
  String? tipoProdottoDettaglio;
  late String immagine;
  late String description;
  late String ingredients;
  late String howToTake;
  late int vendibile;
  late String codice;
  List<String> rendibile = ["", "", ""]; // Lista di 3 stringhe

  @ignore
  late ValueNotifier<int> pezziNotifier;

  late int pezzi; // campo salvato in Isar

  /// Inizializza il ValueNotifier per sincronizzare `pezzi`
  void initNotifier() {
    pezziNotifier = ValueNotifier(pezzi);
    pezziNotifier.addListener(() {
      pezzi = pezziNotifier.value;
    });
  }

  /// Conversione da entità Isar -> Domain
  Prodotto toDomain() {
    return Prodotto(
      id: id,
      nome: nome,
      minsan: minsan,
      tipoProdotto: tipoProdotto,
      tipoProdottoDettaglio: tipoProdottoDettaglio,
      immagine: immagine,
      description: description,
      ingredients: ingredients,
      howToTake: howToTake,
      vendibile: vendibile,
      codice: codice,
      rendibile: List<String>.from(rendibile),
      pezzi: pezzi,
    );
  }

  static ProdottoIsar fromDomain(Prodotto prodotto) {
    final entity =
        ProdottoIsar()
          ..id = prodotto.id
          ..nome = prodotto.nome
          ..minsan = prodotto.minsan
          ..tipoProdotto = prodotto.tipoProdotto
          ..tipoProdottoDettaglio = prodotto.tipoProdottoDettaglio
          ..immagine = prodotto.immagine
          ..description = prodotto.description
          ..ingredients = prodotto.ingredients
          ..howToTake = prodotto.howToTake
          ..vendibile = prodotto.vendibile
          ..codice = prodotto.codice
          ..rendibile = List<String>.from(prodotto.rendibile)
          ..pezzi = prodotto.pezzi.value; // ✅ estrai il valore dall’observable

    entity.initNotifier(); // inizializza il ValueNotifier locale
    return entity;
  }
}
