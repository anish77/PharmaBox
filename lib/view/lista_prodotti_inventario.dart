import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/models/lotto_confezione.dart';
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
  bool _perScadenza = false;

  /// Alfabetico, oppure prima i prodotti con la scadenza più vicina (quelli
  /// senza scadenza in fondo, in ordine alfabetico)
  List<Prodotto> _ordina(List<Prodotto> prodotti) {
    int perNome(Prodotto a, Prodotto b) =>
        a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
    final ordinati = List<Prodotto>.from(prodotti);
    if (!_perScadenza) return ordinati..sort(perNome);
    final scadenze = {
      for (final p in ordinati) p.minsan: scadenzaPiuVicina(p.lotti.value),
    };
    return ordinati..sort((a, b) {
      final sa = scadenze[a.minsan];
      final sb = scadenze[b.minsan];
      if (sa == null && sb == null) return perNome(a, b);
      if (sa == null) return 1;
      if (sb == null) return -1;
      final c = sa.compareTo(sb);
      return c != 0 ? c : perNome(a, b);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ValueListenableBuilder<List<Prodotto>>(
          valueListenable: Carrello.instance.prodotti,
          builder: (context, prodotti, _) {
            final conScadenze = prodotti.any(
              (p) => scadenzaPiuVicina(p.lotti.value) != null,
            );
            if (!conScadenze) return const SizedBox(height: 8);
            return Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() => _perScadenza = !_perScadenza),
                icon: Icon(
                  _perScadenza ? Icons.event_outlined : Icons.sort_by_alpha,
                  size: 18,
                ),
                label: Text(
                  _perScadenza ? 'Ordinati per scadenza' : 'Ordinati per nome',
                ),
                style: TextButton.styleFrom(foregroundColor: kPrimary),
              ),
            );
          },
        ),
        Expanded(
          child: ValueListenableBuilder<List<Prodotto>>(
            valueListenable: Carrello.instance.prodotti,
            builder: (context, prodotti, _) {
              // Per nome (case-insensitive) o per scadenza più vicina
              final sorted = _ordina(prodotti);
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
                  return Dismissible(
                    key: ValueKey('product-${prodotto.minsan}'),
                    direction: DismissDirection.endToStart,
                    background: const SizedBox.expand(),
                    secondaryBackground: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      color: kRed,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss:
                        (_) async =>
                            await showDialog<bool>(
                              context: context,
                              builder:
                                  (dialogContext) => AlertDialog(
                                    title: const Text('Conferma eliminazione'),
                                    content: Text(
                                      'Vuoi davvero eliminare "${prodotto.nome}" '
                                      'dalla lista?',
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
                                        child: const Text('Elimina'),
                                      ),
                                    ],
                                  ),
                            ) ??
                            false,
                    onDismissed: (_) {
                      Carrello.instance.rimuoviProdotto(prodotto);
                    },
                    child: ValueListenableBuilder<int>(
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
                    ),
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
