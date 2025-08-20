import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/web.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:xml/xml.dart' as xml;

class Prodotto {
  final String codice;
  final String nome;
  Prodotto({required this.codice, required this.nome});
}

List<Prodotto> _parseInnerProductsXml(String innerXml) {
  final innerDoc = xml.XmlDocument.parse(innerXml);

  // se l'XML ha un root <Prodotti> con figli <Prodotto>...
  final prodotti = innerDoc.findAllElements('Product');
  return prodotti.map((p) {
    final codice = p.getElement('FDI_0001')?.text.trim() ?? '';
    final nome   = p.getElement('FDI_0004')?.text.trim()   ?? '';
    return Prodotto(codice: codice, nome: nome);
  }).toList();
}

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
  final _cercaProdottoKeyForm = GlobalKey<FormState>();
  String _query = '';
  bool _isLoading = false;
  List<Prodotto> _prodotti = [];

  // de-escape XML tipo "&lt;Prodotti&gt;...&lt;/Prodotti&gt;"
String _xmlUnescape(String s) => s
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&amp;', '&')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'");

// prova a trovare il <soap:Body> (SOAP 1.1 o 1.2)
xml.XmlElement? _findSoapBody(xml.XmlDocument doc) {
  final body11 = doc.findAllElements('Body',
      namespace: 'http://schemas.xmlsoap.org/soap/envelope/');
  if (body11.isNotEmpty) return body11.first;

  final body12 = doc.findAllElements('Body',
      namespace: 'http://www.w3.org/2003/05/soap-envelope');
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
  final candidates = body.descendants
      .whereType<xml.XmlElement>()
      .where((e) => e.name.local.endsWith('OutputValue'))
      .toList();

  if (candidates.isEmpty) {
    // fallback: prendi il primo figlio del Body
    final first = body.children.whereType<xml.XmlElement>().toList();
    if (first.isEmpty) return null;
    // se ha CDATA o testo con &lt;...&gt; lo gestiamo sotto
    final text = first.first.descendants.whereType<xml.XmlText>().map((t) => t.text).join().trim();
    if (text.contains('<') || text.contains('&lt;')) {
      return text.contains('&lt;') ? _xmlUnescape(text) : text;
    }
    // altrimenti potremmo avere già XML annidato come elementi: prendi l'outer XML del sottoalbero
    return first.first.toXmlString();
  }

  final node = candidates.first;

  // 1) CDATA?
  final cdataText = node.children.whereType<xml.XmlCDATA>().map((c) => c.text.trim()).join();
  if (cdataText.isNotEmpty) return cdataText;

  // 2) Testo escapato?
  final text = node.descendants.whereType<xml.XmlText>().map((t) => t.text).join().trim();
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
          'SOAPAction': 'http://webservices.farmadati.it/FarmadatiItaliaWebServicesM1/ExecuteQuery',
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
  final cCampo = int.tryParse(query) != null ? 'FDI_0001':'FDI_0004'; 
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

  Future<void> _submit() async {
  if (!_cercaProdottoKeyForm.currentState!.validate()) return;
  _cercaProdottoKeyForm.currentState!.save(); // 👉 qui scatta il tuo onSaved
  logger.i('Hai cercato: $_query');

  // fai qui la chiamata HTTP con _query
  setState(() => _isLoading = true);
  try {
    // TODO: chiama il tuo endpoint. Esempio GET:
    // final uri = Uri.parse('https://tuoserver/search?q=${Uri.encodeQueryComponent(_query)}');
    // final resp = await http.get(uri);
    // if (resp.statusCode == 200) {
    //   final data = jsonDecode(resp.body) as List;
    //   setState(() => _risultati = data);
    // }
    final xmlBody = buildSearchXml(_query);
    final responseXml = await _postXml('http://webservices.farmadati.it/WS2/FarmadatiItaliaWebServicesM1.svc', xmlBody);

    final inner = _extractInnerXmlFromSoap(responseXml);
    if (inner == null) {
    setState(() => _prodotti = []);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nessun XML interno trovato')),
    );
    return;
  }
    final prodotti = _parseInnerProductsXml(inner);
    setState(() => _prodotti = prodotti);
    } catch (e) {
    logger.e('SOAP parse error: $e');
    setState(() => _prodotti = []);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Errore nella lettura dei prodotti')),
    );


    // per demo:
    await Future.delayed(const Duration(milliseconds: 500));
    //setState(() => _risultati = ['Prodotto A', 'Prodotto B', 'Prodotto C']);
  } finally {
    setState(() => _isLoading = false);
  }

}

  Widget cercaProdotto() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: kCercaProdotto,
        suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _submit, // 🔎 esegue la ricerca
        ),
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
      textInputAction: TextInputAction.search, // invio fa “cerca”
      autocorrect: false,
      validator: (value) {
        if (value == null || value.trim().length < 3) {
          return kMsgErroreCercaProdotto;
        }
        logger.i('validator');
        return null;
      },
      onSaved: (value) {
        // Logica per salvare il prodotto
        _query = (value ?? '').trim();
        logger.i('onSaved query: $_query');
      },
      onFieldSubmitted: (_) => _submit(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titolo),
        centerTitle: false,
        titleSpacing: 0, // riduce lo spazio prima del titolo
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                SizedBox(
                  width:
                      double.infinity, // occupa tutta la larghezza disponibile
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
                  Form(
                    key: _cercaProdottoKeyForm,
                    child: cercaProdotto()
                    )
                    ],
              ],
            ),
          ),
          SizedBox(
  height: 300,
  child: _prodotti.isEmpty
      ? const Center(child: Text('Nessun risultato'))
      : Expanded(child:ListView.builder(
          itemCount: _prodotti.length,
          itemBuilder: (context, i) {
            final p = _prodotti[i];
            return Card(
              child: ListTile(
                leading: Text(p.codice),
                title: Text(p.nome),
              ),
            );
          },
        )),
),
        ],
      ),
      
    );
  }
}
