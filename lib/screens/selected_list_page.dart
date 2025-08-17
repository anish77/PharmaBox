import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/widgets/container_opzione.dart';
import 'package:pharma_box/widgets/custom_button.dart';
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
  var productToSearch = '';

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
      onChanged: (value) {
        setState(() {
          productToSearch = value;
        });
        print(productToSearch);
      },
    );
  }

  Widget opzioni(String title) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kBluScuro,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Align(
          alignment: Alignment.topLeft,
          child: Wrap(
            spacing: 8, // spazio orizzontale tra elementi
            runSpacing: 8, // spazio verticale tra righe
            children: [
              ContainerOpzione(nomeOpione: "Warning 1"),
              ContainerOpzione(nomeOpione: "Warning 1"),
              ContainerOpzione(nomeOpione: "Warning 1"),
              ContainerOpzione(nomeOpione: "Warning 1"),
              ContainerOpzione(nomeOpione: "Warning 1"),
            ],
          ),
        ),
        SizedBox(height: 18),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titolo),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
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
                    if (selectedIndex == 0) ...[
                      cercaProdotto(),
                    ] else ...[
                      opzioni("Status"),
                      opzioni("Category"),
                      opzioni("Category"),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          selectedIndex == 1
              ? Padding(
                padding: const EdgeInsets.only(
                  top: 18,
                  bottom: 45,
                  left: 24,
                  right: 24,
                ),
                child: CustomButton(
                  title: "Applica opzioni",
                  titleColor: Colors.white,
                  backgroundColor: kPrimary,
                  onPressed: () {
                    //TODO
                  },
                ),
              )
              : null,
    );
  }
}
