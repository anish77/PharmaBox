import 'package:pharma_box/logic/preferenze_dispositivo.dart';

/// Pezzi di un prodotto letti da DataMatrix con lo stesso lotto e scadenza.
class LottoConfezione {
  const LottoConfezione({
    required this.lotto,
    required this.scadenza,
    required this.quantity,
  });

  final String lotto;
  final DateTime? scadenza;
  final int quantity;
}

/// [inScadenza]: arancione, [prossima]: ocra
enum StatoScadenza { scaduto, inScadenza, prossima, ok }

/// Scaduto dal giorno dopo la data di scadenza. Soglie in mesi: se non
/// indicate, quelle scelte nelle Opzioni (di default 3 e 6).
StatoScadenza statoScadenza(
  DateTime scadenza, {
  DateTime? oggi,
  int? mesiInScadenza,
  int? mesiProssima,
}) {
  final m1 = mesiInScadenza ?? PreferenzeDispositivo.mesiInScadenza.value;
  final m2 = mesiProssima ?? PreferenzeDispositivo.mesiProssima.value;
  final adesso = oggi ?? DateTime.now();
  final giorno = DateTime(adesso.year, adesso.month, adesso.day);
  if (scadenza.isBefore(giorno)) return StatoScadenza.scaduto;
  if (scadenza.isBefore(DateTime(giorno.year, giorno.month + m1, giorno.day))) {
    return StatoScadenza.inScadenza;
  }
  if (scadenza.isBefore(DateTime(giorno.year, giorno.month + m2, giorno.day))) {
    return StatoScadenza.prossima;
  }
  return StatoScadenza.ok;
}

/// Scadenza più vicina tra i lotti con pezzi, null se nessuna.
DateTime? scadenzaPiuVicina(Iterable<LottoConfezione> lotti) {
  DateTime? minima;
  for (final l in lotti) {
    final s = l.scadenza;
    if (s == null || l.quantity <= 0) continue;
    if (minima == null || s.isBefore(minima)) minima = s;
  }
  return minima;
}

String _dd(int n) => n.toString().padLeft(2, '0');

/// "31/03/2028"
String formattaScadenza(DateTime d) =>
    '${_dd(d.day)}/${_dd(d.month)}/${d.year}';

/// "2028-03-31": formato salvato su Firestore (niente fusi orari)
String scadenzaIso(DateTime d) => '${d.year}-${_dd(d.month)}-${_dd(d.day)}';

DateTime? scadenzaDaIso(dynamic valore) =>
    valore is String && valore.isNotEmpty ? DateTime.tryParse(valore) : null;
