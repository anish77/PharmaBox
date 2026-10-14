import 'package:pharma_box/include/general_functions.dart';
import 'package:pharma_box/include/gs1_datamatrix.dart';

/// Una lettura dello scanner: il codice da cercare e, per i DataMatrix, i
/// dati della singola confezione (scadenza, lotto, seriale).
class LetturaScanner {
  const LetturaScanner(this.codice, {this.confezione});

  /// MINSAN/AIC o EAN da cercare su Farmadati
  final String codice;
  final ConfezioneGs1? confezione;

  @override
  String toString() => 'LetturaScanner($codice, $confezione)';
}

/// Lettura BLE già decodificata in testo -> codice da cercare.
/// DataMatrix: AIC (o EAN dal GTIN). Altrimenti la conversione del bollino
/// (Code 32) di sempre.
LetturaScanner interpretaLettura(String raw) {
  final confezione = parseGs1(raw);
  final codice = confezione?.codiceRicerca;
  if (codice != null) return LetturaScanner(codice, confezione: confezione);
  return LetturaScanner(tradCode(raw));
}
