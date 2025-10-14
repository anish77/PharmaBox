import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/web.dart';
import 'package:pharma_box/domain/repository/carrello.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/domain/models/prodotto.dart';
import 'package:pharma_box/include/ble_functions.dart';
import 'package:pharma_box/include/general_functions.dart';
import 'package:pharma_box/main.dart';
import 'package:pharma_box/view/cerca_prodotto_field.dart';
import 'package:pharma_box/view/lista_prodotti_inventario.dart';
import 'package:pharma_box/widgets/scan_tab.dart';
import 'package:pharma_box/widgets/full_screen_loader.dart';
import 'package:pharma_box/widgets/container_opzione.dart';
import 'package:pharma_box/widgets/risultati_ricerca.dart';

class SelectedListPage extends ConsumerStatefulWidget {
  const SelectedListPage({
    super.key,
    required this.titolo,
    required this.nrListe,
  });

  final String titolo;
  final int nrListe;

  @override
  ConsumerState<SelectedListPage> createState() => _SelectedListPageState();
}

class _SelectedListPageState extends ConsumerState<SelectedListPage> {
  final logger = Logger(printer: PrettyPrinter());
  final _searchCtrl = TextEditingController();

  int selectedIndex = 0;
  String productToSearch = '';
  bool _isSearching = false;
  bool _isFidelityLoading = true;
  bool _isAccountActive = false;

  List<Prodotto> _risultati = [];
  String? _lastSearchedQuery;
  final Set<String> _selectedFilters = {};
  bool _hideUnselectedFilters = false;
  bool _searchSubmitted = false;

  final carrello = CarrelloIsar.instance;

  @override
  void initState() {
    super.initState();
    carrello.usaLista(widget.titolo); // collega il carrello alla lista
    _loadFidelityStatus();
  }

