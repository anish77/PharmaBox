import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:logger/web.dart';
import 'package:pharma_box/data/datacached.dart';
import 'package:pharma_box/farmadati/farmadati_cache.dart';
import 'package:pharma_box/farmadati/farmadati_repository.dart';
import 'package:pharma_box/models/prodotto.dart';

final _log = Logger(printer: PrettyPrinter());

/// Restituisce l'ID token Firebase; [forceRefresh] dopo un 401.
typedef TokenProvider = Future<String?> Function({bool forceRefresh});

Future<String?> _firebaseToken({bool forceRefresh = false}) async =>
    FirebaseAuth.instance.currentUser?.getIdToken(forceRefresh);

/// Durate della cache locale (sopra c'è la cache condivisa del Worker).
const _ttlCodice = Duration(days: 30);
const _ttlNome = Duration(days: 7);
const _ttlRendibilita = Duration(days: 7);
const _ttlImmagine = Duration(days: 90);
const _ttlBugiardino = Duration(days: 7);
// lotti invendibili: il Worker li tiene 12 ore, qui poco per non sommare ritardi
const _ttlVendibilita = Duration(hours: 1);

/// Le celle chiedono la vendibilità una alla volta: le richieste che arrivano
/// entro questa finestra partono insieme in una sola chiamata al Worker.
const _finestraGruppo = Duration(milliseconds: 40);
const _maxCodiciPerRichiesta = 50;
const _attesaRiprova = Duration(milliseconds: 400);

/// Parla con il Worker Cloudflare (workers/farmadati-proxy), che interroga
/// Farmadati e tiene la cache condivisa. Qui c'è solo la cache locale.
class WorkerFarmadatiRepository implements FarmadatiRepository {
  WorkerFarmadatiRepository({
    required String baseUrl,
    FarmadatiCache? cache,
    http.Client? client,
    TokenProvider? token,
  }) : _baseUrl =
           baseUrl.endsWith('/')
               ? baseUrl.substring(0, baseUrl.length - 1)
               : baseUrl,
       _cache = cache ?? FarmadatiCache(),
       _client = client ?? http.Client(),
       _token = token ?? _firebaseToken;

  final String _baseUrl;
  final FarmadatiCache _cache;
  final http.Client _client;
  final TokenProvider _token;
  final Map<String, Future<String?>> _inFlight = {};
  final Map<String, Completer<Map<String, dynamic>?>> _gruppo = {};
  Timer? _timerGruppo;

  @override
  Future<List<Prodotto>> cercaProdotti(String q) async {
    final query = q.trim();
    try {
      final payload = await _cached(
        'w|prodotti|${query.toUpperCase()}',
        RegExp(r'^[0-9]+$').hasMatch(query) ? _ttlCodice : _ttlNome,
        () async =>
            jsonEncode((await _get('/v1/prodotti', {'q': query}))['prodotti']),
      );
      final prodotti = jsonDecode(payload!) as List<dynamic>;
      return prodotti.cast<Map<String, dynamic>>().map(_prodotto).toList();
    } catch (errore) {
      _log.e(errore);
      return [];
    }
  }

  @override
  Future<String?> rendibilita(String codice) async {
    try {
      final payload = await _cached(
        'w|rendibilita|$codice',
        _ttlRendibilita,
        () async =>
            jsonEncode(await _get('/v1/rendibilita', {'codice': codice})),
      );
      final esito = jsonDecode(payload!) as Map<String, dynamic>;
      if (esito['trovato'] != true) return null;
      final code = esito['codice'] as String?;
      if (code != null && code.isNotEmpty) {
        return RendiIndennizzoMapper.getDescrizione(code) ?? code;
      }
      return "non rendibile";
    } catch (errore) {
      _log.e('Errore rendibilita: $errore');
      return null;
    }
  }

  @override
  Future<bool?> vendibilita(String codice) async {
    try {
      final payload = await _cached(
        'w|vendibilita|$codice',
        _ttlVendibilita,
        () async {
          final esito = await _esitoVendibilita(codice);
          // errore lato Worker: niente in cache, si riproverà
          if (esito == null || esito['errore'] == true) {
            throw Exception('vendibilita non disponibile per $codice');
          }
          return jsonEncode(esito);
        },
      );
      final lotto = (jsonDecode(payload!) as Map<String, dynamic>)['lotto'];
      if (lotto == null) return calcolaVendibilita(haLotto: false);
      return calcolaVendibilita(
        haLotto: true,
        stato: lotto['stato'] as String?,
        data: lotto['data'] as String?,
      );
    } catch (errore) {
      _log.e('Errore vendibilita: $errore');
      return null;
    }
  }

  @override
  Future<String> immagineUrl(String codice) async {
    final payload = await _cached(
      'w|immagine|$codice',
      _ttlImmagine,
      () async =>
          (await _get('/v1/immagine', {'codice': codice}))['url'] as String?,
    );
    return payload ?? "";
  }

