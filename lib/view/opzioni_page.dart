import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/logic/preferenze_dispositivo.dart';
import 'package:pharma_box/logic/suoni.dart';

/// Scelte per la soglia arancione (in scadenza) e ocra, in mesi
const kMesiInScadenza = [1, 2, 3, 4, 6];
const kMesiProssima = [3, 6, 9, 12, 18, 24];

const _kGrigio = Color(0xFF86899D);

String _mesi(int n) => n == 1 ? '1 mese' : '$n mesi';

/// Opzioni di questo dispositivo, indipendenti dall'account
class OpzioniPage extends StatelessWidget {
  const OpzioniPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: const Text(
          'Opzioni',
          style: TextStyle(
            color: kBluScuro,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: kBluScuro),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const _Sezione('Scanner', [_Scanner()]),
          _Sezione('Lettura', [
            _Interruttore(
              preferenza: PreferenzeDispositivo.feedbackAptico,
              icona: Icons.vibration,
              titolo: 'Feedback aptico',
              sottotitolo:
                  'Vibrazione quando modifichi i pezzi e agli avvisi di '
                  'lettura.',
              // Riattivandolo si sente subito com'è
              anteprima: Aptico.leggero,
            ),
            _Interruttore(
              preferenza: PreferenzeDispositivo.suonoLettura,
              icona: Icons.volume_up_outlined,
              titolo: 'Suono alla lettura',
              sottotitolo:
                  'Un bip a ogni lettura, un suono diverso per gli avvisi. '
                  'Non suona con il telefono in silenzioso.',
              anteprima: Suoni.lettura,
            ),
          ]),
          _Sezione('Avvisi alla lettura', [
            _Interruttore(
              preferenza: PreferenzeDispositivo.avvisoScaduta,
              icona: Icons.event_busy_outlined,
              titolo: 'Confezione scaduta',
            ),
            ValueListenableBuilder<int>(
              valueListenable: PreferenzeDispositivo.mesiInScadenza,
              builder:
                  (context, mesi, _) => _Interruttore(
                    preferenza: PreferenzeDispositivo.avvisoInScadenza,
                    icona: Icons.schedule,
                    titolo: 'Confezione in scadenza',
                    sottotitolo: 'Scade entro ${_mesi(mesi)}.',
                  ),
            ),
            _Interruttore(
              preferenza: PreferenzeDispositivo.avvisoAmbigua,
              icona: Icons.qr_code_2,
              titolo: 'Lettura ambigua',
              sottotitolo:
                  'Lotto o seriale non separati: lo scanner va configurato '
                  'per trasmettere il separatore GS.',
            ),
            const _Nota('L\'avviso di confezione già contata è sempre attivo.'),
          ]),
          const _Sezione('Scadenze', [_Soglie()]),
          _Sezione('Inventario', [
            _Interruttore(
              preferenza: PreferenzeDispositivo.schermoAcceso,
              icona: Icons.light_mode_outlined,
              titolo: 'Schermo sempre acceso',
              sottotitolo:
                  'Mentre una lista è aperta il telefono non va in standby.',
            ),
            const _Ordinamento(),
            _Interruttore(
              preferenza: PreferenzeDispositivo.scadenzeAperte,
              icona: Icons.unfold_more,
              titolo: 'Scadenze e lotti sempre aperti',
              sottotitolo:
                  'Nella lista, sotto ogni prodotto letto da DataMatrix.',
            ),
          ]),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              'Queste opzioni valgono solo per questo dispositivo, '
              'qualunque account sia collegato.',
              style: TextStyle(color: _kGrigio, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sezione extends StatelessWidget {
  const _Sezione(this.titolo, this.figli);

  final String titolo;
  final List<Widget> figli;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
          child: Text(
            titolo,
            style: const TextStyle(
              color: kPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        Card(margin: EdgeInsets.zero, child: Column(children: figli)),
      ],
    );
  }
}

class _Nota extends StatelessWidget {
  const _Nota(this.testo);

  final String testo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          testo,
          style: const TextStyle(color: _kGrigio, fontSize: 12),
        ),
      ),
    );
  }
}

class _Icona extends StatelessWidget {
  const _Icona(this.icona);

  final IconData icona;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    backgroundColor: kSecondary,
    child: Icon(icona, color: kPrimary),
  );
}

class _Interruttore extends StatelessWidget {
  const _Interruttore({
    required this.preferenza,
    required this.icona,
    required this.titolo,
    this.sottotitolo,
    this.anteprima,
  });

  final Preferenza<bool> preferenza;
  final IconData icona;
  final String titolo;
  final String? sottotitolo;

  /// Fatta sentire quando l'opzione viene attivata
  final VoidCallback? anteprima;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: preferenza,
      builder:
          (context, attivo, _) => SwitchListTile(
            secondary: _Icona(icona),
            title: Text(
              titolo,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: sottotitolo == null ? null : Text(sottotitolo!),
            activeThumbColor: kPrimary,
            value: attivo,
            onChanged: (valore) async {
              await preferenza.imposta(valore);
              if (valore) anteprima?.call();
            },
          ),
    );
  }
}

