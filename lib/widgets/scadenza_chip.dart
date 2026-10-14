import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/logic/preferenze_dispositivo.dart';
import 'package:pharma_box/models/lotto_confezione.dart';
import 'package:pharma_box/models/prodotto.dart';

const _kOcra = Color(0xFFA67C00);

Color coloreScadenza(StatoScadenza stato) => switch (stato) {
  StatoScadenza.scaduto => kRed,
  StatoScadenza.inScadenza => kWarning,
  StatoScadenza.prossima => _kOcra,
  StatoScadenza.ok => kGreen,
};

String etichettaScadenza(DateTime scadenza) => switch (statoScadenza(
  scadenza,
)) {
  StatoScadenza.scaduto => 'Scaduto il ${formattaScadenza(scadenza)}',
  _ => 'Scad. ${formattaScadenza(scadenza)}',
};

/// Scadenza più vicina del prodotto in lista; tocca per aprire sul posto
/// l'elenco delle scadenze, ognuna con tutti i suoi lotti.
/// Non occupa spazio se il prodotto non è mai stato letto da DataMatrix.
class ScadenzaChip extends StatefulWidget {
  const ScadenzaChip({super.key, required this.prodotto});

  final Prodotto prodotto;

  @override
  State<ScadenzaChip> createState() => _ScadenzaChipState();
}

class _ScadenzaChipState extends State<ScadenzaChip> {
  bool _aperto = PreferenzeDispositivo.scadenzeAperte.value;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<LottoConfezione>>(
      valueListenable: widget.prodotto.lotti,
      builder: (context, lotti, _) {
        final scadenza = scadenzaPiuVicina(lotti);
        if (scadenza == null) return const SizedBox.shrink();
        final colore = coloreScadenza(statoScadenza(scadenza));
        final nLotti = lotti.where((l) => l.quantity > 0).length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _aperto = !_aperto),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 3, 4, 3),
                  decoration: BoxDecoration(
                    color: colore.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colore),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_outlined, size: 14, color: colore),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          nLotti > 1
                              ? '${etichettaScadenza(scadenza)} · $nLotti lotti'
                              : etichettaScadenza(scadenza),
                          style: TextStyle(
                            color: colore,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        _aperto ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                        color: colore,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topLeft,
              child:
                  _aperto
                      ? _ElencoScadenze(
                        lotti: lotti,
                        pezzi: widget.prodotto.pezzi.value,
                      )
                      : const SizedBox(width: double.infinity),
            ),
          ],
        );
      },
    );
  }
}

/// Lotti con pezzi raggruppati per scadenza, dalla più vicina; quelli senza
/// scadenza in fondo.
List<({DateTime? scadenza, List<LottoConfezione> lotti})> lottiPerScadenza(
  Iterable<LottoConfezione> lotti,
) {
  final gruppi = <DateTime?, List<LottoConfezione>>{};
  for (final l in lotti.where((l) => l.quantity > 0)) {
    gruppi.putIfAbsent(l.scadenza, () => []).add(l);
  }
  final date =
      gruppi.keys.toList()
        ..sort((a, b) => (a ?? DateTime(9999)).compareTo(b ?? DateTime(9999)));
  return [
    for (final d in date)
      (
        scadenza: d,
        lotti: gruppi[d]!..sort((a, b) => a.lotto.compareTo(b.lotto)),
      ),
  ];
}

class _ElencoScadenze extends StatelessWidget {
  const _ElencoScadenze({required this.lotti, required this.pezzi});

  final List<LottoConfezione> lotti;

  /// Pezzi del prodotto in lista, anche quelli senza scadenza
  final int pezzi;

  @override
  Widget build(BuildContext context) {
    final gruppi = lottiPerScadenza(lotti);
    final conDataMatrix = lotti
        .where((l) => l.quantity > 0)
        .fold<int>(0, (somma, l) => somma + l.quantity);
    final senza = pezzi - conDataMatrix;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final g in gruppi) _GruppoScadenza(g.scadenza, g.lotti),
          if (senza > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '$senza ${senza == 1 ? 'pezzo' : 'pezzi'} senza scadenza '
                '(bollino o a mano)',
                style: const TextStyle(color: Color(0xFF86899D), fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _GruppoScadenza extends StatelessWidget {
  const _GruppoScadenza(this.scadenza, this.lotti);

  final DateTime? scadenza;
  final List<LottoConfezione> lotti;

  @override
  Widget build(BuildContext context) {
    final s = scadenza;
    final colore = s == null ? kBluScuro : coloreScadenza(statoScadenza(s));
    final totale = lotti.fold<int>(0, (somma, l) => somma + l.quantity);
    const testo = TextStyle(color: kBluScuro, fontSize: 13);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colore,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  s == null ? 'Scadenza non letta' : etichettaScadenza(s),
                  style: TextStyle(
                    color: colore,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'Tot. $totale pz',
                style: testo.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          for (final l in lotti)
            Padding(
              padding: const EdgeInsets.only(left: 14, top: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.lotto.isEmpty ? 'Lotto non letto' : 'Lotto ${l.lotto}',
                      style: testo,
                    ),
                  ),
                  Text('${l.quantity} pz', style: testo),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
