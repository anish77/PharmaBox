import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/models/prodotto.dart';
import 'package:pharma_box/widgets/carrello.dart';
import 'package:pharma_box/widgets/prodotto_cell.dart';

class RisultatiRicerca extends StatelessWidget {
  final List<Prodotto> risultati;

  const RisultatiRicerca({
    super.key,
    required this.risultati,
  });

  @override
  Widget build(BuildContext context) {
    if (risultati.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const Divider(thickness: 1, color: kBluScuro),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: risultati.length,
          itemBuilder: (context, index) {
            final prodotto = risultati[index];
            return ValueListenableBuilder<List<Prodotto>>(
              valueListenable: Carrello.instance.prodotti,
              builder: (context, lista, _) {
                final idx = lista.indexWhere((p) => p.minsan == prodotto.minsan);
                final inListQty = idx >= 0 ? lista[idx].pezzi.value : 0;
                return ValueListenableBuilder<int>(
                  valueListenable: prodotto.pezzi,
                  builder: (context, value, __) {
                    return ProdottoCell(
                      prodotto: prodotto,
                      inListQty: inListQty,
                      onQuantityChanged: (newValue) {
                        Carrello.instance.aggiornaQuantita(
                          prodotto,
                          newValue,
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}
