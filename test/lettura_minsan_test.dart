// Test di lettura: 20 MINSAN reali (fonti: schede prodotto di farmacie online
// e foglietti illustrativi) passano per la stessa catena delle letture BLE:
// byte dallo scanner -> bleDecode -> tradCode -> MINSAN da cercare.
//
// Il gruppo "Farmadati" interroga il servizio reale ed è disattivato di
// default: flutter test --dart-define=ONLINE=true test/lettura_minsan_test.dart

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pharma_box/include/ble_functions.dart';
import 'package:pharma_box/include/general_functions.dart';

const _minsan = {
  '012745182': 'Tachipirina 1000 mg 16 compresse',
  '012745170': 'Tachipirina 1000 mg 8 compresse',
  '012745220': 'Tachipirina 1000 mg granulato 16 bustine',
  '012745028': 'Tachipirina 500 mg 10 compresse',
  '022593204': 'Brufen 400 mg 30 compresse',
  '052892015': 'Brufen Analgesico 400 mg 12 compresse',
  '041962034': 'Aspirina Dolore e Infiammazione 500 mg 20 compresse',
  '004763330': 'Aspirina C 20 compresse effervescenti',
  '004763544': 'Aspirina 500 mg granulato 20 bustine',
  '025669019': 'Moment 200 mg 12 compresse',
  '025669072': 'Moment 200 mg 24 compresse',
  '025669185': 'Moment 200 mg 36 compresse',
  '026089019': 'Augmentin 875/125 mg 12 compresse',
  '013046038': 'Enterogermina 2 miliardi 10 flaconcini',
  '013046040': 'Enterogermina 2 miliardi 20 flaconcini',
  '034548065': 'Voltaren Emulgel 2% 60 g',
  '048414104': 'OKi Dolore e Febbre 25 mg 12 compresse effervescenti',
  '020582209': 'Fluimucil 600 mg 30 compresse effervescenti',
  '034936171': 'Fluimucil 600 mg 10 compresse effervescenti',
  '034248068': 'Gaviscon Advance sospensione orale 500 ml',
};

const _online = bool.fromEnvironment('ONLINE');

void main() {
  group('Conversione MINSAN <-> codice scanner (Code 32)', () {
    for (final MapEntry(key: minsan, value: nome) in _minsan.entries) {
      test('$minsan $nome', () {
        final code32 = tradCode(minsan);
        expect(code32, matches(RegExp(r'^[0-9BCDFGHJKLMNPQRSTUVWXYZ]{6}$')));
        expect(tradCode(code32), minsan);
      });
    }
  });

  group('Lettura BLE simulata', () {
    for (final minsan in _minsan.keys) {
      final code32 = tradCode(minsan);

      test('$minsan testo semplice con CR/LF (servizio FFF0)', () {
        final bytes = utf8.encode('$code32\r\n');
        expect(tradCode(bleDecode(bytes)), minsan);
      });

      test('$minsan pacchetto da 17 byte (servizio FEEA)', () {
        // 10 byte di intestazione, 6 di codice, 1 terminatore
        final bytes = utf8.encode('HDR0000000$code32\r');
        expect(bytes, hasLength(17));
        expect(tradCode(bleDecode(bytes)), minsan);
      });
    }
  });

  group('Ricerca su Farmadati', () {
    for (final MapEntry(key: minsan, value: nome) in _minsan.entries) {
      test('$minsan $nome', () async {
        final risultati = await doSearch(minsan);
        expect(risultati, isNotEmpty, reason: 'nessun prodotto per $minsan');
        // ignore: avoid_print
        print('$minsan -> ${risultati.first.nome}');
      }, timeout: const Timeout(Duration(seconds: 30)));
    }
  }, skip: _online ? false : 'servizio reale: usa --dart-define=ONLINE=true');
}
