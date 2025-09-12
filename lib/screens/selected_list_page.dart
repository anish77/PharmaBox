import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:logger/web.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/main.dart';
//import 'package:pharma_box/widgets/container_opzione.dart';
import 'package:pharma_box/widgets/custom_button.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:xml/xml.dart' as xml;
import 'package:pharma_box/data/datacached.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../include/general_functions.dart';
import 'package:pharma_box/include/ble_functions.dart';

class Prodotto {
  final String codice;
  final String nome;
  final String tipo_prodotto;
  Prodotto({
    required this.codice,
    required this.nome,
    required this.tipo_prodotto,
  });
}

List<Prodotto> _parseInnerProductsXml(String innerXml) {
  final innerDoc = xml.XmlDocument.parse(innerXml);

  // se l'XML ha un root <Prodotti> con figli <Prodotto>...
  final prodotti = innerDoc.findAllElements('Product');
  return prodotti.map((p) {
    final codice = p.getElement('FDI_0001')?.text.trim() ?? '';
    final nome = p.getElement('FDI_0004')?.text.trim() ?? '';
    final tipo_prodotto =
        CategoriaMapper.getDescrizione(
          p.getElement('FDI_0008')?.text.trim() ?? '',
        ) ??
        '';
    return Prodotto(codice: codice, nome: nome, tipo_prodotto: tipo_prodotto);
  }).toList();
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

class ProdottiSearchDelegate extends SearchDelegate<Prodotto?> {
  ProdottiSearchDelegate({required this.onSearch});

  final Future<List<Prodotto>> Function(String query) onSearch;

  @override
  String? get searchFieldLabel => 'Cerca prodotto…';
  @override
  TextInputAction get textInputAction => TextInputAction.search;

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(
      icon: const Icon(Icons.search),
      onPressed: () => showResults(context), // 👈 tasto lente avvia risultati
    ),
    if (query.isNotEmpty)
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildSuggestions(BuildContext context) {
    // 👇 Se arrivo già con una query (da showSearch(query: ...)),
    // mostra SUBITO i risultati al primo frame.
    final q = query.trim();
    if (q.length >= 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).mounted) {
          showResults(context);
        }
      });
    }
    return const Center(child: Text('Scrivi almeno 3 caratteri e premi Invio'));
  }

  @override
  Widget buildResults(BuildContext context) {
    final q = query.trim();
    if (q.length < 3) {
      return const Center(child: Text('Inserisci almeno 3 caratteri'));
    }
    return FutureBuilder<List<Prodotto>>(
      key: ValueKey(q), // forza il refresh quando cambia query
      future: onSearch(q),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return const Center(child: Text('Errore durante la ricerca'));
        }
        final results = snap.data ?? [];
        if (results.isEmpty) {
          return const Center(child: Text('Nessun risultato'));
        }
        return ListView.separated(
          itemCount: results.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final p = results[i];
            return ListTile(
              dense: true,
              title: Text(p.nome, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                p.codice,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => close(context, p),
            );
          },
        );
      },
    );
  }
}

class _SelectedListPageState extends ConsumerState<SelectedListPage> {
  var logger = Logger(printer: PrettyPrinter());
  var selectedIndex = 0;
  final _cercaProdottoKeyForm = GlobalKey<FormState>();
  String _query = '';
  bool _isLoading = false;
  List<Prodotto> _risultati = [];
  // lista selezionata dall’utente (inventario da comporre)
  final List<Prodotto> _selezionati = [];
  final Set<String> _codiciSelezionati = {}; // per evitare duplicati
  final TextEditingController _searchCtrl = TextEditingController();

  // quantità per codice prodotto
  final Map<String, int> _qta = {};

  
  

  int get _totaleQta => _qta.values.fold(0, (a, b) => a + b);
  // initState non usa più ref.listen; listener spostato nel build

