import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:toggle_switch/toggle_switch.dart';

class SelectedListPage extends StatefulWidget {
  const SelectedListPage({
    super.key,
    required this.titolo,
    required this.nrListe,
  });
  final String titolo;
  final int nrListe;

  @override
  State<SelectedListPage> createState() => _SelectedListPageState();
}

class _SelectedListPageState extends State<SelectedListPage> {
  var cercaProdottoSelected = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titolo),
        centerTitle: false,
        titleSpacing: 0, // riduce lo spazio prima del titolo
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                SizedBox(
                  width:
                      double.infinity, // occupa tutta la larghezza disponibile
                  child: ToggleSwitch(
                    minWidth: double.infinity,
                    initialLabelIndex: 0,
                    totalSwitches: 3,
                    labels: [
                      'Scan',
                      'Cerca',
                      'Lista(${widget.nrListe.toString()})',
                    ],
                    activeBgColor: [kPrimary],
                    inactiveBgColor: kSecondary,
                    borderColor: [kPrimary],
                    borderWidth: 1.0,
                    cornerRadius: 28.0,
                    onToggle: (index) {
                      print('switched to: $index');
                      setState(() {
                        if (index == 0) {
                          cercaProdottoSelected = false;
                          // Logica per Scan
                        } else if (index == 1) {
                          cercaProdottoSelected = true;
                        } else if (index == 2) {
                          cercaProdottoSelected = false;
                          // Logica per Lista
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(height: 18),
                if (cercaProdottoSelected == true) ...[
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: kCercaProdotto,
                      labelStyle: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: kBluScuro),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: kPrimary),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: kPrimary),
                      ),
                    ),
                    keyboardType: TextInputType.text,
                    autocorrect: false,
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty ||
                          value.length < 3) {
                        return kMsgErroreCercaProdotto;
                      }
                      return null;
                    },
                    onSaved: (value) {
                      // Logica per salvare il prodotto
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
