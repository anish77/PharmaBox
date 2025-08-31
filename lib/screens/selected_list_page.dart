import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/firebase/firebase_logic.dart';
import 'package:pharma_box/widgets/container_opzione.dart';
import 'package:pharma_box/widgets/custom_button.dart';
import 'package:pharma_box/widgets/gestione_prodotto.dart';
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
  var uid_ble = '54DCB6B0-828C-D8CF-57BB-3D4D7E54EC3B';
  bool? isAuthorized;

  @override
  void initState() {
    super.initState();
    FirebaseLogic.instance.isUIDAuthorized(uid_ble).then((value) {
      setState(() {
        isAuthorized = value;
      });
    });
  }

  Widget opzioni(String title, List<String> kFiltro) {
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
            spacing: 8, // spazio orizzontale
            runSpacing: 8, // spazio verticale
            children:
                kFiltro
                    .map((filtro) => ContainerOpzione(nomeOpione: filtro))
                    .toList(),
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
                        totalSwitches: 3,
                        labels: ['Scan', 'Cerca', 'Lista'],
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
                      if (isAuthorized == true)
                        GestioneProdotto().prodottoTrovato()
                      else
                        GestioneProdotto().nonAutorizzato(),
                    ] else if (selectedIndex == 1) ...[
                      GestioneProdotto().cercaProdotto(
                        context: context,
                        onChanged: (value) {
                          setState(() {
                            productToSearch = value;
                          });
                        },
                      ),
                      opzioni("Status", kFiltri1),
                      opzioni("Category", kFiltri2),
                      opzioni("Category", kFiltri1),
                    ] else ...[
                      //cercaProdotto(),
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
