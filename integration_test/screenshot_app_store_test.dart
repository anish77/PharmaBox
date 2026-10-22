// Screenshot per App Store Connect, dall'app vera su simulatore iOS.
//
// Non si lancia da solo: tool/screenshot_app_store.sh prepara il simulatore
// (barra di stato 9:41) e cattura lo schermo a ogni riga "SCATTA:<nome>"
// stampata dal test, alla risoluzione nativa del dispositivo.
//
// Serve un account con email verificata e liste demo (nessuna scrittura qui:
// il test apre schermate, non modifica dati).

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/features/subscribtions/revenuecat_service.dart';
import 'package:pharma_box/firebase/firebase_options.dart';
import 'package:pharma_box/main.dart';
import 'package:pharma_box/widgets/prodotto_cell.dart';
import 'package:pharma_box/widgets/scadenza_chip.dart';

const _email = String.fromEnvironment('TEST_EMAIL');
const _password = String.fromEnvironment('TEST_PASSWORD');
const _listaPrincipale = 'Inventario ottobre';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Il Mac cattura lo schermo appena legge la riga: qui si aspetta che
  /// abbia finito, senza far avanzare la UI.
  Future<void> scatta(WidgetTester tester, String nome) async {
    await tester.pump(const Duration(milliseconds: 800));
    // ignore: avoid_print
    print('SCATTA:$nome');
    await _pausa(tester, const Duration(seconds: 3));
  }

  testWidgets('Screenshot App Store', (tester) async {
    expect(_email, isNotEmpty, reason: 'manca --dart-define=TEST_EMAIL');
    expect(_password, isNotEmpty, reason: 'manca --dart-define=TEST_PASSWORD');
    expect(
      kScreenshotAppStore,
      isTrue,
      reason: 'manca --dart-define=SCREENSHOT_APP_STORE=true',
    );

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await RevenuecatService.configurRevenuecat(
      Platform.isAndroid ? kApiKeyGoogle : kApiKeyApple,
    );
    await FirebaseAuth.instance.signOut();
    addTearDown(FirebaseAuth.instance.signOut);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await _attendi(tester, find.text('Accedi'));
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), _email);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      _password,
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.tap(find.text('Accedi'));
    await _attendi(tester, find.text(_listaPrincipale));
    await _pausa(tester, const Duration(seconds: 2));
    await scatta(tester, '01_liste');

    // Lista con scadenze e lotti letti dal DataMatrix
    await tester.tap(find.text(_listaPrincipale));
    await _attendi(tester, find.text('Lista'));
    await tester.tap(find.text('Lista'));
    await _attendi(tester, find.byType(ProdottoCell));
    await _pausa(tester, const Duration(seconds: 4)); // vendibilità
    await scatta(tester, '02_lista');

    // ogni prodotto ha uno ScadenzaChip, vuoto se non ha lotti: si apre
    // il primo con più lotti
    final chip = find.ancestor(
      of: find.textContaining('lotti'),
      matching: find.descendant(
        of: find.byType(ScadenzaChip),
        matching: find.byType(InkWell),
      ),
    );
    if (chip.evaluate().isNotEmpty) {
      await tester.tap(chip.first);
      await _pausa(tester, const Duration(seconds: 1));
      await scatta(tester, '03_lotti');
    }

    // Scheda di un parafarmaco: Farmadati ha le immagini solo per loro
    final nome =
        tester
            .widgetList<ProdottoCell>(find.byType(ProdottoCell))
            .firstWhere((c) => c.prodotto.minsan.startsWith('9'))
            .prodotto
            .nome;
    await tester.tap(find.text(nome).first);
    await _attendi(tester, find.byType(Image));
    await _pausa(tester, const Duration(seconds: 5)); // immagine e bugiardino
    await scatta(tester, '04_scheda');
    await _indietro(tester, find.byType(Image).first);
    await _attendi(tester, find.text('Cerca'));

    // Ricerca nel catalogo
    await tester.tap(find.text('Cerca'));
    await _pausa(tester, const Duration(seconds: 1));
    await tester.enterText(find.byType(TextFormField).first, 'tachipirina');
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, kCercaProdotto));
    await _pausa(tester, const Duration(seconds: 1));
    await _attendiAssente(tester, find.byType(CircularProgressIndicator));
    FocusManager.instance.primaryFocus?.unfocus();
    await _pausa(tester, const Duration(seconds: 4));
    await scatta(tester, '05_ricerca');

    // Esportazione di più liste
    await _indietro(tester, find.text('Cerca'));
    await _attendi(tester, find.text('Crea una lista'));
    for (final nome in [_listaPrincipale, 'Banco OTC']) {
      await tester.tap(
        find
            .descendant(
              of: find.ancestor(
                of: find.text(nome),
                matching: find.byType(ListTile),
              ),
              matching: find.byType(Checkbox),
            )
            .first,
      );
      await tester.pump();
    }
    await tester.tap(find.text('Scarica liste selezionate'));
    await _attendi(tester, find.text('Scarica PDF'));
    await _pausa(tester, const Duration(seconds: 1));
    await scatta(tester, '06_esporta');
  });
}

/// Le pagine dell'app hanno una freccia indietro propria, non BackButton.
Future<void> _indietro(WidgetTester tester, Finder inPagina) async {
  Navigator.of(tester.element(inPagina)).pop();
  await _pausa(tester, const Duration(seconds: 1));
}

/// Fa scorrere il tempo reale aggiornando lo schermo.
Future<void> _pausa(WidgetTester tester, Duration durata) async {
  final fine = DateTime.now().add(durata);
  while (DateTime.now().isBefore(fine)) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> _attendi(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 40),
}) async {
  final fine = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(fine)) {
    await tester.pump(const Duration(milliseconds: 300));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Non trovato entro ${timeout.inSeconds}s: $finder');
}

Future<void> _attendiAssente(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 40),
}) async {
  final fine = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(fine)) {
    await tester.pump(const Duration(milliseconds: 300));
    if (finder.evaluate().isEmpty) return;
  }
  fail('Ancora presente dopo ${timeout.inSeconds}s: $finder');
}
