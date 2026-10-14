// Screenshot delle scadenze lette da DataMatrix, su simulatore o telefono:
//
//   SCREEN_DIR=screenshots/datamatrix flutter drive \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/datamatrix_scadenze_test.dart -d <device> \
//     --dart-define=TEST_EMAIL=... --dart-define=TEST_PASSWORD=...
//
// Login, crea una lista temporanea e legge dal simulatore BLE (tab "Lista")
// 8 DataMatrix dell'AIC 040295141 con scadenze, lotti e seriali diversi.
// Dopo ogni lettura salva uno screenshot, poi l'etichetta di scadenza e
// l'elenco delle scadenze con i lotti; verifica pezzi e lotti su Firestore. Alla fine la lista
// viene eliminata.

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/features/subscribtions/offerings_cubit.dart';
import 'package:pharma_box/features/subscribtions/revenuecat_service.dart';
import 'package:pharma_box/features/subscribtions/subscribtion_cubit.dart';
import 'package:pharma_box/firebase/firebase_options.dart';
import 'package:pharma_box/firebase/liste_repository.dart';
import 'package:pharma_box/models/lotto_confezione.dart';
import 'package:pharma_box/view/selected_list_page.dart';
import 'package:pharma_box/widgets/scadenza_chip.dart';

const _email = String.fromEnvironment('TEST_EMAIL');
const _password = String.fromEnvironment('TEST_PASSWORD');
const _aic = '040295141';

/// Stessi codici di test/ble_simulator_test.dart. L'ultimo ripete il
/// seriale del 4: va rifiutato come già contato.
const _letture = [
  (
    'scaduta',
    '(01)08032082951415(17)260915(10)LA01(21)SN7K2M9QX4PA(716)040295141',
  ),
  (
    'entro_3_mesi',
    '(01)08032082951415(17)261120(10)LB02(21)SN3HD8W2RT6B(716)040295141',
  ),
  (
    'giorno_00_entro_6_mesi',
    '(01)08032082951415(17)270300(10)LC03(21)SN9PL4ZE7VJC(716)040295141',
  ),
  (
    'giorno_preciso',
    '(01)08032082951415(17)280615(10)LD04(21)SN5TQ2NB8XKD(716)040295141',
  ),
  (
    'stesso_lotto_altro_seriale',
    '(01)08032082951415(17)280615(10)LD04(21)SN2WF6YC3MHE(716)040295141',
  ),
  (
    'stesso_lotto_giorno_00',
    '(01)08032082951415(17)280600(10)LD04(21)SN8RJ5UA4GLF(716)040295141',
  ),
  (
    'stessa_scadenza_altro_lotto',
    '(01)08032082951415(17)280615(10)LD07(21)SN4CV7HN2QWG(716)040295141',
  ),
  (
    'seriale_gia_contato',
    '(01)08032082951415(17)280615(10)LD04(21)SN5TQ2NB8XKD(716)040295141',
  ),
];

