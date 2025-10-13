import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/presentation/lists_cubit.dart';

class CreaListaPopup {
  const CreaListaPopup();

  bool _listaEsiste(BuildContext context, String nomeLista) {
    final lists = context.read<ListsCubit>().state;
    return lists.any(
      (lista) => lista.nameList.toLowerCase() == nomeLista.toLowerCase(),
    );
  }

  Future<void> _aggiungiLista(BuildContext context, String nomeLista) async {
    final listsCubit = context.read<ListsCubit>();
    await listsCubit.addNewList(nomeLista);
  }

  void showPopup(BuildContext context) {
    final now = DateTime.now();
    final meseAnno = '${_nomeMese(now.month)} ${now.year} - ';
    final controller = TextEditingController(text: meseAnno);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        var isCreaSelected = true;

        return StatefulBuilder(
          builder: (stateContext, setState) {
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
                  onPressed: () {
                    setState(() => isCreaSelected = false);
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Chiudi'),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor:
                        isCreaSelected ? kPrimary : Colors.transparent,
                    foregroundColor: isCreaSelected ? Colors.white : kPrimary,
                  ),
                  onPressed: () async {
                    setState(() => isCreaSelected = true);
                    final nomeLista = controller.text.trim();

                    if (nomeLista.isEmpty) {
                      if (!stateContext.mounted) return;
                      _mostraErrore(
                        stateContext,
                        'Il nome della lista non può essere vuoto',
                      );
                      return;
                    }

                    if (_listaEsiste(stateContext, nomeLista)) {
                      if (!stateContext.mounted) return;
                      _mostraErrore(
                        stateContext,
                        'Esiste già una lista con questo nome',
                      );
                      return;
                    }

                    await _aggiungiLista(stateContext, nomeLista);

                    if (!stateContext.mounted) return;
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Crea'),
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
      'Gennaio',
      'Febbraio',
      'Marzo',
      'Aprile',
      'Maggio',
      'Giugno',
      'Luglio',
      'Agosto',
      'Settembre',
      'Ottobre',
      'Novembre',
      'Dicembre',
    ];
    return mesi[mese - 1];
  }
}
