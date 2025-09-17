import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/models/prodotto.dart';
import 'package:pharma_box/widgets/carrello.dart';
import 'package:pharma_box/widgets/counter_button.dart';

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
    return Card(
      color: selected ? kYellow : kBackGround,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.only(
          top: 10,
          bottom: 10,
          left: 12,
          right: 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            child: Text(
                              prodotto.nome,
                              maxLines: 2,
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      Text(
                        prodotto.codice,
                        maxLines: 1,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if ((inListQty ?? 0) > 0)
                        Text(
                          prodotto.minsan,
                          style: const TextStyle(
                            fontSize: 12,
                            color: kBluScuro,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                if ((inListQty ?? 0) > 0)
                  CounterButton(
                    key: ValueKey('list-${prodotto.minsan}'),
                    initialValue: inListQty ?? 0,
                    onChanged: (newValue) {
                      Carrello.instance.aggiornaQuantita(
                        prodotto,
                        newValue,
                      );
                      onQuantityChanged(newValue);
                    },
                  )
                else
                  GestureDetector(
                    onTap: () {
                      final currentNotifier = prodotto.pezzi;
                      final newValue = currentNotifier.value > 0
                          ? currentNotifier.value
                          : 1;
                      currentNotifier.value = newValue;
                      Carrello.instance.aggiungiProdotto(prodotto);
                      onQuantityChanged(newValue);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: kPrimary,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: kPrimary, width: 1),
                      ),
                      child: const Text(
                        kAddToList,
                        style: TextStyle(
                          fontSize: 16,
                          color: kWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(thickness: 1, color: kBluScuro, height: 1),
          ],
        ),
      ),
    );
  }
}
