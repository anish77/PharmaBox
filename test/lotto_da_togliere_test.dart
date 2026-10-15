import 'package:flutter_test/flutter_test.dart';
import 'package:pharma_box/models/lotto_confezione.dart';

LottoConfezione lotto(String nome, DateTime? scadenza, int quantity) =>
    LottoConfezione(lotto: nome, scadenza: scadenza, quantity: quantity);

void main() {
  test('sceglie il lotto che scade prima', () {
    final scelto = lottoDaTogliere([
      lotto('LONTANO', DateTime(2030, 6, 30), 3),
      lotto('SCADUTO', DateTime(2020, 1, 31), 1),
      lotto('VICINO', DateTime(2026, 12, 31), 2),
    ]);
    expect(scelto?.lotto, 'SCADUTO');
  });

  test('ignora i lotti a 0 pezzi', () {
    final scelto = lottoDaTogliere([
      lotto('SCADUTO', DateTime(2020, 1, 31), 0),
      lotto('VICINO', DateTime(2026, 12, 31), 2),
    ]);
    expect(scelto?.lotto, 'VICINO');
  });

  test('i lotti senza data per ultimi', () {
    expect(
      lottoDaTogliere([
        lotto('SENZA', null, 5),
        lotto('LONTANO', DateTime(2030, 6, 30), 1),
      ])?.lotto,
      'LONTANO',
    );
    expect(lottoDaTogliere([lotto('SENZA', null, 5)])?.lotto, 'SENZA');
  });

  test('nessun lotto con pezzi: null', () {
    expect(lottoDaTogliere([]), isNull);
    expect(lottoDaTogliere([lotto('A', DateTime(2028), 0)]), isNull);
  });
}
