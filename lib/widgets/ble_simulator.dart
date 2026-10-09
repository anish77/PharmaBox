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
                    maxLines: 3,
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
                  const SizedBox(height: 12),
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
