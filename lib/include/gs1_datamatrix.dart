/// Lettura del GS1 DataMatrix dei farmaci (D.Lgs. 10/2025, DM Salute
/// 6 marzo 2025, Reg. UE 2016/161).
///
/// Campi sulla confezione italiana:
///   (01)  GTIN, 14 cifre             (17)  scadenza AAMMGG
///   (10)  lotto, fino a 20 car.      (21)  seriale, fino a 20 car.
///   (716) AIC (= MINSAN), 9 cifre
///
/// I campi a lunghezza variabile finiscono con il carattere GS (0x1D) se non
/// sono gli ultimi. L'ordine dei campi non è garantito.
library;

/// Separatore FNC1 trasmesso dagli scanner (ASCII 29)
const kGs = '\x1D';

/// Confezione letta da un GS1 DataMatrix.
class ConfezioneGs1 {
  const ConfezioneGs1({
    this.gtin,
    this.aic,
    this.scadenza,
    this.lotto,
    this.seriale,
    this.ambigua = false,
  });

  final String? gtin;

  /// Codice AIC a 9 cifre: è il MINSAN usato nel resto dell'app
  final String? aic;

  /// Ultimo giorno di validità (giorno 00 = ultimo giorno del mese)
  final DateTime? scadenza;
  final String? lotto;
  final String? seriale;

  /// Mancava il separatore GS e lotto/seriale potevano essere divisi in più
  /// modi: i campi su cui le interpretazioni non concordano sono null.
  final bool ambigua;

  /// Codice da cercare su Farmadati: l'AIC, altrimenti l'EAN-13 ricavato
  /// dal GTIN (Farmadati cerca per EAN sopra le 9 cifre).
  String? get codiceRicerca => aic ?? ean;

  /// EAN-13 ricavato dal GTIN-14 (che inizia per 0 sui prodotti al dettaglio)
  String? get ean {
    final g = gtin;
    if (g == null) return null;
    return g.startsWith('0') ? g.substring(1) : g;
  }

  @override
  String toString() =>
      'ConfezioneGs1(gtin: $gtin, aic: $aic, scadenza: $scadenza, '
      'lotto: $lotto, seriale: $seriale${ambigua ? ', ambigua' : ''})';
}

/// Lunghezza dei campi: fissa ([fissa] true) o massima.
typedef _Ai = ({int lunghezza, bool fissa});

/// AI che possono comparire sulle confezioni di medicinali. Un AI sconosciuto
/// interrompe la lettura: senza sapere quanto è lungo non si può proseguire.
const Map<String, _Ai> _ai = {
  '00': (lunghezza: 18, fissa: true),
  '01': (lunghezza: 14, fissa: true),
  '02': (lunghezza: 14, fissa: true),
  '10': (lunghezza: 20, fissa: false),
  '11': (lunghezza: 6, fissa: true),
  '13': (lunghezza: 6, fissa: true),
  '15': (lunghezza: 6, fissa: true),
  '16': (lunghezza: 6, fissa: true),
  '17': (lunghezza: 6, fissa: true),
  '21': (lunghezza: 20, fissa: false),
  '22': (lunghezza: 20, fissa: false),
  '30': (lunghezza: 8, fissa: false),
  '240': (lunghezza: 30, fissa: false),
  '241': (lunghezza: 30, fissa: false),
  '710': (lunghezza: 20, fissa: false),
  '711': (lunghezza: 20, fissa: false),
  '712': (lunghezza: 20, fissa: false),
  '713': (lunghezza: 20, fissa: false),
  '714': (lunghezza: 20, fissa: false),
  '715': (lunghezza: 20, fissa: false),
  '716': (lunghezza: 20, fissa: false),
  '7003': (lunghezza: 10, fissa: true),
};

final _prefissoAim = RegExp(r'\][dCQ][0-9]');
final _formatoParentesi = RegExp(r'\((\d{2,4})\)([^(]*)');

/// Campi (AI, valore) del formato leggibile "(01)...(17)...", in ordine.
List<(String, String)> campiTraParentesi(String s) => [
  for (final m in _formatoParentesi.allMatches(s))
    if (m.group(2)!.replaceAll(kGs, '').trim() case final valore
        when valore.isNotEmpty)
      (m.group(1)!, valore),
];

/// Testo che uno scanner trasmette per i [campi]: prefisso AIM "]d2", poi
/// AI e valore uno dopo l'altro, con GS dopo i campi a lunghezza variabile
/// che non sono gli ultimi. Con [conGs] false i GS mancano, come da uno
/// scanner non configurato per trasmettere l'FNC1.
String componiGs1(List<(String, String)> campi, {bool conGs = true}) {
  final sb = StringBuffer(']d2');
  for (var i = 0; i < campi.length; i++) {
    final (ai, valore) = campi[i];
    sb.write('$ai$valore');
    final variabile = !(_ai[ai]?.fissa ?? false);
    if (conGs && variabile && i < campi.length - 1) sb.write(kGs);
  }
  return sb.toString();
}

