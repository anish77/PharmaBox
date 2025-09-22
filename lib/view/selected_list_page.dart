import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:logger/web.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/include/ble_functions.dart';
import 'package:pharma_box/logic/_soap_config.dart';
import 'package:pharma_box/main.dart';
import 'package:pharma_box/models/prodotto.dart';
import 'package:pharma_box/view/cerca_prodotto_field.dart';
import 'package:pharma_box/view/lista_prodotti_inventario.dart';
import 'package:pharma_box/widgets/scan_tab.dart';
import 'package:pharma_box/widgets/full_screen_loader.dart';
import 'package:pharma_box/widgets/container_opzione.dart';
import 'package:pharma_box/widgets/risultati_ricerca.dart';
import 'package:pharma_box/widgets/gestione_prodotto.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:xml/xml.dart' as xml;
import 'package:pharma_box/data/datacached.dart';
import '../include/general_functions.dart';

enum DatasetKind { tr001, tdz }

List<Prodotto> _parseInnerProductsXml(
  String innerXml,
  DatasetKind dataSetSchema,
) {
  final innerDoc = xml.XmlDocument.parse(innerXml);
  final prodotti = innerDoc.findAllElements('Product');

  switch (dataSetSchema) {
    case DatasetKind.tr001:

      // se l'XML ha un root <Prodotti> con figli <Prodotto>...

      return prodotti.map((p) {
        final codice = p.getElement('FDI_0001')?.text.trim() ?? '';
        final minsan = p.getElement('FDI_0002')?.text.trim();
        final nome = p.getElement('FDI_0004')?.text.trim() ?? '';
        final tipo_prodotto =
            CategoriaMapper.getDescrizione(
              p.getElement('FDI_0008')?.text.trim() ?? '',
            ) ??
            '';
        return Prodotto(
          codice: codice,
          nome: nome,
          tipo_prodotto: tipo_prodotto,
          minsan: (minsan != null && minsan.isNotEmpty) ? minsan : codice,
          immagine: '',
          pezzi: 1,
          consentito: true,
          description: '',
          ingredients: '',
          howToTake: '',
        );
      }).toList();
    case DatasetKind.tdz:
      // se l'XML ha un root <Prodotti> con figli <Prodotto>...

      return prodotti.map((p) {
        final codice = p.getElement('FDI_T218')?.text.trim() ?? '';
        final immagine = p.getElement('FDI_T438')?.text.trim() ?? '';

        return Prodotto(
          codice: codice,
          immagine: immagine,
          nome: '',
          minsan: codice,
          pezzi: 1,
          consentito: true,
          description: '',
          ingredients: '',
          howToTake: '',
        );
      }).toList();
  }
}

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
  bool _isFidelizzato = false;

  // quantità per codice prodotto
  final Map<String, int> _qta = {};
  final GestioneProdotto _gestioneProdotto = GestioneProdotto();

  @override
  void initState() {
    super.initState();
    _loadFidelityStatus();
  }

  Future<void> _loadFidelityStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isFidelityLoading = false;
        _isFidelizzato = false;
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
      final fidelizzato = (data?['fidelizzato'] ?? false) as bool;
      if (!mounted) return;
      setState(() {
        _isFidelityLoading = false;
        _isFidelizzato = fidelizzato;
      });
    } catch (e, stack) {
      logger.e('Errore nel recuperare stato fidelity: $e', stackTrace: stack);
      if (!mounted) return;
      setState(() {
        _isFidelityLoading = false;
        _isFidelizzato = false;
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
  // initState non usa più ref.listen; listener spostato nel build
  // de-escape XML tipo "&lt;Prodotti&gt;...&lt;/Prodotti&gt;"
  String _xmlUnescape(String s) => s
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'");

  // prova a trovare il <soap:Body> (SOAP 1.1 o 1.2)
  xml.XmlElement? _findSoapBody(xml.XmlDocument doc) {
    final body11 = doc.findAllElements(
      'Body',
      namespace: 'http://schemas.xmlsoap.org/soap/envelope/',
    );
    if (body11.isNotEmpty) return body11.first;

    final body12 = doc.findAllElements(
      'Body',
      namespace: 'http://www.w3.org/2003/05/soap-envelope',
    );
    if (body12.isNotEmpty) return body12.first;

    // fallback senza namespace (non standard ma utile in test)
    final any = doc.findAllElements('Body');
    return any.isNotEmpty ? any.first : null;
  }

  /// Estrae la stringa XML annidata:
  /// - Se c’è CDATA: prende il contenuto cdata
  /// - Se è escapato: fa unescape
  /// - Se l’XML è direttamente annidato come sotto-elementi, restituisce l’outerXML di quel nodo
  String? _extractInnerXmlFromSoap(String soapXml) {
    final doc = xml.XmlDocument.parse(soapXml);
    final body = _findSoapBody(doc);
    if (body == null) return null;

    // Cerca un nodo "Result" o "Response" che tipicamente contiene l'XML annidato
    final candidates =
        body.descendants
            .whereType<xml.XmlElement>()
            .where((e) => e.name.local.endsWith('OutputValue'))
            .toList();

    if (candidates.isEmpty) {
      // fallback: prendi il primo figlio del Body
      final first = body.children.whereType<xml.XmlElement>().toList();
      if (first.isEmpty) return null;
      // se ha CDATA o testo con &lt;...&gt; lo gestiamo sotto
      final text =
          first.first.descendants
              .whereType<xml.XmlText>()
              .map((t) => t.text)
              .join()
              .trim();
      if (text.contains('<') || text.contains('&lt;')) {
        return text.contains('&lt;') ? _xmlUnescape(text) : text;
      }
      // altrimenti potremmo avere già XML annidato come elementi: prendi l'outer XML del sottoalbero
      return first.first.toXmlString();
    }

    final node = candidates.first;

    // 1) CDATA?
    final cdataText =
        node.children
            .whereType<xml.XmlCDATA>()
            .map((c) => c.text.trim())
            .join();
    if (cdataText.isNotEmpty) return cdataText;

    // 2) Testo escapato?
    final text =
        node.descendants
            .whereType<xml.XmlText>()
            .map((t) => t.text)
            .join()
            .trim();
    if (text.isNotEmpty) {
      return text.contains('&lt;') ? _xmlUnescape(text) : text;
    }

    // 3) XML direttamente annidato come elementi
    final firstChildElem = node.children.whereType<xml.XmlElement>().toList();
    if (firstChildElem.isNotEmpty) {
      // restituisce l'outer xml del sottoalbero
      return firstChildElem.first.toXmlString();
    }

    return null;
  }

  Future<String> _postXml(String endpoint, String xmlBody) async {
    final uri = Uri.parse(endpoint);
    final resp = await http
        .post(
          uri,
          headers: kFarmadatiSoapHeaders,
          body: xmlBody, // assicuri UTF-8
        )
        .timeout(const Duration(seconds: 12));

    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
    }
    logger.i(utf8.decode(resp.bodyBytes));
    return utf8.decode(resp.bodyBytes); // risposta come XML string
  }

  Future<void> _getOrPutImage(String minsan) async {
    String xmlBodyImage = buildSearchXml(minsan, kind: SearchKind.immagine);

    String xmlResp2 = await _postXml(kFarmadatiEndpoint, xmlBodyImage);

    String? inner2 = _extractInnerXmlFromSoap(xmlResp2);

    if (inner2 != null && inner2 != "EMPTY") {
      String imagefilename =
          _parseInnerProductsXml(inner2, DatasetKind.tdz).first.immagine ?? "";
      String imageurl =
          "https://ws.farmadati.it/WS_DOC/GetDoc.aspx?accesskey=epxD67iZR&tipodoc=Z&nomefile=$imagefilename";

      String? cdnUrl = await r2IngestImageByUrl(
        minsan: _parseInnerProductsXml(inner2, DatasetKind.tdz).first.codice,
        imageUrl: imageurl,
      );
      print(cdnUrl);
    }
  }

  Future<List<Prodotto>> _doSearch(String q) async {
    try {
      if (q.length > 6 && RegExp(r'^[0-9]+$').hasMatch(q)) {
        String xmlEanBody = buildSearchXml(q, kind: SearchKind.ean);
        String eanList = await _postXml(kFarmadatiEndpoint, xmlEanBody);
        String? inner = _extractInnerXmlFromSoap(eanList);
        if (inner == null) return [];
        List<Prodotto> listaEan = _parseInnerProductsXml(
          inner,
          DatasetKind.tr001,
        );

        List<Prodotto> Minsan = [];

        for (var prodotto in listaEan) {
          String xmlBody = buildSearchXml(
            prodotto.codice,
            kind: SearchKind.prodotti,
          );
          String xmlResp = await _postXml(kFarmadatiEndpoint, xmlBody);
          String? inner = _extractInnerXmlFromSoap(xmlResp);
          if (inner != null) {
            Minsan.add(_parseInnerProductsXml(inner, DatasetKind.tr001).first);

            _getOrPutImage(
              _parseInnerProductsXml(inner, DatasetKind.tr001).first.codice,
            );
          }
        }
        logger.i(Minsan.length);
        return Minsan;
      }
      final xmlBody = buildSearchXml(q, kind: SearchKind.prodotti);
      final xmlResp = await _postXml(kFarmadatiEndpoint, xmlBody);
      final inner = _extractInnerXmlFromSoap(xmlResp);
      if (inner == null) return [];
      _getOrPutImage(
        _parseInnerProductsXml(inner, DatasetKind.tr001).first.codice,
      );
      return _parseInnerProductsXml(inner, DatasetKind.tr001);
    } catch (errore) {
      print(errore);
      return [];
    }
  }

  void _aggiungi(Prodotto p) {
    setState(() {
      if (_codiciSelezionati.contains(p.codice)) {
        // già presente: incrementa la quantità
        _qta[p.codice] = (_qta[p.codice] ?? 0) + 1;
      } else {
        // nuovo prodotto selezionato
        _selezionati.add(p);
        _codiciSelezionati.add(p.codice);
        _qta[p.codice] = 1;
      }
      _risultati = []; // facoltativo: pulisci risultati
      _searchCtrl.clear(); // facoltativo: svuota barra
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
      final prelim = await _doSearch(query);
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
        await openSearch(code);
        ref.read(scannedBarcodeProvider.notifier).state = null;
      });
    });

    final _bleScanning = ref.watch(bleScanningProvider);
    final _bleStatus = ref.watch(bleStatusProvider);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(widget.titolo),
            centerTitle: false,
            titleSpacing: 0,
            /*  actions: [
                IconButton(
                tooltip:
                    _bleScanning ? 'Interrompi scansione' : 'Avvia scanner BLE',
                icon:
                    Icon(_bleScanning ? Icons.stop : Icons.bluetooth_searching),
                onPressed:
                    _bleScanning
                        ? () => FlutterBluePlus.stopScan()
                        : () => bleStartScanAndListen(ref),
              ),
            ],*/
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
                                _searchCtrl.text = '';
                                _risultati = [];
                                _hideUnselectedFilters =
                                    false; // mostra di nuovo i gruppi opzioni
                                _selectedFilters
                                    .clear(); // deseleziona tutti i filtri
                                _searchSubmitted =
                                    false; // nascondi la riga selezionati
                                _lastSearchedQuery =
                                    null; // reset query cercata
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
                                if (!_isFidelizzato) {
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
