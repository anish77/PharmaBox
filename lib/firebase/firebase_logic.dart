import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/web.dart';

class FirebaseLogic {
  FirebaseLogic._privateConstructor();
  static final FirebaseLogic instance = FirebaseLogic._privateConstructor();

  final _logger = Logger(printer: PrettyPrinter());
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  Future<bool> isUIDAuthorized(String uidBle) async {
    try {
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
}
