import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:shared_preferences/shared_preferences.dart';

/// Una preferenza salvata su questo dispositivo (bool, int o String).
class Preferenza<T> extends ValueNotifier<T> {
  Preferenza(this.chiave, this.predefinito) : super(predefinito);

  final String chiave;
  final T predefinito;

  void _leggi(SharedPreferences prefs) {
    final salvato = prefs.get(chiave);
    value = salvato is T ? salvato : predefinito;
  }

  Future<void> imposta(T nuovo) async {
    value = nuovo;
    final prefs = await SharedPreferences.getInstance();
    switch (nuovo) {
      case null:
        await prefs.remove(chiave);
      case final bool b:
        await prefs.setBool(chiave, b);
      case final int i:
        await prefs.setInt(chiave, i);
      case final String s:
        await prefs.setString(chiave, s);
      default:
        throw UnsupportedError('Tipo non salvabile: $T');
    }
  }
}

/// Ordinamento con cui si apre la lista dell'inventario
enum OrdinamentoLista { nome, scadenza, ultimo }

/// Preferenze di questo telefono (SharedPreferences): non seguono l'account
/// e restano dopo il logout, per chiunque acceda da questo dispositivo.
abstract final class PreferenzeDispositivo {
  // Feedback
  static final feedbackAptico = Preferenza<bool>('feedback_aptico', true);
  static final suonoLettura = Preferenza<bool>('suono_lettura', false);

  // Scanner: l'ultimo collegato, per ricollegarlo aprendo una lista
  static final riconnettiScanner = Preferenza<bool>('riconnetti_scanner', true);
  static final ultimoScannerId = Preferenza<String?>('ultimo_scanner_id', null);
  static final ultimoScannerNome = Preferenza<String?>(
    'ultimo_scanner_nome',
    null,
  );

  // Inventario
  static final schermoAcceso = Preferenza<bool>('schermo_acceso', false);
  static final _ordinamento = Preferenza<String>(
    'ordinamento',
    OrdinamentoLista.nome.name,
  );

  /// Ultimo ordinamento scelto nella lista (per [OrdinamentoLista.ultimo])
  static final ultimoPerScadenza = Preferenza<bool>(
    'ultimo_per_scadenza',
    false,
  );
  static final scadenzeAperte = Preferenza<bool>('scadenze_aperte', false);

  /// Con lotti in lista il − toglie subito un pezzo invece di aprire il
  /// pannello dei lotti (prima senza scadenza, poi scadenza più vicina)
  static final menoDiretto = Preferenza<bool>('meno_diretto', false);

  // Scadenze: arancione entro [mesiInScadenza], ocra entro [mesiProssima]
  static final mesiInScadenza = Preferenza<int>('mesi_in_scadenza', 3);
  static final mesiProssima = Preferenza<int>('mesi_prossima', 6);

  // Avvisi alla lettura ("già contata" è sempre attivo)
  static final avvisoScaduta = Preferenza<bool>('avviso_scaduta', true);
  static final avvisoInScadenza = Preferenza<bool>('avviso_in_scadenza', true);
  static final avvisoAmbigua = Preferenza<bool>('avviso_ambigua', true);

  static final List<Preferenza<Object?>> _tutte = [
    feedbackAptico,
    suonoLettura,
    riconnettiScanner,
    ultimoScannerId,
    ultimoScannerNome,
    schermoAcceso,
    _ordinamento,
    ultimoPerScadenza,
    scadenzeAperte,
    menoDiretto,
    mesiInScadenza,
    mesiProssima,
    avvisoScaduta,
    avvisoInScadenza,
    avvisoAmbigua,
  ];

  /// Da chiamare all'avvio, prima di runApp
  static Future<void> carica() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final p in _tutte) {
        p._leggi(prefs);
      }
    } catch (e) {
      debugPrint('Preferenze dispositivo non lette: $e');
    }
  }

  /// Tutte ai valori predefiniti, senza salvarle (per i test)
  @visibleForTesting
  static void ripristinaPredefiniti() {
    for (final p in _tutte) {
      p.value = p.predefinito;
    }
  }

  static OrdinamentoLista get ordinamento => OrdinamentoLista.values.firstWhere(
    (o) => o.name == _ordinamento.value,
    orElse: () => OrdinamentoLista.nome,
  );

  static ValueListenable<String> get ordinamentoListenable => _ordinamento;

  static Future<void> impostaOrdinamento(OrdinamentoLista o) =>
      _ordinamento.imposta(o.name);

  /// Lista aperta per scadenza secondo la preferenza
  static bool get apriPerScadenza => switch (ordinamento) {
    OrdinamentoLista.nome => false,
    OrdinamentoLista.scadenza => true,
    OrdinamentoLista.ultimo => ultimoPerScadenza.value,
  };

  static Future<void> salvaUltimoScanner(String id, String nome) async {
    await ultimoScannerId.imposta(id);
    await ultimoScannerNome.imposta(nome.isEmpty ? null : nome);
  }

  static Future<void> dimenticaScanner() async {
    await ultimoScannerId.imposta(null);
    await ultimoScannerNome.imposta(null);
  }
}

/// Feedback aptico dell'app: non vibra se disattivato nelle Opzioni.
abstract final class Aptico {
  static bool get _attivo => PreferenzeDispositivo.feedbackAptico.value;

  static void leggero() {
    if (_attivo) HapticFeedback.lightImpact();
  }

  static void medio() {
    if (_attivo) HapticFeedback.mediumImpact();
  }

  static void forte() {
    if (_attivo) HapticFeedback.heavyImpact();
  }
}
