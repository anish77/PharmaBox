// TEMPORANEO: giro sull'app vera per verificare i commit di Ana del 10/10.
// flutter drive --driver=test_driver/integration_test.dart \
//   --target=integration_test/verifica_modifiche_ana_test.dart -d <device> \
//   --dart-define=TEST_EMAIL=... --dart-define=TEST_PASSWORD=...

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
import 'package:pharma_box/firebase/liste_repository.dart';
import 'package:pharma_box/main.dart';

const _email = String.fromEnvironment('TEST_EMAIL');
const _password = String.fromEnvironment('TEST_PASSWORD');
const _lista1 = 'Prova Ana 1';
const _lista2 = 'Prova Ana 2';

bool _eliminabile(String nome) =>
    nome.startsWith('Prova Ana') || nome.startsWith('Test lettura');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  var n = 0;

  Future<void> foto(WidgetTester tester, String nome) async {
    await tester.pump(const Duration(milliseconds: 600));
    n++;
    await binding.takeScreenshot('${n.toString().padLeft(2, '0')}_$nome');
  }

  testWidgets('Modifiche di Ana sull\'app vera', (tester) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await RevenuecatService.configurRevenuecat(
      Platform.isAndroid ? kApiKeyGoogle : kApiKeyApple,
    );
    await FirebaseAuth.instance.signOut();

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await _attendi(tester, find.text('Accedi'));
    await foto(tester, 'login');

    // Login dalla pagina vera
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), _email);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      _password,
    );
    await tester.tap(find.text('Accedi'));
    await _attendi(tester, find.text('Crea una lista'));
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // Pulizia di liste "Prova Ana" rimaste da giri precedenti
    for (final l in await ListeRepository.instance.leggiListe(uid)) {
      if (l.nome.startsWith('Prova Ana')) {
        await ListeRepository.instance.eliminaLista(uid, l.id);
      }
    }
    final iniziali = await ListeRepository.instance.leggiListe(uid);
    debugPrint('LISTE INIZIALI: ${iniziali.map((l) => l.nome).toList()}');
    final altre = iniziali.where((l) => !_eliminabile(l.nome)).toList();
    await _attendiLista(tester, iniziali.isEmpty);
    await foto(tester, 'home');

    // --- 2a7e104: popup "Crea Nuova Lista" ---
    await tester.tap(find.byTooltip('Crea nuova lista'));
    await _attendi(tester, find.text('Crea Nuova Lista'));
    expect(
      _bottone(tester, 'Crea').onPressed,
      isNull,
      reason: 'Crea attivo a campo vuoto',
    );
    await foto(tester, 'popup_vuoto');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Titolo Lista'),
      _lista1,
    );
    await tester.pump();
    expect(_bottone(tester, 'Crea').onPressed, isNotNull);
    await foto(tester, 'popup_con_nome');
    await tester.tap(find.widgetWithText(TextButton, 'Crea'));
    await _attendiAssente(tester, find.text('Crea Nuova Lista'));
    await _attendi(tester, find.text(_lista1));
    debugPrint('OK popup: Crea disattivo a vuoto, lista creata');

    // Nome duplicato: errore e popup resta aperto
    await tester.tap(find.byTooltip('Crea nuova lista'));
    await _attendi(tester, find.text('Crea Nuova Lista'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Titolo Lista'),
      _lista1,
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Crea'));
    await _attendi(tester, find.text('Esiste già una lista con questo nome'));
    expect(find.text('Crea Nuova Lista'), findsOneWidget);
    await foto(tester, 'popup_duplicato');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Titolo Lista'),
      _lista2,
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Crea'));
    await _attendiAssente(tester, find.text('Crea Nuova Lista'));
    await _attendi(tester, find.text(_lista2));
    await foto(tester, 'home_due_liste');
    debugPrint('OK popup: duplicato segnalato');

    // --- 89a1f9b: pagina lista, "Cerca prodotto" e stato Bluetooth ---
    await tester.tap(find.text(_lista1));
    await _attendi(tester, find.text('Connetti scanner'));
    expect(
      find.text('Inserisci almeno 3 caratteri per cercare'),
      findsOneWidget,
    );
    expect(_bottoneCerca(tester).onPressed, isNull);
    await foto(tester, 'lista_cerca_vuoto');

    await tester.enterText(find.byType(TextFormField), 'ta');
    await tester.pump();
    expect(
      find.text('Inserisci almeno 3 caratteri per cercare'),
      findsOneWidget,
    );
    expect(_bottoneCerca(tester).onPressed, isNull);
    await foto(tester, 'cerca_2_caratteri');

    await tester.enterText(find.byType(TextFormField), 'tachipirina');
    await tester.pump();
    expect(find.text('Inserisci almeno 3 caratteri per cercare'), findsNothing);
    expect(_bottoneCerca(tester).onPressed, isNotNull);
    await foto(tester, 'cerca_pronto');
    await tester.tap(find.widgetWithText(ElevatedButton, kCercaProdotto));
    await tester.pump(const Duration(seconds: 1));
    await _attendiAssente(
      tester,
      find.byType(CircularProgressIndicator),
      timeout: const Duration(seconds: 40),
    );
    await foto(tester, 'cerca_risultati');
    debugPrint('OK cerca: soglia 3 caratteri e ricerca eseguita');

    // Torna allo stato Bluetooth e apre il selettore
    await tester.enterText(find.byType(TextFormField), '');
    await tester.pump();
    await _attendi(tester, find.text('Connetti scanner'));
    await tester.ensureVisible(find.text('Connetti scanner'));
    await tester.pump();
    await foto(tester, 'stato_bluetooth');
    await tester.tap(find.text('Connetti scanner'));
    await _attendi(tester, find.text('Seleziona scanner'));
    await tester.pump(const Duration(seconds: 2));
    await foto(tester, 'selettore_scanner');
    debugPrint('OK bluetooth: il pulsante apre il selettore');
    Navigator.of(tester.element(find.text('Seleziona scanner'))).pop();
    await _attendiAssente(tester, find.text('Seleziona scanner'));
    Navigator.of(tester.element(find.text('Connetti scanner'))).pop();
    await _attendiAssente(tester, find.text('Connetti scanner'));
    await _attendi(tester, find.text('Crea una lista'));

    // --- 8c01a01: eliminazione liste (tutte, se l'account ha solo liste di prova) ---
    final daEliminare = [
      ...iniziali.map((l) => l.nome).where(_eliminabile),
      _lista1,
      _lista2,
    ];
    for (final nome in daEliminare) {
      await _attendi(tester, find.text(nome));
      await tester.drag(find.text(nome), const Offset(-600, 0));
      await _attendi(tester, find.text('Conferma eliminazione'));
      await tester.tap(find.widgetWithText(TextButton, 'Elimina'));
      await _attendiAssente(tester, find.text(nome));
      expect(tester.takeException(), isNull);
      debugPrint('eliminata "$nome"');
    }
    if (altre.isEmpty) {
      await _attendi(tester, find.text('Crea la tua prima lista'));
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
      expect(find.text('Crea la tua prima lista'), findsOneWidget);
      debugPrint('OK eliminazione: tutte le liste cancellate, nessun crash');
    } else {
      debugPrint(
        'ATTENZIONE: non cancello le liste ${altre.map((l) => l.nome)}, '
        'eliminazione di TUTTE non verificata',
      );
    }
    await foto(tester, 'home_dopo_eliminazione');
    final finali = await ListeRepository.instance.leggiListe(uid);
    debugPrint('LISTE FINALI: ${finali.map((l) => l.nome).toList()}');
    expect(finali.where((l) => l.nome.startsWith('Prova Ana')), isEmpty);
  });
}

TextButton _bottone(WidgetTester tester, String testo) =>
    tester.widget<TextButton>(find.widgetWithText(TextButton, testo));

ElevatedButton _bottoneCerca(WidgetTester tester) =>
    tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, kCercaProdotto),
    );

Future<void> _attendiLista(WidgetTester tester, bool vuota) => _attendi(
  tester,
  vuota ? find.text('Crea la tua prima lista') : find.byType(ListTile),
);

Future<void> _attendi(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
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
  Duration timeout = const Duration(seconds: 30),
}) async {
  final fine = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(fine)) {
    await tester.pump(const Duration(milliseconds: 300));
    if (finder.evaluate().isEmpty) return;
  }
  fail('Ancora presente dopo ${timeout.inSeconds}s: $finder');
}
