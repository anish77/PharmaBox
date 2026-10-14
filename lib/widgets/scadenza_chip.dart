import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/models/lotto_confezione.dart';
import 'package:pharma_box/models/prodotto.dart';

const _kEntro6Mesi = Color(0xFFA67C00);

Color coloreScadenza(StatoScadenza stato) => switch (stato) {
  StatoScadenza.scaduto => kRed,
  StatoScadenza.entro3Mesi => kWarning,
  StatoScadenza.entro6Mesi => _kEntro6Mesi,
  StatoScadenza.ok => kGreen,
};

String etichettaScadenza(DateTime scadenza) => switch (statoScadenza(
  scadenza,
)) {
  StatoScadenza.scaduto => 'Scaduto il ${formattaScadenza(scadenza)}',
  _ => 'Scad. ${formattaScadenza(scadenza)}',
};

/// Scadenza più vicina del prodotto in lista; tocca per vedere i lotti.
/// Non occupa spazio se il prodotto non è mai stato letto da DataMatrix.
class ScadenzaChip extends StatelessWidget {
  const ScadenzaChip({super.key, required this.prodotto});

  final Prodotto prodotto;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<LottoConfezione>>(
      valueListenable: prodotto.lotti,
      builder: (context, lotti, _) {
        final scadenza = scadenzaPiuVicina(lotti);
        if (scadenza == null) return const SizedBox.shrink();
        final colore = coloreScadenza(statoScadenza(scadenza));
        final nLotti = lotti.where((l) => l.quantity > 0).length;
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => mostraLotti(context, prodotto),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                  Text(
                    nLotti > 1
                        ? '${etichettaScadenza(scadenza)} · $nLotti lotti'
                        : etichettaScadenza(scadenza),
                    style: TextStyle(
                      color: colore,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Lotti e scadenze del prodotto, dal più vicino alla scadenza.
Future<void> mostraLotti(BuildContext context, Prodotto prodotto) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: kWhite,
    showDragHandle: true,
    builder:
        (sheetContext) => SafeArea(
          child: ValueListenableBuilder<List<LottoConfezione>>(
            valueListenable: prodotto.lotti,
            builder: (context, lotti, _) {
              final ordinati =
                  lotti.where((l) => l.quantity > 0).toList()..sort(
                    (a, b) => (a.scadenza ?? DateTime(9999)).compareTo(
                      b.scadenza ?? DateTime(9999),
                    ),
                  );
              final conDataMatrix = ordinati.fold<int>(
                0,
                (somma, l) => somma + l.quantity,
              );
              final senza = prodotto.pezzi.value - conDataMatrix;
              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prodotto.nome,
                      style: const TextStyle(
                        color: kBluScuro,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final l in ordinati) _RigaLotto(lotto: l),
                    if (senza > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '$senza ${senza == 1 ? 'pezzo' : 'pezzi'} senza '
                          'scadenza (letti dal bollino o inseriti a mano)',
                          style: const TextStyle(
                            color: Color(0xFF86899D),
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
  );
}

class _RigaLotto extends StatelessWidget {
  const _RigaLotto({required this.lotto});

  final LottoConfezione lotto;

  @override
  Widget build(BuildContext context) {
    final scadenza = lotto.scadenza;
    final colore =
        scadenza == null ? kBluScuro : coloreScadenza(statoScadenza(scadenza));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: colore, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scadenza == null
                      ? 'Scadenza non letta'
                      : etichettaScadenza(scadenza),
                  style: TextStyle(color: colore, fontWeight: FontWeight.w600),
                ),
                Text(
                  lotto.lotto.isEmpty
                      ? 'Lotto non letto'
                      : 'Lotto ${lotto.lotto}',
                  style: const TextStyle(color: kBluScuro, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            '${lotto.quantity} pz',
            style: const TextStyle(
              color: kBluScuro,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