  Widget cercaProdotto() {
    return TextFormField(
      controller: _searchCtrl,
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
      onFieldSubmitted: (q) => openSearch(q),

      //onSubmitted: (q) => _openSearch(q),
      onChanged: (value) {
        setState(() {
          //productToSearch = value;
        });
        //print(productToSearch);
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
              //ContainerOpzione(nomeOpione: "Warning 1"),
              //ContainerOpzione(nomeOpione: "Warning 1"),
              //ContainerOpzione(nomeOpione: "Warning 1"),
              //ContainerOpzione(nomeOpione: "Warning 1"),
              //ContainerOpzione(nomeOpione: "Warning 1"),
            ],
          ),
        ),
        SizedBox(height: 18),
      ],
    );
  }

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
          headers: {
            'Content-Type': 'text/xml; charset=utf-8',
            'Accept': 'application/xml',
            'SOAPAction':
                'http://webservices.farmadati.it/FarmadatiItaliaWebServicesM1/ExecuteQuery',
          },
          body: xmlBody, // assicuri UTF-8
        )
        .timeout(const Duration(seconds: 12));

    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
    }
    logger.i(utf8.decode(resp.bodyBytes));
    return utf8.decode(resp.bodyBytes); // risposta come XML string
  }

  String buildSearchXml(String query) {
    final cCampo = int.tryParse(query) != null ? 'FDI_0001' : 'FDI_0004';
    return '''
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:web="http://webservices.farmadati.it" xmlns:arr="http://schemas.microsoft.com/2003/10/Serialization/Arrays" xmlns:fdiw="http://schemas.datacontract.org/2004/07/FDIWebServices">
   <soapenv:Header/>
   <soapenv:Body>
      <web:ExecuteQuery>
         <web:Username>BDF203348XC</web:Username>
         <web:Password>epxD67iZR</web:Password>
         <web:CodiceSetDati>TR001</web:CodiceSetDati>
         <web:CampiDaEstrarre>
            <arr:string>ALL</arr:string>
         </web:CampiDaEstrarre>
         
		<web:Filtri>            
            <fdiw:Filter>               
               <fdiw:Key>$cCampo</fdiw:Key>               
               <fdiw:Operator>CONTIENE</fdiw:Operator>               
               <fdiw:Value>$query</fdiw:Value>
            </fdiw:Filter>
         </web:Filtri>
         <web:PageN>1</web:PageN>
         <web:PagingN>100</web:PagingN>
      </web:ExecuteQuery>
   </soapenv:Body>
</soapenv:Envelope>
''';
  }

  Future<List<Prodotto>> _doSearch(String q) async {
    try {
      final xmlBody = buildSearchXml(q);
      final xmlResp = await _postXml(
        'http://webservices.farmadati.it/WS2/FarmadatiItaliaWebServicesM1.svc',
        xmlBody,
      );
      final inner = _extractInnerXmlFromSoap(xmlResp);
      if (inner == null) return [];
      return _parseInnerProductsXml(inner);
    } catch (_) {
      return [];
    }
  }

  void _aggiungi(Prodotto p) {
    if (_codiciSelezionati.contains(p.codice)) return;
    setState(() {
      _selezionati.add(p);
      _codiciSelezionati.add(p.codice);
      _qta[p.codice] = 1;
      _risultati = []; // facoltativo: pulisci risultati
      _searchCtrl.clear(); // facoltativo: svuota barra
    });
  }

  Future<void> openSearch(String q) async {
    final Prodotto? scelto = await showSearch<Prodotto?>(
      context: context,
      delegate: ProdottiSearchDelegate(onSearch: _doSearch),
      query: q.trim(), // 👈 usa il parametro nativo
    );

    if (!mounted) return;
    if (scelto != null) {
      _aggiungi(scelto);
      _searchCtrl.clear();
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
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titolo),
        centerTitle: false,
        titleSpacing: 0,
        actions: [
          IconButton(
            tooltip:
                _bleScanning ? 'Interrompi scansione' : 'Avvia scanner BLE',
            icon: Icon(_bleScanning ? Icons.stop : Icons.bluetooth_searching),
            onPressed:
                _bleScanning
                    ? () => FlutterBluePlus.stopScan()
                    : () => bleStartScanAndListen(ref),
          ),
        ],
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
                      //opzioni("Status"),
                      //opzioni("Category"),
                      //opzioni("Category"),
                    ],
                    // piccolo status BLE
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 12,
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _bleStatus,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(
          top: 18,
          bottom: 45,
          left: 24,
          right: 24,
        ),
        child: // Bottone
            CustomButton(
          title: "Applica opzioni",
          titleColor: Colors.white,
          backgroundColor: kPrimary,
          onPressed: () {
            //TODO
          },
        ),
      ),
    );
  }
}
