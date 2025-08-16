import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:pharma_box/data/constants.dart';

class CreaListaPopup {
  var logger = Logger(printer: PrettyPrinter());

  Future<void> aggiungiLista(String nomeLista) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'liste': FieldValue.arrayUnion([
        {'nomeLista': nomeLista, 'items': []},
      ]),
    });
  }

  void showPopup(BuildContext context) {
    // Ottieni mese e anno attuali
    final now = DateTime.now();
    final String meseAnno = "${_nomeMese(now.month)} ${now.year} - ";

    // Controller con testo iniziale
    final TextEditingController controller = TextEditingController(
      text: meseAnno,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool isCreaSelected = true; // default selezionato

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: kBackGround,
              title: const Text(
                'Crea Nuova Lista',
                style: TextStyle(
                  color: kBluScuro,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 46),
                  TextFormField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Titolo Lista',
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: kPrimary),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: kPrimary),
                      ),
                    ),
                    autocorrect: false,
                  ),
                  const SizedBox(height: 40),
                ],
              ),

              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor:
                        !isCreaSelected ? kPrimary : Colors.transparent,
                    foregroundColor: !isCreaSelected ? Colors.white : kPrimary,
                  ),
                  child: const Text('Chiudi'),
                  onPressed: () {
                    setState(
                      () => isCreaSelected = false,
                    ); // aggiorna background
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor:
                        isCreaSelected ? kPrimary : Colors.transparent,
                    foregroundColor: isCreaSelected ? Colors.white : kPrimary,
                  ),
                  child: const Text('Crea'),
                  onPressed: () {
                    setState(
                      () => isCreaSelected = true,
                    ); // aggiorna background
                    final nomeLista = controller.text.trim();
                    if (nomeLista.isNotEmpty) {
                      aggiungiLista(nomeLista);
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Funzione per convertire numero mese in nome italiano
  String _nomeMese(int mese) {
    const mesi = [
      "Gennaio",
      "Febbraio",
      "Marzo",
      "Aprile",
      "Maggio",
      "Giugno",
      "Luglio",
      "Agosto",
      "Settembre",
      "Ottobre",
      "Novembre",
      "Dicembre",
    ];
    return mesi[mese - 1];
  }
}
