import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:pharma_box/data/constants.dart';

class CreaListaPopup {
  var logger = Logger(printer: PrettyPrinter());

  Future<bool> listaEsiste(String nomeLista) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (doc.exists) {
      final data = doc.data();
      final liste = data?['liste'] ?? [];
      for (var lista in liste) {
        if (lista['nomeLista'].toString().toLowerCase() ==
            nomeLista.toLowerCase()) {
          return true; // già esistente
        }
      }
    }
    return false;
  }

  Future<void> aggiungiLista(String nomeLista, BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // controllo duplicati
    final esiste = await listaEsiste(nomeLista);
    if (esiste) {
      // ignore: use_build_context_synchronously
      _mostraErrore(context, "Esiste già una lista con questo nome");
      return;
    }

    // aggiunta lista
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'liste': FieldValue.arrayUnion([
        {'nomeLista': nomeLista, 'items': []},
      ]),
    });
  }

  void showPopup(BuildContext context) {
    final now = DateTime.now();
    final String meseAnno = "${_nomeMese(now.month)} ${now.year} - ";
    final TextEditingController controller = TextEditingController(
      text: meseAnno,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool isCreaSelected = true;

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
                    setState(() => isCreaSelected = false);
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
                  onPressed: () async {
                    setState(() => isCreaSelected = true);
                    final nomeLista = controller.text.trim();

                    if (nomeLista.isEmpty) {
                      if (!context.mounted) return;
                      _mostraErrore(
                        context,
                        "Il nome della lista non può essere vuoto",
                      );
                      return;
                    }

                    await aggiungiLista(nomeLista, context);

                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _mostraErrore(BuildContext context, String messaggio) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(messaggio), backgroundColor: Colors.red),
    );
  }

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
