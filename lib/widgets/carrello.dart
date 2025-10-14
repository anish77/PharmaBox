import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:pharma_box/data/models/lists_isar.dart';
import 'package:pharma_box/data/models/prodotto_isar.dart';
import 'package:pharma_box/domain/models/prodotto.dart';

/// Gestisce il carrello persistente su Isar.
/// È un singleton che sincronizza i prodotti in memoria e nel DB locale.
class CarrelloIsar {
  CarrelloIsar._();
  static final CarrelloIsar instance = CarrelloIsar._();

  final ValueNotifier<List<Prodotto>> prodotti = ValueNotifier([]);
  ListsIsar? _listaCorrente;
  Isar? _isar;
  bool _inizializzato = false;

  /// Collega un'istanza di Isar al carrello.
  void attachDb(Isar isar) {
    if (_isar == isar && _listaCorrente != null) return;
    _isar = isar;
    _listaCorrente = null;
    _inizializzato = false;
    prodotti.value = const <Prodotto>[];
  }

  /// Scollega l'istanza corrente (opzionale ma utile al logout).
  void detachDb() {
    _isar = null;
    _listaCorrente = null;
    _inizializzato = false;
    prodotti.value = const <Prodotto>[];
  }

  Isar _db() {
    final isar = _isar;
    if (isar == null || !isar.isOpen) {
      throw StateError(
        'Isar non collegato. Chiama attachDb prima di usare il carrello.',
      );
    }
    return isar;
  }

  /// Inizializza o crea la lista corrente in base al titolo (nome lista).
  Future<void> usaLista(String titolo) async {
    final isar = _db();
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

  /// Carica i prodotti collegati alla lista.
  Future<void> _caricaProdotti() async {
    final lista = _listaCorrente;
    if (lista == null) return;

    await lista.products.load();
    final prodottiIsar = lista.products.toList();
    final prodottiDom = prodottiIsar.map((p) => p.toDomain()).toList();
    prodotti.value = prodottiDom;

    _inizializzato = true;
  }

  /// Aggiunge un prodotto alla lista.
  Future<void> aggiungiProdotto(Prodotto prodotto) async {
    final isar = _db();
    final lista = _listaCorrente;
    if (!_inizializzato || lista == null) return;

    await isar.writeTxn(() async {
      var prodottoIsar = ProdottoIsar.fromDomain(prodotto);
      final existing =
          await isar.prodottoIsars
              .filter()
              .minsanEqualTo(prodotto.minsan)
              .findFirst();

      if (existing != null) {
        prodottoIsar = existing..pezzi = prodotto.pezzi.value;
        await isar.prodottoIsars.put(existing);
      } else {
        await isar.prodottoIsars.put(prodottoIsar);
      }

      await lista.products.load();
      final giaPresente = lista.products.any(
        (p) => p.minsan == prodottoIsar.minsan,
      );
      if (!giaPresente) {
        lista.products.add(prodottoIsar);
        await lista.products.save();
      }
    });

    await _caricaProdotti();
  }

  /// Aggiorna la quantità di un prodotto.
  Future<void> aggiornaQuantita(Prodotto prodotto, int nuovaQta) async {
    final isar = _db();
    final lista = _listaCorrente;
    if (!_inizializzato || lista == null) return;

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
        final nuovo = ProdottoIsar.fromDomain(prodotto)..pezzi = nuovaQta;
        await isar.prodottoIsars.put(nuovo);
        lista.products.add(nuovo);
        await lista.products.save();
      }
    });

    await _caricaProdotti();
  }

  /// Rimuove un prodotto dal carrello.
  Future<void> rimuoviProdotto(Prodotto prodotto) async {
    final isar = _db();
    final lista = _listaCorrente;
    if (!_inizializzato || lista == null) return;

    await isar.writeTxn(() async {
      final prodottoIsar =
          await isar.prodottoIsars
              .filter()
              .minsanEqualTo(prodotto.minsan)
              .findFirst();
      if (prodottoIsar == null) return;

      await lista.products.load();
      lista.products.removeWhere((p) => p.id == prodottoIsar.id);
      await lista.products.save();

      await isar.prodottoIsars.delete(prodottoIsar.id);
    });

    await _caricaProdotti();
  }

  /// Svuota completamente la lista.
  Future<void> svuotaLista() async {
    final isar = _db();
    final lista = _listaCorrente;
    if (!_inizializzato || lista == null) return;

    await isar.writeTxn(() async {
      await lista.products.load();
      lista.products.clear();
      await lista.products.save();
    });

    prodotti.value = const <Prodotto>[];
  }

  /// Sostituisce la lista di prodotti in memoria (per esempio dopo un load esterno).
  void sostituisciProdottiCorrenti(List<Prodotto> nuovi) {
    prodotti.value = List<Prodotto>.from(nuovi);
  }
}
