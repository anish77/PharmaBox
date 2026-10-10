import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/firebase/liste_repository.dart';

class CreaListaPopup {
  var logger = Logger(printer: PrettyPrinter());

  Future<bool> aggiungiLista(String nomeLista, BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _mostraErrore(context, 'Effettua il login per creare una lista');
      return false;
    }

    try {
      final esiste = await ListeRepository.instance.esisteNome(uid, nomeLista);
      if (esiste) {
        if (context.mounted) {
          _mostraErrore(context, 'Esiste già una lista con questo nome');
        }
        return false;
      }

      ListeRepository.instance.creaLista(uid, nomeLista.trim());
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
    showDialog<void>(
      context: context,
      builder:
          (_) => _CreaListaDialog(
            onCreate: (nomeLista, context) => aggiungiLista(nomeLista, context),
          ),
    );
  }

  void _mostraErrore(BuildContext context, String messaggio) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(messaggio), backgroundColor: Colors.red),
    );
  }
}

class _CreaListaDialog extends StatefulWidget {
  const _CreaListaDialog({required this.onCreate});

  final Future<bool> Function(String nomeLista, BuildContext context) onCreate;

  @override
  State<_CreaListaDialog> createState() => _CreaListaDialogState();
}

class _CreaListaDialogState extends State<_CreaListaDialog> {
  final _controller = TextEditingController();
  bool _isCreateSelected = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = _controller.text.trim().isNotEmpty;

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
            controller: _controller,
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
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 40),
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: !_isCreateSelected ? kPrimary : Colors.transparent,
            foregroundColor: !_isCreateSelected ? Colors.white : kPrimary,
          ),
          onPressed: () {
            setState(() => _isCreateSelected = false);
            Navigator.of(context).pop();
          },
          child: const Text('Chiudi'),
        ),
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor:
                !canCreate
                    ? Colors.grey.shade300
                    : _isCreateSelected
                    ? kPrimary
                    : Colors.transparent,
            foregroundColor:
                !canCreate
                    ? Colors.grey.shade600
                    : _isCreateSelected
                    ? Colors.white
                    : kPrimary,
          ),
          onPressed:
              canCreate
                  ? () async {
                    setState(() => _isCreateSelected = true);
                    final creata = await widget.onCreate(
                      _controller.text.trim(),
                      context,
                    );
                    if (creata && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                  : null,
          child: const Text('Crea'),
        ),
      ],
    );
  }
}