/// true se [raw] ha l'aspetto di un GS1 (prefisso AIM, FNC1, parentesi o
/// GTIN in testa). Un MINSAN, un EAN-13 o un codice del bollino non lo sono.
bool sembraGs1(String raw) {
  final s = raw.trim();
  return s.contains(']d2') ||
      s.contains(kGs) ||
      s.startsWith('(01)') ||
      s.startsWith('(716)') ||
      RegExp(r'^01\d{14}').hasMatch(s) && s.length > 16;
}

/// Interpreta una lettura GS1. Restituisce null se [raw] non è un GS1 o non
/// contiene né GTIN né AIC validi. [oggi] serve solo ai test (secolo della
/// scadenza).
ConfezioneGs1? parseGs1(String raw, {DateTime? oggi}) {
  if (!sembraGs1(raw)) return null;
  final campi = _campi(raw.trim());
  if (campi == null) return null;
  final ambigua = campi.ambigua;
  final c = campi.valori;

  final gtin = c['01'];
  final aic = c['716'];
  final gtinValido = gtin != null && gtinValido14(gtin);
  final aicValido = aic != null && aicValida(aic);
  if (!gtinValido && !aicValido) return null;

  return ConfezioneGs1(
    gtin: gtinValido ? gtin : null,
    aic: aicValido ? aic : null,
    scadenza: c['17'] == null ? null : scadenzaGs1(c['17']!, oggi: oggi),
    lotto: c['10'],
    seriale: c['21'],
    ambigua: ambigua,
  );
}

typedef _Campi = ({Map<String, String?> valori, bool ambigua});

_Campi? _campi(String s) {
  // Formato leggibile "(01)...(17)..." (scanner in modalità testo)
  if (s.startsWith('(')) {
    final valori = <String, String?>{
      for (final (ai, valore) in campiTraParentesi(s)) ai: valore,
    };
    return valori.isEmpty ? null : (valori: valori, ambigua: false);
  }

  // Tutto ciò che precede il prefisso AIM (intestazioni dello scanner) va
  // scartato, poi il prefisso stesso e un eventuale FNC1 iniziale
  var dati = s.replaceAll('<GS>', kGs);
  final aim = _prefissoAim.firstMatch(dati);
  if (aim != null) dati = dati.substring(aim.end);
  while (dati.startsWith(kGs)) {
    dati = dati.substring(1);
  }
  while (dati.endsWith(kGs)) {
    dati = dati.substring(0, dati.length - 1);
  }

  final letture = _analizza(dati, 0, const {});
  if (letture.isEmpty) return null;

  // Una confezione vera ha tutti i campi: tra le interpretazioni possibili
  // vince quella con più campi; se ne restano più d'una si tengono solo i
  // valori su cui concordano
  final massimo = letture.map((l) => l.length).reduce((a, b) => a > b ? a : b);
  final migliori = letture.where((l) => l.length == massimo).toList();
  if (migliori.length == 1) return (valori: migliori.first, ambigua: false);

  final valori = <String, String?>{};
  for (final ai in migliori.first.keys) {
    final v = migliori.first[ai];
    valori[ai] = migliori.every((l) => l[ai] == v) ? v : null;
  }
  return (valori: valori, ambigua: true);
}

/// Oltre questo numero di interpretazioni si smette di cercarne altre.
const _maxLetture = 32;

/// AI delle confezioni di medicinali (Reg. UE 2016/161 e NHRN nazionali).
/// Senza GS solo questi possono iniziare dentro un campo variabile: un
/// seriale casuale contiene facilmente "22" o "30", che altrimenti
/// moltiplicherebbero le interpretazioni.
const _aiFarmaco = {
  '01',
  '17',
  '10',
  '21',
  '710',
  '711',
  '712',
  '713',
  '714',
  '715',
  '716',
};

