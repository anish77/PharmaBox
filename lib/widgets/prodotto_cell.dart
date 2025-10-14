import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/include/general_functions.dart';
import 'package:pharma_box/domain/models/prodotto.dart';
import 'package:pharma_box/domain/repository/carrello.dart';
import 'package:pharma_box/widgets/counter_button.dart';

const double _titleFontSize = 14.0;
const double _titleLineHeight = 1.3;
const double _twoLineTitleHeight = _titleFontSize * _titleLineHeight * 2;
const TextStyle _titleStyle = TextStyle(
  fontSize: _titleFontSize,
  fontWeight: FontWeight.bold,
  height: _titleLineHeight,
  color: kBluScuro,
);

class ProdottoCell extends StatefulWidget {
  final Prodotto prodotto;
  final ValueChanged<int> onQuantityChanged;
  final bool selected;
  final int? inListQty;
  final VoidCallback? onInfoTap;

  const ProdottoCell({
    super.key,
    required this.prodotto,
    required this.onQuantityChanged,
    this.selected = false,
    this.inListQty,
    this.onInfoTap,
  });

  @override
  State<ProdottoCell> createState() => _ProdottoCellState();
}

class _ProdottoCellState extends State<ProdottoCell> {
  late final Future<bool?> _vendibilitaFuture;
  final carrello = CarrelloIsar.instance;

  @override
  void initState() {
    super.initState();
    _vendibilitaFuture = _loadVendibilita();
  }

  Future<bool?> _loadVendibilita() async {
    final codice = widget.prodotto.codice.isNotEmpty
        ? widget.prodotto.codice
        : widget.prodotto.minsan;
    if (codice.isEmpty) return null;

    try {
      return await loadVendibilita(codice);
    } catch (error) {
      debugPrint('Errore durante il recupero dei dati vendibilita: $error');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mostraQuantita = (widget.inListQty ?? 0) > 0;
    final codiceDaMostrare = widget.prodotto.codice.isNotEmpty
        ? widget.prodotto.codice
        : widget.prodotto.minsan;

    const actionWidth = 120.0;
    const actionHeight = 40.0;

    return Card(
      color: widget.selected ? kYellow : kBackGround,
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: widget.onInfoTap,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    splashFactory: NoSplash.splashFactory,
                    child: FutureBuilder<bool?>(
                      future: _vendibilitaFuture,
                      builder: (context, snapshot) {
                        final isDone =
                            snapshot.connectionState == ConnectionState.done;
                        final hasError = snapshot.hasError;
                        final isVendibile = snapshot.data == true;

                        bool showAlert = false;
                        if (hasError) {
                          showAlert = true;
                        } else if (isDone) {
                          showAlert = !isVendibile;
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (showAlert)
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
                            if (showAlert) const SizedBox(height: 8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                minHeight: _twoLineTitleHeight,
                              ),
                              child: Text(
                                widget.prodotto.nome,
                                maxLines: 2,
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                                style: _titleStyle,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              codiceDaMostrare,
                              maxLines: 1,
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: kBluScuro),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: SizedBox(
                    width: actionWidth,
                    child: mostraQuantita
                        ? CounterButton(
                            key: ValueKey(
                                'list-${widget.prodotto.minsan}-${widget.inListQty ?? 0}'),
                            initialValue: widget.inListQty ?? 0,
                            height: actionHeight,
                            width: actionWidth,
                            onChanged: (newValue) async {
                              await carrello.aggiornaQuantita(
                                widget.prodotto,
                                newValue,
                              );
                              widget.onQuantityChanged(newValue);
                            },
                          )
                        : GestureDetector(
                            onTap: () async {
                              final currentNotifier = widget.prodotto.pezzi;
                              final newValue =
                                  currentNotifier.value > 0
                                      ? currentNotifier.value
                                      : 1;
                              currentNotifier.value = newValue;
                              await carrello.aggiungiProdotto(widget.prodotto);
                              widget.onQuantityChanged(newValue);
                            },
                            child: SizedBox(
                              height: actionHeight,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: kPrimary,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: kPrimary,
                                    width: 1,
                                  ),
                                ),
                                child: const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 6,
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        kAddToList,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: kWhite,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(thickness: 1, color: kBluScuro, height: 1),
          ],
        ),
      ),
    );
  }
}
