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
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

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
}
