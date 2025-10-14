import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/include/general_functions.dart';
import 'package:pharma_box/domain/models/prodotto.dart';
import 'package:pharma_box/domain/repository/carrello.dart';
import 'package:pharma_box/widgets/counter_button_large.dart';
import 'package:pharma_box/widgets/custom_button.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  final bool popOnAdd;

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  late final Future<String?> _imageFuture;
  late final Future<String?> _bugiardinoFuture;
  late final Future<String?> _rendibileFuture;
  late final Future<bool?> _vendibilitaFuture;
  WebViewController? _bugiardinoController;
  String? _bugiardinoUrl;
  double _bugiardinoHeight = 400;

  final carrello = CarrelloIsar.instance;

  @override
  void initState() {
    super.initState();
    _imageFuture = _loadImage();
    _bugiardinoFuture = _loadBugiardino();
    _rendibileFuture = _loadRendibilita();
    _vendibilitaFuture = _loadVendibilita();
  }

  Future<String?> _loadImage() async {
    final existing = widget.prodotto.immagine;
    if (existing.isNotEmpty && existing.startsWith('http')) {
      return existing;
    }
    try {
      final codice = widget.prodotto.codice.isNotEmpty
          ? widget.prodotto.codice
          : widget.prodotto.minsan;
      if (codice.isEmpty) return null;
      return await getOrPutImage(codice);
    } catch (error) {
      debugPrint('Errore durante il recupero immagine: $error');
      return null;
    }
  }

  Future<String?> _loadRendibilita() async {
    final codice = widget.prodotto.codice.isNotEmpty
        ? widget.prodotto.codice
        : widget.prodotto.minsan;
    if (codice.isEmpty) return null;

    try {
      final descrizione = await loadRendibilita(codice);
      return descrizione?.trim().isEmpty ?? true ? null : descrizione?.trim();
    } catch (error) {
      debugPrint('Errore durante il recupero rendibilita: $error');
      return null;
    }
  }

  Future<bool?> _loadVendibilita() async {
    final codice = widget.prodotto.codice.isNotEmpty
        ? widget.prodotto.codice
        : widget.prodotto.minsan;
    if (codice.isEmpty) return null;

    try {
      if (widget.prodotto.vendibile != 0) {
        return isBit(widget.prodotto.vendibile, kBitProdottoVendibile);
      }
      final vendibile = await loadVendibilita(codice);
      if (vendibile == null) return null;

      widget.prodotto.vendibile = setBit(
        widget.prodotto.vendibile,
        vendibile ? kBitProdottoVendibile : kBitProdottoNonVendibile,
      );
      return vendibile;
    } catch (error) {
      debugPrint('Errore durante il recupero vendibilita: $error');
      return null;
    }
  }

  Future<String?> _loadBugiardino() async {
    final codice = widget.prodotto.codice.isNotEmpty
        ? widget.prodotto.codice
        : widget.prodotto.minsan;
    if (codice.isEmpty) return null;

    try {
      final url = await getBugiardino(codice, widget.prodotto.tipoProdottoDettaglio);
      return url?.trim().isEmpty ?? true ? null : url?.trim();
    } catch (error) {
      debugPrint('Errore durante il recupero bugiardino: $error');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final prodotto = widget.prodotto;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dettaglio"),
        centerTitle: false,
        backgroundColor: kBackGround,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, prodotto),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // immagine
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.3,
              width: double.infinity,
              child: FutureBuilder<String?>(
                future: _imageFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final imageUrl = snapshot.data;
                  if (imageUrl != null && imageUrl.isNotEmpty) {
                    return Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Image.asset(_fallbackAsset(), fit: BoxFit.contain),
                    );
                  }
                  return Image.asset(_fallbackAsset(), fit: BoxFit.contain);
                },
              ),
            ),
            const SizedBox(height: 16),

            // parte testuale
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<bool?>(
                      future: _vendibilitaFuture,
                      builder: (context, snapshot) {
                        final isDone = snapshot.connectionState == ConnectionState.done;
                        final hasError = snapshot.hasError;
                        final isVendibile = snapshot.data == true;
                        final showAlert = hasError || (isDone && !isVendibile);

                        if (!showAlert) return const SizedBox.shrink();
                        return Row(
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
                        );
                      },
                    ),
                    Text(
                      prodotto.nome,
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
                    if ((prodotto.tipoProdotto ?? '').isNotEmpty)
                      Text(
                        prodotto.tipoProdotto!,
                        style: const TextStyle(fontSize: 13, color: kBluScuro),
                      ),
                    const SizedBox(height: 8),
                    const Divider(thickness: 1, color: kBluScuro),
                    const SizedBox(height: 8),
                    _buildSection("Foglietto illustrativo", _buildDescrizioneContent()),
                  ],
                ),
              ),
            ),

            // bottone fisso in basso
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 24),
              child: ValueListenableBuilder<List<Prodotto>>(
                valueListenable: carrello.prodotti,
                builder: (context, prodotti, _) {
                  final index = prodotti.indexWhere((p) => p.minsan == prodotto.minsan);
                  final isInList = index >= 0;

                  if (isInList) {
                    final currentQty = prodotti[index].pezzi.value;
                    return CounterButtonLarge(
                      key: ValueKey(currentQty),
                      initialValue: currentQty,
                      onChanged: (newValue) async {
                        await carrello.aggiornaQuantita(prodotti[index], newValue);
                      },
                    );
                  }

                  return CustomButton(
                    title: kAddToList,
                    titleColor: kWhite,
                    backgroundColor: kPrimary,
                    onPressed: () async {
                      if (prodotto.pezzi.value <= 0) prodotto.pezzi.value = 1;
                      await carrello.aggiungiProdotto(prodotto);
                      if (widget.popOnAdd) Navigator.pop(context);
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

  Widget _buildDescrizioneContent() {
    const textStyle = TextStyle(fontSize: 16, color: kBluScuro);

    return FutureBuilder<String?>(
      future: _bugiardinoFuture,
      builder: (context, snapshot) {
        final fallback = Text(
          widget.prodotto.description.isNotEmpty
              ? widget.prodotto.description
              : 'Descrizione non disponibile',
          style: textStyle,
        );

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              const SizedBox(height: 12),
              fallback,
            ],
          );
        }

        final url = snapshot.data;
        if (url != null && url.isNotEmpty) {
          _ensureWebViewController(url);
          if (_bugiardinoController == null) return fallback;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: _bugiardinoHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: WebViewWidget(controller: _bugiardinoController!),
                ),
              ),
              const SizedBox(height: 12),
              fallback,
            ],
          );
        }

        return fallback;
      },
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kBluScuro)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  String _fallbackAsset() {
    final image = widget.prodotto.immagine;
    if (image.isNotEmpty && !image.startsWith('http')) return image;
    return kNoImage;
  }

  void _ensureWebViewController(String url) {
    final normalizedUrl = url.trim();
    if (_bugiardinoUrl == normalizedUrl && _bugiardinoController != null) {
      return;
    }

    final uri = Uri.tryParse(normalizedUrl);
    if (uri == null) {
      _bugiardinoController = null;
      _bugiardinoUrl = null;
      return;
    }

    final controller = WebViewController();
    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    controller.setBackgroundColor(Colors.transparent);
    controller.setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (finishedUrl) async {
          try {
            await controller.runJavaScript(
              "(function(){var m=document.querySelector('meta[name=viewport]'); if(!m){m=document.createElement('meta'); m.name='viewport'; m.content='width=device-width, initial-scale=1.0'; document.head.appendChild(m);} })();",
            );
            final result = await controller.runJavaScriptReturningResult(
              'Math.max(document.body.scrollHeight, document.documentElement.scrollHeight)',
            );
            if (mounted) {
              setState(() => _bugiardinoHeight = (double.tryParse(result.toString()) ?? 400).clamp(400, 2000));
            }
          } catch (_) {}
        },
      ),
    );
    controller.loadRequest(uri);

    _bugiardinoController = controller;
    _bugiardinoUrl = normalizedUrl;
  }
}
