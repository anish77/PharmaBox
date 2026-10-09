import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/web.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/features/subscribtions/offerings_cubit.dart';
import 'package:pharma_box/features/subscribtions/offerings_state.dart';
import 'package:pharma_box/features/subscribtions/subscribtion_cubit.dart';
import 'package:pharma_box/features/subscribtions/subscribtion_state.dart';
import 'package:pharma_box/include/ble_functions.dart';
import 'package:pharma_box/main.dart';
import 'package:pharma_box/models/prodotto.dart';
import 'package:pharma_box/view/cerca_prodotto_field.dart';
import 'package:pharma_box/view/lista_prodotti_inventario.dart';
import 'package:pharma_box/widgets/full_screen_loader.dart';
import 'package:pharma_box/widgets/container_opzione.dart';
import 'package:pharma_box/widgets/risultati_ricerca.dart';
import 'package:pharma_box/widgets/carrello.dart';
import 'package:pharma_box/widgets/scanner_not_connected_card.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:url_launcher/url_launcher.dart';
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
  @override
  void initState() {
    super.initState();
    // Associa il carrello alla lista corrente (in base al titolo della pagina)
    Carrello.instance.usaLista(widget.titolo);
    _loadSubscriptionStatus();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSubscriptionStatus() async {
    setState(() {
      _isFidelityLoading = true;
    });
    await context.read<SubscriptionCubit>().checkProStatus();
    if (mounted) {
      setState(() {
        _isFidelityLoading = false;
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
    // Durante il caricamento iniziale, mostra un loading invece di assumere pro
    if (_isFidelityLoading && productToSearch.trim().isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (productToSearch.trim().isEmpty &&
        !_isFidelityLoading &&
        !_isAccountActive) {
      return _buildSubscriptionUpsell();
    }
    if (productToSearch.trim().isEmpty) {
      return _buildBluetoothStatus(bleScanning, isBleConnected);
    }
    return const SizedBox.shrink();
  }

  Widget _buildBluetoothStatus(bool bleScanning, bool isBleConnected) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBluetoothImage(bleScanning, isBleConnected),
          const SizedBox(height: 12),
          if (!isBleConnected && !bleScanning) const ScannerNotConnectedCard(),
        ],
      ),
    );
  }

  Widget _buildBluetoothImage(bool bleScanning, bool isBleConnected) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        if (!_isAccountActive) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Account non attivo')));
          return;
        }
        if (bleScanning) {
          FlutterBluePlus.stopScan();
          ref.read(bleScanningProvider.notifier).state = false;
        } else if (isBleConnected) {
          await bleDisconnect(ref);
        } else {
          bleStartScanAndListen(ref);
        }
      },
      child: Image.asset(
        kBluetoothImage,
        width: 150,
        fit: BoxFit.contain,
        color: isBleConnected ? null : kPrimary,
      ),
    );
  }

  // Schermata compatta: i due requisiti sono immediatamente visibili.
  Widget _buildSubscriptionUpsell() {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 8),
      child: Column(
        children: [
          Image.asset(
            kScanCode2,
            height: 112,
            width: double.infinity,
            fit: BoxFit.contain,
            errorBuilder:
                (_, __, ___) => const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: kPrimary,
                  size: 72,
                ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Attiva lo scanner Bluetooth',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kBluScuro,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Per scansionare i prodotti servono due cose:',
            textAlign: TextAlign.center,
            style: TextStyle(color: kBluScuro, fontSize: 12),
          ),
          const SizedBox(height: 4),
          _buildRequirementCard(
            number: '1',

            title: 'Attiva PharmaBox Premium',
            description: 'Sblocca la scansione Bluetooth nell’app.',
            child: BlocConsumer<OfferingsCubit, OfferingsState>(
              listener: (context, state) {
                if (state is PurchaseError) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.message)));
                }
              },
              builder: (context, state) {
                Package? annualPackage;
                String? annualPrice;
                final isPurchasing = state is PurchaseLoading;
                if (state is OfferingsLoaded) {
                  for (final package in state.packages) {
                    if (package.packageType == PackageType.annual) {
                      annualPackage = package;
                      annualPrice = package.storeProduct.priceString;
                      break;
                    }
                  }
                } else if (state is PurchaseLoading || state is PurchaseError) {
                  final packages =
                      state is PurchaseLoading
                          ? state.packages
                          : (state as PurchaseError).packages;
                  for (final package in packages) {
                    if (package.packageType == PackageType.annual) {
                      annualPackage = package;
                      annualPrice = package.storeProduct.priceString;
                      break;
                    }
                  }
                }
                final packageToPurchase = annualPackage;
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        packageToPurchase == null || isPurchasing
                            ? null
                            : () => context
                                .read<OfferingsCubit>()
                                .purchasePackage(packageToPurchase, () {}),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      shape: const StadiumBorder(),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child:
                          isPurchasing
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    annualPrice == null
                                        ? 'Attiva Premium'
                                        : 'Attiva Premium · $annualPrice / anno',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 7),
          _buildRequirementCard(
            number: '2',
            imagePath: kScaner,
            title: 'Acquista un lettore barcode',
            description:
                'Serve un lettore Bluetooth compatibile, '
                'da acquistare separatamente.',
            inlineChild: true,
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _openBarcodeReader,
                style: TextButton.styleFrom(
                  foregroundColor: kPrimary,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Vedi lettore barcode ↗',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: kBluScuro),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Il lettore non è incluso nell’abbonamento.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kBluScuro, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementCard({
    required String number,
    IconData? icon,
    String? imagePath,
    required String title,
    required String description,
    required Widget child,
    bool inlineChild = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kSecondary),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 58,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: kSecondary,
                      child: Text(
                        number,
                        style: const TextStyle(
                          color: kBluScuro,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    if (imagePath != null)
                      Image.asset(
                        imagePath,
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                      )
                    else if (icon != null)
                      Icon(icon, color: kPrimary, size: 35),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: kBluScuro,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(color: kBluScuro, fontSize: 12),
                    ),
                    if (inlineChild) ...[const SizedBox(height: 3), child],
                  ],
                ),
              ),
            ],
          ),
          if (!inlineChild) ...[const SizedBox(height: 7), child],
        ],
      ),
    );
  }

  Future<void> _openBarcodeReader() async {
    final launched = await launchUrl(
      Uri.parse(kAmazonScanner),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossibile aprire la pagina del lettore barcode.'),
        ),
      );
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
    //final bleStatus = ref.watch(bleStatusProvider);
    final isBleConnected = ref.watch(bleConnected);
    return BlocListener<SubscriptionCubit, SubscribtionState>(
      listener: (context, state) {
        if (state is SubscribtionLoaded) {
          setState(() {
            _isAccountActive = state.isPro;
            _isFidelityLoading = false;
          });
        }
      },
      child: Stack(
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
                                                  _hideUnselectedFilters =
                                                      false;
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
      ),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Errore ricerca: $e')));
      }
    }
  }
}