  Future<void> _loadFidelityStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isFidelityLoading = false;
        _isAccountActive = false;
      });
      return;
    }

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = snapshot.data();
      final isActive = (data?['isActive'] ?? false) as bool;
      if (!mounted) return;
      setState(() {
        _isFidelityLoading = false;
        _isAccountActive = isActive;
      });
    } catch (e, stack) {
      logger.e('Errore nel recuperare stato fidelity: $e', stackTrace: stack);
      if (!mounted) return;
      setState(() {
        _isFidelityLoading = false;
        _isAccountActive = false;
      });
    }
  }

  Future<void> openSearch(String q, {bool autoAddIfSingle = true}) async {
    final query = q.trim();
    if (query.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci almeno 3 caratteri')),
      );
      return;
    }

    if (_lastSearchedQuery == query && _risultati.isNotEmpty) {
      setState(() {
        _hideUnselectedFilters = true;
        _searchSubmitted = true;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await doSearch(query);
      if (!mounted) return;

      if (results.isEmpty) {
        setState(() {
          _risultati = [];
          _hideUnselectedFilters = true;
          _searchSubmitted = true;
          _lastSearchedQuery = query;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nessun risultato')),
        );
        return;
      }

      if (results.length == 1 && autoAddIfSingle) {
        await carrello.aggiungiProdotto(results.first);
        setState(() {
          _risultati = [];
          _searchCtrl.clear();
        });
        return;
      }

      setState(() {
        _risultati = results;
        _hideUnselectedFilters = true;
        _searchSubmitted = true;
        _lastSearchedQuery = query;
      });
    } catch (e) {
      logger.e('Errore ricerca: $e');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Widget _buildOpzioni(String title, List<String> items) {
    final filteredItems = (_selectedFilters.isNotEmpty
            ? items.where((f) => !_selectedFilters.contains(f))
            : items)
        .toList();

    if (filteredItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_hideUnselectedFilters)
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: kBluScuro)),
        if (!_hideUnselectedFilters) const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: filteredItems
              .map(
                (f) => ContainerOpzione(
                  nomeOpione: f,
                  hideWhenUnselected: _hideUnselectedFilters,
                  selected: _selectedFilters.contains(f),
                  onSelectedChanged: (isSel) {
                    setState(() {
                      if (isSel) {
                        _selectedFilters.add(f);
                      } else {
                        _selectedFilters.remove(f);
                      }
                    });
                  },
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listener BLE barcode scan
    ref.listen<String?>(scannedBarcodeProvider, (prev, next) async {
      final code = next;
      if (code == null || code.trim().isEmpty) return;

      if (selectedIndex == 1) {
        await _handleScannedCode(code);
      } else {
        _searchCtrl.text = code;
        setState(() => productToSearch = code);
        await openSearch(code, autoAddIfSingle: false);
      }
      ref.read(scannedBarcodeProvider.notifier).state = null;
    });

    final bleScanning = ref.watch(bleScanningProvider);
    final bleStatus = ref.watch(bleStatusProvider);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            scrolledUnderElevation: 0,
            title: Text(widget.titolo,
                style: const TextStyle(
                    color: kBluScuro,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            iconTheme: const IconThemeData(color: kBluScuro),
            actions: [
              IconButton(
                icon: Icon(
                  bleScanning ? Icons.bluetooth_searching : Icons.bluetooth,
                  color: bleScanning ? kPrimary : kBluScuro,
                ),
                onPressed: () async {
                  if (!_isAccountActive) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Account non attivo')),
                    );
                    return;
                  }
                  if (bleScanning) {
                    FlutterBluePlus.stopScan();
                    ref.read(bleScanningProvider.notifier).state = false;
                    ref.read(bleStatusProvider.notifier).state =
                        'Scansione interrotta';
                  } else {
                    bleStartScanAndListen(ref);
                  }
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 8),
                ToggleSwitch(
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
                  labels: ['Cerca', 'Lista'],
                  onToggle: (index) => setState(() => selectedIndex = index!),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (selectedIndex == 0) {
                        return SingleChildScrollView(
                          child: Column(
                            children: [
                              CercaProdottoField(
                                initialValue: productToSearch,
                                controller: _searchCtrl,
                                onChanged: (value) {
                                  setState(() {
                                    productToSearch = value;
                                    _risultati = [];
                                    if (value.trim().isEmpty) {
                                      _hideUnselectedFilters = false;
                                      _selectedFilters.clear();
                                      _searchSubmitted = false;
                                      _lastSearchedQuery = null;
                                    }
                                  });
                                },
                                onFieldSubmitted: (_) {
                                  final query = _searchCtrl.text.trim();
                                  if (query.length >= 3 &&
                                      !_isSearching &&
                                      query != _lastSearchedQuery) {
                                    openSearch(query, autoAddIfSingle: false);
                                  }
                                },
                              ),
                              if (_selectedFilters.isNotEmpty)
                                Wrap(
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
                              RisultatiRicerca(
                                risultati: _risultati,
                                listaTitolo: widget.titolo,
                                nrListe: widget.nrListe,
                              ),
                            ],
                          ),
                        );
                      } else {
                        return ListaProdottiInventario(
                          titolo: widget.titolo,
                          nrListe: widget.nrListe,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: selectedIndex == 0
              ? CercaProdottoBottomBar(
                  title: kCercaProdotto,
                  query: productToSearch,
                  onPressed: (productToSearch.trim().length >= 3 &&
                          !_isSearching &&
                          productToSearch.trim() != _lastSearchedQuery)
                      ? () => openSearch(productToSearch.trim(),
                          autoAddIfSingle: false)
                      : null,
                )
              : null,
        ),
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !_isSearching,
            child: FullScreenLoader(isLoading: _isSearching),
          ),
        ),
      ],
    );
  }

  Future<void> _handleScannedCode(String code) async {
    try {
      final results = await doSearch(code.trim());
      if (results.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nessun prodotto trovato')),
          );
        }
        return;
      }

      final prodotto = results.first;
      await carrello.aggiungiProdotto(prodotto);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore ricerca: $e')),
        );
      }
    }
  }
}
