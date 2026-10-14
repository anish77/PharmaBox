import 'package:flutter_test/flutter_test.dart';
import 'package:pharma_box/include/general_functions.dart';
import 'package:pharma_box/include/gs1_datamatrix.dart';
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

  group('DataMatrix simulati', () {
    final oggi = DateTime(2026, 10, 13);
    final esempi = BleSimulator.dataMatrixEsempio(oggi: oggi);

    test('esempi: AIC dei MINSAN, scadenze diverse, seriali tutti diversi', () {
      final confezioni = [for (final e in esempi) parseGs1(e, oggi: oggi)!];
      expect(confezioni.map((c) => c.aic), codici.keys.take(esempi.length));
      expect(confezioni.first.scadenza, DateTime(2026, 9, 30));
      expect(
        confezioni.map((c) => c.seriale).toSet(),
        hasLength(esempi.length),
      );
    });

    for (final esempio in esempi) {
      test('$esempio: catena BLE completa, con GS', () {
        final atteso = parseGs1(esempio)!;
        final lettura = BleSimulator.letturaDataMatrix(esempio)!;
        expect(lettura.codice, atteso.aic);
        expect(lettura.confezione!.gtin, atteso.gtin);
        expect(lettura.confezione!.scadenza, atteso.scadenza);
        expect(lettura.confezione!.lotto, atteso.lotto);
        expect(lettura.confezione!.seriale, atteso.seriale);
        expect(lettura.confezione!.ambigua, isFalse);
      });
    }

    test('senza GS: AIC e scadenza si leggono comunque', () {
      for (final esempio in esempi) {
        final atteso = parseGs1(esempio)!;
        final lettura = BleSimulator.letturaDataMatrix(esempio, conGs: false)!;
        expect(lettura.codice, atteso.aic, reason: esempio);
        expect(lettura.confezione!.scadenza, atteso.scadenza, reason: esempio);
      }
    });

    test('senza GS con lotto e seriale divisibili in più modi', () {
      // "A21B" + "21C" oppure "A" + "B21C"
      const testo = '(01)08032089000017(17)280300(10)A21B(21)C(716)012745182';
      final lettura = BleSimulator.letturaDataMatrix(testo, conGs: false);
      expect(lettura, isNotNull);
      expect(lettura!.codice, '012745182');
    });

    test('il formato con le parentesi diventa il testo trasmesso', () {
      expect(
        componiGs1(
          campiTraParentesi(
            '(01)08032089000017(17)280300(10)L1(21)S1(716)012745182',
          ),
        ),
        ']d20108032089000017172803001'
        '0L1${kGs}21S1${kGs}716012745182',
      );
      expect(
        componiGs1(campiTraParentesi('(10)L1(17)280300'), conGs: false),
        ']d210L117280300',
      );
    });

    test('non DataMatrix: bollino e MINSAN restano fuori dalla catena', () {
      expect(BleSimulator.letturaDataMatrix('0FB4XN'), isNull);
      expect(BleSimulator.letturaDataMatrix('012745182'), isNull);
    });
  });
}
