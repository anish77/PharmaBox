import 'package:flutter/material.dart';
import 'package:pharma_box/screens/product_details.dart';
import 'package:pharma_box/widgets/carrello.dart';
import 'package:pharma_box/widgets/prodotto_cell.dart';
import 'package:pharma_box/models/prodotto.dart';

class ListaProdottiInventario extends StatelessWidget {
  const ListaProdottiInventario({
    super.key,
    required this.titolo,
    required this.nrListe,
  });

  final String titolo;
  final int nrListe;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Expanded(
          child: ValueListenableBuilder<List<Prodotto>>(
            valueListenable: Carrello.instance.prodotti,
            builder: (context, prodotti, _) {
              return ListView.builder(
                itemCount: prodotti.length,
                itemBuilder: (context, index) {
                  final prodotto = prodotti[index];
                  // print("lista prodotti - ${prodotto.titolo}");
                  return InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ProductDetails(
                                title: prodotto.titolo,
                                nrListe: nrListe,
                                prodotto: prodotto,
                              ),
                        ),
                      );
                    },
                    child: ValueListenableBuilder<int>(
                      valueListenable: prodotto.pezzi,
                      builder: (context, value, _) {
                        return ProdottoCell(
                          prodotto: prodotto,
                          onQuantityChanged: (newValue) {
                            Carrello.instance.aggiornaQuantita(
                              prodotto,
                              newValue,
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
