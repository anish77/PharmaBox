import 'package:flutter/material.dart';
import 'package:pharma_box/screens/product_details.dart';
import 'package:pharma_box/widgets/carrello.dart';
import 'package:pharma_box/models/prodotto.dart';
import 'package:pharma_box/widgets/prodotto_cell.dart';

class ListaProdottiInventario extends StatefulWidget {
  const ListaProdottiInventario({
    super.key,
    required this.titolo,
    required this.nrListe,
  });
  final String titolo;
  final int nrListe;

  @override
  State<ListaProdottiInventario> createState() =>
      _ListaProdottiInventarioState();
}

class _ListaProdottiInventarioState extends State<ListaProdottiInventario> {
  final prodotti = Carrello.instance.prodotti;

  void aggiornaQuantita(int index, int newQuantity) {
    setState(() {
      if (newQuantity <= 0) {
        prodotti.removeAt(index);
      } else {
        prodotti[index] = Prodotto(
          titolo: prodotti[index].titolo,
          minsan: prodotti[index].minsan,
          imagePath: prodotti[index].imagePath,
          pezzi: newQuantity,
          consentito: prodotti[index].consentito,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: prodotti.length,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ProductDetails(
                            title: widget.titolo,
                            nrListe: widget.nrListe,
                          ),
                    ),
                  );
                },
                child: ProdottoCell(
                  prodotto: prodotti[index],
                  onQuantityChanged: (value) => aggiornaQuantita(index, value),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
