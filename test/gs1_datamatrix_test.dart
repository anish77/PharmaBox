import 'package:flutter_test/flutter_test.dart';
import 'package:pharma_box/include/gs1_datamatrix.dart';
import 'package:pharma_box/include/lettura_scanner.dart';
import 'package:pharma_box/widgets/ble_simulator.dart';

const gs = kGs;
final oggi = DateTime(2026, 10, 13);

// GTIN con cifra di controllo corretta
final gtin = '0803208900001${cifraControlloGs1('0803208900001')}';
const aic = '012745182'; // Tachipirina 1000 mg 16 compresse

void main() {
  group('cifre di controllo', () {
    test('GTIN', () {
      expect(gtinValido14(gtin), isTrue);
      expect(
        gtinValido14(
          '${gtin.substring(0, 13)}${(int.parse(gtin[13]) + 1) % 10}',
        ),
        isFalse,
      );
      expect(gtinValido14('123'), isFalse);
    });

    test('AIC: tutti i MINSAN reali del simulatore sono validi', () {
      for (final minsan in BleSimulator.minsanEsempio.keys) {
        expect(aicValida(minsan), isTrue, reason: minsan);
      }
    });

    test('AIC con cifra di controllo sbagliata', () {
      expect(aicValida('012745183'), isFalse);
      expect(aicValida('01274518'), isFalse);
    });
  });

  group('scadenza', () {
    test('AAMMGG', () {
      expect(scadenzaGs1('280327', oggi: oggi), DateTime(2028, 3, 27));
    });

    test('giorno 00 = ultimo giorno del mese', () {
      expect(scadenzaGs1('280200', oggi: oggi), DateTime(2028, 2, 29));
      expect(scadenzaGs1('270400', oggi: oggi), DateTime(2027, 4, 30));
      expect(scadenzaGs1('271200', oggi: oggi), DateTime(2027, 12, 31));
    });

    test('date impossibili', () {
      expect(scadenzaGs1('271300', oggi: oggi), isNull);
      expect(scadenzaGs1('270231', oggi: oggi), isNull);
      expect(scadenzaGs1('27023', oggi: oggi), isNull);
    });

    test('secolo secondo la regola GS1', () {
      expect(scadenzaGs1('760101', oggi: oggi)!.year, 2076);
      expect(scadenzaGs1('770101', oggi: oggi)!.year, 1977);
      expect(scadenzaGs1('990101', oggi: DateTime(2098))!.year, 2099);
      expect(scadenzaGs1('010101', oggi: DateTime(2098))!.year, 2101);
    });
  });

  group('parseGs1', () {
    void verificaCompleta(ConfezioneGs1? c) {
      expect(c, isNotNull);
      expect(c!.gtin, gtin);
      expect(c.aic, aic);
      expect(c.scadenza, DateTime(2028, 3, 27));
      expect(c.lotto, '123ABC');
      expect(c.seriale, '12gn328');
      expect(c.ambigua, isFalse);
      expect(c.codiceRicerca, aic);
    }

    test('con prefisso AIM e separatori GS', () {
      verificaCompleta(
        parseGs1(
          ']d201${gtin}17280327'
          '10123ABC${gs}2112gn328${gs}716$aic',
          oggi: oggi,
        ),
      );
    });

    test('ordine dei campi diverso, FNC1 iniziale', () {
      verificaCompleta(
        parseGs1(
          '${gs}716$aic${gs}2112gn328${gs}17280327'
          '01$gtin'
          '10123ABC',
          oggi: oggi,
        ),
      );
    });

    test('intestazione dello scanner prima del prefisso AIM', () {
      verificaCompleta(
        parseGs1(
          'HDR0000000]d201${gtin}17280327'
          '10123ABC${gs}2112gn328${gs}716$aic\r\n',
          oggi: oggi,
        ),
      );
    });

    test('formato leggibile con parentesi', () {
      verificaCompleta(
        parseGs1(
          '(01)$gtin(17)280327(10)123ABC(21)12gn328(716)$aic',
          oggi: oggi,
        ),
      );
    });

    test('separatore trasmesso come testo <GS>', () {
      verificaCompleta(
        parseGs1(
          '01${gtin}17280327'
          '10123ABC<GS>2112gn328<GS>716$aic',
          oggi: oggi,
        ),
      );
    });

    test(
      'senza GS: AIC in coda riconosciuto grazie alla cifra di controllo',
      () {
        // lotto e seriale senza separatore: "123ABC2112gn328" si può dividere
        // in un solo modo che lasci anche l'AIC valido in coda
        final c = parseGs1(
          '01${gtin}17280327'
          '10123ABC'
          '2112gn328'
          '716$aic',
          oggi: oggi,
        );
        expect(c, isNotNull);
        expect(c!.gtin, gtin);
        expect(c.aic, aic);
        expect(c.scadenza, DateTime(2028, 3, 27));
      },
    );

    test('senza GS e con divisione ambigua: lotto/seriale non affidabili', () {
      // "A21B" + "21C" oppure "A" + "B21C"? Entrambe complete
      final c = parseGs1(
        '01${gtin}17280327'
        '10A21B21C',
        oggi: oggi,
      );
      expect(c, isNotNull);
      expect(c!.gtin, gtin);
      expect(c.scadenza, DateTime(2028, 3, 27));
      expect(c.ambigua, isTrue);
      expect(c.lotto, isNull);
      expect(c.seriale, isNull);
    });

    test('solo GTIN: si cerca per EAN-13', () {
      final c = parseGs1(
        '01${gtin}17280300'
        '10L1',
        oggi: oggi,
      );
      expect(c!.aic, isNull);
      expect(c.codiceRicerca, gtin.substring(1));
      expect(c.scadenza, DateTime(2028, 3, 31));
    });

    test('GTIN e AIC entrambi non validi', () {
      expect(parseGs1('01${'1' * 14}17280327', oggi: oggi), isNull);
    });

    test('non sono GS1: bollino, MINSAN, EAN-13', () {
      expect(parseGs1('0FB4XN'), isNull);
      expect(parseGs1(aic), isNull);
      expect(parseGs1('8001234567890'), isNull);
    });
  });

  group('interpretaLettura', () {
    test('DataMatrix: cerca per AIC e porta i dati della confezione', () {
      final l = interpretaLettura(
        ']d201${gtin}17280327'
        '10123ABC${gs}2112gn328${gs}716$aic',
      );
      expect(l.codice, aic);
      expect(l.confezione!.seriale, '12gn328');
    });

    test('bollino Code 32: conversione di sempre', () {
      final code32 = BleSimulator.minsanEsempio.keys.first;
      final l = interpretaLettura(interpretaLettura(code32).codice);
      expect(l.codice, code32);
      expect(l.confezione, isNull);
    });
  });
}