/// Lotti attesi su Firestore: 'lotto|scadenza' -> pezzi
const _lottiAttesi = {
  'LA01|2026-09-15': 1,
  'LB02|2026-11-20': 1,
  'LC03|2027-03-31': 1,
  'LD04|2028-06-15': 2,
  'LD04|2028-06-30': 1,
  'LD07|2028-06-15': 1,
};

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  var n = 0;

  Future<void> foto(WidgetTester tester, String nome) async {
    await tester.pump(const Duration(milliseconds: 600));
    n++;
    await binding.takeScreenshot('${n.toString().padLeft(2, '0')}_$nome');
  }

  testWidgets('DataMatrix 040295141: scadenze, lotti e seriali', (
    tester,
  ) async {
    expect(_email, isNotEmpty, reason: 'manca --dart-define=TEST_EMAIL');
    expect(_password, isNotEmpty, reason: 'manca --dart-define=TEST_PASSWORD');

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await RevenuecatService.configurRevenuecat(
      Platform.isAndroid ? kApiKeyGoogle : kApiKeyApple,
    );
    final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _email,
      password: _password,
    );
    final uid = cred.user!.uid;

    final repo = ListeRepository.instance;
    final idLista = repo.creaLista(
      uid,
      'Test DataMatrix ${DateTime.now().toIso8601String()}',
    );
    addTearDown(() async {
      await repo.eliminaLista(uid, idLista);
      await FirebaseAuth.instance.signOut();
    });

    if (Platform.isAndroid) await binding.convertFlutterSurfaceToImage();
    await tester.pumpWidget(
      ProviderScope(
        child: MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => SubscriptionCubit()),
            BlocProvider(
              create:
                  (context) =>
                      OfferingsCubit(context.read<SubscriptionCubit>())
                        ..loadOfferings(),
            ),
          ],
          child: MaterialApp(
            home: SelectedListPage(
              idLista: idLista,
              titolo: 'Test DataMatrix',
              nrListe: 1,
            ),
          ),
        ),
      ),
    );
    await _attendi(
      tester,
      () async => find.text('Lista').evaluate().isNotEmpty,
    );

    // Tab "Lista": ogni lettura aggiunge direttamente un pezzo
    await tester.tap(find.text('Lista'));
    await tester.pumpAndSettle();

    Future<int> pezzi() async {
      final items = await repo.leggiItems(uid, idLista);
      return items.fold<int>(0, (somma, i) => somma + i.quantity);
    }

    var attesi = 0;
    for (final (nome, codice) in _letture) {
      final giaContata = nome == 'seriale_gia_contato';
      ScaffoldMessenger.of(tester.element(find.text('Lista'))).clearSnackBars();
      await _simula(tester, codice);

      if (giaContata) {
        await _attendi(
          tester,
          () async =>
              find
                  .textContaining('Confezione già contata')
                  .evaluate()
                  .isNotEmpty,
        );
        expect(await pezzi(), attesi, reason: 'seriale ripetuto contato');
      } else {
        attesi++;
        await _attendi(tester, () async => await pezzi() >= attesi);
        if (nome == 'scaduta') {
          await _attendi(
            tester,
            () async =>
                find
                    .textContaining('Confezione SCADUTA il 15/09/2026')
                    .evaluate()
                    .isNotEmpty,
          );
        }
      }
      await foto(tester, nome);
      debugPrint('OK $nome: $attesi pezzi');
    }

    // Firestore: 7 pezzi in 6 lotti, il seriale ripetuto non è salvato due volte
    final items = await repo.leggiItems(uid, idLista);
    expect(items, hasLength(1));
    final item = items.single;
    expect(item.minsan, _aic);
    expect(item.quantity, 7);
    expect(item.seriali, hasLength(7));
    expect({
      for (final l in item.lotti)
        '${l.lotto}|${l.scadenza == null ? '' : scadenzaIso(l.scadenza!)}':
            l.quantity,
    }, _lottiAttesi);

    // Etichetta con la scadenza più vicina, poi aperta sulle scadenze
    ScaffoldMessenger.of(tester.element(find.text('Lista'))).clearSnackBars();
    await tester.pumpAndSettle();
    final chip = find.byType(ScadenzaChip);
    expect(chip, findsOneWidget);
    expect(find.text('Scaduto il 15/09/2026 · 6 lotti'), findsOneWidget);
    await foto(tester, 'lista_etichetta_scadenza');

    await tester.tap(chip);
    await tester.pumpAndSettle();
    // 15/06/2028: LD04 (2 pz) e LD07 (1 pz); 30/06/2028: LD04
    expect(find.text('Tot. 3 pz'), findsOneWidget);
    expect(find.text('Lotto LD04'), findsNWidgets(2));
    expect(find.text('Lotto LD07'), findsOneWidget);
    expect(find.text('2 pz'), findsOneWidget);
    await foto(tester, 'scadenze_e_lotti');
  }, timeout: const Timeout(Duration(minutes: 5)));
}

/// Una lettura dal simulatore BLE dell'app (stessa catena dello scanner)
Future<void> _simula(WidgetTester tester, String codice) async {
  await tester.tap(find.byTooltip('Simula lettura Bluetooth (debug)'));
  await tester.pumpAndSettle();
  await tester.enterText(find.widgetWithText(TextField, 'Codici'), codice);
  await tester.enterText(find.widgetWithText(TextField, 'Ripetizioni'), '1');
  await tester.enterText(find.widgetWithText(TextField, 'Ritardo (ms)'), '0');
  await tester.tap(find.widgetWithText(TextButton, 'Simula'));
  await tester.pump();
}

/// Fa girare l'app finché [condizione] è vera, oppure fallisce dopo [timeout]
Future<void> _attendi(
  WidgetTester tester,
  Future<bool> Function() condizione, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final fine = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(fine)) {
    if (await condizione()) return;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await tester.pump();
  }
  fail('Condizione non raggiunta entro ${timeout.inSeconds}s');
}
