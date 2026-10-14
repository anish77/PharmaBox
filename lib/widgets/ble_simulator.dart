import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/include/ble_functions.dart';
import 'package:pharma_box/include/general_functions.dart';
import 'package:pharma_box/include/gs1_datamatrix.dart';
import 'package:pharma_box/include/lettura_scanner.dart';
import 'package:pharma_box/main.dart';
import 'package:pharma_box/models/lotto_confezione.dart';

typedef _Richiesta = ({List<String> codici, int ripetizioni, int ritardoMs});

/// Solo debug: simula letture dello scanner Bluetooth pubblicando i codici su
/// [scannedBarcodeProvider], come fa ble_functions.dart. I DataMatrix fanno
/// lo stesso percorso di una lettura vera: byte con separatori GS, spezzati
/// in notifiche da 20 byte, ricomposti da [AssemblatoreBle] e decodificati.
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

  /// DataMatrix di esempio nel formato leggibile "(01)...(716)...", uno per
  /// ciascuno dei primi MINSAN, con scadenze diverse: scaduto, entro 3 mesi,
  /// entro 6 mesi e lontane. Seriali nuovi a ogni chiamata: ripetendo la
  /// stessa sequenza si prova il riconoscimento delle confezioni già contate.
  static List<String> dataMatrixEsempio({DateTime? oggi}) {
    final adesso = oggi ?? DateTime.now();
    final random = Random();
    const scadenzeInMesi = [-1, 2, 5, 14, 30, 2];
    final minsan = minsanEsempio.keys.take(scadenzeInMesi.length).toList();
    return [
      for (var i = 0; i < minsan.length; i++)
        _dataMatrix(
          minsan: minsan[i],
          // giorno 00 = fine mese, come su molte confezioni
          scadenza: DateTime(adesso.year, adesso.month + scadenzeInMesi[i]),
          lotto: 'L${(i + 1) * 1111}${String.fromCharCode(65 + i)}',
          seriale: _nuovoSeriale(random),
        ),
    ];
  }

  static const _caratteriSeriale = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static String _nuovoSeriale([Random? random]) {
    final r = random ?? Random();
    return [
      for (var k = 0; k < 12; k++)
        _caratteriSeriale[r.nextInt(_caratteriSeriale.length)],
    ].join();
  }

  /// [fineMese]: giorno 00, come su molte confezioni. Lotto o seriale vuoti
  /// vengono omessi.
  static String _dataMatrix({
    required String minsan,
    required DateTime scadenza,
    required String lotto,
    required String seriale,
    bool fineMese = true,
  }) {
    final base = '0803208${minsan.substring(3)}';
    final gtin = '$base${cifraControlloGs1(base)}';
    String dd(int n) => n.toString().padLeft(2, '0');
    final aammgg =
        '${dd(scadenza.year % 100)}${dd(scadenza.month)}'
        '${fineMese ? '00' : dd(scadenza.day)}';
    return '(01)$gtin(17)$aammgg'
        '${lotto.isEmpty ? '' : '(10)$lotto'}'
        '${seriale.isEmpty ? '' : '(21)$seriale'}'
        '(716)$minsan';
  }

  /// Simula uno scanner non configurato per trasmettere il separatore GS
  static bool senzaGs = false;

  /// Lettura di un DataMatrix scritto come "(01)…(716)…", trasmessa come da
  /// uno scanner BLE: null se [testo] non è un DataMatrix valido.
  static LetturaScanner? letturaDataMatrix(String testo, {bool conGs = true}) {
    if (!testo.startsWith('(') || parseGs1(testo)?.codiceRicerca == null) {
      return null;
    }
    final trasmesso = componiGs1(campiTraParentesi(testo), conGs: conGs);
    LetturaScanner? lettura;
    final assemblatore = AssemblatoreBle(
      (bytes) => lettura = interpretaLettura(bleDecode(bytes)),
    );
    final bytes = utf8.encode('$trasmesso\r');
    for (var i = 0; i < bytes.length; i += 20) {
      assemblatore.aggiungi(bytes.sublist(i, min(i + 20, bytes.length)));
    }
    return lettura;
  }

  static final List<String> _recenti = [];
  static int _ultimeRipetizioni = 1;
  static int _ultimoRitardoMs = 500;

  /// Avanzamento della raffica in corso (null = nessuna raffica).
  static final ValueNotifier<({int fatte, int totale})?> raffica =
      ValueNotifier(null);

  // Incrementato a ogni nuova raffica o stop: una raffica vecchia si ferma
  static int _generazione = 0;

  /// I DataMatrix passano dalla catena BLE ([letturaDataMatrix]); i codici
  /// fino a 6 caratteri (bollino) da tradCode; gli altri (es. MINSAN a 9
  /// cifre) sono cercati così come sono.
  static void simula(WidgetRef ref, String codice) {
    final testo = codice.trim();
    if (testo.isEmpty) return;
    final dataMatrix = letturaDataMatrix(testo, conGs: !senzaGs);
    // Il seriale distingue maiuscole e minuscole: niente toUpperCase sui GS1
    final raw = dataMatrix != null ? testo : testo.toUpperCase();
    final lettura =
        dataMatrix ?? LetturaScanner(raw.length <= 6 ? tradCode(raw) : raw);

    _recenti.remove(raw);
    _recenti.insert(0, raw);
    if (_recenti.length > 8) _recenti.removeLast();

    // Reset prima del codice così il listener scatta anche se il codice è
    // uguale alla lettura precedente
    final notifier = ref.read(scannedBarcodeProvider.notifier);
    notifier.state = null;
    notifier.state = lettura;
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
          (dialogContext) => StatefulBuilder(
            builder:
                (dialogContext, setDialogState) => AlertDialog(
                  title: const Text(
                    'Simula lettura Bluetooth',
                    style: TextStyle(
                      color: kBluScuro,
                      fontWeight: FontWeight.bold,
                    ),
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
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Codici',
                            helperText:
                                'Codice scanner (6 car.), MINSAN (9 cifre) o\n'
                                'DataMatrix "(01)…(17)AAMMGG(10)…(21)…(716)…".\n'
                                'Più codici: separali con spazio o virgola.',
                            helperMaxLines: 3,
                          ),
                          onSubmitted:
                              (_) =>
                                  Navigator.of(dialogContext).pop(leggiCampi()),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed:
                                () =>
                                    codiciCtrl.text = minsanEsempio.keys.join(
                                      ' ',
                                    ),
                            icon: const Icon(Icons.playlist_add),
                            label: Text(
                              'Inserisci ${minsanEsempio.length} MINSAN di esempio',
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed:
                                () =>
                                    codiciCtrl.text = dataMatrixEsempio().join(
                                      ' ',
                                    ),
                            icon: const Icon(Icons.qr_code_2),
                            label: const Text(
                              'Inserisci DataMatrix di esempio',
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () async {
                              final composto = await componi(dialogContext);
                              if (composto == null) return;
                              final attuale = codiciCtrl.text.trim();
                              codiciCtrl.text =
                                  attuale.isEmpty
                                      ? composto
                                      : '$attuale $composto';
                            },
                            icon: const Icon(Icons.edit_note),
                            label: const Text('Componi DataMatrix…'),
                          ),
                        ),
                        CheckboxListTile(
                          value: senzaGs,
                          onChanged:
                              (v) => setDialogState(() => senzaGs = v ?? false),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: const Text('DataMatrix senza separatore GS'),
                          subtitle: const Text(
                            'Come uno scanner non configurato per l’FNC1',
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
                                        label: Text(
                                          c,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        onPressed:
                                            () => Navigator.of(
                                              dialogContext,
                                            ).pop((
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

  /// Finestra per comporre un DataMatrix: prodotto, scadenza, lotto e
  /// seriale. Restituisce il testo "(01)…(716)…" da simulare.
  static Future<String?> componi(BuildContext context) {
    final random = Random();
    final adesso = DateTime.now();
    const preset = {
      'Scaduto': -1,
      'Tra 2 mesi': 2,
      'Tra 5 mesi': 5,
      'Tra 2 anni': 24,
    };
    var minsan = minsanEsempio.keys.first;
    int? mesiScelti = 5;
    var scadenza = DateTime(adesso.year, adesso.month + 5);
    var fineMese = true;
    final lottoCtrl = TextEditingController(
      text: 'L${1000 + random.nextInt(9000)}',
    );
    final serialeCtrl = TextEditingController(text: _nuovoSeriale(random));
    // Lo spazio separa i codici nel simulatore; le parentesi gli AI
    String pulisci(String t) => t.replaceAll(RegExp(r'[\s,;()]'), '');

    return showDialog<String>(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text(
                    'Componi DataMatrix',
                    style: TextStyle(
                      color: kBluScuro,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: minsan,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Prodotto (AIC)',
                          ),
                          items: [
                            for (final e in minsanEsempio.entries)
                              DropdownMenuItem(
                                value: e.key,
                                child: Text(
                                  '${e.key} ${e.value}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (v) => setState(() => minsan = v!),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Scadenza',
                          style: TextStyle(color: kBluScuro, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            for (final p in preset.entries)
                              ChoiceChip(
                                label: Text(p.key),
                                selected: mesiScelti == p.value,
                                onSelected:
                                    (_) => setState(() {
                                      mesiScelti = p.value;
                                      scadenza = DateTime(
                                        adesso.year,
                                        adesso.month + p.value,
                                      );
                                      fineMese = true;
                                    }),
                              ),
                            ChoiceChip(
                              avatar: const Icon(
                                Icons.calendar_today,
                                size: 16,
                              ),
                              label: Text(
                                mesiScelti == null
                                    ? formattaScadenza(scadenza)
                                    : 'Scegli data…',
                              ),
                              selected: mesiScelti == null,
                              onSelected: (_) async {
                                final data = await showDatePicker(
                                  context: context,
                                  initialDate: scadenza,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2070),
                                );
                                if (data == null) return;
                                setState(() {
                                  mesiScelti = null;
                                  scadenza = data;
                                  fineMese = false;
                                });
                              },
                            ),
                          ],
                        ),
                        if (fineMese)
                          Text(
                            'Giorno 00: scade il '
                            '${formattaScadenza(DateTime(scadenza.year, scadenza.month + 1, 0))}',
                            style: const TextStyle(
                              color: kBluScuro,
                              fontSize: 12,
                            ),
                          ),
                        TextField(
                          controller: lottoCtrl,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Lotto (vuoto = assente)',
                          ),
                        ),
                        TextField(
                          controller: serialeCtrl,
                          autocorrect: false,
                          decoration: InputDecoration(
                            labelText: 'Seriale (vuoto = assente)',
                            suffixIcon: IconButton(
                              tooltip: 'Nuovo seriale',
                              icon: const Icon(Icons.refresh),
                              onPressed:
                                  () =>
                                      serialeCtrl.text = _nuovoSeriale(random),
                            ),
                          ),
                        ),
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
                          () => Navigator.of(dialogContext).pop(
                            _dataMatrix(
                              minsan: minsan,
                              scadenza: scadenza,
                              lotto: pulisci(lottoCtrl.text),
                              seriale: pulisci(serialeCtrl.text),
                              fineMese: fineMese,
                            ),
                          ),
                      child: const Text('Aggiungi'),
                    ),
                  ],
                ),
          ),
    );
  }
}
