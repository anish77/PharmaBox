import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharma_box/logic/preferenze_dispositivo.dart';
import 'package:pharma_box/widgets/counter_button.dart';

void main() {
  late List<String?> vibrazioni;
  late List<int> valori;

  setUp(() {
    PreferenzeDispositivo.feedbackAptico.value = true;
    vibrazioni = [];
    valori = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            vibrazioni.add(call.arguments as String?);
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<void> mostra(WidgetTester tester, int iniziale) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CounterButton(initialValue: iniziale, onChanged: valori.add),
      ),
    ),
  );

  testWidgets('+ e -: vibrazione leggera, più decisa arrivando a 0', (
    tester,
  ) async {
    await mostra(tester, 1);

    await tester.tap(find.text('+'));
    await tester.tap(find.text('-'));
    await tester.tap(find.text('-'));
    expect(valori, [2, 1, 0]);
    expect(vibrazioni, [
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.mediumImpact',
    ]);
  });

  testWidgets('- a 0: nessuna modifica, nessuna vibrazione', (tester) async {
    await mostra(tester, 0);

    await tester.tap(find.text('-'));
    expect(valori, isEmpty);
    expect(vibrazioni, isEmpty);
  });

  testWidgets('feedback aptico disattivato: i pezzi cambiano senza vibrare', (
    tester,
  ) async {
    PreferenzeDispositivo.feedbackAptico.value = false;
    await mostra(tester, 1);

    await tester.tap(find.text('+'));
    await tester.tap(find.text('-'));
    await tester.tap(find.text('-'));
    expect(valori, [2, 1, 0]);
    expect(vibrazioni, isEmpty);
  });
}
