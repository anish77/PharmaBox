import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/models/prodotto.dart';

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

      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
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
                  const SizedBox(height: 10),
                  const Divider(thickness: 1, color: kBluScuro, height: 1),
                ],
              ),
            ),

            //Spacer(),
            //Text("Pz. ${prodotto.pezzi}"),
          ],
        ),
      ),
    );
  }
}
