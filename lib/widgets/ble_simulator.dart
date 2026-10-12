import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/include/general_functions.dart';
import 'package:pharma_box/main.dart';

typedef _Richiesta = ({List<String> codici, int ripetizioni, int ritardoMs});

/// Solo debug: simula letture dello scanner Bluetooth pubblicando i codici su
/// [scannedBarcodeProvider], come fa ble_functions.dart.
class BleSimulator {
  /// 30 MINSAN reali, tutti trovati dalla ricerca Farmadati (descrizione
  /// come restituita dal servizio). I primi 20 sono quelli di
  /// test/lettura_minsan_test.dart.
  static const Map<String, String> minsanEsempio = {
    '012745182': 'TACHIPIRINA*16CPR DIV 1000MG',
    '012745170': 'TACHIPIRINA*8CPR DIV 1000MG',
    '012745220': 'TACHIPIRINA*GRAT 16BUST 1000MG',
    '012745028': 'TACHIPIRINA*10CPR DIV 500MG',
    '022593204': 'BRUFEN*30CPR RIV 400MG',
    '052892015': 'BRUFEN ANALGESICO*12CPR 400MG',
    '041962034': 'ASPIRINA DOLORE INF*20CPR500MG',
    '004763330': 'ASPIRINA C*20CPR EFF 400+240MG',
    '004763544': 'ASPIRINA*OS GRAT 20BUST 500MG',
    '025669019': 'MOMENT*12CPR RIV 200MG',
    '025669072': 'MOMENT*24CPR RIV 200MG',
    '025669185': 'MOMENT*36CPR RIV 200MG',
    '026089019': 'AUGMENTIN*12CPR RIV875MG+125MG',
    '013046038': 'ENTEROGERMINA*OS 10FL 2MLD/5ML',
    '013046040': 'ENTEROGERMINA*OS 20FL 2MLD/5ML',
    '034548065': 'VOLTAREN EMULGEL*GEL 60G 2%',
    '048414104': 'OKI DOLORE E FEBBRE*12CPR EFF',
    '020582209': 'FLUIMUCIL*30CPR EFF 600MG',
    '034936171': 'FLUIMUCIL MUCOL*10CPR EFF600MG',
    '034248068': 'GAVISCON ADVANCE*OS SOSP 500ML',
    '019655012': 'BENTELAN*10CPR EFF 0,5MG',
    '006979013': 'BUSCOPAN*20CPR RIV 10MG',
    '024840074': 'CARDIOASPIRIN*30CPR GAST 100MG',
    '023356025': 'DAFLON*30CPR RIV 500MG',
    '024402024': 'EUTIROX*FL 50CPR 100MCG',
    '025634015': 'NUROFEN*12CPR RIV 200MG',
    '020702054': 'MAALOX*40CPR MAST 400MG+400MG',
    '000590012': 'RINAZINA*AD GTT 10ML 10MG 0,1%',
    '026894016': 'ZIRTEC*20CPR RIV 10MG',
    '028978017': 'BACTROBAN*UNG 15G 20MG/G',
  };

  static final List<String> _recenti = [];
  static int _ultimeRipetizioni = 1;
  static int _ultimoRitardoMs = 500;

  /// Avanzamento della raffica in corso (null = nessuna raffica).
  static final ValueNotifier<({int fatte, int totale})?> raffica =
      ValueNotifier(null);

  // Incrementato a ogni nuova raffica o stop: una raffica vecchia si ferma
  static int _generazione = 0;

  /// I codici fino a 6 caratteri (formato inviato dallo scanner) passano da
  /// tradCode come le letture reali; gli altri (es. MINSAN a 9 cifre) no.
  static void simula(WidgetRef ref, String codice) {
    final raw = codice.trim().toUpperCase();
    if (raw.isEmpty) return;
    final code = raw.length <= 6 ? tradCode(raw) : raw;

    _recenti.remove(raw);
    _recenti.insert(0, raw);
    if (_recenti.length > 8) _recenti.removeLast();

    // Reset prima del codice così il listener scatta anche se il codice è
    // uguale alla lettura precedente
    final notifier = ref.read(scannedBarcodeProvider.notifier);
    notifier.state = null;
    notifier.state = code;
  }

