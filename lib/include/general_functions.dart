import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/web.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/data/datacached.dart';
import 'package:pharma_box/logic/_soap_config.dart';
import 'package:pharma_box/models/prodotto.dart';
import 'package:xml/xml.dart' as xml;

var logger = Logger(printer: PrettyPrinter());
/// 32^5 = 33.554.432
final int _nNumero32Start = 33554432;

/// Alfabetico BC Code 32 (niente A, E, I, O)
final String _cChar32 = "0123456789BCDFGHJKLMNPQRSTUVWXYZ";

/// Replica di TradCode:
/// - Se [code] (trim) ha lunghezza <= 6: ALFANUMERICO -> NUMERICO (9 cifre, padded)
/// - Altrimenti: NUMERICO (stringa di cifre) -> ALFANUMERICO (6 chars)
String tradCode(String code) {
  final s = code.trim().toUpperCase();

  if (s.length <= 6) {
    // ALFANUMERICO -> NUMERICO
    int nNumero32 = _nNumero32Start;
    int cNewCodice = 0;

    for (int k = 0; k < 6; k++) {
      final ch = (k < s.length) ? s[k] : ' '; // se mancano char, contribuisce 0
      final pos = _cChar32.indexOf(ch); // 0-based, -1 se non trovato
      final val = (pos >= 0) ? pos : 0; // Max(At(..)-1,0) equivalente
      cNewCodice += nNumero32 * val;
      nNumero32 = nNumero32 ~/ 32;
    }

    return cNewCodice.toString().padLeft(9, '0');
  } else if (s.length == 9) {
    // NUMERICO -> ALFANUMERICO
    // nella versione originale fanno Val(cCodice); qui richiediamo solo cifre
    final numVal = int.tryParse(s) ?? 0;

    int nNumero32 = _nNumero32Start;
    final sb = StringBuffer();

    for (int k = 5; k >= 0; k--) {
      final nPosi3 = numVal ~/ nNumero32;
      final ch = _cChar32[nPosi3]; // SubStr(_cChar32, nPosi3+1, 1)
      sb.write(ch);
      // aggiorna resto
      //final resto = numVal - nNumero32 * nPosi3;
      // per i passi successivi serve aggiornare numVal; in Harbour sovrascrivevano cCodice
      // in Dart manteniamo un accumulatore
      // -> per mirror perfetto, convertiamo numVal in variabile mutabile:
    }
    // Nota: dobbiamo mutare il valore numerico man mano:
    return _numericToAlpha(numVal);
  } else {
    return s;
  }
}

/// Helper per la seconda branch (NUMERICO -> ALFANUMERICO)
String _numericToAlpha(int value) {
  int nNumero32 = _nNumero32Start;
  final sb = StringBuffer();
  int v = value;

  for (int k = 5; k >= 0; k--) {
    final nPosi3 = v ~/ nNumero32;
    sb.write(_cChar32[nPosi3]);
    v = v - nNumero32 * nPosi3;
    nNumero32 = nNumero32 ~/ 32;
  }
  return sb.toString();
}

