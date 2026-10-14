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

  // Stessi codici di integration_test/datamatrix_scadenze_test.dart
  group('DataMatrix AIC 040295141 (screenshot scadenze)', () {
    const casi = [
      (
        '(01)08032082951415(17)260915(10)LA01(21)SN7K2M9QX4PA(716)040295141',
        (2026, 9, 15),
        'LA01',
        'SN7K2M9QX4PA',
      ),
      (
        '(01)08032082951415(17)261120(10)LB02(21)SN3HD8W2RT6B(716)040295141',
        (2026, 11, 20),
        'LB02',
        'SN3HD8W2RT6B',
      ),
      (
        '(01)08032082951415(17)270300(10)LC03(21)SN9PL4ZE7VJC(716)040295141',
        (2027, 3, 31),
        'LC03',
        'SN9PL4ZE7VJC',
      ),
      (
        '(01)08032082951415(17)280615(10)LD04(21)SN5TQ2NB8XKD(716)040295141',
        (2028, 6, 15),
        'LD04',
        'SN5TQ2NB8XKD',
      ),
      (
        '(01)08032082951415(17)280615(10)LD04(21)SN2WF6YC3MHE(716)040295141',
        (2028, 6, 15),
        'LD04',
        'SN2WF6YC3MHE',
      ),
      (
        '(01)08032082951415(17)280600(10)LD04(21)SN8RJ5UA4GLF(716)040295141',
        (2028, 6, 30),
        'LD04',
        'SN8RJ5UA4GLF',
      ),
      (
        '(01)08032082951415(17)280615(10)LD07(21)SN4CV7HN2QWG(716)040295141',
        (2028, 6, 15),
        'LD07',
        'SN4CV7HN2QWG',
      ),
    ];

    for (final (testo, (a, m, g), lotto, seriale) in casi) {
      test('$seriale: scadenza $g/$m/$a, lotto $lotto dalla catena BLE', () {
        final lettura = BleSimulator.letturaDataMatrix(testo)!;
        expect(lettura.codice, '040295141');
        final c = lettura.confezione!;
        expect(c.gtin, '08032082951415');
        expect(c.scadenza, DateTime(a, m, g));
        expect(c.lotto, lotto);
        expect(c.seriale, seriale);
        expect(c.ambigua, isFalse);
      });
    }
  });
}
