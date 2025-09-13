import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/widgets/container_opzione.dart';
import 'package:pharma_box/widgets/gestione_prodotto.dart';
import 'package:pharma_box/widgets/cerca_prodotto_field.dart';
import 'package:pharma_box/screens/lista_prodotti_inventario.dart';
import 'package:pharma_box/screens/product_details.dart';
import 'package:pharma_box/models/prodotto.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:pharma_box/widgets/carrello.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  //var uid_ble = '54DCB6B0-828C-D8CF-57BB-3D4D7E54EC3B';
  //bool? isAuthorized;

  @override
  void initState() {
    super.initState();
    // Imposta e carica la lista corrente per questa pagina
    Carrello.instance.usaLista(widget.titolo);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      Carrello.instance.caricaListaDaCloud(uid);
    }
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
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        switch (selectedIndex) {
                          case 0:
                            return //isAuthorized == true ?
                            GestioneProdotto().prodottoTrovato();
                          //: GestioneProdotto().nonAutorizzato();
                          case 1:
                            return SingleChildScrollView(
                              child: Column(
                                children: [
                                  CercaProdottoField(
                                    initialValue: productToSearch,
                                    onChanged: (value) {
                                      setState(() {
                                        productToSearch = value;
                                      });
                                    },
                                  ),
                                  opzioni("Status", kFiltri1),
                                  opzioni("Category", kFiltri2),
                                  opzioni("Category", kFiltri1),
                                ],
                              ),
                            );
                          case 2:
                            return ListaProdottiInventario(
                              titolo: widget.titolo,
                              nrListe: widget.nrListe,
                            );
                          default:
                            return const SizedBox();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: selectedIndex == 1
          ? CercaProdottoBottomBar(
              query: productToSearch,
              onPressed: () {
                // Naviga a ProductDetails con il prodotto cercato (placeholder)
                final prodotto = Prodotto(
                  titolo: productToSearch,
                  minsan: 'Minsan ${productToSearch.hashCode}',
                  imagePath: kNoImage,
                  pezzi: 1,
                  consentito: false,
                  description: '',
                  ingredients: '',
                  howToTake: '',
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetails(
                      title: prodotto.titolo,
                      nrListe: widget.nrListe,
                      prodotto: prodotto,
                    ),
                  ),
                );
              },
            )
          : null,
    );
  }
}
