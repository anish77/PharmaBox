import 'package:flutter_test/flutter_test.dart';
import 'package:pharma_box/include/general_functions.dart';
import 'package:pharma_box/widgets/ble_simulator.dart';

void main() {
  const codici = BleSimulator.minsanEsempio;

  test('30 MINSAN di esempio, tutti diversi', () {
    expect(codici, hasLength(30));
    expect(codici.keys.toSet(), hasLength(30));
  });

  for (final minsan in codici.keys) {
    test('$minsan: 9 cifre e conversione codice scanner reversibile', () {
      expect(minsan, matches(RegExp(r'^\d{9}$')));
      final code32 = tradCode(minsan);
      expect(code32, matches(RegExp(r'^[0-9BCDFGHJKLMNPQRSTUVWXYZ]{6}$')));
      expect(tradCode(code32), minsan);
    });
  }
}
