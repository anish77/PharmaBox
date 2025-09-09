import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/models/prodotto.dart';

class ProductDetails extends StatefulWidget {
  const ProductDetails({super.key, required this.title, required this.nrListe});

  final String title;
  final int nrListe;
  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  // Creo il prodotto da aggiungere
  final Prodotto prodotto = Prodotto(
    titolo: 'Prodotto Oki',
    minsan: 'Minsan 123456789',
    imagePath: 'assets/noImage.png',
    pezzi: 1,
    consentito: false,
  );
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: false,
        titleSpacing: 24,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // immagine che prende quasi metà schermo
            Expanded(
              flex: 2, // più grande = prende più spazio
              child: Image.asset(
                kLogo,
                fit: BoxFit.contain, 
                width: double.infinity,
              ),
            ),
            // parte bassa con i testi
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: kRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          kProdottoNonConsentito,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: kRed,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      prodotto.titolo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kBluScuro,
                      ),
                    ),
                    Text(
                      prodotto.minsan,
                      style: const TextStyle(fontSize: 16, color: kBluScuro),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
