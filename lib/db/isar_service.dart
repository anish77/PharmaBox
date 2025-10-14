import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pharma_box/data/models/lists_isar.dart';
import 'package:pharma_box/data/models/prodotto_isar.dart';
import 'package:flutter/foundation.dart';

class IsarService {
  IsarService._();
  static final IsarService instance = IsarService._();

  Isar? _isar;
  String? _currentUserId;
  Future<Isar>? _pendingOpen;

  /// Apre (o riusa) il database locale per un utente specifico.
  Future<Isar> openForUser(String userId) async {
    final existing = _isar;

    // 🔹 Se il DB è già aperto per lo stesso utente, riusalo
    if (existing != null && existing.isOpen && _currentUserId == userId) {
      return existing;
    }

    // 🔹 Se stai cambiando utente, chiudi la vecchia istanza
    if (existing != null && existing.isOpen && _currentUserId != userId) {
      try {
        await existing.close();
      } catch (e) {
        debugPrint('Errore durante la chiusura Isar: $e');
      }
      _isar = null;
    }

    // 🔹 Se c’è un’apertura già in corso, attendila
    final pending = _pendingOpen;
    if (pending != null) {
      final isar = await pending;
      if (isar.isOpen && _currentUserId == userId) {
        return isar;
      }
    }

    // 🔹 Avvia una nuova apertura
    final openFuture = _open(userId);
    _pendingOpen = openFuture;

    try {
      final isar = await openFuture;
      _isar = isar;
      _currentUserId = userId;
      return isar;
    } finally {
      _pendingOpen = null;
    }
  }

  /// Chiude il database corrente
  Future<void> closeCurrent() async {
    if (_isar != null && _isar!.isOpen) {
      await _isar!.close();
    }
    _isar = null;
    _currentUserId = null;
  }

  /// Restituisce l’istanza Isar aperta, o lancia se non inizializzata.
  Isar get db {
    final isar = _isar;
    if (isar == null || !isar.isOpen) {
      throw Exception(
        'Isar non inizializzato! Devi chiamare openForUser() prima.',
      );
    }
    return isar;
  }

  Future<Isar> _open(String userId) async {
    final dir = await getApplicationDocumentsDirectory();
    return Isar.open(
      [ListsIsarSchema, ProdottoIsarSchema],
      directory: dir.path,
      name: 'pharmabox_$userId',
      inspector: true,
    );
  }
}
