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
}
