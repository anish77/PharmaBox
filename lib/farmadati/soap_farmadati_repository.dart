import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logger/web.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/data/datacached.dart';
import 'package:pharma_box/farmadati/farmadati_cache.dart';
import 'package:pharma_box/farmadati/farmadati_repository.dart';
import 'package:pharma_box/logic/_soap_config.dart';
import 'package:pharma_box/models/prodotto.dart';
import 'package:xml/xml.dart' as xml;

final _log = Logger(printer: PrettyPrinter());

/// Per quanto tempo una risposta Farmadati resta valida in cache.
/// Le risposte vuote ("EMPTY") vengono salvate con la stessa durata.
Duration ttlFor(SearchKind kind, String value) => switch (kind) {
  // ricerca per codice: anagrafica stabile; ricerca per nome: più breve
  SearchKind.prodotti =>
    int.tryParse(value) != null
        ? const Duration(days: 30)
        : const Duration(days: 7),
  SearchKind.ean => const Duration(days: 30),
  SearchKind.immagine => const Duration(days: 90),
  SearchKind.bugiardino ||
  SearchKind.bugiardinoparafarmaco => const Duration(days: 30),
  SearchKind.rendibili => const Duration(days: 7),
  // lotti invendibili: dato di sicurezza, durata breve
  SearchKind.lottiInvendibili => const Duration(hours: 12),
};

/// L'URL CDN di un'immagine già caricata su R2 non cambia.
const _ttlImmagineCdn = Duration(days: 90);

/// Contatori delle richieste per dataset: quante sono andate a Farmadati,
/// quante servite dalla cache, quante con un dato scaduto perché la rete è fallita.
class FarmadatiStats {
  final Map<String, int> rete = {};
  final Map<String, int> cache = {};
  final Map<String, int> scaduti = {};

  void _conta(Map<String, int> contatori, String dataset) =>
      contatori[dataset] = (contatori[dataset] ?? 0) + 1;

  @override
  String toString() => 'rete=$rete cache=$cache scaduti=$scaduti';
}

typedef SoapPost = Future<String> Function(String xmlBody);
typedef ImageIngest =
    Future<String?> Function({
      required String minsan,
      required String imageUrl,
    });

/// Interroga direttamente il web service SOAP di Farmadati, con cache locale
/// persistente e unione delle richieste identiche in corso.
class SoapFarmadatiRepository implements FarmadatiRepository {
  SoapFarmadatiRepository({
    FarmadatiCache? cache,
    SoapPost? post,
    ImageIngest? ingestImage,
  }) : _cache = cache ?? FarmadatiCache(),
       _post = post ?? ((body) => postXml(kFarmadatiEndpoint, body)),
       _ingestImage = ingestImage ?? r2IngestImageByUrl;

  final FarmadatiCache _cache;
  final SoapPost _post;
  final ImageIngest _ingestImage;
  final Map<String, Future<String?>> _inFlight = {};
  final stats = FarmadatiStats();

  @override
  Future<List<Prodotto>> cercaProdotti(String q) async {
    try {
      final start = DateTime.now();
      if (q.length > 9 && RegExp(r'^[0-9]+$').hasMatch(q)) {
        // EAN -> codici ministeriali (TR016), poi anagrafica di ciascuno (TR001)
        final eanInner = await _query(SearchKind.ean, q);
        if (eanInner == null) return [];
        final codici = parseInnerProductsXml(eanInner, DatasetKind.tr001);

        final dettagli = await Future.wait(
          codici.map((p) async {
            final inner = await _query(SearchKind.prodotti, p.codice);
            if (inner == null) return null;
            final trovati = parseInnerProductsXml(inner, DatasetKind.tr001);
            return trovati.isEmpty ? null : trovati.first;
          }),
        );
        _log.i(DateTime.now().difference(start));
        return dettagli.whereType<Prodotto>().toList();
      }

      final inner = await _query(SearchKind.prodotti, q);
      if (inner == null) return [];
      _log.i(DateTime.now().difference(start));
      return parseInnerProductsXml(inner, DatasetKind.tr001);
    } catch (errore) {
      _log.e(errore);
      return [];
    }
  }

