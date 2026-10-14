import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharma_box/logic/preferenze_dispositivo.dart';
import 'package:pharma_box/view/opzioni_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef P = PreferenzeDispositivo;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    P.ripristinaPredefiniti();
  });

  group('PreferenzeDispositivo', () {
    test('valori predefiniti se mai impostate', () async {
      P.feedbackAptico.value = false;
      P.mesiInScadenza.value = 1;
      await P.carica();
      expect(P.feedbackAptico.value, isTrue);
      expect(P.suonoLettura.value, isFalse);
      expect(P.riconnettiScanner.value, isTrue);
      expect(P.ultimoScannerId.value, isNull);
      expect(P.schermoAcceso.value, isFalse);
      expect(P.ordinamento, OrdinamentoLista.nome);
      expect(P.scadenzeAperte.value, isFalse);
      expect(P.mesiInScadenza.value, 3);
      expect(P.mesiProssima.value, 6);
      expect(P.avvisoScaduta.value, isTrue);
      expect(P.avvisoInScadenza.value, isTrue);
      expect(P.avvisoAmbigua.value, isTrue);
    });

    test('le scelte restano salvate dopo un riavvio', () async {
      await P.feedbackAptico.imposta(false);
      await P.mesiInScadenza.imposta(2);
      await P.impostaOrdinamento(OrdinamentoLista.scadenza);
      await P.salvaUltimoScanner('AA:BB', 'BarCode Scanner BLE');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('feedback_aptico'), isFalse);
      expect(prefs.getInt('mesi_in_scadenza'), 2);

      P.ripristinaPredefiniti();
      await P.carica();
      expect(P.feedbackAptico.value, isFalse);
      expect(P.mesiInScadenza.value, 2);
      expect(P.ordinamento, OrdinamentoLista.scadenza);
      expect(P.ultimoScannerId.value, 'AA:BB');
      expect(P.ultimoScannerNome.value, 'BarCode Scanner BLE');
    });

    test('dimentica scanner cancella la preferenza', () async {
      await P.salvaUltimoScanner('AA:BB', '');
      expect(P.ultimoScannerNome.value, isNull);
      await P.dimenticaScanner();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('ultimo_scanner_id'), isFalse);
      expect(P.ultimoScannerId.value, isNull);
    });

    test('valore salvato di tipo sbagliato: predefinito', () async {
      SharedPreferences.setMockInitialValues({'mesi_in_scadenza': 'tre'});
      await P.carica();
      expect(P.mesiInScadenza.value, 3);
    });

    test('ordinamento con cui si apre la lista', () async {
      expect(P.apriPerScadenza, isFalse);
      await P.impostaOrdinamento(OrdinamentoLista.scadenza);
      expect(P.apriPerScadenza, isTrue);
      await P.impostaOrdinamento(OrdinamentoLista.ultimo);
      expect(P.apriPerScadenza, isFalse);
      await P.ultimoPerScadenza.imposta(true);
      expect(P.apriPerScadenza, isTrue);
    });
  });

  group('Pagina Opzioni', () {
    Future<void> mostra(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: OpzioniPage()));
    }

    SwitchListTile interruttore(WidgetTester tester, String titolo) => tester
        .widget<SwitchListTile>(find.widgetWithText(SwitchListTile, titolo));

    testWidgets('tutte le opzioni, con i valori predefiniti', (tester) async {
      await mostra(tester);
      for (final titolo in [
        'Ricollega l\'ultimo scanner',
        'Feedback aptico',
        'Confezione scaduta',
        'Confezione in scadenza',
        'Lettura ambigua',
      ]) {
        expect(interruttore(tester, titolo).value, isTrue, reason: titolo);
      }
      for (final titolo in [
        'Suono alla lettura',
        'Schermo sempre acceso',
        'Scadenze e lotti sempre aperti',
      ]) {
        expect(interruttore(tester, titolo).value, isFalse, reason: titolo);
      }
      expect(find.text('Scade entro 3 mesi.'), findsOneWidget);
      expect(find.text('entro 3 mesi'), findsOneWidget);
      expect(find.text('entro 6 mesi'), findsOneWidget);
      expect(find.text('Per nome'), findsOneWidget);
      expect(find.text('Dimentica'), findsNothing);
    });

    testWidgets('un interruttore cambia e salva la preferenza', (tester) async {
      await mostra(tester);
      await tester.tap(find.widgetWithText(SwitchListTile, 'Feedback aptico'));
      await tester.pumpAndSettle();
      expect(P.feedbackAptico.value, isFalse);
      expect(interruttore(tester, 'Feedback aptico').value, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('feedback_aptico'), isFalse);

      await tester.tap(
        find.widgetWithText(SwitchListTile, 'Schermo sempre acceso'),
      );
      await tester.pumpAndSettle();
      expect(P.schermoAcceso.value, isTrue);
    });

    testWidgets('soglia arancione oltre la ocra: la ocra si sposta', (
      tester,
    ) async {
      await mostra(tester);
      await tester.tap(find.byKey(const Key('soglia_in_scadenza')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('entro 6 mesi').last);
      await tester.pumpAndSettle();

      expect(P.mesiInScadenza.value, 6);
      expect(P.mesiProssima.value, 9);
      expect(find.text('Scade entro 6 mesi.'), findsOneWidget);
      expect(find.text('entro 9 mesi'), findsOneWidget);
    });

    testWidgets('ordinamento della lista', (tester) async {
      await mostra(tester);
      await tester.tap(find.byKey(const Key('ordinamento_lista')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ultimo usato').last);
      await tester.pumpAndSettle();
      expect(P.ordinamento, OrdinamentoLista.ultimo);
      expect(find.text('Ultimo usato'), findsOneWidget);
    });

    testWidgets('scanner salvato: nome e "Dimentica"', (tester) async {
      await P.salvaUltimoScanner('AA:BB', 'BarCode Scanner BLE');
      await mostra(tester);
      expect(
        find.text(
          'Aprendo una lista si collega da solo a BarCode Scanner BLE.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Dimentica'));
      await tester.pumpAndSettle();
      expect(P.ultimoScannerId.value, isNull);
      expect(find.text('Dimentica'), findsNothing);
    });
  });
}
