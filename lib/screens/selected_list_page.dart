import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/screens/cerca_prodotto_field.dart';
import 'package:pharma_box/widgets/container_opzione.dart';
import 'package:pharma_box/widgets/gestione_prodotto.dart';
import 'package:pharma_box/screens/lista_prodotti_inventario.dart';
import 'package:pharma_box/models/prodotto.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:pharma_box/widgets/carrello.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pharma_box/widgets/risultati_ricerca.dart';

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
  late final TextEditingController _searchController;
  List<Prodotto> _searchResults = [];
  final Set<String> _selectedFilters = {};
  bool _hideUnselectedFilters = false;
  //var uid_ble = '54DCB6B0-828C-D8CF-57BB-3D4D7E54EC3B';
  //bool? isAuthorized;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // Imposta e carica la lista corrente per questa pagina
    Carrello.instance.usaLista(widget.titolo);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      Carrello.instance.caricaListaDaCloud(uid);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget opzioni(String title, List<String> kFiltro) {
    return Column(
      children: [
        if (!_hideUnselectedFilters)
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
        if (!_hideUnselectedFilters) SizedBox(height: 8),
        Align(
          alignment: Alignment.topLeft,
          child: Wrap(
            spacing: 8, // spazio orizzontale
            runSpacing: 8, // spazio verticale
            children: kFiltro
                .map(
                  (filtro) => ContainerOpzione(
                    nomeOpione: filtro,
                    hideWhenUnselected: _hideUnselectedFilters,
                    selected: _selectedFilters.contains(filtro),
                    onSelectedChanged: (isSel) {
                      setState(() {
                        if (isSel) {
                          _selectedFilters.add(filtro);
                        } else {
                          _selectedFilters.remove(filtro);
                        }
                      });
                    },
                  ),
                )
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
                          // Se torni alla tab "Cerca" (1), ripristina lo stato iniziale della ricerca
                          if (selectedIndex == 1) {
                            productToSearch = '';
                            _searchController.text = '';
                            _searchResults = [];
                            _hideUnselectedFilters = false; // mostra di nuovo i gruppi opzioni
                            _selectedFilters.clear(); // deseleziona tutti i filtri
                          }
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
                            return GestioneProdotto().prodottoTrovato();
                          //: GestioneProdotto().nonAutorizzato();
                          case 1:
                            return SingleChildScrollView(
                              child: Column(
                                children: [
                                  CercaProdottoField(
                                    initialValue: productToSearch,
                                    controller: _searchController,
                                    onChanged: (value) {
                                      setState(() {
                                        productToSearch = value;
                                        // Non mostrare risultati automaticamente mentre si digita
                                        // Svuota i risultati finché non si preme il bottone "Cerca"
                                        _searchResults = [];
                                        if (productToSearch.trim().isEmpty) {
                                          _hideUnselectedFilters = false;
                                          _selectedFilters.clear();
                                        }
                                      });
                                    },
                                  ),
                                  if (_selectedFilters.isNotEmpty)
                                    Align(
                                      alignment: Alignment.topLeft,
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: _selectedFilters
                                            .map(
                                              (f) => ContainerOpzione(
                                                nomeOpione: f,
                                                selected: true,
                                                onSelectedChanged: (isSel) {
                                                  if (!isSel) {
                                                    setState(() {
                                                      _selectedFilters.remove(f);
                                                    });
                                                  }
                                                },
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ),
                                  if (!_hideUnselectedFilters || _selectedFilters.isEmpty) ...[
                                    opzioni(kFiltri1.title, kFiltri1.items),
                                    opzioni(kFiltri2.title, kFiltri2.items),
                                    opzioni(kFiltri1.title, kFiltri1.items),
                                  ],
                                  RisultatiRicerca(risultati: _searchResults),
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
      bottomNavigationBar:
          selectedIndex == 1
              ? CercaProdottoBottomBar(
                title: kCercaProdotto,
                query: productToSearch,
                onPressed: () {
                  if (productToSearch.trim().length >= 3) {
                    setState(() {
                      _searchResults = [
                        Prodotto(
                          titolo: productToSearch,
                          minsan: 'Minsan ${productToSearch.hashCode}',
                          imagePath: kNoImage,
                          pezzi: 1,
                          consentito: false,
                          description: '',
                          ingredients: '',
                          howToTake: '',
                        ),
                      ];
                      _hideUnselectedFilters = true;
                    });
                  }
                },
              )
              : null,
    );
  }
}
