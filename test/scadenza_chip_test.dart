import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharma_box/logic/preferenze_dispositivo.dart';
import 'package:pharma_box/models/lotto_confezione.dart';
import 'package:pharma_box/models/prodotto.dart';
import 'package:pharma_box/widgets/scadenza_chip.dart';

Prodotto prodotto() => Prodotto(
  nome: 'TACHIPIRINA*16CPR DIV 1000MG',
  minsan: '012745182',
  immagine: '',
  pezzi: 3,
  vendibile: 0,
  description: '',
  ingredients: '',
  howToTake: '',
  codice: '',
);

Future<void> mostra(WidgetTester tester, Prodotto p) => tester.pumpWidget(
  MaterialApp(home: Scaffold(body: ScadenzaChip(prodotto: p))),
);

void main() {
  testWidgets('nessun lotto: nessuna etichetta', (tester) async {
    await mostra(tester, prodotto());
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('scadenza più vicina, numero lotti e dettaglio', (tester) async {
    final p = prodotto();
    await mostra(tester, p);
    p.lotti.value = [
      LottoConfezione(lotto: 'B', scadenza: DateTime(2099, 5, 31), quantity: 1),
      LottoConfezione(lotto: 'A', scadenza: DateTime(2098, 1, 31), quantity: 1),
    ];
    await tester.pump();
    expect(find.text('Scad. 31/01/2098 · 2 lotti'), findsOneWidget);

    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();
    expect(find.text('Lotto A'), findsOneWidget);
    expect(find.text('Lotto B'), findsOneWidget);
    // 3 pezzi, 2 letti da DataMatrix
    expect(find.textContaining('1 pezzo senza scadenza'), findsOneWidget);
  });

  testWidgets('scaduto', (tester) async {
    final p = prodotto();
    p.lotti.value = [
      LottoConfezione(lotto: 'A', scadenza: DateTime(2020, 1, 31), quantity: 1),
    ];
    await mostra(tester, p);
    expect(find.text('Scaduto il 31/01/2020'), findsOneWidget);
  });

  testWidgets('aperta: lotti raggruppati per scadenza, poi si richiude', (
    tester,
  ) async {
    final p = prodotto()..pezzi.value = 5;
    p.lotti.value = [
      LottoConfezione(
        lotto: 'LD07',
        scadenza: DateTime(2098, 6, 15),
        quantity: 1,
      ),
      LottoConfezione(
        lotto: 'LD04',
        scadenza: DateTime(2098, 6, 30),
        quantity: 1,
      ),
      LottoConfezione(
        lotto: 'LD04',
        scadenza: DateTime(2098, 6, 15),
        quantity: 2,
      ),
      LottoConfezione(lotto: 'X', scadenza: DateTime(2098, 1, 1), quantity: 0),
    ];
    await mostra(tester, p);
    expect(find.text('Scad. 15/06/2098 · 3 lotti'), findsOneWidget);
    expect(find.text('Lotto LD07'), findsNothing);

    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();
    // 15/06: LD04 e LD07 sotto la stessa data; 30/06: LD04
    expect(find.text('Scad. 15/06/2098'), findsOneWidget);
    expect(find.text('Scad. 30/06/2098'), findsOneWidget);
    expect(find.text('Tot. 3 pz'), findsOneWidget);
    expect(find.text('Tot. 1 pz'), findsOneWidget);
    expect(find.text('Lotto LD04'), findsNWidgets(2));
    expect(find.text('Lotto LD07'), findsOneWidget);
    expect(find.text('Lotto X'), findsNothing);
    expect(find.textContaining('1 pezzo senza scadenza'), findsOneWidget);
    final y = tester.getTopLeft;
    expect(
      y(find.text('Scad. 15/06/2098')).dy,
      lessThan(y(find.text('Lotto LD07')).dy),
    );
    expect(
      y(find.text('Lotto LD07')).dy,
      lessThan(y(find.text('Scad. 30/06/2098')).dy),
    );

    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();
    expect(find.text('Lotto LD07'), findsNothing);
  });

  test('lottiPerScadenza: date in ordine, senza scadenza in fondo', () {
    final gruppi = lottiPerScadenza([
      const LottoConfezione(lotto: 'N', scadenza: null, quantity: 1),
      LottoConfezione(lotto: 'B', scadenza: DateTime(2030, 2, 1), quantity: 1),
      LottoConfezione(lotto: 'C', scadenza: DateTime(2030, 1, 1), quantity: 1),
      LottoConfezione(lotto: 'A', scadenza: DateTime(2030, 2, 1), quantity: 3),
    ]);
    expect(gruppi.map((g) => g.scadenza), [
      DateTime(2030, 1, 1),
      DateTime(2030, 2, 1),
      null,
    ]);
    expect(gruppi[1].lotti.map((l) => l.lotto), ['A', 'B']);
  });

  testWidgets('"scadenze sempre aperte" nelle Opzioni: parte aperta', (
    tester,
  ) async {
    PreferenzeDispositivo.scadenzeAperte.value = true;
    addTearDown(PreferenzeDispositivo.ripristinaPredefiniti);
    final p = prodotto();
    p.lotti.value = [
      LottoConfezione(lotto: 'A', scadenza: DateTime(2098, 1, 31), quantity: 1),
    ];
    await mostra(tester, p);
    expect(find.text('Lotto A'), findsOneWidget);
  });
}
