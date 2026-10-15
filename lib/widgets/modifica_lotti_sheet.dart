import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/logic/preferenze_dispositivo.dart';
import 'package:pharma_box/models/lotto_confezione.dart';
import 'package:pharma_box/models/prodotto.dart';
import 'package:pharma_box/widgets/carrello.dart';
import 'package:pharma_box/widgets/scadenza_chip.dart';

/// Per un prodotto con lotti (letti da DataMatrix) le quantità si cambiano
/// lotto per lotto: il contatore della lista apre questo pannello invece di
/// togliere un pezzo senza dire da quale lotto.
Future<void> mostraModificaLotti(
  BuildContext context,
  Prodotto prodotto, {
  void Function(LottoConfezione lotto, int delta)? onLotto,
  void Function(int delta)? onSenzaLotto,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: kBackGround,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder:
        (_) => ModificaLotti(
          prodotto: prodotto,
          onLotto:
              onLotto ??
              (lotto, delta) =>
                  Carrello.instance.modificaLotto(prodotto, lotto, delta),
          onSenzaLotto:
              onSenzaLotto ??
              (delta) => Carrello.instance.modificaSenzaLotto(prodotto, delta),
        ),
  );
}

/// Con l'opzione "Togli senza scegliere il lotto" il − di un prodotto con
/// lotti toglie subito un pezzo e dice da dove; altrimenti null (il − apre
/// il pannello come + e il numero).
VoidCallback? menoDiretto(BuildContext context, String minsan) {
  if (!PreferenzeDispositivo.menoDiretto.value) return null;
  if (!Carrello.instance.haLotti(minsan)) return null;
  return () {
    final prodotto = Carrello.instance.inLista(minsan);
    if (prodotto == null) return;
    final esito = Carrello.instance.togliUnPezzo(prodotto);
    if (esito == null || !context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(esito), duration: const Duration(seconds: 2)),
      );
  };
}

class ModificaLotti extends StatefulWidget {
  const ModificaLotti({
    super.key,
    required this.prodotto,
    required this.onLotto,
    required this.onSenzaLotto,
  });

  final Prodotto prodotto;
  final void Function(LottoConfezione lotto, int delta) onLotto;
  final void Function(int delta) onSenzaLotto;

  @override
  State<ModificaLotti> createState() => _ModificaLottiState();
}

class _ModificaLottiState extends State<ModificaLotti> {
  /// Lotti mostrati: quelli presenti all'apertura restano anche a 0 pezzi,
  /// così un pezzo tolto per sbaglio si rimette con +.
  late final List<LottoConfezione> _righe = [
    for (final l in widget.prodotto.lotti.value)
      if (l.quantity > 0) l,
  ];

  bool _stesso(LottoConfezione a, LottoConfezione b) =>
      a.lotto == b.lotto && a.scadenza == b.scadenza;

  int _quantita(LottoConfezione riga) {
    for (final l in widget.prodotto.lotti.value) {
      if (_stesso(l, riga)) return l.quantity;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final prodotto = widget.prodotto;
    return AnimatedBuilder(
      animation: Listenable.merge([prodotto.pezzi, prodotto.lotti]),
      builder: (context, _) {
        // lotti arrivati dallo scanner a pannello aperto
        for (final l in prodotto.lotti.value) {
          if (l.quantity > 0 && !_righe.any((r) => _stesso(r, l))) {
            _righe.add(l);
          }
        }
        final righe = [
          for (final g in lottiPerScadenza([
            for (final r in _righe)
              LottoConfezione(
                lotto: r.lotto,
                scadenza: r.scadenza,
                quantity: 1,
              ),
          ]))
            ...g.lotti,
        ];
        final senzaLotto = Carrello.pezziSenzaLotto(prodotto);

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.8,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: kBluScuro.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    prodotto.nome,
                    style: const TextStyle(
                      color: kBluScuro,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Togli o aggiungi pezzi lotto per lotto',
                    style: TextStyle(color: Color(0xFF86899D), fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final r in righe)
                          _Riga(
                            key: ValueKey('lotto-${r.lotto}-${r.scadenza}'),
                            colore:
                                r.scadenza == null
                                    ? kBluScuro
                                    : coloreScadenza(
                                      statoScadenza(r.scadenza!),
                                    ),
                            titolo:
                                r.scadenza == null
                                    ? 'Senza data di scadenza'
                                    : etichettaScadenza(r.scadenza!),
                            sottotitolo:
                                r.lotto.isEmpty
                                    ? 'Lotto non indicato'
                                    : 'Lotto ${r.lotto}',
                            quantita: _quantita(r),
                            onMeno: () => widget.onLotto(r, -1),
                            onPiu: () => widget.onLotto(r, 1),
                          ),
                        _Riga(
                          key: const ValueKey('senza-lotto'),
                          colore: const Color(0xFF86899D),
                          titolo: 'Senza scadenza',
                          sottotitolo: 'Bollino o aggiunti a mano',
                          quantita: senzaLotto,
                          onMeno: () => widget.onSenzaLotto(-1),
                          onPiu: () => widget.onSenzaLotto(1),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Totale ${prodotto.pezzi.value} '
                          '${prodotto.pezzi.value == 1 ? 'pezzo' : 'pezzi'}',
                          style: const TextStyle(
                            color: kBluScuro,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: kPrimary,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Fatto'),
                      ),
                    ],
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

class _Riga extends StatelessWidget {
  const _Riga({
    super.key,
    required this.colore,
    required this.titolo,
    required this.sottotitolo,
    required this.quantita,
    required this.onMeno,
    required this.onPiu,
  });

  final Color colore;
  final String titolo;
  final String sottotitolo;
  final int quantita;
  final VoidCallback onMeno;
  final VoidCallback onPiu;

  @override
  Widget build(BuildContext context) {
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
                  titolo,
                  style: TextStyle(
                    color: colore,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  sottotitolo,
                  style: const TextStyle(color: kBluScuro, fontSize: 13),
                ),
              ],
            ),
          ),
          _BottoneTondo(
            icona: Icons.remove,
            tooltip: 'Togli un pezzo',
            onPressed: quantita > 0 ? onMeno : null,
          ),
          SizedBox(
            width: 40,
            child: Text(
              '$quantita',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kBluScuro,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _BottoneTondo(
            icona: Icons.add,
            tooltip: 'Aggiungi un pezzo',
            onPressed: onPiu,
          ),
        ],
      ),
    );
  }
}

class _BottoneTondo extends StatelessWidget {
  const _BottoneTondo({
    required this.icona,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icona;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icona, size: 18),
      color: kBluScuro,
      style: IconButton.styleFrom(
        side: BorderSide(color: onPressed == null ? kSecondary : kPrimary),
        backgroundColor: kSecondary,
      ),
    );
  }
}
