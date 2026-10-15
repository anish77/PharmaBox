import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharma_box/models/lotto_confezione.dart';
import 'package:pharma_box/models/prodotto.dart';
import 'package:pharma_box/widgets/modifica_lotti_sheet.dart';

void main() {
  final scaduto = DateTime(2020, 1, 31);
  final lontano = DateTime(2030, 6, 30);

  late Prodotto prodotto;
  late List<(String, int)> chiamate;

  Prodotto nuovoProdotto() {
    final p = Prodotto(
      nome: 'TACHIPIRINA*16CPR DIV 1000MG',
      minsan: '012745182',
      immagine: '',
      pezzi: 4,
      vendibile: 0,
      description: '',
      ingredients: '',
      howToTake: '',
      codice: '012745182',
    );
    p.lotti.value = [
      LottoConfezione(lotto: 'LB02', scadenza: lontano, quantity: 2),
      LottoConfezione(lotto: 'LA01', scadenza: scaduto, quantity: 1),
    ];
    return p;
  }

  // simula il Carrello: aggiorna lotti e totale come farebbe l'app
  void suLotto(LottoConfezione lotto, int delta) {
    chiamate.add((lotto.lotto, delta));
    prodotto.lotti.value =
        [
          for (final l in prodotto.lotti.value)
            if (l.lotto == lotto.lotto)
              LottoConfezione(
                lotto: l.lotto,
                scadenza: l.scadenza,
                quantity: l.quantity + delta,
              )
            else
              l,
        ].where((l) => l.quantity > 0).toList();
    prodotto.pezzi.value += delta;
  }

  void senzaLotto(int delta) {
    chiamate.add(('senza', delta));
    prodotto.pezzi.value += delta;
  }

  Future<void> apri(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ModificaLotti(
            prodotto: prodotto,
            onLotto: suLotto,
            onSenzaLotto: senzaLotto,
          ),
        ),
      ),
    );
  }

  Finder meno(int riga) => find.byTooltip('Togli un pezzo').at(riga);
  Finder piu(int riga) => find.byTooltip('Aggiungi un pezzo').at(riga);

  setUp(() {
    prodotto = nuovoProdotto();
    chiamate = [];
  });

  testWidgets('una riga per lotto, dalla scadenza più vicina, più i pezzi '
      'senza scadenza', (tester) async {
    await apri(tester);

    expect(find.text('Scaduto il 31/01/2020'), findsOneWidget);
    expect(find.text('Lotto LA01'), findsOneWidget);
    expect(find.text('Scad. 30/06/2030'), findsOneWidget);
    expect(find.text('Lotto LB02'), findsOneWidget);
    expect(find.text('Senza scadenza'), findsOneWidget);
    expect(find.text('Totale 4 pezzi'), findsOneWidget);

    // ordine: scaduto, poi 2030, poi senza scadenza (1 pezzo: 4 - 1 - 2)
    final yScaduto = tester.getTopLeft(find.text('Lotto LA01')).dy;
    final yLontano = tester.getTopLeft(find.text('Lotto LB02')).dy;
    final ySenza = tester.getTopLeft(find.text('Senza scadenza')).dy;
    expect(yScaduto < yLontano && yLontano < ySenza, isTrue);
  });

  testWidgets('il − toglie dal lotto scelto e aggiorna il totale', (
    tester,
  ) async {
    await apri(tester);

    await tester.tap(meno(1)); // LB02
    await tester.pump();

    expect(chiamate, [('LB02', -1)]);
    expect(find.text('Totale 3 pezzi'), findsOneWidget);
  });

  testWidgets('un lotto a 0 resta in elenco: si rimette con +, il − è '
      'disattivato', (tester) async {
    await apri(tester);

    await tester.tap(meno(0)); // LA01: 1 -> 0
    await tester.pump();
    expect(find.text('Lotto LA01'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.ancestor(
              of: find.byIcon(Icons.remove).at(0),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(piu(0));
    await tester.pump();
    expect(chiamate, [('LA01', -1), ('LA01', 1)]);
    expect(find.text('Totale 4 pezzi'), findsOneWidget);
  });

  testWidgets('pezzi senza scadenza: − fino a 0, poi disattivato', (
    tester,
  ) async {
    await apri(tester);

    await tester.tap(meno(2));
    await tester.pump();
    expect(chiamate, [('senza', -1)]);
    expect(find.text('Totale 3 pezzi'), findsOneWidget);

    await tester.tap(meno(2));
    await tester.pump();
    expect(chiamate, hasLength(1));
  });
}
