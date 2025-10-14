import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:pharma_box/data/models/lists_isar.dart';
import 'package:pharma_box/data/models/prodotto_isar.dart';
import 'package:pharma_box/domain/models/prodotto.dart';
import 'package:pharma_box/db/isar_service.dart';

/// Gestisce il carrello persistente su Isar.
/// È un singleton che sincronizza i prodotti in memoria e nel DB locale.
class CarrelloIsar {
  CarrelloIsar._();
  static final CarrelloIsar instance = CarrelloIsar._();

  final ValueNotifier<List<Prodotto>> prodotti = ValueNotifier([]);
  late ListsIsar _listaCorrente;
  bool _inizializzato = false;

  /// Inizializza o crea la lista corrente in base al titolo (nome lista)
  Future<void> usaLista(String titolo) async {
    final isar = await IsarService.instance.db;
    _listaCorrente = await isar.writeTxn(() async {
      final existing =
          await isar.listsIsars.filter().nameListEqualTo(titolo).findFirst();

      if (existing != null) return existing;

      final nuova =
          ListsIsar()
            ..nameList = titolo
            ..date = DateTime.now().toIso8601String()
            ..isCompleted = false;
      await isar.listsIsars.put(nuova);
      return nuova;
    });

    await _caricaProdotti();
  }

  /// Carica i prodotti collegati alla lista
  Future<void> _caricaProdotti() async {
    final isar = await IsarService.instance.db;

    await _listaCorrente.products.load();
    final prodottiIsar = _listaCorrente.products.toList();

    final prodottiDom = prodottiIsar.map((p) => p.toDomain()).toList();
    prodotti.value = prodottiDom;

    _inizializzato = true;
  }

  /// Aggiunge un prodotto alla lista
  Future<void> aggiungiProdotto(Prodotto prodotto) async {
    final isar = await IsarService.instance.db;
    if (!_inizializzato) return;

    await isar.writeTxn(() async {
      // Se il prodotto non è ancora salvato, salvalo prima
      var prodottoIsar = ProdottoIsar.fromDomain(prodotto);
      final existing =
          await isar.prodottoIsars
              .filter()
              .minsanEqualTo(prodotto.minsan)
              .findFirst();

      if (existing != null) {
        prodottoIsar = existing;
        existing.pezzi = prodotto.pezzi.value;
        await isar.prodottoIsars.put(existing);
      } else {
        await isar.prodottoIsars.put(prodottoIsar);
      }

      // Crea il link solo se non già presente
      await _listaCorrente.products.load();
      final giaPresente = _listaCorrente.products.any(
        (p) => p.minsan == prodottoIsar.minsan,
      );
      if (!giaPresente) {
        _listaCorrente.products.add(prodottoIsar);
        await _listaCorrente.products.save();
      }
    });

    await _caricaProdotti();
  }

  /// Aggiorna la quantità di un prodotto
  Future<void> aggiornaQuantita(Prodotto prodotto, int nuovaQta) async {
    final isar = await IsarService.instance.db;
    if (!_inizializzato) return;

    await isar.writeTxn(() async {
      final existing =
          await isar.prodottoIsars
              .filter()
              .minsanEqualTo(prodotto.minsan)
              .findFirst();

      if (existing != null) {
        existing.pezzi = nuovaQta;
        await isar.prodottoIsars.put(existing);
      } else {
        // se non esiste, lo aggiungo
        final nuovo = ProdottoIsar.fromDomain(prodotto)..pezzi = nuovaQta;
        await isar.prodottoIsars.put(nuovo);
        _listaCorrente.products.add(nuovo);
        await _listaCorrente.products.save();
      }
    });

    await _caricaProdotti();
  }

  /// Rimuove un prodotto dal carrello
  Future<void> rimuoviProdotto(Prodotto prodotto) async {
    final isar = await IsarService.instance.db;
    if (!_inizializzato) return;

    await isar.writeTxn(() async {
      final prodottoIsar =
          await isar.prodottoIsars
              .filter()
              .minsanEqualTo(prodotto.minsan)
              .findFirst();
      if (prodottoIsar == null) return;

      await _listaCorrente.products.load();
      _listaCorrente.products.removeWhere((p) => p.id == prodottoIsar.id);
      await _listaCorrente.products.save();

      // opzionale: elimina anche dal DB se non collegato ad altre liste
      await isar.prodottoIsars.delete(prodottoIsar.id);
    });

    await _caricaProdotti();
  }

  /// Svuota completamente la lista
  Future<void> svuotaLista() async {
    final isar = await IsarService.instance.db;
    if (!_inizializzato) return;

    await isar.writeTxn(() async {
      await _listaCorrente.products.load();
      _listaCorrente.products.clear();
      await _listaCorrente.products.save();
    });

    prodotti.value = [];
  }

  void sostituisciProdottiCorrenti(List<Prodotto> nuovi) {
    prodotti.value = List<Prodotto>.from(nuovi);
  }
}
