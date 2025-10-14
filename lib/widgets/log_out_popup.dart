import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:pharma_box/data/constants.dart';

class LogoutPopup {
  var logger = Logger(printer: PrettyPrinter());

  void showLogout(BuildContext parentContext) {
    final drawerNavigator = Navigator.of(parentContext);
    final rootNavigator = Navigator.of(parentContext, rootNavigator: true);

    showDialog(
      context: parentContext,
      builder:
          (dialogContext) => AlertDialog(
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
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop(); // chiudi dialog
                      }
                      if (drawerNavigator.mounted && drawerNavigator.canPop()) {
                        drawerNavigator.pop(); // chiudi il drawer se aperto
                      }
                      if (rootNavigator.mounted) {
                        rootNavigator.popUntil((route) => route.isFirst);
                      }

                      logger.d('Log out: SUCCESS');
                    } catch (error) {
                      logger.e(error);
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
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
                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop(false); // Annulla
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
