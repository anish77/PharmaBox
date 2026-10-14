// Un DataMatrix (45-70 caratteri) arriva dallo scanner BLE spezzato in più
// notifiche: AssemblatoreBle le ricompone prima di decodificare.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pharma_box/include/ble_functions.dart';
import 'package:pharma_box/include/gs1_datamatrix.dart';
import 'package:pharma_box/include/lettura_scanner.dart';
import 'package:pharma_box/models/lotto_confezione.dart';

const aic = '012745182';
final gtin = '0803208900001${cifraControlloGs1('0803208900001')}';
final dataMatrix =
    ']d201${gtin}17280300'
    '10L1234$kGs'
    '21SN9X7Q2K$kGs'
    '716$aic';

List<List<int>> aPezzi(List<int> bytes, int dimensione) => [
  for (var i = 0; i < bytes.length; i += dimensione)
    bytes.sublist(
      i,
      i + dimensione > bytes.length ? bytes.length : i + dimensione,
    ),
];

void main() {
  test('pezzi da 20 byte con CR finale: una sola lettura completa', () {
    final letture = <List<int>>[];
    final a = AssemblatoreBle(letture.add);
    for (final p in aPezzi(utf8.encode('$dataMatrix\r'), 20)) {
      a.aggiungi(p);
    }

    expect(letture, hasLength(1));
    final l = interpretaLettura(bleDecode(letture.single));
    expect(l.codice, aic);
    expect(l.confezione!.lotto, 'L1234');
    expect(l.confezione!.seriale, 'SN9X7Q2K');
    expect(l.confezione!.scadenza, DateTime(2028, 3, 31));
  });

  test('senza terminatore la lettura parte dopo la pausa', () async {
    final letture = <List<int>>[];
    final a = AssemblatoreBle(letture.add);
    for (final p in aPezzi(utf8.encode(dataMatrix), 20)) {
      a.aggiungi(p);
    }
    expect(letture, isEmpty);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(letture, hasLength(1));
    expect(interpretaLettura(bleDecode(letture.single)).codice, aic);
  });

  test('il pacchetto da 17 byte del bollino passa subito, come prima', () {
    final letture = <List<int>>[];
    final a = AssemblatoreBle(letture.add);
    final code32 = interpretaLettura(aic).codice;
    a.aggiungi(utf8.encode('HDR0000000$code32\r'));
    a.aggiungi(utf8.encode('HDR0000000$code32\r'));

    expect(letture, hasLength(2));
    expect(interpretaLettura(bleDecode(letture.first)).codice, aic);
  });

  test('chiudi scarta una lettura a metà', () async {
    final letture = <List<int>>[];
    final a = AssemblatoreBle(letture.add);
    a.aggiungi(utf8.encode(dataMatrix.substring(0, 20)));
    a.chiudi();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(letture, isEmpty);
  });

  group('statoScadenza', () {
    final oggi = DateTime(2026, 10, 13);
    test('scaduto dal giorno dopo', () {
      expect(
        statoScadenza(DateTime(2026, 10, 13), oggi: oggi),
        StatoScadenza.entro3Mesi,
      );
      expect(
        statoScadenza(DateTime(2026, 10, 12), oggi: oggi),
        StatoScadenza.scaduto,
      );
    });
    test('soglie 3 e 6 mesi', () {
      expect(
        statoScadenza(DateTime(2027, 1, 12), oggi: oggi),
        StatoScadenza.entro3Mesi,
      );
      expect(
        statoScadenza(DateTime(2027, 1, 13), oggi: oggi),
        StatoScadenza.entro6Mesi,
      );
      expect(
        statoScadenza(DateTime(2027, 4, 13), oggi: oggi),
        StatoScadenza.ok,
      );
    });
  });
}
