import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/models/prodotto.dart';
import 'package:pharma_box/view/product_details.dart';
import 'package:pharma_box/widgets/carrello.dart';
import 'package:pharma_box/widgets/custom_button.dart';
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
              final sorted = List<Prodotto>.from(prodotti)..sort(
                (a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()),
              );
              if (sorted.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: kSecondary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shopping_basket_outlined,
                            size: 48,
                            color: kPrimary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'La lista è vuota',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: kBluScuro,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Scansiona un prodotto o cercalo per aggiungerlo '
                          'alla lista.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: kBluScuro, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final bottomInset = MediaQuery.of(context).padding.bottom;
              return ListView.builder(
                padding: EdgeInsets.only(bottom: bottomInset + 45),
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  final prodotto = sorted[index];
                  // print("lista prodotti - ${prodotto.titolo}");
                  return ValueListenableBuilder<int>(
                    valueListenable: prodotto.pezzi,
                    builder: (context, value, _) {
                      return ProdottoCell(
                        key: ValueKey(prodotto.minsan),
                        prodotto: prodotto,
                        inListQty: value,
                        selected: _highlightedIndex == index,
                        onQuantityChanged: (newValue) {
                          Carrello.instance.aggiornaQuantita(
                            prodotto,
                            newValue,
                          );
                        },
                        onInfoTap: () async {
                          setState(() => _highlightedIndex = index);
                          await Future.delayed(
                            const Duration(milliseconds: 120),
                          );
                          if (context.mounted) {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => ProductDetails(
                                      title: prodotto.nome,
                                      nrListe: widget.nrListe,
                                      prodotto: prodotto,
                                      popOnAdd: false,
                                    ),
                              ),
                            );
                          }
                          if (mounted) {
                            setState(() => _highlightedIndex = null);
                          }
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          left: false,
          right: false,
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 16),
            child: ValueListenableBuilder<List<Prodotto>>(
              valueListenable: Carrello.instance.prodotti,
              builder: (context, prodotti, _) {
                final sorted = List<Prodotto>.from(prodotti)..sort(
                  (a, b) =>
                      a.nome.toLowerCase().compareTo(b.nome.toLowerCase()),
                );
                return CustomButton(
                  title: 'Svuota lista',
                  titleColor: kWhite,
                  backgroundColor: kPrimary,
                  onPressed:
                      sorted.isEmpty
                          ? null
                          : () async {
                            final confirmed =
                                await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (dialogContext) => AlertDialog(
                                        title: const Text(
                                          'Conferma svuotamento',
                                        ),
                                        content: Text(
                                          'Vuoi davvero svuotare la lista '
                                          '"${widget.titolo}"?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  dialogContext,
                                                ).pop(false),
                                            child: const Text('Annulla'),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  dialogContext,
                                                ).pop(true),
                                            child: const Text('Svuota'),
                                          ),
                                        ],
                                      ),
                                ) ??
                                false;

                            if (confirmed && context.mounted) {
                              Carrello.instance.svuotaLista();
                            }
                          },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
