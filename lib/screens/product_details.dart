import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/models/prodotto.dart';
import 'package:pharma_box/widgets/counter_button_large.dart';

class ProductDetails extends StatefulWidget {
  const ProductDetails({
    super.key,
    required this.title,
    required this.nrListe,
    required this.prodotto,
  });

  final String title;
  final int nrListe;
  final Prodotto prodotto;

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: false,
        titleSpacing: 24,
        backgroundColor: kBackGround,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // immagine sopra
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.3, // 30% schermo
              width: double.infinity,
              child: Image.asset(kLogo, fit: BoxFit.contain),
            ),
            const SizedBox(height: 16),

            // parte scrollabile
            Expanded(
              child: SingleChildScrollView(
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
                        const Text(
                          kProdottoNonConsentito,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: kRed,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      widget.prodotto.titolo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kBluScuro,
                      ),
                    ),
                    Text(
                      widget.prodotto.minsan,
                      style: const TextStyle(fontSize: 16, color: kBluScuro),
                    ),
                    const SizedBox(height: 8),
                    const Divider(thickness: 1, color: kBluScuro),
                    const SizedBox(height: 8),

                    // sezioni descrizione
                    _buildSection("Descrizione", widget.prodotto.description),
                    _buildSection("Ingredienti", widget.prodotto.ingredients),
                    _buildSection("Modo di uso", widget.prodotto.howToTake),
                  ],
                ),
              ),
            ),

            // bottone fisso in basso
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 24),
              child: CounterButtonLarge(
                initialValue: widget.prodotto.pezzi,
                onChanged: (value) {
                  print("Valore aggiornato: $value");
                  setState(() {
                    widget.prodotto.pezzi = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kBluScuro,
            ),
          ),
          Text(content, style: const TextStyle(fontSize: 16, color: kBluScuro)),
        ],
      ),
    );
  }
}