  /// Spara [codici] in sequenza, ripetendo la sequenza [ripetizioni] volte,
  /// con [ritardo] tra una lettura e la successiva.
  static Future<void> spara(
    BuildContext context,
    WidgetRef ref,
    List<String> codici, {
    int ripetizioni = 1,
    Duration ritardo = Duration.zero,
  }) async {
    if (codici.isEmpty || ripetizioni < 1) return;
    final sequenza = [for (var r = 0; r < ripetizioni; r++) ...codici];
    final generazione = ++_generazione;

    for (var i = 0; i < sequenza.length; i++) {
      if (generazione != _generazione || !context.mounted) break;
      raffica.value = (fatte: i + 1, totale: sequenza.length);
      simula(ref, sequenza[i]);
      if (i < sequenza.length - 1) await Future.delayed(ritardo);
    }

    if (generazione == _generazione) raffica.value = null;
  }

  static void ferma() {
    _generazione++;
    raffica.value = null;
  }

  static Future<void> mostra(BuildContext context, WidgetRef ref) async {
    final codiciCtrl = TextEditingController();
    final ripetizioniCtrl = TextEditingController(
      text: '$_ultimeRipetizioni',
    );
    final ritardoCtrl = TextEditingController(text: '$_ultimoRitardoMs');

    _Richiesta leggiCampi() => (
      codici:
          codiciCtrl.text
              .split(RegExp(r'[\s,;]+'))
              .where((c) => c.isNotEmpty)
              .toList(),
      ripetizioni: int.tryParse(ripetizioniCtrl.text) ?? 1,
      ritardoMs: int.tryParse(ritardoCtrl.text) ?? 0,
    );

    final richiesta = await showDialog<_Richiesta>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text(
              'Simula lettura Bluetooth',
              style: TextStyle(color: kBluScuro, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: codiciCtrl,
                    autofocus: true,
                    autocorrect: false,
                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Codici',
                      helperText:
                          'Codice scanner (6 car.) o MINSAN (9 cifre).\n'
                          'Più codici: separali con spazio o virgola.',
                      helperMaxLines: 2,
                    ),
                    onSubmitted:
                        (_) => Navigator.of(dialogContext).pop(leggiCampi()),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed:
                          () =>
                              codiciCtrl.text = minsanEsempio.keys.join(' '),
                      icon: const Icon(Icons.playlist_add),
                      label: Text(
                        'Inserisci ${minsanEsempio.length} MINSAN di esempio',
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: ripetizioniCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Ripetizioni',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: ritardoCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Ritardo (ms)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_recenti.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Recenti (tocca per una lettura singola)',
                      style: TextStyle(color: kBluScuro, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children:
                          _recenti
                              .map(
                                (c) => ActionChip(
                                  label: Text(c),
                                  onPressed:
                                      () => Navigator.of(dialogContext).pop((
                                        codici: [c],
                                        ripetizioni: 1,
                                        ritardoMs: 0,
                                      )),
                                ),
                              )
                              .toList(),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Annulla'),
              ),
              TextButton(
                onPressed:
                    () => Navigator.of(dialogContext).pop(leggiCampi()),
                child: const Text('Simula'),
              ),
            ],
          ),
    );

    if (richiesta == null || richiesta.codici.isEmpty) return;
    if (richiesta.codici.length > 1 || richiesta.ripetizioni > 1) {
      _ultimeRipetizioni = richiesta.ripetizioni;
      _ultimoRitardoMs = richiesta.ritardoMs;
    }
    if (!context.mounted) return;
    await spara(
      context,
      ref,
      richiesta.codici,
      ripetizioni: richiesta.ripetizioni,
      ritardo: Duration(milliseconds: richiesta.ritardoMs),
    );
  }
}
