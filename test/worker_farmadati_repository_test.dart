import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pharma_box/farmadati/farmadati_cache.dart';
import 'package:pharma_box/farmadati/farmadati_repository.dart';
import 'package:pharma_box/farmadati/worker_farmadati_repository.dart';

void main() {
  late List<Uri> richieste;
  late Map<String, Object? Function(Uri)> rotte;
  late DateTime now;
  late int rinnovi;
  late bool tokenScaduto;
  late int erroriWorker;

  WorkerFarmadatiRepository repository() => WorkerFarmadatiRepository(
    baseUrl: 'https://proxy.test/',
    cache: FarmadatiCache(directory: () async => null, clock: () => now),
    token: ({bool forceRefresh = false}) async {
      if (forceRefresh) {
        rinnovi++;
        tokenScaduto = false;
      }
      return tokenScaduto ? 'vecchio' : 'nuovo';
    },
    client: MockClient((request) async {
      richieste.add(request.url);
      if (request.headers['authorization'] != 'Bearer nuovo') {
        return http.Response('{"errore":"token non valido"}', 401);
      }
      if (erroriWorker > 0) {
        erroriWorker--;
        return http.Response('error code: 1101', 500);
      }
      final rotta = rotte[request.url.path];
      if (rotta == null) return http.Response('{}', 404);
      return http.Response(jsonEncode(rotta(request.url)), 200);
    }),
  );

  setUp(() {
    richieste = [];
    now = DateTime(2026, 10, 13, 9);
    rinnovi = 0;
    tokenScaduto = false;
    erroriWorker = 0;
    rotte = {
      '/v1/prodotti':
          (_) => {
            'prodotti': [
              {
                'codice': '034329110',
                'minsan': '034329110',
                'nome': 'TACHIPIRINA FLASHTAB*12CPR 125',
                'categoria': 'E',
              },
            ],
          },
      '/v1/vendibilita': (uri) {
        final codici = uri.queryParameters['codici']!.split(',');
        return {
          'esiti': {
            for (final c in codici)
              c:
                  c == '000000001'
                      ? {
                        'lotto': {'stato': 'VF', 'data': '2020-01-01'},
                      }
                      : c == '000000002'
                      ? {'errore': true}
                      : {'lotto': null},
          },
        };
      },
      '/v1/rendibilita': (_) => {'trovato': true, 'codice': 'J'},
      '/v1/immagine': (_) => {'url': 'https://cdn.test/1.jpg'},
    };
  });

  test(
    'prodotti: mappa la categoria e la seconda volta usa la cache',
    () async {
      final repo = repository();

      final primo = await repo.cercaProdotti('tachipirina');
      final secondo = await repo.cercaProdotti('TACHIPIRINA');

      expect(primo.single.nome, 'TACHIPIRINA FLASHTAB*12CPR 125');
      expect(primo.single.tipoProdotto, 'FARMACO ETICO');
      expect(primo.single.tipoProdottoDettaglio, 'F');
      expect(secondo.single.codice, '034329110');
      expect(richieste, hasLength(1));
      expect(
        richieste.single.toString(),
        'https://proxy.test/v1/prodotti?q=tachipirina',
      );
    },
  );

  test(
    'vendibilità: le celle ravvicinate partono in una sola richiesta',
    () async {
      final repo = repository();

      final esiti = await Future.wait([
        repo.vendibilita('000000001'),
        repo.vendibilita('034329110'),
        repo.vendibilita('012745182'),
        repo.vendibilita('034329110'),
      ]);

      expect(esiti, [false, true, true, true]);
      expect(richieste, hasLength(1));
      expect(richieste.single.queryParameters['codici']!.split(',')..sort(), [
        '000000001',
        '012745182',
        '034329110',
      ]);

      await repo.vendibilita('034329110');
      expect(richieste, hasLength(1));
    },
  );

  test('vendibilità: in cache locale per un\'ora', () async {
    final repo = repository();
    await repo.vendibilita('034329110');

    now = now.add(const Duration(minutes: 61));
    await repo.vendibilita('034329110');

    expect(richieste, hasLength(2));
  });

  test('vendibilità: un errore del Worker non finisce in cache', () async {
    final repo = repository();

    expect(await repo.vendibilita('000000002'), isNull);
    expect(await repo.vendibilita('000000002'), isNull);
    expect(richieste, hasLength(2));
  });

  test(
    'errore 5xx del Worker: un secondo tentativo, la lettura non va persa',
    () async {
      erroriWorker = 1;
      final repo = repository();

      expect(
        (await repo.cercaProdotti('034329110')).single.codice,
        '034329110',
      );
      expect(richieste, hasLength(2));
    },
  );

  test(
    'due errori 5xx di fila: nessun risultato, nessun terzo tentativo',
    () async {
      erroriWorker = 2;
      final repo = repository();

      expect(await repo.cercaProdotti('034329110'), isEmpty);
      expect(richieste, hasLength(2));
    },
  );

  test('token scaduto: rinnova e riprova una volta', () async {
    tokenScaduto = true;
    final repo = repository();

    expect(await repo.rendibilita('012745182'), isNotEmpty);
    expect(rinnovi, 1);
    expect(richieste, hasLength(2));
  });

  test(
    'rendibilità e immagine passano dal Worker e restano in cache',
    () async {
      final repo = repository();

      expect(
        await repo.rendibilita('012745182'),
        await repo.rendibilita('012745182'),
      );
      expect(await repo.immagineUrl('012745182'), 'https://cdn.test/1.jpg');
      expect(await repo.immagineUrl('012745182'), 'https://cdn.test/1.jpg');
      expect(richieste.map((u) => u.path), ['/v1/rendibilita', '/v1/immagine']);
    },
  );

  test('bugiardino: i link firmati /v1/doc non vanno in cache', () async {
    var url = 'https://proxy.test/v1/doc?tipo=F&nome=a.htm&exp=1&sig=x';
    rotte['/v1/bugiardino'] = (_) => {'url': url};
    final repo = repository();

    await repo.bugiardinoUrl('012745182', 'F');
    await repo.bugiardinoUrl('012745182', 'F');
    expect(richieste, hasLength(2));

    url = 'http://api.doublecore.it/pdf_html/012745182.html';
    await repo.bugiardinoUrl('012745182', 'F');
    await repo.bugiardinoUrl('012745182', 'F');
    expect(richieste, hasLength(3));
  });

  test(
    'Worker irraggiungibile: dato scaduto se c\'è, altrimenti nessun risultato',
    () async {
      final repo = repository();
      await repo.cercaProdotti('034329110');

      now = now.add(const Duration(days: 31));
      rotte.clear();

      expect(
        (await repo.cercaProdotti('034329110')).single.codice,
        '034329110',
      );
      expect(await repo.cercaProdotti('999999999'), isEmpty);
    },
  );

  group('calcolaVendibilita', () {
    final oggi = DateTime(2026, 10, 13);
    test('nessun lotto: vendibile', () {
      expect(calcolaVendibilita(haLotto: false), isTrue);
    });
    test('VF/RD vendibili fino alla data, RI dalla data in poi', () {
      bool? v(String stato, String data) => calcolaVendibilita(
        haLotto: true,
        stato: stato,
        data: data,
        oggi: oggi,
      );
      expect(v('VF', '2026-12-01'), isTrue);
      expect(v('VF', '2026-01-01'), isFalse);
      expect(v('RD', '2026-12-01'), isTrue);
      expect(v('RI', '2026-01-01'), isTrue);
      expect(v('RI', '2026-12-01'), isFalse);
    });
    test('dati incompleti o data non valida: non determinabile', () {
      expect(calcolaVendibilita(haLotto: true, stato: 'VF', data: ''), isNull);
      expect(calcolaVendibilita(haLotto: true, stato: 'VF', data: 'x'), isNull);
    });
  });
}
