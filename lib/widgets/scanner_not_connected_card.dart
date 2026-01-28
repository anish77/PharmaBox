import 'package:flutter/material.dart';

class ScannerNotConnectedCard extends StatelessWidget {
  const ScannerNotConnectedCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.bluetooth_disabled, color: Colors.orange, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scanner non connesso',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Lo scanner Bluetooth non è attualmente connesso.',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              '• Tocca l’icona Bluetooth per avviare la connessione.\n'
              '• Assicurati che lo scanner esterno sia acceso e già collegato al dispositivo.\n'
              '• Se non disponi di uno scanner, dal Menu "Abbonamento & Scanner" '
              'puoi accedere a un sito esterno per visualizzare e acquistare uno scanner compatibile.',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
