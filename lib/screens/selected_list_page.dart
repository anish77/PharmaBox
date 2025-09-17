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

enum SearchKind { prodotti, ean, lottiInvendibili, immagine }

enum DatasetKind { tr001, tdz }

class Prodotto {
  final String codice;
  final String? nome;
  final String? tipo_prodotto;
  final String? immagine;
  Prodotto({
    required this.codice,
    this.nome,
    this.tipo_prodotto,
    this.immagine,
  });
}

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
        );
      }).toList();
    case DatasetKind.tdz:
      // se l'XML ha un root <Prodotti> con figli <Prodotto>...

      return prodotti.map((p) {
        final codice = p.getElement('FDI_T218')?.text.trim() ?? '';
        final immagine = p.getElement('FDI_T438')?.text.trim() ?? '';

        return Prodotto(codice: codice, immagine: immagine);
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
        if (results.length == 1) {
          // Un solo risultato: selezionalo automaticamente
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.of(context).mounted) {
              close(context, results.first);
            }
          });
          return const SizedBox.shrink();
        }
        return ListView.separated(
          itemCount: results.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final p = results[i];
            return ListTile(
              dense: true,
              title: Text(
                p.nome ?? "",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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

  String buildSearchXml(String query, {SearchKind kind = SearchKind.prodotti}) {
    switch (kind) {
      case SearchKind.prodotti:
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
      case SearchKind.ean:
        return '''
      <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:web="http://webservices.farmadati.it" xmlns:arr="http://schemas.microsoft.com/2003/10/Serialization/Arrays" xmlns:fdiw="http://schemas.datacontract.org/2004/07/FDIWebServices">
        <soapenv:Header/>
        <soapenv:Body>
            <web:ExecuteQuery>
              <web:Username>BDF203348XC</web:Username>
              <web:Password>epxD67iZR</web:Password>
              <web:CodiceSetDati>TR016</web:CodiceSetDati>
              <web:CampiDaEstrarre>
                  <arr:string>ALL</arr:string>
              </web:CampiDaEstrarre>
              
          <web:Filtri>            
                  <fdiw:Filter>               
                    <fdiw:Key>FDI_0002</fdiw:Key>               
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
      case SearchKind.lottiInvendibili:
        return '''
      <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:web="http://webservices.farmadati.it" xmlns:arr="http://schemas.microsoft.com/2003/10/Serialization/Arrays" xmlns:fdiw="http://schemas.datacontract.org/2004/07/FDIWebServices">
        <soapenv:Header/>
        <soapenv:Body>
            <web:ExecuteQuery>
              <web:Username>BDF203348XC</web:Username>
              <web:Password>epxD67iZR</web:Password>
              <web:CodiceSetDati>TR_LOTTI_INV</web:CodiceSetDati>
              <web:CampiDaEstrarre>
                  <arr:string>ALL</arr:string>
              </web:CampiDaEstrarre>
              
          <web:Filtri>            
                  <fdiw:Filter>               
                    <fdiw:Key>FDI_0001</fdiw:Key>               
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
      case SearchKind.immagine:
        return '''
      <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:web="http://webservices.farmadati.it" xmlns:arr="http://schemas.microsoft.com/2003/10/Serialization/Arrays" xmlns:fdiw="http://schemas.datacontract.org/2004/07/FDIWebServices">
   <soapenv:Header/>
   <soapenv:Body>
      <web:ExecuteQuery>
         <web:Username>BDF203348XC</web:Username>
         <web:Password>epxD67iZR</web:Password>
         <web:CodiceSetDati>TDZ</web:CodiceSetDati>
         <web:CampiDaEstrarre>
            <arr:string>ALL</arr:string>
         </web:CampiDaEstrarre>
         
		<web:Filtri>            
            <fdiw:Filter>               
               <fdiw:Key>FDI_T218</fdiw:Key>               
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
  }

  Future<void> _getOrPutImage(String minsan) async {
    
    String xmlBodyImage = buildSearchXml(
      minsan,
      kind: SearchKind.immagine,
    );

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
      print( cdnUrl);
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

            _getOrPutImage(_parseInnerProductsXml(inner, DatasetKind.tr001).first.codice);
          }
        }
        logger.i(Minsan.length);
        return Minsan;
      }
      final xmlBody = buildSearchXml(q, kind: SearchKind.prodotti);
      final xmlResp = await _postXml(kFarmadatiEndpoint, xmlBody);
      final inner = _extractInnerXmlFromSoap(xmlResp);
      if (inner == null) return [];
      _getOrPutImage(_parseInnerProductsXml(inner, DatasetKind.tr001).first.codice);
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

    try {
      final prelim = await _doSearch(query);
      if (!mounted) return;
      if (prelim.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Nessun risultato')));
        return;
      }
      if (prelim.length == 1) {
        _aggiungi(prelim.first);
        _searchCtrl.clear();
        return; // evita di aprire la UI
      }
    } catch (_) {
      // in caso di errore rete, degrada su UI di ricerca per eventuale retry
    }

    final Prodotto? scelto = await showSearch<Prodotto?>(
      context: context,
      delegate: ProdottiSearchDelegate(onSearch: _doSearch),
      query: query, // 👈 usa il parametro nativo
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

  Widget _buildSelezionatiList() {
    if (_selezionati.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.centerLeft,
        child: Text(
          'Nessun prodotto selezionato',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Selezionati (${_selezionati.length}) · Totale pezzi: $_totaleQta',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: kBluScuro,
              ),
            ),
            TextButton(
              onPressed: _svuotaSelezionati,
              child: const Text('Svuota'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _selezionati.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final p = _selezionati[i];
            final q = _qta[p.codice] ?? 0;
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: 4,
              ),
              title: Text(
                p.nome ?? "",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${p.codice}${p.tipo_prodotto!.isNotEmpty ? ' • ${p.tipo_prodotto}' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => _decQta(p.codice),
                    tooltip: 'Diminuisci',
                  ),
                  Text(
                    '$q',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => _incQta(p.codice),
                    tooltip: 'Aumenta',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _rimuoviByIndex(i),
                    tooltip: 'Rimuovi',
                  ),
                ],
              ),
            );
          },
        ),
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
                    const SizedBox(height: 8),
                    _buildSelezionatiList(),
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