List<Prodotto> parseInnerProductsXml(
  String innerXml,
  DatasetKind dataSetSchema,
) {
  final innerDoc = xml.XmlDocument.parse(innerXml);
  final prodotti = innerDoc.findAllElements('Product');

  switch (dataSetSchema) {
    case DatasetKind.tr001:

      // se l'XML ha un root <Prodotti> con figli <Prodotto>...

      return prodotti.map((p) {
        final codice = p.getElement('FDI_0001')?.innerText.trim() ?? '';
        final minsan = p.getElement('FDI_0002')?.innerText.trim();
        final nome = p.getElement('FDI_0004')?.innerText.trim() ?? '';
        final tipoProdotto =
            CategoriaMapper.getDescrizione(
              p.getElement('FDI_0008')?.innerText.trim() ?? '',
            ) ??
            ['', ''];
        return Prodotto(
          codice: codice,
          nome: nome,
          tipoProdotto: tipoProdotto[0],
          tipoProdottoDettaglio: tipoProdotto[1],
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
        final codice = p.getElement('FDI_T218')?.innerText.trim() ?? '';
        final immagine = p.getElement('FDI_T438')?.innerText.trim() ?? '';

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
    case DatasetKind.tdf:
      // se l'XML ha un root <Prodotti> con figli <Prodotto>...

      return prodotti.map((p) {
        final codice = p.getElement('FDI_T218')?.innerText.trim() ?? '';
        final description = p.getElement('FDI_T227')?.innerText.trim() ?? '';

        return Prodotto(
          codice: codice,
          immagine: '',
          nome: '',
          minsan: codice,
          pezzi: 1,
          consentito: true,
          description: description,
          ingredients: '',
          howToTake: '',
        );
      }).toList();
    case DatasetKind.td1:
      // se l'XML ha un root <Prodotti> con figli <Prodotto>...

      return prodotti.map((p) {
        final codice = p.getElement('FDI_T218')?.innerText.trim() ?? '';
        final description = p.getElement('FDI_T477')?.innerText.trim() ?? '';

        return Prodotto(
          codice: codice,
          immagine: '',
          nome: '',
          minsan: codice,
          pezzi: 1,
          consentito: true,
          description: description,
          ingredients: '',
          howToTake: '',
        );
      }).toList();
  }
}

Future<List<Prodotto>> doSearch(String q) async {
  try {
    if (q.length > 9 && RegExp(r'^[0-9]+$').hasMatch(q)) {
      String xmlEanBody = buildSearchXml(q, kind: SearchKind.ean);
      String eanList = await postXml(kFarmadatiEndpoint, xmlEanBody);
      String? inner = _extractInnerXmlFromSoap(eanList);
      if (inner == null) return [];
      List<Prodotto> listaEan = parseInnerProductsXml(inner, DatasetKind.tr001);

      List<Prodotto> Minsan = [];

      for (var prodotto in listaEan) {
        String xmlBody = buildSearchXml(
          prodotto.codice,
          kind: SearchKind.prodotti,
        );
        String xmlResp = await postXml(kFarmadatiEndpoint, xmlBody);
        String? inner = _extractInnerXmlFromSoap(xmlResp);
        if (inner != null) {
          Minsan.add(parseInnerProductsXml(inner, DatasetKind.tr001).first);

          getOrPutImage(
            parseInnerProductsXml(inner, DatasetKind.tr001).first.codice,
          );
        }
      }
      //logger.i(Minsan.length);
      return Minsan; // questo è più lento 
    }
    final xmlBody = buildSearchXml(q, kind: SearchKind.prodotti);
    final xmlResp = await postXml(kFarmadatiEndpoint, xmlBody);
    final inner = _extractInnerXmlFromSoap(xmlResp);
    if (inner == null) return [];
    //getOrPutImage(parseInnerProductsXml(inner, DatasetKind.tr001).first.codice);
    
    return parseInnerProductsXml(inner, DatasetKind.tr001); // questo è più veloce
  } catch (errore) {
    logger.e(errore);
    return [];
  }
}

/// Restituisce la descrizione di rendibilità/indennizzo per un codice prodotto.
/// Tenta prima di leggere il campo descrittivo dal dataset TR015 (FDI_T305);
/// in alternativa usa il codice (FDI_T303) mappandolo tramite RendiIndennizzoMapper.
Future<String?> loadRendibilita(String minsan) async {
  try {
    final xmlBody = buildSearchXml(minsan, kind: SearchKind.rendibili);
    final xmlResp = await postXml(kFarmadatiEndpoint, xmlBody);
    final inner = _extractInnerXmlFromSoap(xmlResp);
    if (inner == null || inner == 'EMPTY') {
      return null;
    }

    final innerDoc = xml.XmlDocument.parse(inner);
    final prodotti = innerDoc.findAllElements('Product');
    if (prodotti.isEmpty) return null;

    final p = prodotti.first;
    final descr = p.getElement('FDI_0460')?.innerText.trim();
    if (descr != null && descr.isNotEmpty) {
      //return descr;
    }
    final code = p.getElement('FDI_0460')?.innerText.trim();
    if (code != null && code.isNotEmpty) {
      return RendiIndennizzoMapper.getDescrizione(code) ?? code;
    }
  } catch (errore) {
    logger.e('Errore loadRendibilita: $errore');
  }
  return null;
}

Future<String> getOrPutImage(String minsan) async {
  String xmlBodyImage = buildSearchXml(minsan, kind: SearchKind.immagine);

  String xmlResp2 = await postXml(kFarmadatiEndpoint, xmlBodyImage);

  String? inner2 = _extractInnerXmlFromSoap(xmlResp2);

  if (inner2 != null && inner2 != "EMPTY") {
    String imagefilename =
        parseInnerProductsXml(inner2, DatasetKind.tdz).first.immagine;
    String imageurl =
        "https://ws.farmadati.it/WS_DOC/GetDoc.aspx?accesskey=epxD67iZR&tipodoc=Z&nomefile=$imagefilename";

    String? cdnUrl = await r2IngestImageByUrl(
      minsan: parseInnerProductsXml(inner2, DatasetKind.tdz).first.codice,
      imageUrl: imageurl,
    );
    logger.i(cdnUrl);
    return cdnUrl ?? "";
  }
  return "";
}

/*
Future<String?> getBugiardino(String minsan) async {

  String xmlBodyImage = buildSearchXml(minsan, kind: SearchKind.bugiardino);

  String xmlResp2 = await postXml(kFarmadatiEndpoint, xmlBodyImage);

  String? inner2 = _extractInnerXmlFromSoap(xmlResp2);

  if (inner2 != null && inner2 != "EMPTY") {
    final entries = parseInnerProductsXml(inner2, DatasetKind.tdf);
    if (entries.isEmpty) {
      return null;
    }

    final rawDescription = entries.first.description.trim();
    if (rawDescription.isEmpty) {
      return null;
    }



    String? urlFromJson;
    if (rawDescription.startsWith('{')) {
      try {
        final decoded = json.decode(rawDescription);
        if (decoded is Map<String, dynamic>) {
          final path = decoded['path'];
          if (path is String && path.isNotEmpty) {
            urlFromJson = path;
          }
        }
      } catch (_) {
        // Continua con il comportamento legacy se il JSON non è valido.
      }
    }

    if (urlFromJson != null) {
      print(urlFromJson);
      return urlFromJson;
    }

    final docurl =
        "https://ws.farmadati.it/WS_DOC/GetDoc.aspx?accesskey=epxD67iZR&tipodoc=Z&nomefile=$rawDescription";
    print(docurl);
    return docurl;
  }
  return null;
}
*/

Future<String?> getBugiardino(
  String minsan,
  String? tipoProdottoDettaglio,
) async {
  final trimmed = minsan.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final cachedUri = Uri.parse('$kBugiardinoMonografieBase/$minsan.html');

  if (await _remoteHtmlExists(cachedUri)) {
    return cachedUri.toString();
  }

  final sourceUrl = await _fetchFarmadatiBugiardinoUrl(
    trimmed,
    tipoProdottoDettaglio,
  );
  if (sourceUrl == null) {
    return null;
  }

  final sourceUri = Uri.tryParse(sourceUrl);
  if (sourceUri != null && sourceUri.host == cachedUri.host) {
    return sourceUrl;
  }

  final cached = await _cacheBugiardinoOnDoublecore(sourceUrl, minsan);
  if (cached && await _remoteHtmlExists(cachedUri)) {
    return cachedUri.toString();
  }
  logger.d(sourceUri);
  return sourceUrl;
}

Future<String?> _fetchFarmadatiBugiardinoUrl(
  String minsan,
  String? tipoProdottoDettaglio,
) async {
  String xmlBody;
  final String tipoDocumento = tipoProdottoDettaglio == "F" ? "F" : '1';

  if (tipoProdottoDettaglio == "F") {
    xmlBody = buildSearchXml(minsan, kind: SearchKind.bugiardino);
  } else {
    xmlBody = buildSearchXml(minsan, kind: SearchKind.bugiardinoparafarmaco);
  }
  final xmlResp = await postXml(kFarmadatiEndpoint, xmlBody);
  final inner = _extractInnerXmlFromSoap(xmlResp);
  if (inner == null || inner == 'EMPTY') {
    return null;
  }

  final entries = parseInnerProductsXml(
    inner,
    tipoProdottoDettaglio == "F" ? DatasetKind.tdf : DatasetKind.td1,
  );
  if (entries.isEmpty) {
    return null;
  }

  final rawDescription = entries.first.description.trim();
  if (rawDescription.isEmpty) {
    return null;
  }

  if (rawDescription.startsWith('{')) {
    try {
      final decoded = json.decode(rawDescription);
      if (decoded is Map<String, dynamic>) {
        final path = decoded['path'];
        if (path is String && path.isNotEmpty) {
          final parsed = Uri.tryParse(path);
          return parsed == null || parsed.hasScheme ? path : path;
        }
      }
    } catch (_) {}
  }

  return 'https://ws.farmadati.it/WS_DOC/GetDoc.aspx?accesskey=$kFarmadatiPassword&tipodoc=$tipoDocumento&nomefile=$rawDescription';
}

Future<bool> _remoteHtmlExists(Uri uri, {int depth = 0}) async {
  if (depth > 2) {
    return false;
  }
  try {
    final response = await http.head(uri).timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      return true;
    }
    if (response.isRedirect) {
      final location = response.headers['location'];
      if (location != null) {
        final redirected = uri.resolve(location);
        return _remoteHtmlExists(redirected, depth: depth + 1);
      }
    }
    if (response.statusCode == 405 || response.statusCode == 501) {
      final getResponse = await http
          .get(uri, headers: const {'Range': 'bytes=0-0'})
          .timeout(const Duration(seconds: 8));
      return getResponse.statusCode == 200 || getResponse.statusCode == 206;
    }
  } catch (error) {
    logger.e('Errore verifica pdf bugiardino: $error');
  }
  return false;
}

Future<bool> _cacheBugiardinoOnDoublecore(
  String sourceUrl,
  String minsan,
) async {
  try {
    final response = await http
        .post(
          Uri.parse(kBugiardinoUploadEndpoint),
          body: {'url': sourceUrl, 'savefileas': minsan},
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      logger.e('Upload bugiardino fallito: HTTP ${response.statusCode}');
      return false;
    }

    final decoded = json.decode(response.body);
    if (decoded is Map<String, dynamic>) {
      final statusRaw = decoded['status'];
      if (statusRaw is String) {
        final status = statusRaw.toLowerCase();
        if (status == 'saved' || status == 'already_exists') {
          return true;
        }
      }
    }
  } catch (error) {
    logger.e('Errore upload bugiardino: $error');
  }
  return false;
}

Future<String> postXml(String endpoint, String xmlBody) async {
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
  //logger.i(utf8.decode(resp.bodyBytes));
  return utf8.decode(resp.bodyBytes); // risposta come XML string
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
      node.children.whereType<xml.XmlCDATA>().map((c) => c.text.trim()).join();
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

/// Invia una richiesta al Worker Cloudflare per scaricare e archiviare
/// l'immagine del prodotto su R2 a partire da un URL sorgente.
/// Ritorna l'URL pubblico (CDN) se disponibile, altrimenti null.
Future<String?> r2IngestImageByUrl({
  required String minsan,
  required String imageUrl,
}) async {
  if (kR2IngestEndpoint.isEmpty) return null;
  try {
    final resp = await http
        .post(
          Uri.parse(kR2IngestEndpoint),
          headers: {
            'content-type': 'application/json',
            if (kR2ApiKey.isNotEmpty) 'x-api-key': kR2ApiKey,
          },
          body: jsonEncode({'ean': minsan, 'imageUrl': imageUrl}),
        )
        .timeout(const Duration(seconds: 12));
    if (resp.statusCode != 200) return null;
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    if (data['ok'] == true && data['origUrl'] is String) {
      return data['origUrl'] as String;
    }
  } catch (errore) {
    logger.e(errore);
  }
  return null;
}
