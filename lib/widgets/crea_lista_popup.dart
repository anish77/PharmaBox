import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:pharma_box/data/constants.dart';

class CreaListaPopup {
  var logger = Logger(printer: PrettyPrinter());

  String _normalizeName(String name) => name.trim().toLowerCase();

  Future<bool> aggiungiLista(String nomeLista, BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _mostraErrore(context, 'Effettua il login per creare una lista');
      return false;
    }

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final creata = await FirebaseFirestore.instance.runTransaction<bool>((
        transaction,
      ) async {
        final doc = await transaction.get(userRef);
        final liste = List<Map<String, dynamic>>.from(
          doc.data()?['liste'] ?? [],
        );

        final nomeNormalizzato = _normalizeName(nomeLista);
        final esiste = liste.any(
          (lista) =>
              _normalizeName(lista['nomeLista']?.toString() ?? '') ==
              nomeNormalizzato,
        );
        if (esiste) return false;

        liste.add({'nomeLista': nomeLista.trim(), 'items': []});
        transaction.set(userRef, {'liste': liste}, SetOptions(merge: true));
        return true;
      });

      if (!creata) {
        if (context.mounted) {
          _mostraErrore(context, 'Esiste già una lista con questo nome');
        }
        return false;
      }
      return true;
    } catch (error, stackTrace) {
      logger.e(
        'Errore durante la creazione della lista: $error',
        stackTrace: stackTrace,
      );
      if (context.mounted) {
        _mostraErrore(context, 'Impossibile creare la lista. Riprova.');
      }
      return false;
    }
  }

  void showPopup(BuildContext context) {
    final TextEditingController controller = TextEditingController();

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
                      hintText: 'Inserisci il nome della lista',
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

                    final creata = await aggiungiLista(nomeLista, context);

                    if (creata && context.mounted) {
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

  void _mostraErrore(BuildContext context, String messaggio) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(messaggio), backgroundColor: Colors.red),
    );
  }
}
