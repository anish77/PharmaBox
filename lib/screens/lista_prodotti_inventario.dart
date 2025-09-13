import 'package:flutter/material.dart';
import 'package:pharma_box/screens/product_details.dart';
import 'package:pharma_box/widgets/carrello.dart';
import 'package:pharma_box/widgets/prodotto_cell.dart';
import 'package:pharma_box/models/prodotto.dart';

class ListaProdottiInventario extends StatefulWidget {
  const ListaProdottiInventario({
    super.key,
    required this.titolo,
    required this.nrListe,
  });

  final String titolo;
  final int nrListe;

  @override
  State<ListaProdottiInventario> createState() => _ListaProdottiInventarioState();
}

class _ListaProdottiInventarioState extends State<ListaProdottiInventario> {
  int? _highlightedIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Expanded(
          child: ValueListenableBuilder<List<Prodotto>>(
            valueListenable: Carrello.instance.prodotti,
            builder: (context, prodotti, _) {
              // Ordina alfabeticamente per titolo (case-insensitive)
              final sorted = List<Prodotto>.from(prodotti)
                ..sort((a, b) => a.titolo.toLowerCase().compareTo(b.titolo.toLowerCase()));
              return ListView.builder(
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  final prodotto = sorted[index];
                  // print("lista prodotti - ${prodotto.titolo}");
                  return InkWell(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    splashFactory: NoSplash.splashFactory,
                    onTap: () async {
                      setState(() => _highlightedIndex = index);
                      // Mostra l'evidenziazione prima di navigare
                      await Future.delayed(const Duration(milliseconds: 120));
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetails(
                            title: prodotto.titolo,
                            nrListe: widget.nrListe,
                            prodotto: prodotto,
                            popOnAdd: false,
                          ),
                        ),
                      );
                      if (mounted) setState(() => _highlightedIndex = null);
                    },
                    child: ValueListenableBuilder<int>(
                      valueListenable: prodotto.pezzi,
                      builder: (context, value, _) {
                        return ProdottoCell(
                          prodotto: prodotto,
                          selected: _highlightedIndex == index,
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
