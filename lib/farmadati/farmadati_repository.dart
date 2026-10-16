import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/farmadati/soap_farmadati_repository.dart';
import 'package:pharma_box/farmadati/worker_farmadati_repository.dart';
import 'package:pharma_box/models/prodotto.dart';

/// Unico punto di accesso ai dati Farmadati per il resto dell'app.
///
/// Oggi: [SoapFarmadatiRepository] (SOAP diretto + cache locale).
/// Fase 2: un'implementazione che parla con il Worker Cloudflare; il resto
/// dell'app non cambia.
abstract class FarmadatiRepository {
  /// Ricerca per testo, codice ministeriale o EAN (più di 9 cifre).
  Future<List<Prodotto>> cercaProdotti(String query);

  /// Descrizione di rendibilità/indennizzo, null se non disponibile.
  Future<String?> rendibilita(String codice);

  /// true se vendibile, false se un provvedimento TR012 in vigore lo vieta,
  /// null se non determinabile (dati incompleti o errore).
  Future<bool?> vendibilita(String codice);

  /// URL CDN dell'immagine prodotto, stringa vuota se assente.
  Future<String> immagineUrl(String codice);

  /// URL del bugiardino (copia su doublecore se disponibile), null se assente.
  Future<String?> bugiardinoUrl(String codice, String? tipoProdottoDettaglio);
}

/// Implementazione in uso: il Worker se è configurato un endpoint
/// (kFarmadatiProxyEndpoint o --dart-define=FARMADATI_PROXY=...),
/// altrimenti SOAP diretto.
FarmadatiRepository farmadati =
    kFarmadatiProxyEndpoint.isEmpty
        ? SoapFarmadatiRepository()
        : WorkerFarmadatiRepository(baseUrl: kFarmadatiProxyEndpoint);

/// Un record di TR012 "Vendibilità ed esaurimento scorte". Un codice ne ha al
/// massimo uno per stato (la chiave Farmadati è codice + stato).
class Provvedimento {
  const Provvedimento({
    required this.stato,
    this.data,
    this.motivo,
    this.esaurimento,
  });

  /// FDI_T292: VF = vendibile fino al, RI = ricommercializzabile dal,
  /// RD = ritiro definitivo dal.
  final String stato;

  /// FDI_T293, la data a cui si riferisce [stato].
  final String? data;

  /// FDI_T294, codice motivo (tabella TS031; E = ad esaurimento scorte).
  final String? motivo;

  /// FDI_T298, data inizio vendibilità fino ad esaurimento scorte.
  final String? esaurimento;
}

/// Vendibilità dai provvedimenti TR012 (tracciati record NBDF, Farmadati).
///
/// Decide il provvedimento più recente già in vigore. Senza provvedimenti il
/// prodotto è vendibile. Un provvedimento senza FDI_T293 ma ad esaurimento
/// scorte non blocca la vendita; senza nessuna data non è determinabile.
bool? calcolaVendibilita(List<Provvedimento> provvedimenti, {DateTime? oggi}) {
  final adesso = oggi ?? DateTime.now();
  final giorno = DateTime(adesso.year, adesso.month, adesso.day);

  final eventi = <(DateTime, bool)>[];
  var indeterminato = false;
  for (final p in provvedimenti) {
    final data = DateTime.tryParse(p.data ?? '');
    if (data == null) {
      final adEsaurimento =
          p.motivo == 'E' || DateTime.tryParse(p.esaurimento ?? '') != null;
      if (!adEsaurimento) indeterminato = true;
      continue;
    }
    final evento = switch (p.stato) {
      // "fino al": il giorno indicato è ancora vendibile
      'VF' => (data.add(const Duration(days: 1)), false),
      'RI' => (data, true),
      'RD' => (data, false),
      _ => null,
    };
    if (evento == null) {
      indeterminato = true;
    } else {
      eventi.add(evento);
    }
  }

  final inVigore = eventi.where((e) => !e.$1.isAfter(giorno)).toList();
  if (inVigore.isEmpty) {
    // un RI futuro dice che fino a quella data il prodotto è ritirato
    final futuri = eventi.toList()..sort((a, b) => a.$1.compareTo(b.$1));
    if (futuri.isNotEmpty && futuri.first.$2) return false;
    return indeterminato ? null : true;
  }

  final ultimaData = inVigore
      .map((e) => e.$1)
      .reduce((a, b) => a.isAfter(b) ? a : b);
  // a parità di data prevale il blocco
  return inVigore.where((e) => e.$1 == ultimaData).every((e) => e.$2);
}