/// Tutte le interpretazioni complete di [s] a partire da [i]. Con
/// [soloFarmaco] sono ammessi solo gli AI di [_aiFarmaco].
List<Map<String, String>> _analizza(
  String s,
  int i,
  Map<String, String> finora, {
  bool soloFarmaco = false,
}) {
  if (i == s.length) return [finora];

  for (final len in const [2, 3, 4]) {
    if (i + len > s.length) break;
    final codiceAi = s.substring(i, i + len);
    final ai = _ai[codiceAi];
    if (ai == null) continue;
    if (soloFarmaco && !_aiFarmaco.contains(codiceAi)) continue;
    if (finora.containsKey(codiceAi)) return const [];
    final inizio = i + len;

    if (ai.fissa) {
      final fine = inizio + ai.lunghezza;
      if (fine > s.length) return const [];
      final valore = s.substring(inizio, fine);
      if (!_valoreValido(codiceAi, valore)) return const [];
      // Dopo un campo fisso il GS è ammesso ma non necessario
      final dopo = fine < s.length && s[fine] == kGs ? fine + 1 : fine;
      return _analizza(s, dopo, {
        ...finora,
        codiceAi: valore,
      }, soloFarmaco: soloFarmaco);
    }

    // Campo variabile terminato da GS: una sola interpretazione
    final gs = s.indexOf(kGs, inizio);
    if (gs != -1) {
      final valore = s.substring(inizio, gs);
      if (valore.isEmpty || valore.length > ai.lunghezza) return const [];
      if (!_valoreValido(codiceAi, valore)) return const [];
      return _analizza(s, gs + 1, {
        ...finora,
        codiceAi: valore,
      }, soloFarmaco: soloFarmaco);
    }

    // Senza GS il campo può finire a fine stringa o dove inizia un altro AI
    final risultati = <Map<String, String>>[];
    final ultimo =
        inizio + ai.lunghezza < s.length ? inizio + ai.lunghezza : s.length;
    for (var fine = ultimo; fine > inizio; fine--) {
      final valore = s.substring(inizio, fine);
      if (!_valoreValido(codiceAi, valore)) continue;
      risultati.addAll(
        _analizza(s, fine, {...finora, codiceAi: valore}, soloFarmaco: true),
      );
      if (risultati.length >= _maxLetture) break;
    }
    return risultati;
  }
  return const [];
}

final _caratteriGs1 = RegExp(r"""^[!"%&'()*+,\-./0-9:;<=>?A-Z_a-z]+$""");

bool _valoreValido(String ai, String valore) {
  switch (ai) {
    case '01':
    case '02':
      return gtinValido14(valore);
    case '716':
      return aicValida(valore);
    case '30':
      return RegExp(r'^\d+$').hasMatch(valore);
    case '11':
    case '13':
    case '15':
    case '16':
    case '17':
      return scadenzaGs1(valore) != null;
    default:
      return _caratteriGs1.hasMatch(valore);
  }
}

/// Cifra di controllo GS1 (mod 10, pesi 3-1 da destra) su 14 cifre.
bool gtinValido14(String gtin) {
  if (!RegExp(r'^\d{14}$').hasMatch(gtin)) return false;
  return cifraControlloGs1(gtin.substring(0, 13)) == int.parse(gtin[13]);
}

int cifraControlloGs1(String cifre) {
  var somma = 0;
  for (var k = 0; k < cifre.length; k++) {
    final d = int.parse(cifre[cifre.length - 1 - k]);
    somma += k.isEven ? d * 3 : d;
  }
  return (10 - somma % 10) % 10;
}

/// AIC/MINSAN: 9 cifre, l'ultima di controllo (stesso algoritmo del Code 32:
/// pesi 1-2 alternati, somma delle cifre dei prodotti, mod 10).
bool aicValida(String aic) {
  if (!RegExp(r'^\d{9}$').hasMatch(aic)) return false;
  var somma = 0;
  for (var k = 0; k < 8; k++) {
    final p = int.parse(aic[k]) * (k.isEven ? 1 : 2);
    somma += p ~/ 10 + p % 10;
  }
  return somma % 10 == int.parse(aic[8]);
}

/// Data GS1 AAMMGG. Giorno 00 = ultimo giorno del mese. Secolo secondo la
/// regola GS1: anni da -49 a +50 rispetto all'anno corrente.
DateTime? scadenzaGs1(String aammgg, {DateTime? oggi}) {
  if (!RegExp(r'^\d{6}$').hasMatch(aammgg)) return null;
  final aa = int.parse(aammgg.substring(0, 2));
  final mm = int.parse(aammgg.substring(2, 4));
  final gg = int.parse(aammgg.substring(4, 6));
  if (mm < 1 || mm > 12) return null;

  final annoCorrente = (oggi ?? DateTime.now()).year;
  final secolo = annoCorrente - annoCorrente % 100;
  var anno = secolo + aa;
  final differenza = aa - annoCorrente % 100;
  if (differenza >= 51) anno -= 100;
  if (differenza <= -50) anno += 100;

  final ultimoGiorno = DateTime(anno, mm + 1, 0).day;
  if (gg == 0) return DateTime(anno, mm, ultimoGiorno);
  if (gg > ultimoGiorno) return null;
  return DateTime(anno, mm, gg);
}
