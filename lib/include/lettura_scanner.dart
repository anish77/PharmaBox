import 'package:flutter/foundation.dart';
import 'package:pharma_box/include/general_functions.dart';
import 'package:pharma_box/include/gs1_datamatrix.dart';
import 'package:pharma_box/models/lotto_confezione.dart';

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
  if (kDebugMode) _stampaDecodifica(raw, confezione);
  final codice = confezione?.codiceRicerca;
  if (codice != null) return LetturaScanner(codice, confezione: confezione);
  return LetturaScanner(tradCode(raw));
}

/// Nel debug: testo letto (GS visibile) e campi decodificati.
void _stampaDecodifica(String raw, ConfezioneGs1? c) {
  debugPrint('[Scanner] letto: "${raw.replaceAll(kGs, '<GS>')}"');
  if (c == null) {
    debugPrint('[Scanner] non è un DataMatrix GS1: bollino/EAN');
    return;
  }
  final s = c.scadenza;
  debugPrint(
    '[Scanner] GTIN ${c.gtin} · AIC ${c.aic} · '
    'scadenza (17) ${c.scadenzaLetta} -> '
    '${s == null ? 'non valida' : formattaScadenza(s)}'
    '${c.scadenzaLetta?.endsWith('00') == true ? ' (giorno 00 = fine mese)' : ''}'
    ' · lotto ${c.lotto} · seriale ${c.seriale}'
    '${c.ambigua ? ' · AMBIGUA' : ''}',
  );
}
