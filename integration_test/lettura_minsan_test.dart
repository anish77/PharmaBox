// Test end-to-end della lettura scanner, da eseguire su simulatore o telefono:
//
//   flutter test integration_test/lettura_minsan_test.dart -d <device> \
//     --dart-define=TEST_EMAIL=... --dart-define=TEST_PASSWORD=...
//
// Login, crea una lista temporanea e la svuota, poi legge ognuno dei 20 MINSAN
// reali da 10 a 40 volte (numero casuale, ordine mescolato) dal simulatore BLE
// dell'app (tab "Lista") e verifica su Firestore pezzi per prodotto e totale.
// Alla fine la lista viene eliminata. Per ripetere la stessa sequenza:
// --dart-define=SEED=<seed stampato>

import 'dart:io';
import 'dart:math';

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
import 'package:pharma_box/view/selected_list_page.dart';

const _email = String.fromEnvironment('TEST_EMAIL');
const _password = String.fromEnvironment('TEST_PASSWORD');
const _seed = int.fromEnvironment('SEED');

/// Stessi codici di test/lettura_minsan_test.dart
const _minsan = [
  '012745182', '012745170', '012745220', '012745028', '022593204',
  '052892015', '041962034', '004763330', '004763544', '025669019',
  '025669072', '025669185', '026089019', '013046038', '013046040',
  '034548065', '048414104', '020582209', '034936171', '034248068',
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Letture BLE simulate (10-40 per prodotto) finiscono nella lista', (
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
      'Test lettura ${DateTime.now().toIso8601String()}',
    );
    addTearDown(() async {
      await repo.eliminaLista(uid, idLista);
      await FirebaseAuth.instance.signOut();
    });

    await repo.svuotaLista(uid, idLista);
    expect(await repo.leggiItems(uid, idLista), isEmpty);

    // Pezzi attesi per prodotto e sequenza di letture mescolata
    final seed = _seed != 0 ? _seed : DateTime.now().millisecondsSinceEpoch;
    final random = Random(seed);
    final attesi = {for (final c in _minsan) c: 10 + random.nextInt(31)};
    final letture = [
      for (final MapEntry(key: codice, value: n) in attesi.entries)
        ...List.filled(n, codice),
    ]..shuffle(random);
    final totaleAtteso = letture.length;
    debugPrint('SEED=$seed, $totaleAtteso letture');

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
              titolo: 'Test lettura',
              nrListe: 1,
            ),
          ),
        ),
      ),
    );
    await _attendi(tester, () async => find.text('Lista').evaluate().isNotEmpty);

    // Tab "Lista": ogni lettura aggiunge direttamente un pezzo
    await tester.tap(find.text('Lista'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Simula lettura Bluetooth (debug)'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Codici'),
      letture.join(' '),
    );
    await tester.enterText(find.widgetWithText(TextField, 'Ripetizioni'), '1');
    await tester.enterText(
      find.widgetWithText(TextField, 'Ritardo (ms)'),
      '200',
    );
    await tester.tap(find.widgetWithText(TextButton, 'Simula'));
    await tester.pump();

    final avvio = DateTime.now();
    List<ItemLista> items = [];
    int salvati() => items.fold(0, (somma, i) => somma + i.quantity);
    await _attendi(tester, () async {
      items = await repo.leggiItems(uid, idLista);
      return salvati() >= totaleAtteso;
    }, timeout: const Duration(minutes: 6));
    // Lascia arrivare eventuali letture in eccesso prima del confronto
    await Future<void>.delayed(const Duration(seconds: 3));
    items = await repo.leggiItems(uid, idLista);
    debugPrint(
      '${salvati()}/$totaleAtteso pezzi salvati in '
      '${DateTime.now().difference(avvio).inSeconds}s',
    );

    final perMinsan = {for (final i in items) i.minsan: i};
    for (final codice in _minsan) {
      final item = perMinsan[codice];
      debugPrint(
        '$codice -> ${item?.titolo} x${item?.quantity} (attesi ${attesi[codice]})',
      );
      expect(item, isNotNull, reason: '$codice non è nella lista');
      expect(item!.quantity, attesi[codice], reason: '$codice: pezzi errati');
    }
    expect(items, hasLength(_minsan.length));

    final lista = (await repo.leggiListe(
      uid,
    )).firstWhere((l) => l.id == idLista);
    expect(lista.totalePezzi, totaleAtteso, reason: 'totale lista errato');
  }, timeout: const Timeout(Duration(minutes: 15)));
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
