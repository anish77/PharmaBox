import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/models/prodotto.dart';
import 'package:pharma_box/widgets/carrello.dart';
import 'package:pharma_box/widgets/counter_button_large.dart';
import 'package:pharma_box/widgets/custom_button.dart';

class ProductDetails extends StatefulWidget {
  const ProductDetails({
    super.key,
    required this.title,
    required this.nrListe,
    required this.prodotto,
    this.popOnAdd = false,
  });

  final String title;
  final int nrListe;
  final Prodotto prodotto;
  final bool popOnAdd; // se true, torna indietro dopo "Aggiungi"

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, widget.prodotto);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // immagine sopra
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.3,
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
              child: ValueListenableBuilder<List<Prodotto>>(
                valueListenable: Carrello.instance.prodotti,
                builder: (context, prodotti, _) {
                  final index = prodotti.indexWhere(
                    (p) => p.minsan == widget.prodotto.minsan,
                  );
                  final isInList = index >= 0;

                  if (isInList) {
                    final currentQty = prodotti[index].pezzi.value;
                    return CounterButtonLarge(
                      key: ValueKey(currentQty),
                      initialValue: currentQty,
                      onChanged: (newValue) {
                        // Aggiorna la quantità nel carrello
                        Carrello.instance.aggiornaQuantita(
                          prodotti[index],
                          newValue,
                        );
                      },
                    );
                  }

                  return CustomButton(
                    title: kAddToList,
                    titleColor: kWhite,
                    backgroundColor: kPrimary,
                    onPressed: () {
                      // Se non presente, aggiunge con quantità almeno 1
                      if (widget.prodotto.pezzi.value <= 0) {
                        widget.prodotto.pezzi.value = 1;
                      }
                      Carrello.instance.aggiungiProdotto(widget.prodotto);
                      // Torna indietro automaticamente solo se richiesto
                      if (widget.popOnAdd) {
                        Navigator.pop(context);
                      }
                    },
                  );
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
