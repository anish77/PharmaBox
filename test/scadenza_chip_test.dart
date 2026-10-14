import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