  /// Tenta il codice FDI_0460 del dataset TR015 e lo mappa tramite
  /// RendiIndennizzoMapper.
  @override
  Future<String?> rendibilita(String codice) async {
    try {
      final inner = await _query(SearchKind.rendibili, codice);
      if (inner == null) return null;

      final prodotti = xml.XmlDocument.parse(inner).findAllElements('Product');
      if (prodotti.isEmpty) return null;

      final code = prodotti.first.getElement('FDI_0460')?.innerText.trim();
      if (code != null && code.isNotEmpty) {
        return RendiIndennizzoMapper.getDescrizione(code) ?? code;
      }
      return "non rendibile";
    } catch (errore) {
      _log.e('Errore rendibilita: $errore');
    }
    return null;
  }

  /// In cache c'è la risposta grezza di TR012: la vendibilità dipende dalla
  /// data odierna e viene ricalcolata a ogni lettura.
  @override
  Future<bool?> vendibilita(String codice) async {
    try {
      final inner = await _query(SearchKind.lottiInvendibili, codice);
      if (inner == null) return calcolaVendibilita(haLotto: false);

      final prodotti = xml.XmlDocument.parse(inner).findAllElements('Product');
      if (prodotti.isEmpty) return null;

      final p = prodotti.first;
      return calcolaVendibilita(
        haLotto: true,
        stato: p.getElement('FDI_T292')?.innerText.trim(),
        data: p.getElement('FDI_T293')?.innerText.trim(),
      );
    } catch (errore) {
      _log.e('Errore vendibilita: $errore');
    }
    return null;
  }

  @override
  Future<String> immagineUrl(String codice) async {
    // se l'immagine è già su R2 non servono né TDZ né un nuovo ingest
    final key = 'r2|$codice';
    final cached = await _cache.read(key);
    final cachedUrl = cached?.payload;
    if (cachedUrl != null && cached!.isFresh(_ttlImmagineCdn, _cache.now())) {
      stats._conta(stats.cache, 'R2');
      return cachedUrl;
    }

    final inner = await _query(SearchKind.immagine, codice);
    if (inner == null) return "";

    final immagine = parseInnerProductsXml(inner, DatasetKind.tdz).first;
    final cdnUrl = await _ingestImage(
      minsan: immagine.codice,
      imageUrl:
          "https://ws.farmadati.it/WS_DOC/GetDoc.aspx?accesskey=$kFarmadatiPassword&tipodoc=Z&nomefile=${immagine.immagine}",
    );
    _log.i(cdnUrl);
    if (cdnUrl == null || cdnUrl.isEmpty) return "";
    await _cache.write(key, cdnUrl);
    return cdnUrl;
  }

  @override
  Future<String?> bugiardinoUrl(
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
    _log.d(sourceUri);
    return sourceUrl;
  }

