import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/models/prodotto.dart';
import 'package:pharma_box/widgets/carrello.dart';
import 'package:pharma_box/widgets/counter_button.dart';

class ProdottoCell extends StatelessWidget {
  final Prodotto prodotto;
  final ValueChanged<int> onQuantityChanged;

  const ProdottoCell({
    super.key,
    required this.prodotto,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kBackGround,
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
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                          Text(
                            prodotto.titolo,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(prodotto.minsan),
                    ],
                  ),
                ),
                ValueListenableBuilder<int>(
                  valueListenable: prodotto.pezzi,
                  builder: (context, value, _) {
                    return CounterButton(
                      key: ValueKey(value),  
                      initialValue: value,
                      onChanged: (newValue) {
                        prodotto.pezzi.value = newValue;
                        Carrello.instance.aggiungiProdotto(prodotto);
                        onQuantityChanged(newValue);
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(thickness: 1, color: kBluScuro, height: 1),
          ],
        ),
      ),
    );
  }
}
