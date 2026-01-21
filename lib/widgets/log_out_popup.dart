import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/view/login_page.dart';

class LogoutPopup {
  var logger = Logger(printer: PrettyPrinter());

  void showLogout(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'Conferma logout',
              style: TextStyle(color: kBluScuro),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Sei sicuro di voler fare il logout?',
                  style: TextStyle(color: kBluScuro),
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () async {
                    try {
                      await FirebaseAuth.instance.signOut();
                      // ignore: use_build_context_synchronously
                      Navigator.of(context).pop(); // chiude il dialog
                      // ignore: use_build_context_synchronously
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                      );
                      logger.d('Log out: SUCCESS');
                    } catch (error) {
                      logger.e(error);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    side: BorderSide(color: kBluScuro, width: 1),
                  ),
                  child: const Text('Logout', style: TextStyle(color: kRed)),
                ),
                const SizedBox(height: 4),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop(false); // Annulla
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    side: BorderSide(color: kBluScuro, width: 1),
                  ),
                  child: const Text(
                    'Annulla',
                    style: TextStyle(color: kBluScuro),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
