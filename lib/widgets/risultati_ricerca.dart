import 'package:flutter/material.dart';
import 'package:pharma_box/models/prodotto.dart';
import 'package:pharma_box/widgets/carrello.dart';
import 'package:pharma_box/widgets/prodotto_cell.dart';
import 'package:pharma_box/view/product_details.dart';

class RisultatiRicerca extends StatefulWidget {
  final List<Prodotto> risultati;
  final String listaTitolo;
  final int nrListe;

  const RisultatiRicerca({
    super.key,
    required this.risultati,
    required this.listaTitolo,
    required this.nrListe,
  });

  @override
  State<RisultatiRicerca> createState() => _RisultatiRicercaState();
}

class _RisultatiRicercaState extends State<RisultatiRicerca> {
  int? _highlightedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.risultati.isEmpty) return const SizedBox.shrink();

    // Ordina alfabeticamente per titolo (case-insensitive)
    final sorted = List<Prodotto>.from(widget.risultati)
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sorted.length,
          itemBuilder: (context, index) {
            final prodotto = sorted[index];
            return ValueListenableBuilder<List<Prodotto>>(
              valueListenable: Carrello.instance.prodotti,
              builder: (context, lista, _) {
                final idx = lista.indexWhere(
                  (p) => p.minsan == prodotto.minsan,
                );
                final inListQty = idx >= 0 ? lista[idx].pezzi.value : 0;
                return InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  splashFactory: NoSplash.splashFactory,
                  onTap: () async {
                    setState(() => _highlightedIndex = index);
                    await Future.delayed(const Duration(milliseconds: 120));
                    if (!mounted) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetails(
                          title: prodotto.nome,
                          nrListe: widget.nrListe,
                          prodotto: prodotto,
                          popOnAdd: true,
                        ),
                      ),
                    );
                    if (mounted) setState(() => _highlightedIndex = null);
                  },
                  child: ValueListenableBuilder<int>(
                    valueListenable: prodotto.pezzi,
                    builder: (context, value, __) {
                      return ProdottoCell(
                        prodotto: prodotto,
                        inListQty: inListQty,
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
      ],
    );
  }
}
