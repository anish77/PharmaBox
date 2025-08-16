import 'package:flutter/material.dart';
import 'package:logger/web.dart';
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
  var logger = Logger(printer: PrettyPrinter());
  var selectedIndex = 0;

  Widget cercaProdotto() {
    return TextFormField(
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
        if (value == null || value.trim().isEmpty || value.length < 3) {
          return kMsgErroreCercaProdotto;
        }
        return null;
      },
      onSaved: (value) {
        // Logica per salvare il prodotto
      },
    );
  }

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
                    cornerRadius: 28.0,
                    borderWidth: 1.0,
                    fontSize: 16,
                    initialLabelIndex: selectedIndex,
                    activeBgColor: [kPrimary],
                    activeFgColor: Colors.white,
                    inactiveBgColor: kSecondary,
                    inactiveFgColor: kBluScuro,
                    totalSwitches: 2,
                    labels: ['Cerca', 'Opzioni'],
                    onToggle: (index) {
                      setState(() {
                        logger.i('switched to: $index');
                        selectedIndex = index!;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 18),
                if (selectedIndex == 0) ...[cercaProdotto()],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
