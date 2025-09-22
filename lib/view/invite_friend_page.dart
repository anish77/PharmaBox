import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:share_plus/share_plus.dart';

class InviteFriendPage extends StatelessWidget {
  final String referralCode;

  const InviteFriendPage({super.key, required this.referralCode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Invita un amico"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Icon(
              Icons.card_giftcard,
              size: 100,
              color: kPrimary,
            ),
            const SizedBox(height: 20),
            const Text(
              "Ottieni il 20% di sconto!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              "Invita un amico a registrarsi su PharmaBox. "
              "Quando completa l’iscrizione, riceverai il 20% di sconto sul tuo prossimo abbonamento.",
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Codice invito
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: kPrimary),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    referralCode,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: referralCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Codice copiato!")),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Spacer(),

            // Pulsante per condividere
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Share.share(
                    "Registrati su PharmaBox e usa il mio codice $referralCode per ricevere il 20% di sconto!",
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  "Invita ora",
                  style: TextStyle(fontSize: 18, color: kWhite),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
