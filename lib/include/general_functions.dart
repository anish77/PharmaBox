import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pharma_box/data/constants.dart';

/// 32^5 = 33.554.432
final int _nNumero32Start = 33554432;

/// Alfabetico BC Code 32 (niente A, E, I, O)
final String _cChar32 = "0123456789BCDFGHJKLMNPQRSTUVWXYZ";

/// Replica di TradCode:
/// - Se [code] (trim) ha lunghezza <= 6: ALFANUMERICO -> NUMERICO (9 cifre, padded)
/// - Altrimenti: NUMERICO (stringa di cifre) -> ALFANUMERICO (6 chars)
String tradCode(String code) {
  final s = code.trim().toUpperCase();

  if (s.length <= 6) {
    // ALFANUMERICO -> NUMERICO
    int nNumero32 = _nNumero32Start;
    int cNewCodice = 0;

    for (int k = 0; k < 6; k++) {
      final ch = (k < s.length) ? s[k] : ' '; // se mancano char, contribuisce 0
      final pos = _cChar32.indexOf(ch); // 0-based, -1 se non trovato
      final val = (pos >= 0) ? pos : 0; // Max(At(..)-1,0) equivalente
      cNewCodice += nNumero32 * val;
      nNumero32 = nNumero32 ~/ 32;
    }

    return cNewCodice.toString().padLeft(9, '0');
  } else {
    // NUMERICO -> ALFANUMERICO
    // nella versione originale fanno Val(cCodice); qui richiediamo solo cifre
    final numVal = int.tryParse(s) ?? 0;

    int nNumero32 = _nNumero32Start;
    final sb = StringBuffer();

    for (int k = 5; k >= 0; k--) {
      final nPosi3 = numVal ~/ nNumero32;
      final ch = _cChar32[nPosi3]; // SubStr(_cChar32, nPosi3+1, 1)
      sb.write(ch);
      // aggiorna resto
      final resto = numVal - nNumero32 * nPosi3;
      // per i passi successivi serve aggiornare numVal; in Harbour sovrascrivevano cCodice
      // in Dart manteniamo un accumulatore
      // -> per mirror perfetto, convertiamo numVal in variabile mutabile:
    }
    // Nota: dobbiamo mutare il valore numerico man mano:
    return _numericToAlpha(numVal);
  }
}

/// Helper per la seconda branch (NUMERICO -> ALFANUMERICO)
String _numericToAlpha(int value) {
  int nNumero32 = _nNumero32Start;
  final sb = StringBuffer();
  int v = value;

  for (int k = 5; k >= 0; k--) {
    final nPosi3 = v ~/ nNumero32;
    sb.write(_cChar32[nPosi3]);
    v = v - nNumero32 * nPosi3;
    nNumero32 = nNumero32 ~/ 32;
  }
  return sb.toString();
}


/// Invia una richiesta al Worker Cloudflare per scaricare e archiviare
/// l'immagine del prodotto su R2 a partire da un URL sorgente.
/// Ritorna l'URL pubblico (CDN) se disponibile, altrimenti null.
Future<String?> r2IngestImageByUrl({
  required String minsan,
  required String imageUrl,
}) async {
  if (kR2IngestEndpoint.isEmpty) return null;
  try {
    final resp = await http
        .post(
          Uri.parse(kR2IngestEndpoint),
          headers: {
            'content-type': 'application/json',
            if (kR2ApiKey.isNotEmpty) 'x-api-key': kR2ApiKey,
          },
          body: jsonEncode({
            'ean': minsan,
            'imageUrl': imageUrl,
          }),
        )
        .timeout(const Duration(seconds: 12));
    if (resp.statusCode != 200) return null;
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    if (data['ok'] == true && data['origUrl'] is String) {
      return data['origUrl'] as String;
    }
  } catch (errore) { print(errore); }
  return null;
}