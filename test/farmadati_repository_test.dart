import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pharma_box/farmadati/farmadati_cache.dart';
import 'package:pharma_box/farmadati/soap_farmadati_repository.dart';

/// Finto web service Farmadati: risponde in base a "dataset|valore" e conta
/// le chiamate ricevute.
class _FakeFarmadati {
  final Map<String, String> risposte = {};
  final List<String> chiamate = [];
  Object? errore;
  Completer<void>? blocco;

  Future<String> post(String body) async {
    final dataset = RegExp(r'<web:CodiceSetDati>(.*?)<').firstMatch(body)![1]!;
    final valore = RegExp(r'<fdiw:Value>(.*?)<').firstMatch(body)![1]!;
    final key = '$dataset|$valore';
    chiamate.add(key);
    if (blocco != null) await blocco!.future;
    if (errore != null) throw errore!;
    return _soap(risposte[key] ?? 'EMPTY');
  }

  static String _soap(String inner) {
    final escaped = inner
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
    return '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">'
        '<s:Body><ExecuteQueryResponse><ExecuteQueryResult>'
        '<OutputValue>$escaped</OutputValue>'
        '</ExecuteQueryResult></ExecuteQueryResponse></s:Body></s:Envelope>';
  }
}

String _tr001(String codice, String nome) =>
    '<Products><Product><FDI_0001>$codice</FDI_0001>'
    '<FDI_0004>$nome</FDI_0004><FDI_0008>D</FDI_0008></Product></Products>';

void main() {
  late _FakeFarmadati ws;
  late DateTime now;
  late int ingest;

  SoapFarmadatiRepository repository({Directory? dir}) =>
      SoapFarmadatiRepository(
        cache: FarmadatiCache(directory: () async => dir, clock: () => now),
        post: ws.post,
        ingestImage: ({required minsan, required imageUrl}) async {
          ingest++;
          return 'https://cdn.test/$minsan.jpg';
        },
      );

  setUp(() {
    ws = _FakeFarmadati();
    now = DateTime(2026, 10, 13, 9);
    ingest = 0;
    ws.risposte['TR001|012345678'] = _tr001('012345678', 'TACHIPIRINA');
    ws.risposte['TR001|987654321'] = _tr001('987654321', 'TACHIFLUDEC');
  });

  test('la seconda ricerca per codice è servita dalla cache', () async {
    final repo = repository();

    final primo = await repo.cercaProdotti('012345678');
    final secondo = await repo.cercaProdotti('012345678');

    expect(primo.single.nome, 'TACHIPIRINA');
    expect(primo.single.tipoProdotto, 'FARMACO DA BANCO');
    expect(secondo.single.nome, 'TACHIPIRINA');
    expect(ws.chiamate, ['TR001|012345678']);
    expect(repo.stats.cache['prodotti'], 1);
  });

  test('EAN: TR016 + TR001 per ogni codice, tutto in cache', () async {
    ws.risposte['TR016|8012345678901'] =
        '<Products><Product><FDI_0001>012345678</FDI_0001></Product>'
        '<Product><FDI_0001>987654321</FDI_0001></Product></Products>';
    final repo = repository();

    final risultati = await repo.cercaProdotti('8012345678901');
    expect(risultati.map((p) => p.nome), ['TACHIPIRINA', 'TACHIFLUDEC']);
    expect(risultati.first.tipoProdottoDettaglio, 'F');
    expect(ws.chiamate, hasLength(3));

    await repo.cercaProdotti('8012345678901');
    // anche la ricerca diretta di un codice già visto via EAN è in cache
    await repo.cercaProdotti('987654321');
    expect(ws.chiamate, hasLength(3));
  });

  test('le risposte vuote vengono messe in cache', () async {
    final repo = repository();

    expect(await repo.vendibilita('012345678'), isTrue);
    expect(await repo.vendibilita('012345678'), isTrue);
    expect(ws.chiamate, ['TR012|012345678']);
  });

  test('i lotti invendibili scadono dopo 12 ore, l\'anagrafica no', () async {
    final repo = repository();
    await repo.vendibilita('012345678');
    await repo.cercaProdotti('012345678');

    now = now.add(const Duration(hours: 13));
    await repo.vendibilita('012345678');
    await repo.cercaProdotti('012345678');

    expect(ws.chiamate, [
      'TR012|012345678',
      'TR001|012345678',
      'TR012|012345678',
    ]);
  });

  test('se Farmadati non risponde usa il dato scaduto', () async {
    ws.risposte['TR012|012345678'] =
        '<Products><Product><FDI_T292>VF</FDI_T292>'
        '<FDI_T293>2020-01-01</FDI_T293></Product></Products>';
    final repo = repository();
    expect(await repo.vendibilita('012345678'), isFalse);

    now = now.add(const Duration(days: 2));
    ws.errore = const SocketException('offline');

    expect(await repo.vendibilita('012345678'), isFalse);
    expect(repo.stats.scaduti['lottiInvendibili'], 1);
  });

  test('senza cache un errore di rete dà nessun risultato', () async {
    ws.errore = const SocketException('offline');
    final repo = repository();

    expect(await repo.cercaProdotti('012345678'), isEmpty);
    expect(await repo.vendibilita('012345678'), isNull);
  });

  test('richieste identiche contemporanee fanno una sola chiamata', () async {
    ws.blocco = Completer<void>();
    final repo = repository();

    final celle = List.generate(5, (_) => repo.vendibilita('012345678'));
    await Future<void>.delayed(Duration.zero);
    ws.blocco!.complete();

    expect(await Future.wait(celle), everyElement(isTrue));
    expect(ws.chiamate, hasLength(1));
  });

  test('immagine: dopo il primo ingest su R2 niente più TDZ né ingest', () async {
    ws.risposte['TDZ|012345678'] =
        '<Products><Product><FDI_T218>012345678</FDI_T218>'
        '<FDI_T438>img.jpg</FDI_T438></Product></Products>';
    final repo = repository();

    expect(await repo.immagineUrl('012345678'), 'https://cdn.test/012345678.jpg');
    expect(await repo.immagineUrl('012345678'), 'https://cdn.test/012345678.jpg');
    expect(ws.chiamate, ['TDZ|012345678']);
    expect(ingest, 1);
  });

  test('la cache su disco sopravvive al riavvio dell\'app', () async {
    final dir = await Directory.systemTemp.createTemp('farmadati_cache');
    addTearDown(() => dir.delete(recursive: true));

    await repository(dir: dir).cercaProdotti('012345678');
    final dopoRiavvio = await repository(dir: dir).cercaProdotti('012345678');

    expect(dopoRiavvio.single.nome, 'TACHIPIRINA');
    expect(ws.chiamate, ['TR001|012345678']);
  });
}
