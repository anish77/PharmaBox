import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/include/general_functions.dart';
import 'package:pharma_box/models/prodotto.dart';
import 'package:pharma_box/widgets/carrello.dart';
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
  final bool popOnAdd; // se true, torna indietro dopo "Aggiungi"

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  late final Future<String?> _imageFuture;
  late final Future<String?> _bugiardinoFuture;
  WebViewController? _bugiardinoController;
  String? _bugiardinoUrl;
  double _bugiardinoHeight = 400;

  @override
  void initState() {
    super.initState();
    _imageFuture = _loadImage();
    _bugiardinoFuture = _loadBugiardino();
  }

  Future<String?> _loadImage() async {
    final existing = widget.prodotto.immagine;
    if (existing.isNotEmpty && existing.startsWith('http')) {
      return existing;
    }

    try {
      final codice =
          widget.prodotto.codice.isNotEmpty
              ? widget.prodotto.codice
              : widget.prodotto.minsan;
      if (codice.isEmpty) return null;
      return await getOrPutImage(codice);
    } catch (error) {
      debugPrint('Errore durante il recupero immagine: $error');
      return null;
    }
  }

  Future<String?> _loadBugiardino() async {
    final codice =
        widget.prodotto.codice.isNotEmpty
            ? widget.prodotto.codice
            : widget.prodotto.minsan;
    if (codice.isEmpty) return null;

    try {
      print(widget.prodotto.tipo_prodotto);
      final url = await getBugiardino(
        codice,
        widget.prodotto.tipo_prodotto_dettaglio,
      );
      if (url == null || url.isEmpty) {
        return null;
      }
      return url.trim();
    } catch (error) {
      debugPrint('Errore durante il recupero bugiardino: $error');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dettaglio"),
        centerTitle: false,
        titleSpacing: 2,
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
                      errorBuilder: (context, error, stackTrace) {
                        final fallbackAsset = _fallbackAsset();
                        return Image.asset(fallbackAsset, fit: BoxFit.contain);
                      },
                    );
                  }

                  final fallbackAsset = _fallbackAsset();
                  return Image.asset(fallbackAsset, fit: BoxFit.contain);
                },
              ),
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
                      widget.prodotto.nome,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kBluScuro,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          widget.prodotto.minsan,
                          style: const TextStyle(
                            fontSize: 16,
                            color: kBluScuro,
                          ),
                        ),
                      ],
                    ),

                    if ((widget.prodotto.tipo_prodotto ?? '').isNotEmpty)
                      Text(
                        widget.prodotto.tipo_prodotto!,
                        style: const TextStyle(fontSize: 13, color: kBluScuro),
                        softWrap: true,
                        textAlign: TextAlign.right,
                      ),

                    const SizedBox(height: 8),
                    const Divider(thickness: 1, color: kBluScuro),
                    const SizedBox(height: 8),

                    // sezioni descrizione
                    _buildSection(
                      "Foglietto illustrativo",
                      _buildDescrizioneContent(),
                    ),
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

        if (snapshot.hasError) {
          return fallback;
        }

        final url = snapshot.data;
        if (url != null && url.isNotEmpty) {
          _ensureWebViewController(url);
          if (_bugiardinoController == null) {
            return fallback;
          }
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kBluScuro,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  String _fallbackAsset() {
    final image = widget.prodotto.immagine;
    if (image.isNotEmpty && !image.startsWith('http')) {
      return image;
    }
    return kNoImage;
  }

  void _ensureWebViewController(String url) {
    final normalizedUrl = _normalizeBugiardinoUrl(url);
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
        onNavigationRequest: (request) {
          return NavigationDecision.navigate;
        },
        onWebResourceError: (error) {
          final originalUri = Uri.tryParse(url);
          if (originalUri != null && originalUri.scheme == 'http') {
            _bugiardinoController?.loadRequest(originalUri);
          }
        },
        onPageFinished: (finishedUrl) async {
          try {
            // Assicura viewport mobile per evitare testo/raster troppo piccolo
            await controller.runJavaScript(
              "(function(){var m=document.querySelector('meta[name=viewport]'); if(!m){m=document.createElement('meta'); m.name='viewport'; m.content='width=device-width, initial-scale=1.0, maximum-scale=1.0'; document.head.appendChild(m);} })();",
            );

            // Forza background bianco e migliora leggibilità (font-size, immagini responsive)
            await controller.runJavaScript(
              "(function(){var css='html,body{background:transparent !important;color:#111;min-height:100vh;}'+" +
                  "'body{margin:0;padding:12px;font-size:16px;line-height:1.5;-webkit-text-size-adjust:110%;text-size-adjust:110%;}'+" +
                  "'img,iframe,video{max-width:100% !important;height:auto !important;}table{width:100% !important;overflow:auto;}';" +
                  "var s=document.createElement('style');s.type='text/css';s.appendChild(document.createTextNode(css));document.head.appendChild(s);document.documentElement.style.background='transparent';document.body.style.background='transparent';})();",
            );
            // Calcola l'altezza del contenuto della pagina
            final result = await controller.runJavaScriptReturningResult(
              'Math.max(document.body.scrollHeight, document.documentElement.scrollHeight)',
            );
            double? newHeight;
            if (result is num) {
              newHeight = result.toDouble();
            } else if (result is String) {
              final sanitized = result.replaceAll('"', '');
              newHeight = double.tryParse(sanitized);
            }
            if (newHeight != null && mounted) {
              final h = newHeight;
              setState(() {
                // Imposta altezza minima 400, senza limite superiore per mostrare tutto
                _bugiardinoHeight = h < 400.0 ? 400.0 : h;
              });
            }
          } catch (_) {
            // Se fallisce, mantieni l'altezza corrente
          }
        },
      ),
    );
    controller.loadRequest(uri);

    _bugiardinoController = controller;
    _bugiardinoUrl = normalizedUrl;
  }

  String _normalizeBugiardinoUrl(String url) {
    // Non forzare più https: usa l'URL così com'è (ripulito)
    return url.trim();
  }
}
