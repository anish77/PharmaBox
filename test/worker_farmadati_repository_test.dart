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
                        'lotto': {'stato': 'RD', 'data': '2020-01-01'},
                        'provvedimenti': [
                          {
                            'stato': 'RD',
                            'data': '2020-01-01',
                            'motivo': 'U',
                            'esaurimento': '',
                          },
                        ],
                      }
                      : c == '000000003'
                      ? {
                        // risposta del Worker precedente: solo il primo record
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

  test('vendibilità: accetta anche le risposte con il solo lotto', () async {
    final repo = repository();
    expect(await repo.vendibilita('000000003'), isFalse);
  });

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
    bool? v(List<Provvedimento> p) => calcolaVendibilita(p, oggi: oggi);
    Provvedimento p(
      String stato, [
      String? data,
      String? motivo,
      String? esaurimento,
    ]) => Provvedimento(
      stato: stato,
      data: data,
      motivo: motivo,
      esaurimento: esaurimento,
    );

    test('nessun provvedimento: vendibile', () {
      expect(v(const []), isTrue);
    });

    test('VF vendibile fino al giorno indicato compreso', () {
      expect(v([p('VF', '2026-12-01')]), isTrue);
      expect(v([p('VF', '2026-10-13')]), isTrue);
      expect(v([p('VF', '2026-10-12')]), isFalse);
    });

    test('RD ritiro dalla data, RI ricommercializzabile dalla data', () {
      expect(v([p('RD', '2026-12-01')]), isTrue);
      expect(v([p('RD', '2026-10-13')]), isFalse);
      expect(v([p('RI', '2026-01-01')]), isTrue);
      expect(v([p('RI', '2026-12-01')]), isFalse);
    });

    test('decide il provvedimento più recente in vigore', () {
      // UNIVIT 034629016: vendibile fino al 30/11/2025, poi ricommercializzato
      expect(
        v([p('RI', '2026-02-26', 'X'), p('VF', '2025-11-30', 'D')]),
        isTrue,
      );
      // ritiro definitivo dopo il reintegro
      expect(v([p('RI', '2020-01-01'), p('RD', '2025-01-01')]), isFalse);
      // reintegro futuro: oggi è ancora ritirato
      expect(v([p('RD', '2025-01-01'), p('RI', '2027-01-01')]), isFalse);
    });

    test('ad esaurimento scorte senza data stato: vendibile', () {
      // DARZALEX 044885010: VF motivo E con sola FDI_T298
      expect(v([p('VF', null, 'E', '2027-06-30')]), isTrue);
      expect(v([p('VF', null, 'E')]), isTrue);
      // il caso che mostrava "non consentito": RD senza data, reintegro dopo
      expect(
        v([
          p('RD', null, 'E', '2007-07-11'),
          p('RI', '2009-08-03', 'X'),
          p('VF', '2009-07-22', 'R'),
        ]),
        isTrue,
      );
    });

    test('senza date o con stato sconosciuto: non determinabile', () {
      expect(v([p('VF', null, 'R')]), isNull);
      expect(v([p('VF', 'x', 'R')]), isNull);
      expect(v([p('ZZ', '2020-01-01')]), isNull);
      // un divieto in vigore resta tale anche con un record incompleto
      expect(v([p('RD', '2020-01-01'), p('VF', null, 'R')]), isFalse);
    });
  });
}
