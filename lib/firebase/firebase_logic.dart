import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/web.dart';

class FirebaseLogic {
  FirebaseLogic._privateConstructor();
  static final FirebaseLogic instance = FirebaseLogic._privateConstructor();

  final Logger _logger = Logger(printer: PrettyPrinter());

  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  Future<bool> isUIDAuthorized(String uidBle) async {
    try {
      final uid = _currentUid;
      if (uid == null) {
        _logger.w('isUIDAuthorized invoked without authenticated user');
        return false;
      }

      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (doc.exists && doc.data()?['UID_BLE'] == uidBle) {
        _logger.i("UID_BLE: compatibile");
        return true;
      } else {
        _logger.e("UID_BLE: non compatibile");
        return false;
      }
    } catch (e) {
      _logger.e("Errore nel recupero UID_BLE: $e");
      return false;
    }
  }

  Future<void> aggiungiProdottoLista({
    required String uid,
    required String nomeLista,
    required Map<String, dynamic> prodottoData,
  }) async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);

    final doc = await docRef.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final liste = List<Map<String, dynamic>>.from(data['liste'] ?? []);

    final indexLista = liste.indexWhere((l) => l['nomeLista'] == nomeLista);

    if (indexLista < 0) return;

    final prodotti = List<Map<String, dynamic>>.from(
      liste[indexLista]['prodotti'] ?? [],
    );

    final indexProdotto = prodotti.indexWhere(
      (p) => p['id'] == prodottoData['id'],
    );

    if (indexProdotto >= 0) {
      prodotti[indexProdotto]['quantity'] += prodottoData['quantity'];
    } else {
      prodotti.add(prodottoData);
    }

    liste[indexLista]['prodotti'] = prodotti;

    await docRef.update({'liste': liste});
  }

  // Nuove API basate su 'items' e 'minsan' come identificatore
  Future<List<Map<String, dynamic>>> leggiItemsLista({
    required String uid,
    required String nomeLista,
  }) async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final doc = await docRef.get();
    if (!doc.exists) return [];

    final data = doc.data()!;
    final liste = List<Map<String, dynamic>>.from(data['liste'] ?? []);
    final indexLista = liste.indexWhere((l) => l['nomeLista'] == nomeLista);
    if (indexLista < 0) return [];

    return List<Map<String, dynamic>>.from(liste[indexLista]['items'] ?? []);
  }

  Future<void> upsertItemLista({
    required String uid,
    required String nomeLista,
    required Map<String, dynamic> item,
  }) async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final liste = List<Map<String, dynamic>>.from(data['liste'] ?? []);
    final indexLista = liste.indexWhere((l) => l['nomeLista'] == nomeLista);
    if (indexLista < 0) return;

    final items = List<Map<String, dynamic>>.from(
      liste[indexLista]['items'] ?? [],
    );
    final idx = items.indexWhere((e) => e['minsan'] == item['minsan']);
    if (idx >= 0) {
      items[idx] = {...items[idx], ...item};
    } else {
      items.add(item);
    }
    liste[indexLista]['items'] = items;
    await docRef.update({'liste': liste});
  }

  Future<void> aggiornaQuantitaItemLista({
    required String uid,
    required String nomeLista,
    required String minsan,
    required int quantity,
  }) async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final liste = List<Map<String, dynamic>>.from(data['liste'] ?? []);
    final indexLista = liste.indexWhere((l) => l['nomeLista'] == nomeLista);
    if (indexLista < 0) return;

    final items = List<Map<String, dynamic>>.from(
      liste[indexLista]['items'] ?? [],
    );
    final idx = items.indexWhere((e) => e['minsan'] == minsan);
    if (idx >= 0) {
      if (quantity <= 0) {
        items.removeAt(idx);
      } else {
        items[idx]['quantity'] = quantity;
      }
    } else if (quantity > 0) {
      items.add({'minsan': minsan, 'quantity': quantity});
    }
    liste[indexLista]['items'] = items;
    await docRef.update({'liste': liste});
  }

  Future<void> svuotaListaUtente({
    required String uid,
    required String nomeLista,
  }) async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final liste = List<Map<String, dynamic>>.from(data['liste'] ?? []);
    final index = liste.indexWhere((l) => l['nomeLista'] == nomeLista);
    if (index < 0) return;

    liste[index]['items'] = [];
    liste[index]['prodotti'] = [];
    await docRef.update({'liste': liste});
  }
}