/// Ultimo scanner collegato e ricollegamento automatico
class _Scanner extends StatelessWidget {
  const _Scanner();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: PreferenzeDispositivo.ultimoScannerId,
      builder: (context, id, _) {
        final nome = PreferenzeDispositivo.ultimoScannerNome.value ?? id;
        return Column(
          children: [
            _Interruttore(
              preferenza: PreferenzeDispositivo.riconnettiScanner,
              icona: Icons.bluetooth_connected,
              titolo: 'Ricollega l\'ultimo scanner',
              sottotitolo:
                  id == null
                      ? 'Aprendo una lista si collega da solo all\'ultimo '
                          'scanner usato. Nessuno scanner salvato: collegane '
                          'uno da una lista.'
                      : 'Aprendo una lista si collega da solo a $nome.',
            ),
            if (id != null)
              ListTile(
                leading: const _Icona(Icons.bluetooth_disabled),
                title: Text(
                  nome!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Scanner salvato su questo dispositivo'),
                trailing: TextButton(
                  onPressed: PreferenzeDispositivo.dimenticaScanner,
                  style: TextButton.styleFrom(foregroundColor: kRed),
                  child: const Text('Dimentica'),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Soglie dei colori di scadenza; la ocra resta sempre oltre l'arancione
class _Soglie extends StatelessWidget {
  const _Soglie();

  static Future<void> _impostaInScadenza(int mesi) async {
    await PreferenzeDispositivo.mesiInScadenza.imposta(mesi);
    if (PreferenzeDispositivo.mesiProssima.value <= mesi) {
      await PreferenzeDispositivo.mesiProssima.imposta(
        kMesiProssima.firstWhere((m) => m > mesi),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        PreferenzeDispositivo.mesiInScadenza,
        PreferenzeDispositivo.mesiProssima,
      ]),
      builder: (context, _) {
        final inScadenza = PreferenzeDispositivo.mesiInScadenza.value;
        final prossima = PreferenzeDispositivo.mesiProssima.value;
        return Column(
          children: [
            _SceltaMesi(
              chiave: const Key('soglia_in_scadenza'),
              colore: kWarning,
              titolo: 'In scadenza (arancione)',
              valore: inScadenza,
              scelte: kMesiInScadenza,
              onChanged: _impostaInScadenza,
            ),
            _SceltaMesi(
              chiave: const Key('soglia_prossima'),
              colore: const Color(0xFFA67C00),
              titolo: 'Scadenza vicina (ocra)',
              valore: prossima,
              scelte: kMesiProssima.where((m) => m > inScadenza).toList(),
              onChanged: PreferenzeDispositivo.mesiProssima.imposta,
            ),
            const _Nota(
              'Oltre la soglia ocra la scadenza è verde. Le soglie valgono '
              'per i colori nella lista e per l\'avviso alla lettura.',
            ),
          ],
        );
      },
    );
  }
}

class _SceltaMesi extends StatelessWidget {
  const _SceltaMesi({
    required this.chiave,
    required this.colore,
    required this.titolo,
    required this.valore,
    required this.scelte,
    required this.onChanged,
  });

  final Key chiave;
  final Color colore;
  final String titolo;
  final int valore;
  final List<int> scelte;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colore.withValues(alpha: 0.15),
        child: Icon(Icons.event_outlined, color: colore),
      ),
      title: Text(titolo, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: DropdownButton<int>(
        key: chiave,
        value: scelte.contains(valore) ? valore : null,
        underline: const SizedBox.shrink(),
        items: [
          for (final m in scelte)
            DropdownMenuItem(value: m, child: Text('entro ${_mesi(m)}')),
        ],
        onChanged: (m) {
          if (m != null) onChanged(m);
        },
      ),
    );
  }
}

/// Ordinamento con cui si apre la lista dell'inventario
class _Ordinamento extends StatelessWidget {
  const _Ordinamento();

  static const _etichette = {
    OrdinamentoLista.nome: 'Per nome',
    OrdinamentoLista.scadenza: 'Per scadenza',
    OrdinamentoLista.ultimo: 'Ultimo usato',
  };

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: PreferenzeDispositivo.ordinamentoListenable,
      builder:
          (context, _, _) => ListTile(
            leading: const _Icona(Icons.sort),
            title: const Text(
              'Ordinamento della lista',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: DropdownButton<OrdinamentoLista>(
              key: const Key('ordinamento_lista'),
              value: PreferenzeDispositivo.ordinamento,
              underline: const SizedBox.shrink(),
              items: [
                for (final MapEntry(key: o, value: testo) in _etichette.entries)
                  DropdownMenuItem(value: o, child: Text(testo)),
              ],
              onChanged: (o) {
                if (o != null) PreferenzeDispositivo.impostaOrdinamento(o);
              },
            ),
          ),
    );
  }
}
