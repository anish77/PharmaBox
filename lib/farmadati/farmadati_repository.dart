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

  /// true se vendibile, false se un lotto è invendibile, null se non determinabile.
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

/// Vendibilità a partire dal lotto invendibile (TR012: FDI_T292 stato,
/// FDI_T293 data). Nessun lotto = vendibile; dati incompleti = non determinabile.
bool? calcolaVendibilita({
  required bool haLotto,
  String? stato,
  String? data,
  DateTime? oggi,
}) {
  if (!haLotto) return true;
  if (stato == null || stato.isEmpty || data == null || data.isEmpty) {
    return null;
  }
  final dData = DateTime.tryParse(data);
  if (dData == null) return null;
  final passata = !(oggi ?? DateTime.now()).difference(dData).isNegative;

  return (stato == "VF" && !passata) ||
      (stato == "RD" && !passata) ||
      (stato == "RI" && passata);
}