  Future<String?> _fetchFarmadatiBugiardinoUrl(
    String minsan,
    String? tipoProdottoDettaglio,
  ) async {
    final isFarmaco = tipoProdottoDettaglio == "F";
    final String tipoDocumento = isFarmaco ? "F" : '1';

    final inner = await _query(
      isFarmaco ? SearchKind.bugiardino : SearchKind.bugiardinoparafarmaco,
      minsan,
    );
    if (inner == null) {
      return null;
    }

    final entries = parseInnerProductsXml(
      inner,
      isFarmaco ? DatasetKind.tdf : DatasetKind.td1,
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
            return path;
          }
        }
      } catch (_) {}
    }

    return 'https://ws.farmadati.it/WS_DOC/GetDoc.aspx?accesskey=$kFarmadatiPassword&tipodoc=$tipoDocumento&nomefile=$rawDescription';
  }

  /// Unico punto da cui partono le richieste a Farmadati.
  /// Restituisce l'XML interno della risposta, null se vuota.
  Future<String?> _query(SearchKind kind, String value) {
    final key = '${kind.name}|$value';
    // richieste identiche contemporanee (es. più celle con lo stesso codice)
    // condividono la stessa chiamata.
    // Blocco con graffe: remove() restituisce questo stesso Future e
    // whenComplete lo attenderebbe, bloccandosi su sé stesso.
    return _inFlight[key] ??= _load(kind, value, key).whenComplete(() {
      _inFlight.remove(key);
    });
  }

  Future<String?> _load(SearchKind kind, String value, String key) async {
    final cached = await _cache.read(key);
    if (cached != null && cached.isFresh(ttlFor(kind, value), _cache.now())) {
      stats._conta(stats.cache, kind.name);
      return cached.payload;
    }

    try {
      stats._conta(stats.rete, kind.name);
      _log.d('Farmadati ${kind.name} "$value" -> rete ($stats)');
      final resp = await _post(buildSearchXml(value, kind: kind));
      final inner = _extractInnerXmlFromSoap(resp);
      final payload = (inner == null || inner == 'EMPTY') ? null : inner;
      await _cache.write(key, payload);
      return payload;
    } catch (errore) {
      if (cached == null) rethrow;
      // meglio un dato scaduto che nessun dato
      stats._conta(stats.scaduti, kind.name);
      _log.w('Farmadati non raggiungibile, uso la cache scaduta: $errore');
      return cached.payload;
    }
  }
}

List<Prodotto> parseInnerProductsXml(
  String innerXml,
  DatasetKind dataSetSchema,
) {
  final innerDoc = xml.XmlDocument.parse(innerXml);
  final prodotti = innerDoc.findAllElements('Product');

  switch (dataSetSchema) {
    case DatasetKind.tr001:
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
          vendibile: 0,
          description: '',
          ingredients: '',
          howToTake: '',
        );
      }).toList();
    case DatasetKind.tdz:
      return prodotti.map((p) {
        final codice = p.getElement('FDI_T218')?.innerText.trim() ?? '';
        final immagine = p.getElement('FDI_T438')?.innerText.trim() ?? '';

        return Prodotto(
          codice: codice,
          immagine: immagine,
          nome: '',
          minsan: codice,
          pezzi: 1,
          vendibile: 0,
          description: '',
          ingredients: '',
          howToTake: '',
        );
      }).toList();
    case DatasetKind.tdf:
      return prodotti.map((p) {
        final codice = p.getElement('FDI_T218')?.innerText.trim() ?? '';
        final description = p.getElement('FDI_T227')?.innerText.trim() ?? '';

        return Prodotto(
          codice: codice,
          immagine: '',
          nome: '',
          minsan: codice,
          pezzi: 1,
          vendibile: 0,
          description: description,
          ingredients: '',
          howToTake: '',
        );
      }).toList();
    case DatasetKind.td1:
      return prodotti.map((p) {
        final codice = p.getElement('FDI_T218')?.innerText.trim() ?? '';
        final description = p.getElement('FDI_T477')?.innerText.trim() ?? '';

        return Prodotto(
          codice: codice,
          immagine: '',
          nome: '',
          minsan: codice,
          pezzi: 1,
          vendibile: 0,
          description: description,
          ingredients: '',
          howToTake: '',
        );
      }).toList();
  }
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
        return await _remoteHtmlExists(redirected, depth: depth + 1);
      }
    }
    if (response.statusCode == 405 || response.statusCode == 501) {
      final getResponse = await http
          .get(uri, headers: const {'Range': 'bytes=0-0'})
          .timeout(const Duration(seconds: 8));
      return getResponse.statusCode == 200 || getResponse.statusCode == 206;
    }
  } catch (error) {
    _log.e('Errore verifica pdf bugiardino: $error');
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
      _log.e('Upload bugiardino fallito: HTTP ${response.statusCode}');
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
    _log.e('Errore upload bugiardino: $error');
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
            .map((t) => t.value)
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
      node.children.whereType<xml.XmlCDATA>().map((c) => c.value.trim()).join();
  if (cdataText.isNotEmpty) return cdataText;

  // 2) Testo escapato?
  final text =
      node.descendants
          .whereType<xml.XmlText>()
          .map((t) => t.value)
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
    _log.e(errore);
  }
  return null;
}
