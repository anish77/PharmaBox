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
import 'package:pharma_box/widgets/non_autorizzato.dart';
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

  void _aggiungi(Prodotto p, {bool clearSearchState = true}) {
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
      if (clearSearchState) {
        _risultati = [];
        _searchCtrl.clear();
      }
    });
  }

  Future<void> openSearch(String q, {bool autoAddIfSingle = true}) async {
    final query = q.trim();
    if (query.length < 3) {
      // opzionale: feedback minimo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci almeno 3 caratteri')),
      );
      return;
    }

    final sameAsLastQuery =
        _lastSearchedQuery != null &&
        _lastSearchedQuery!.toLowerCase() == query.toLowerCase();
    final hasCachedResults = sameAsLastQuery && _risultati.isNotEmpty;

    if (hasCachedResults) {
      setState(() {
        _hideUnselectedFilters = true;
        _searchSubmitted = true;
        _lastSearchedQuery = query;
      });
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

      if (prelim.length == 1 && autoAddIfSingle) {
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

  Widget _checkStatus(bool bleScanning, bool isBleConnected) {
    if (productToSearch.trim().isEmpty &&
        !_isFidelityLoading &&
        !_isAccountActive) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Center(
              child: Image.asset(
                kNoScanCode, // assicurati che il path sia corretto nel pubspec.yaml
                width: 240,
                fit: BoxFit.contain,
              ),
            ),

            Text(
              'Attiva il tuo abbonamento per utilizzare lo scanner Bluetooth.',
              style: TextStyle(
                color: kBluScuro,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NonAutorizzato(),
                  ),
                );
              },
              icon: const Icon(Icons.star, color: Colors.yellow),
              label: const Text(
                'Attiva',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
      // 🔹 Mostra immagine scanCode finché non rilevi la connessione BLE
    } else if (productToSearch.trim().isEmpty && !isBleConnected) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  if (!_isAccountActive) {
                    if (!context.mounted) {
                      logger.i(
                        'Context non montato, impossibile mostrare SnackBar',
                      );
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Account non attivo')),
                    );
                  } else {
                    if (bleScanning) {
                      FlutterBluePlus.stopScan();
                      ref.read(bleScanningProvider.notifier).state = false;
                      ref.read(bleStatusProvider.notifier).state =
                          'Scansione interrotta';
                      logger.i('Stopped BLE scan from image tap');
                    } else {
                      logger.i('Starting BLE scan from image tap');
                      bleStartScanAndListen(ref);
                    }
                  }
                },
                child: Image.asset(
                  kBluetoothImage,
                  width: 200,
                  fit: BoxFit.contain,
                  color: bleScanning ? null : kPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                bleScanning
                    ? 'Cerca Bluetooth in corso...\nInterrompi scansione Bluetooth toccando l\'icona.'
                    : 'Scanner Bluetooth non connesso.\nClicca sull\'icona Bluetooth per connetterlo.',
                style: const TextStyle(
                  color: kBluScuro,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } else {
      // 🔹 Caso predefinito: restituisci qualcosa anche se non entra nell'if
      return const SizedBox.shrink(); // widget vuoto (non occupa spazio)
    }
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
                        key: ValueKey('opt-$filtro'),
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
        // Eventi da scanner BLE
        if (selectedIndex == 1) {
          // In "Lista": aggiungi/incrementa direttamente
          await _handleScannedCode(code);
        } else if (selectedIndex == 0) {
          // In "Cerca": incrementa di 1 e mostra anche i risultati
          await _handleScannedCode(code);
          _searchCtrl.text = code;
          setState(() => productToSearch = code);
          await openSearch(code, autoAddIfSingle: false);
        } else {
          // In altre tab, facoltativamente apri la ricerca
          _searchCtrl.text = code;
          setState(() => productToSearch = code);
          await openSearch(code, autoAddIfSingle: false);
        }
        ref.read(scannedBarcodeProvider.notifier).state = null;
      });
    });

    final bleScanning = ref.watch(bleScanningProvider);
    final bleStatus = ref.watch(bleStatusProvider);
    final isBleConnected = ref.watch(bleConnected);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            scrolledUnderElevation: 0,
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
              IconButton(
                icon: Icon(
                  bleScanning ? Icons.bluetooth_searching : Icons.bluetooth,
                  color: bleScanning ? kPrimary : kBluScuro,
                ),
                tooltip:
                    bleScanning
                        ? 'Interrompi scansione Bluetooth'
                        : 'Connetti scanner Bluetooth',
                onPressed: () async {
                  if (!_isAccountActive) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Account non attivo')),
                    );
                  } else {
                    if (bleScanning) {
                      FlutterBluePlus.stopScan();
                      ref.read(bleScanningProvider.notifier).state = false;
                      ref.read(bleStatusProvider.notifier).state =
                          'Scansione interrotta';
                    } else {
                      bleStartScanAndListen(ref);
                    }
                  }
                },
              ),
            ],
          ),
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            onVerticalDragDown: (_) => FocusScope.of(context).unfocus(),
            child: Padding(
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
                            totalSwitches: 2,
                            labels: ['Cerca', 'Lista'],
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
                                              if (productToSearch
                                                  .trim()
                                                  .isEmpty) {
                                                _hideUnselectedFilters = false;
                                                _selectedFilters.clear();
                                                _searchSubmitted = false;
                                                _lastSearchedQuery = null;
                                              } else {
                                                if (_lastSearchedQuery !=
                                                        null &&
                                                    productToSearch.trim() !=
                                                        _lastSearchedQuery) {
                                                  _searchSubmitted = false;
                                                }
                                              }
                                            });
                                          },
                                          onFieldSubmitted: (_) {
                                            final query =
                                                _searchCtrl.text.trim();
                                            final canSearch =
                                                query.length >= 3 &&
                                                (_lastSearchedQuery == null ||
                                                    query !=
                                                        _lastSearchedQuery) &&
                                                !_isSearching;
                                            if (canSearch) {
                                              openSearch(
                                                query,
                                                autoAddIfSingle: false,
                                              );
                                            }
                                          },
                                        ),
                                        Column(
                                          children: [
                                            _checkStatus(
                                              bleScanning,
                                              isBleConnected,
                                            ),

                                            //button per attivare l'abbonamento
                                            // const NonAutorizzato(),
                                            if (_selectedFilters.isNotEmpty)
                                              Align(
                                                alignment: Alignment.topLeft,
                                                child: Wrap(
                                                  alignment:
                                                      WrapAlignment.start,
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children:
                                                      _selectedInOriginalOrder()
                                                          .map(
                                                            (
                                                              f,
                                                            ) => ContainerOpzione(
                                                              key: ValueKey(
                                                                'sel-$f',
                                                              ),
                                                              nomeOpione: f,
                                                              selected: true,
                                                              onSelectedChanged: (
                                                                isSel,
                                                              ) {
                                                                if (!isSel) {
                                                                  setState(() {
                                                                    _selectedFilters
                                                                        .remove(
                                                                          f,
                                                                        );
                                                                  });
                                                                }
                                                              },
                                                            ),
                                                          )
                                                          .toList(),
                                                ),
                                              ),
                                            RisultatiRicerca(
                                              risultati: _risultati,
                                              listaTitolo: widget.titolo,
                                              nrListe: widget.nrListe,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                case 1:
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
          ),
          bottomNavigationBar:
              selectedIndex == 0
                  ? CercaProdottoBottomBar(
                    title: kCercaProdotto,
                    query: productToSearch,
                    onPressed:
                        (productToSearch.trim().length >= 3 &&
                                (_lastSearchedQuery == null ||
                                    productToSearch.trim() !=
                                        _lastSearchedQuery) &&
                                !_isSearching)
                            ? () => openSearch(
                              productToSearch.trim(),
                              autoAddIfSingle: false,
                            )
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
      _aggiungi(prodotto, clearSearchState: false);

      /*
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aggiunto: ${prodotto.nome.isNotEmpty ? prodotto.nome : prodotto.minsan}')),
        );
      }
      */
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Errore ricerca: $e')));
      }
    }
  }
}
