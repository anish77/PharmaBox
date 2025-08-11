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
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),

                child: SizedBox(
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
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
