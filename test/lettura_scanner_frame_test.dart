// Una lettura dello scanner BLE cambia solo scannedBarcodeProvider, ascoltato
// con ref.listen: nulla viene ridisegnato. Se la gestione della lettura
// aspetta il prossimo frame, quel frame va richiesto, altrimenti a schermo
// fermo la lista non si aggiorna finché l'utente non tocca lo schermo.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharma_box/include/ble_functions.dart';

void main() {
  testWidgets('a schermo fermo la lettura viene gestita al frame successivo', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);

    var gestita = false;
    dopoIlProssimoFrame(() => gestita = true);

    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump();
    expect(gestita, isTrue);
  });
}