  @override
  Future<String?> bugiardinoUrl(
    String codice,
    String? tipoProdottoDettaglio,
  ) async {
    final trimmed = codice.trim();
    if (trimmed.isEmpty) return null;
    final key = 'w|bugiardino|$trimmed';
    final cached = await _cache.read(key);
    if (cached != null && cached.isFresh(_ttlBugiardino, _cache.now())) {
      return cached.payload;
    }

    final url =
        (await _get('/v1/bugiardino', {
              'codice': trimmed,
              if (tipoProdottoDettaglio != null) 'tipo': tipoProdottoDettaglio,
            }))['url']
            as String?;
    // i link firmati /v1/doc scadono dopo un'ora: non vanno in cache
    if (url == null || !url.contains('/v1/doc?')) {
      await _cache.write(key, url);
    }
    return url;
  }

  /// Vendibilità di un codice, raccolta con le altre richieste ravvicinate.
  Future<Map<String, dynamic>?> _esitoVendibilita(String codice) {
    final esistente = _gruppo[codice];
    if (esistente != null) return esistente.future;

    final completer = Completer<Map<String, dynamic>?>();
    _gruppo[codice] = completer;
    if (_gruppo.length >= _maxCodiciPerRichiesta) {
      _inviaGruppo();
    } else {
      _timerGruppo ??= Timer(_finestraGruppo, _inviaGruppo);
    }
    return completer.future;
  }

  Future<void> _inviaGruppo() async {
    _timerGruppo?.cancel();
    _timerGruppo = null;
    final gruppo = Map.of(_gruppo);
    _gruppo.clear();
    if (gruppo.isEmpty) return;

    try {
      final risposta = await _get('/v1/vendibilita', {
        'codici': gruppo.keys.join(','),
      });
      final esiti = risposta['esiti'] as Map<String, dynamic>;
      for (final MapEntry(key: codice, value: completer) in gruppo.entries) {
        completer.complete(esiti[codice] as Map<String, dynamic>?);
      }
    } catch (errore) {
      for (final completer in gruppo.values) {
        completer.completeError(errore);
      }
    }
  }

  /// Cache locale + richieste identiche unite + dato scaduto se il Worker
  /// non risponde (stesso schema di SoapFarmadatiRepository).
  Future<String?> _cached(
    String key,
    Duration ttl,
    Future<String?> Function() fetch,
  ) {
    return _inFlight[key] ??= _load(key, ttl, fetch).whenComplete(() {
      _inFlight.remove(key);
    });
  }

  Future<String?> _load(
    String key,
    Duration ttl,
    Future<String?> Function() fetch,
  ) async {
    final cached = await _cache.read(key);
    if (cached != null && cached.isFresh(ttl, _cache.now())) {
      return cached.payload;
    }
    try {
      final payload = await fetch();
      await _cache.write(key, payload);
      return payload;
    } catch (errore) {
      if (cached == null) rethrow;
      _log.w('Worker non raggiungibile, uso la cache scaduta: $errore');
      return cached.payload;
    }
  }

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> params,
  ) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: params);
    var resp = await _sendConRiprova(uri, await _token());
    if (resp.statusCode == 401) {
      // token scaduto nel frattempo: un nuovo tentativo con token rinnovato
      resp = await _sendConRiprova(uri, await _token(forceRefresh: true));
    }
    if (resp.statusCode != 200) {
      throw Exception('Worker ${resp.statusCode}: ${resp.body}');
    }
    return jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
  }

  /// Un secondo tentativo per errori 5xx o di rete: una lettura dello scanner
  /// la cui ricerca fallisce andrebbe persa. Sono tutte GET di sola lettura.
  Future<http.Response> _sendConRiprova(Uri uri, String? token) async {
    try {
      final resp = await _send(uri, token);
      if (resp.statusCode < 500) return resp;
      _log.w('Worker ${resp.statusCode} su ${uri.path}, nuovo tentativo');
    } on Exception catch (errore) {
      _log.w(
        'Worker non raggiungibile su ${uri.path} ($errore), nuovo tentativo',
      );
    }
    await Future<void>.delayed(_attesaRiprova);
    return _send(uri, token);
  }

  Future<http.Response> _send(Uri uri, String? token) {
    if (token == null) throw Exception('utente non autenticato');
    return _client
        .get(uri, headers: {'authorization': 'Bearer $token'})
        .timeout(const Duration(seconds: 20));
  }
}

Prodotto _prodotto(Map<String, dynamic> p) {
  final codice = p['codice'] as String? ?? '';
  final minsan = p['minsan'] as String? ?? '';
  final tipoProdotto =
      CategoriaMapper.getDescrizione(p['categoria'] as String? ?? '') ??
      ['', ''];
  return Prodotto(
    codice: codice,
    nome: p['nome'] as String? ?? '',
    tipoProdotto: tipoProdotto[0],
    tipoProdottoDettaglio: tipoProdotto[1],
    minsan: minsan.isNotEmpty ? minsan : codice,
    immagine: '',
    pezzi: 1,
    vendibile: 0,
    description: '',
    ingredients: '',
    howToTake: '',
  );
}
