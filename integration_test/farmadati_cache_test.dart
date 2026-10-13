// Test della cache Farmadati sul dispositivo, con il servizio reale:
//
//   flutter test integration_test/farmadati_cache_test.dart -d <device>
//
// Svuota la cache su disco, poi verifica che le richieste ripetute (stessa
// istanza, nuova istanza = riavvio app, richieste contemporanee) non tornino
// a Farmadati. Non serve login.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pharma_box/farmadati/soap_farmadati_repository.dart';
import 'package:pharma_box/models/prodotto.dart';

/// Stessi codici di test/lettura_minsan_test.dart
const _minsan = [
  '012745182', '012745170', '012745220', '012745028', '022593204',
  '052892015', '041962034', '004763330', '004763544', '025669019',
  '025669072', '025669185', '026089019', '013046038', '013046040',
  '034548065', '048414104', '020582209', '034936171', '034248068',
];

int _totale(Map<String, int> contatori) =>
    contatori.values.fold(0, (somma, n) => somma + n);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late SoapFarmadatiRepository repo;
  final nomi = <String, String>{};
  final prodotti = <String, Prodotto>{};

  setUpAll(() async {
    final base = await getApplicationCacheDirectory();
    dir = Directory('${base.path}/farmadati');
    if (await dir.exists()) await dir.delete(recursive: true);
    repo = SoapFarmadatiRepository();
  });

  testWidgets('prima passata: 20 MINSAN letti da Farmadati', (_) async {
    final avvio = DateTime.now();
    for (final codice in _minsan) {
      final risultati = await repo.cercaProdotti(codice);
      expect(risultati, isNotEmpty, reason: 'nessun prodotto per $codice');
      nomi[codice] = risultati.first.nome;
      prodotti[codice] = risultati.first;
    }
    debugPrint('Rete: ${DateTime.now().difference(avvio).inMilliseconds} ms');
    expect(repo.stats.rete['prodotti'], _minsan.length);
  });

  testWidgets('seconda passata: tutto dalla cache in memoria', (_) async {
    final avvio = DateTime.now();
    for (final codice in _minsan) {
      final risultati = await repo.cercaProdotti(codice);
      expect(risultati.first.nome, nomi[codice]);
    }
    debugPrint('Cache: ${DateTime.now().difference(avvio).inMilliseconds} ms');
    expect(repo.stats.rete['prodotti'], _minsan.length);
    expect(repo.stats.cache['prodotti'], _minsan.length);
  });

  testWidgets('dopo un riavvio: tutto dalla cache su disco', (_) async {
    final files = await dir.list().where((f) => f is File).length;
    expect(files, greaterThanOrEqualTo(_minsan.length));

    final riavviato = SoapFarmadatiRepository();
    for (final codice in _minsan) {
      final risultati = await riavviato.cercaProdotti(codice);
      expect(risultati.first.nome, nomi[codice]);
      expect(risultati.first.tipoProdotto, prodotti[codice]!.tipoProdotto);
    }
    expect(riavviato.stats.rete, isEmpty);
    debugPrint('File in cache: $files');
  });

  testWidgets('ricerca per nome ripetuta: una sola chiamata', (_) async {
    final primo = await repo.cercaProdotti('TACHIPIRINA');
    final secondo = await repo.cercaProdotti('TACHIPIRINA');

    expect(primo, isNotEmpty);
    expect(secondo.map((p) => p.codice), primo.map((p) => p.codice));
    expect(repo.stats.rete['prodotti'], _minsan.length + 1);
  });

  testWidgets('scheda prodotto: vendibilità, rendibilità, immagine, bugiardino '
      'non tornano a Farmadati alla seconda apertura', (_) async {
    Future<void> apriScheda(String codice) async {
      final p = prodotti[codice]!;
      await Future.wait([
        repo.vendibilita(codice),
        repo.rendibilita(codice),
        repo.immagineUrl(codice),
        repo.bugiardinoUrl(codice, p.tipoProdottoDettaglio),
      ]);
    }

    final schede = _minsan.take(5);
    for (final codice in schede) {
      await apriScheda(codice);
    }
    final dopoPrima = _totale(repo.stats.rete);
    debugPrint('Prima apertura di 5 schede: ${repo.stats}');

    for (final codice in schede) {
      await apriScheda(codice);
    }
    expect(_totale(repo.stats.rete), dopoPrima);
    // immagine servita dalla cache: URL R2 oppure risposta TDZ (anche vuota)
    expect(
      (repo.stats.cache['R2'] ?? 0) + (repo.stats.cache['immagine'] ?? 0),
      schede.length,
    );
    debugPrint('Seconda apertura di 5 schede: ${repo.stats}');
  });

  testWidgets('20 celle con lo stesso codice: una sola chiamata', (_) async {
    const codice = '034248068'; // non ancora interrogato per vendibilità
    final prima = repo.stats.rete['lottiInvendibili'] ?? 0;

    final esiti = await Future.wait(
      List.generate(20, (_) => repo.vendibilita(codice)),
    );

    expect(esiti.toSet(), hasLength(1));
    expect(repo.stats.rete['lottiInvendibili'], prima + 1);
    debugPrint('Statistiche finali: ${repo.stats}');
  });
}
