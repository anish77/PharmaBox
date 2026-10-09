import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/web.dart';

/// Struttura dati:
///   users/{uid}/liste/{idLista}                 nome, totalePezzi, createdAt, updatedAt
///   users/{uid}/liste/{idLista}/items/{minsan}  minsan, titolo, quantity, updatedAt
///
/// Le letture dello scanner usano FieldValue.increment: più telefoni sullo
/// stesso account possono scrivere in contemporanea senza perdere pezzi.
class ListaInfo {
  const ListaInfo({
    required this.id,
    required this.nome,
    required this.totalePezzi,
    required this.createdAt,
  });

  final String id;
  final String nome;
  final int totalePezzi;
  final DateTime createdAt;

  factory ListaInfo.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final createdAt = data['createdAt'];
    return ListaInfo(
      id: doc.id,
      nome: (data['nome'] ?? '').toString(),
      totalePezzi: _toInt(data['totalePezzi']),
      createdAt:
          createdAt is Timestamp
              ? createdAt.toDate()
              : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class ItemLista {
  const ItemLista({
    required this.minsan,
    required this.titolo,
    required this.quantity,
  });

  final String minsan;
  final String titolo;
  final int quantity;

  factory ItemLista.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return ItemLista(
      minsan: (data['minsan'] ?? doc.id).toString(),
      titolo: (data['titolo'] ?? '').toString(),
      quantity: _toInt(data['quantity']),
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

// Margine sotto il limite di 500 operazioni per batch di Firestore
const _maxOpsPerBatch = 450;

class ListeRepository {
  ListeRepository._(this._db);
  static final ListeRepository instance = ListeRepository._(
    FirebaseFirestore.instance,
  );

  @visibleForTesting
  ListeRepository.conDb(this._db);

  final FirebaseFirestore _db;
  final Logger _logger = Logger(printer: PrettyPrinter());

  DocumentReference<Map<String, dynamic>> _utente(String uid) =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _liste(String uid) =>
      _utente(uid).collection('liste');

  CollectionReference<Map<String, dynamic>> _items(
    String uid,
    String idLista,
  ) => _liste(uid).doc(idLista).collection('items');

  // Il MINSAN è usato come id del documento: '/' non è ammesso negli id
  String _idItem(String minsan) => minsan.replaceAll('/', '_');

  // ---------------------------- LISTE ----------------------------

  Stream<List<ListaInfo>> streamListe(String uid) {
    return _liste(uid)
        .snapshots(includeMetadataChanges: true)
        // Una cache vuota all'avvio non significa "nessuna lista": si aspetta
        // la conferma del server prima di mostrare la schermata vuota
        .where((snap) => !snap.metadata.isFromCache || snap.docs.isNotEmpty)
        .map(_ordina);
  }

  Future<List<ListaInfo>> leggiListe(String uid) async {
    return _ordina(await _liste(uid).get());
  }

  List<ListaInfo> _ordina(QuerySnapshot<Map<String, dynamic>> snap) {
    return snap.docs
        .map(ListaInfo.fromDoc)
        .where((l) => l.nome.isNotEmpty)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<bool> esisteNome(
    String uid,
    String nome, {
    String? escludiId,
  }) async {
    final cercato = nome.trim().toLowerCase();
    final liste = await leggiListe(uid);
    return liste.any(
      (l) => l.id != escludiId && l.nome.trim().toLowerCase() == cercato,
    );
  }

  /// Crea la lista e ne restituisce l'id. La scrittura non viene attesa:
  /// offline resta in coda e la lista compare subito dalla cache locale.
  String creaLista(String uid, String nome) {
    final ref = _liste(uid).doc();
    final adesso = Timestamp.now();
    ref
        .set({
          'nome': nome,
          'totalePezzi': 0,
          'createdAt': adesso,
          'updatedAt': adesso,
        })
        .catchError((e) => _logger.e('Errore creazione lista: $e'));
    return ref.id;
  }

  Future<void> rinominaLista(String uid, String idLista, String nome) {
    return _liste(
      uid,
    ).doc(idLista).update({'nome': nome, 'updatedAt': Timestamp.now()});
  }

  Future<void> eliminaLista(String uid, String idLista) async {
    // Prima la lista: le letture in arrivo da altri telefoni falliscono
    // (update su documento inesistente) invece di ricreare prodotti orfani
    await _liste(uid).doc(idLista).delete();
    final items = await _items(uid, idLista).get();
    await _commitInBlocchi([
      for (final doc in items.docs) (WriteBatch b) => b.delete(doc.reference),
    ]);
  }

  Future<void> svuotaLista(String uid, String idLista) async {
    final items = await _items(uid, idLista).get();
    if (items.docs.isEmpty) return;
    final rimossi = items.docs.fold<int>(
      0,
      (somma, doc) => somma + _toInt(doc.data()['quantity']),
    );
    // Decremento invece di azzerare: le letture arrivate nel frattempo da
    // altri telefoni restano conteggiate nel totale
    await _commitInBlocchi([
      for (final doc in items.docs) (WriteBatch b) => b.delete(doc.reference),
      (WriteBatch b) => b.update(_liste(uid).doc(idLista), {
        'totalePezzi': FieldValue.increment(-rimossi),
        'updatedAt': Timestamp.now(),
      }),
    ]);
  }

  // ---------------------------- PRODOTTI ----------------------------

  Stream<List<ItemLista>> streamItems(String uid, String idLista) {
    return _items(uid, idLista).snapshots().map(
      (snap) => snap.docs.map(ItemLista.fromDoc).toList(),
    );
  }

  Future<List<ItemLista>> leggiItems(String uid, String idLista) async {
    final snap = await _items(uid, idLista).get();
    return snap.docs.map(ItemLista.fromDoc).toList();
  }

  /// Aggiunge [delta] pezzi in modo atomico (lettura scanner, "Aggiungi").
  Future<void> incrementa(
    String uid,
    String idLista, {
    required String minsan,
    required String titolo,
    int delta = 1,
  }) {
    final adesso = Timestamp.now();
    final batch = _db.batch();
    batch.set(_items(uid, idLista).doc(_idItem(minsan)), {
      'minsan': minsan,
      'titolo': titolo,
      'quantity': FieldValue.increment(delta),
      'updatedAt': adesso,
    }, SetOptions(merge: true));
    batch.update(_liste(uid).doc(idLista), {
      'totalePezzi': FieldValue.increment(delta),
      'updatedAt': adesso,
    });
    return batch.commit();
  }

  /// Imposta la quantità esatta (contatore, inserimento manuale). [delta] è
  /// la differenza rispetto alla quantità precedente, per il totale lista.
  /// A quantità 0 il prodotto resta in lista: si elimina con [rimuoviItem].
  Future<void> impostaQuantita(
    String uid,
    String idLista, {
    required String minsan,
    required String titolo,
    required int quantity,
    required int delta,
  }) {
    final adesso = Timestamp.now();
    final batch = _db.batch();
    batch.set(_items(uid, idLista).doc(_idItem(minsan)), {
      'minsan': minsan,
      'titolo': titolo,
      'quantity': quantity < 0 ? 0 : quantity,
      'updatedAt': adesso,
    }, SetOptions(merge: true));
    batch.update(_liste(uid).doc(idLista), {
      'totalePezzi': FieldValue.increment(delta),
      'updatedAt': adesso,
    });
    return batch.commit();
  }

  /// Elimina il prodotto; [quantity] sono i pezzi da togliere dal totale lista.
  Future<void> rimuoviItem(
    String uid,
    String idLista, {
    required String minsan,
    required int quantity,
  }) {
    final batch = _db.batch();
    batch.delete(_items(uid, idLista).doc(_idItem(minsan)));
    batch.update(_liste(uid).doc(idLista), {
      'totalePezzi': FieldValue.increment(-quantity),
      'updatedAt': Timestamp.now(),
    });
    return batch.commit();
  }

  // ---------------------------- MIGRAZIONE ----------------------------

  /// Copia le liste dal vecchio array `liste` del documento utente nelle
  /// sottocollezioni. Il vecchio array resta intatto come backup.
  /// Gli id `legacy_N` sono deterministici: rieseguirla non duplica le liste.
  Future<void> migraListeLegacy(String uid) async {
    final utente = await _utente(uid).get();
    final data = utente.data();
    if (data == null || data['listeMigrate'] == true) return;

    final legacy = data['liste'] is List ? data['liste'] as List : const [];
    final base = DateTime.now().millisecondsSinceEpoch - legacy.length;
    final operazioni = <void Function(WriteBatch)>[];

    for (var i = 0; i < legacy.length; i++) {
      final raw = legacy[i];
      if (raw is! Map) continue;
      final nome = (raw['nomeLista'] ?? '').toString();
      if (nome.isEmpty) continue;

      // Formato attuale: 'items'; formato più vecchio: 'prodotti'
      var entries = _mappe(raw['items']);
      if (entries.isEmpty) entries = _mappe(raw['prodotti']);

      final perMinsan = <String, ({String titolo, int quantity})>{};
      for (final e in entries) {
        final minsan = (e['minsan'] ?? e['id'] ?? '').toString();
        final quantity = _toInt(
          e['quantity'] ?? e['qty'] ?? e['pezzi'] ?? e['quantita'] ?? e['qta'],
        );
        if (minsan.isEmpty || quantity < 0) continue;
        final titolo =
            (e['titolo'] ??
                    e['title'] ??
                    e['name'] ??
                    e['nome'] ??
                    e['description'] ??
                    '')
                .toString();
        final prec = perMinsan[minsan];
        perMinsan[minsan] = (
          titolo: titolo.isNotEmpty ? titolo : (prec?.titolo ?? ''),
          quantity: (prec?.quantity ?? 0) + quantity,
        );
      }

      final listaRef = _liste(uid).doc('legacy_$i');
      final createdAt = Timestamp.fromMillisecondsSinceEpoch(base + i);
      final totale = perMinsan.values.fold<int>(0, (s, v) => s + v.quantity);
      operazioni.add(
        (b) => b.set(listaRef, {
          'nome': nome,
          'totalePezzi': totale,
          'createdAt': createdAt,
          'updatedAt': createdAt,
        }),
      );
      perMinsan.forEach((minsan, v) {
        operazioni.add(
          (b) => b.set(listaRef.collection('items').doc(_idItem(minsan)), {
            'minsan': minsan,
            'titolo': v.titolo,
            'quantity': v.quantity,
            'updatedAt': createdAt,
          }),
        );
      });
    }

    // Il flag va nell'ultimo batch: se la migrazione si interrompe viene
    // ripetuta al login successivo
    operazioni.add(
      (b) => b.update(_utente(uid), {'listeMigrate': true}),
    );
    await _commitInBlocchi(operazioni);
    _logger.i('Migrazione liste completata per $uid (${legacy.length} liste)');
  }

  List<Map<String, dynamic>> _mappe(dynamic raw) {
    if (raw is! Iterable) return const [];
    return raw
        .whereType<Map>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
  }

  Future<void> _commitInBlocchi(
    List<void Function(WriteBatch)> operazioni,
  ) async {
    for (var i = 0; i < operazioni.length; i += _maxOpsPerBatch) {
      final batch = _db.batch();
      for (final op in operazioni.skip(i).take(_maxOpsPerBatch)) {
        op(batch);
      }
      await batch.commit();
    }
  }
}
