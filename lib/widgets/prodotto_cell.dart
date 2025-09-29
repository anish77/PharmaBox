import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/models/prodotto.dart';
import 'package:pharma_box/widgets/carrello.dart';
import 'package:pharma_box/widgets/counter_button.dart';

const double _titleFontSize = 14.0;
const double _titleLineHeight = 1.3;
const double _twoLineTitleHeight = _titleFontSize * _titleLineHeight * 2;
const TextStyle _titleStyle = TextStyle(
  fontSize: _titleFontSize,
  fontWeight: FontWeight.bold,
  height: _titleLineHeight,
  color: kBluScuro,
);

class ProdottoCell extends StatelessWidget {
  final Prodotto prodotto;
  final ValueChanged<int> onQuantityChanged;
  final bool selected;
  final int? inListQty;

  const ProdottoCell({
    super.key,
    required this.prodotto,
    required this.onQuantityChanged,
    this.selected = false,
    this.inListQty,
  });

  @override
  Widget build(BuildContext context) {
    final mostraQuantita = (inListQty ?? 0) > 0;

    const actionWidth = 120.0;
    const actionHeight = 40.0;

    return Card(
      color: selected ? kYellow : kBackGround,
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!prodotto.consentito)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: kRed,
                                shape: BoxShape.circle,
                              ),
                            ),
                          if (!prodotto.consentito) const SizedBox(width: 8),
                          Expanded(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minHeight: _twoLineTitleHeight,
                              ),
                              child: Text(
                                prodotto.nome,
                                maxLines: 2,
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                                style: _titleStyle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        prodotto.codice,
                        maxLines: 1,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: kBluScuro),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: SizedBox(
                    width: actionWidth,
                    child:
                        mostraQuantita
                            ? CounterButton(
                              // Include la quantità nella key per forzare il rebuild quando cambia esternamente
                              key: ValueKey('list-${prodotto.minsan}-${inListQty ?? 0}'),
                              initialValue: inListQty ?? 0,
                              height: actionHeight,
                              width: actionWidth,
                              onChanged: (newValue) {
                                Carrello.instance.aggiornaQuantita(
                                  prodotto,
                                  newValue,
                                );
                                onQuantityChanged(newValue);
                              },
                            )
                            : GestureDetector(
                              onTap: () {
                                final currentNotifier = prodotto.pezzi;
                                final newValue =
                                    currentNotifier.value > 0
                                        ? currentNotifier.value
                                        : 1;
                                currentNotifier.value = newValue;
                                Carrello.instance.aggiungiProdotto(prodotto);
                                onQuantityChanged(newValue);
                              },
                              child: SizedBox(
                                height: actionHeight,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: kPrimary,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: kPrimary,
                                      width: 1,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 6,
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          kAddToList,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: kWhite,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(thickness: 1, color: kBluScuro, height: 1),
          ],
        ),
      ),
    );
  }
}
