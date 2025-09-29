import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/web.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/include/ble_functions.dart';
import 'package:pharma_box/main.dart';
import 'package:pharma_box/models/prodotto.dart';
import 'package:pharma_box/view/cerca_prodotto_field.dart';
import 'package:pharma_box/view/lista_prodotti_inventario.dart';
import 'package:pharma_box/widgets/scan_tab.dart';
import 'package:pharma_box/widgets/full_screen_loader.dart';
import 'package:pharma_box/widgets/container_opzione.dart';
import 'package:pharma_box/widgets/risultati_ricerca.dart';
import 'package:pharma_box/widgets/carrello.dart';
import 'package:pharma_box/widgets/gestione_prodotto.dart';
import 'package:toggle_switch/toggle_switch.dart';
import '../include/general_functions.dart';

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
  var logger = Logger(printer: PrettyPrinter());
  var selectedIndex = 0;
  var productToSearch = '';
  List<Prodotto> _risultati = [];
  // lista selezionata dall’utente (inventario da comporre)
  final List<Prodotto> _selezionati = [];
  final Set<String> _codiciSelezionati = {}; // per evitare duplicati
  final TextEditingController _searchCtrl = TextEditingController();
  final Set<String> _selectedFilters = {};
  bool _hideUnselectedFilters = false;
  bool _searchSubmitted = false;
  String? _lastSearchedQuery;
  bool _isSearching = false;
  bool _isFidelityLoading = true;
  bool _isAccountActive = false;

  // quantità per codice prodotto
  final Map<String, int> _qta = {};
  final GestioneProdotto _gestioneProdotto = GestioneProdotto();

  @override
  void initState() {
    super.initState();
    // Associa il carrello alla lista corrente (in base al titolo della pagina)
    Carrello.instance.usaLista(widget.titolo);
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
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
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

  // Restituisce i filtri selezionati nell'ordine originale definito nelle costanti
  List<String> _selectedInOriginalOrder() {
    final seen = <String>{};
    final ordered = <String>[];
    void addItems(List<String> items) {
      for (final it in items) {
        if (seen.add(it)) ordered.add(it);
      }
    }

    addItems(kFiltri1.items);
    addItems(kFiltri2.items);
    addItems(kFiltri3.items);
    // se in futuro aggiungi altri gruppi, chiamali qui con addItems
    return ordered.where((f) => _selectedFilters.contains(f)).toList();
  }

  int get _totaleQta => _qta.values.fold(0, (a, b) => a + b);

  void _aggiungi(Prodotto p) {
    // Aggiungi/aggiorna nel carrello (fonte verità usata dalla tab Lista)
    if (p.pezzi.value <= 0) p.pezzi.value = 1;
    Carrello.instance.aggiungiProdotto(p);

    // Mantieni anche lo stato locale per eventuali usi interni
    setState(() {
      if (_codiciSelezionati.contains(p.codice)) {
        _qta[p.codice] = (_qta[p.codice] ?? 0) + 1;
      } else {
        _selezionati.add(p);
        _codiciSelezionati.add(p.codice);
        _qta[p.codice] = 1;
      }
      _risultati = [];
      _searchCtrl.clear();
    });
  }

  Future<void> openSearch(String q) async {
    final query = q.trim();
    if (query.length < 3) {
      // opzionale: feedback minimo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci almeno 3 caratteri')),
      );
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final prelim = await doSearch(query);
      if (!mounted) return;

      if (prelim.isEmpty) {
        setState(() {
          _risultati = [];
          _hideUnselectedFilters = true;
          _searchSubmitted = true;
          _lastSearchedQuery = query;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Nessun risultato')));
        return;
      }

      if (prelim.length == 1) {
        _aggiungi(prelim.first);
        _searchCtrl.clear();
        setState(() {
          _risultati = [];
          _hideUnselectedFilters = true;
          _searchSubmitted = true;
          _lastSearchedQuery = query;
        });
        return;
      }

      setState(() {
        _risultati = prelim;
        _hideUnselectedFilters = true;
        _searchSubmitted = true;
        _lastSearchedQuery = query;
      });
    } catch (_) {
      // in caso di errore rete, degrada su UI di ricerca per eventuale retry
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _rimuoviByIndex(int i) {
    final p = _selezionati[i];
    setState(() {
      _selezionati.removeAt(i);
      _codiciSelezionati.remove(p.codice);
      _qta.remove(p.codice);
    });
  }

  void _svuotaSelezionati() {
    setState(() {
      _selezionati.clear();
      _codiciSelezionati.clear();
      _qta.clear();
    });
  }

  void _incQta(String codice) {
    setState(() {
      _qta[codice] = (_qta[codice] ?? 0) + 1;
    });
  }

  void _decQta(String codice) {
    setState(() {
      final cur = _qta[codice] ?? 0;
      if (cur > 1) {
        _qta[codice] = cur - 1;
      }
    });
  }

  Widget opzioni(String title, List<String> kFiltro) {
    // Calcola gli item visibili per questo gruppo (escludendo i già selezionati)
    final List<String> itemsToShow =
        (_selectedFilters.isNotEmpty
                ? kFiltro.where((f) => !_selectedFilters.contains(f))
                : kFiltro)
            .toList();

    // Se il gruppo non ha più item da mostrare, nascondi l'intero blocco (titolo compreso)
    if (itemsToShow.isEmpty) {
      return const SizedBox.shrink();
    }

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
            children:
                itemsToShow
                    .map(
                      (filtro) => ContainerOpzione(
                        key: ValueKey('opt-' + filtro),
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
    // Listener agli eventi di barcode (registrato durante il build)
    ref.listen<String?>(scannedBarcodeProvider, (prev, next) {
      final code = next;
      if (code == null || code.trim().isEmpty) return;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        // Se siamo nella tab "Lista", aggiungi direttamente
        if (selectedIndex == 2) {
          await _handleScannedCode(code);
        } else {
          await openSearch(code);
        }
        ref.read(scannedBarcodeProvider.notifier).state = null;
      });
    });

    final _bleScanning = ref.watch(bleScanningProvider);
    final _bleStatus = ref.watch(bleStatusProvider);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(
              widget.titolo,
              style: TextStyle(
                color: kBluScuro,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            iconTheme: const IconThemeData(color: kBluScuro),
            centerTitle: false,
            titleSpacing: 0,
            actions: [
              /*   IconButton(
                tooltip:
                    _bleScanning ? 'Interrompi scansione' : 'Avvia scanner BLE',
                icon:
                    Icon(_bleScanning ? Icons.stop : Icons.bluetooth_searching),
                onPressed:
                    _bleScanning
                        ? () => FlutterBluePlus.stopScan()
                        : () => bleStartScanAndListen(ref),
              ),*/
            ],
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
                                /*  productToSearch = '';
                                _searchCtrl.text = '';
                                _risultati = [];
                                _hideUnselectedFilters =
                                    false; // mostra di nuovo i gruppi opzioni
                                _selectedFilters
                                    .clear(); // deseleziona tutti i filtri
                                _searchSubmitted =
                                    false; // nascondi la riga selezionati
                                _lastSearchedQuery =
                                    null; // reset query cercata*/

                                _bleScanning
                                    ? () => FlutterBluePlus.stopScan()
                                    : () => bleStartScanAndListen(ref);
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
                                if (_isFidelityLoading) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                if (!_isAccountActive) {
                                  return _gestioneProdotto.nonAutorizzato();
                                }
                                return ScanTab(
                                  isScanning: _bleScanning,
                                  statusLabel: _bleStatus,
                                  onToggleScan:
                                      _bleScanning
                                          ? () => FlutterBluePlus.stopScan()
                                          : () => bleStartScanAndListen(ref),
                                );

                              //: GestioneProdotto().nonAutorizzato();
                              case 1:
                                final showFilterGroups =
                                    !_hideUnselectedFilters ||
                                    _selectedFilters.isNotEmpty;

                                return SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      CercaProdottoField(
                                        initialValue: productToSearch,
                                        controller: _searchCtrl,
                                        onChanged: (value) {
                                          setState(() {
                                            productToSearch = value;
                                            // Non mostrare risultati automaticamente mentre si digita
                                            // Svuota i risultati finché non si preme il bottone "Cerca"
                                            _risultati = [];
                                            if (productToSearch
                                                .trim()
                                                .isEmpty) {
                                              _hideUnselectedFilters = false;
                                              _selectedFilters.clear();
                                              _searchSubmitted = false;
                                              _lastSearchedQuery = null;
                                            } else {
                                              // Riabilita il bottone se il testo differisce dall'ultima ricerca
                                              if (_lastSearchedQuery != null &&
                                                  productToSearch.trim() !=
                                                      _lastSearchedQuery) {
                                                _searchSubmitted = false;
                                              }
                                            }
                                          });
                                        },
                                      ),
                                      if (_selectedFilters.isNotEmpty)
                                        Align(
                                          alignment: Alignment.topLeft,
                                          child: Wrap(
                                            alignment: WrapAlignment.start,
                                            spacing: 8,
                                            runSpacing: 8,
                                            children:
                                                _selectedInOriginalOrder()
                                                    .map(
                                                      (f) => ContainerOpzione(
                                                        key: ValueKey(
                                                          'sel-' + f,
                                                        ),
                                                        nomeOpione: f,
                                                        selected: true,
                                                        onSelectedChanged: (
                                                          isSel,
                                                        ) {
                                                          if (!isSel) {
                                                            setState(() {
                                                              _selectedFilters
                                                                  .remove(f);
                                                            });
                                                          }
                                                        },
                                                      ),
                                                    )
                                                    .toList(),
                                          ),
                                        ),
                                      if (showFilterGroups) ...[
                                        opzioni(kFiltri1.title, kFiltri1.items),
                                        opzioni(kFiltri2.title, kFiltri2.items),
                                        opzioni(kFiltri3.title, kFiltri3.items),
                                      ],
                                      RisultatiRicerca(
                                        risultati: _risultati,
                                        listaTitolo: widget.titolo,
                                        nrListe: widget.nrListe,
                                      ),
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
                    onPressed:
                        (productToSearch.trim().length >= 3 &&
                                (_lastSearchedQuery == null ||
                                    productToSearch.trim() !=
                                        _lastSearchedQuery) &&
                                !_isSearching)
                            ? () => openSearch(productToSearch.trim())
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
}

extension on _SelectedListPageState {
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

      // Se più risultati, per ora aggiunge il primo
      final prodotto = results.first;
      _aggiungi(prodotto);

      /*
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aggiunto: ${prodotto.nome.isNotEmpty ? prodotto.nome : prodotto.minsan}')),
        );
      }
      */
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore ricerca: $e')),
        );
      }
    }
  }
}
