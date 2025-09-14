import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/screens/product_details.dart';
import 'package:pharma_box/widgets/carrello.dart';
import 'package:pharma_box/widgets/custom_button.dart';
import 'package:pharma_box/widgets/prodotto_cell.dart';
import 'package:pharma_box/models/prodotto.dart';

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
  /*
  Future<void> _showExportSheet(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.description_outlined, color: kBluScuro),
              title: const Text('Salva come TXT'),
              onTap: () async {
                Navigator.pop(context);
                await _exportAsTxt();
              },
            ),
            ListTile(
              leading: const Icon(Icons.code, color: kBluScuro),
              title: const Text('Salva come XML'),
              onTap: () async {
                Navigator.pop(context);
                await _exportAsXml();
              },
            ),
            ListTile(
              leading: const Icon(Icons.print, color: kBluScuro),
              title: const Text('Condividi / Stampa'),
              onTap: () async {
                Navigator.pop(context);
                await _shareTxt();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportAsTxt() async {
    final prodotti = Carrello.instance.prodotti.value;
    final buffer = StringBuffer()
      ..writeln('Lista: ${widget.titolo}')
      ..writeln('Prodotti: ${prodotti.length}')
      ..writeln('');
    for (final p in prodotti) {
      buffer.writeln('- ${p.titolo} | Minsan: ${p.minsan} | Quantità: ${p.pezzi.value}');
    }
    final file = await _saveContent(buffer.toString(), ext: 'txt');
    _showSavedSnack(file);
  }

  Future<void> _exportAsXml() async {
    final prodotti = Carrello.instance.prodotti.value;
    final buffer = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<lista nome="${_escapeXml(widget.titolo)}" count="${prodotti.length}">');
    for (final p in prodotti) {
      buffer
        ..writeln('  <prodotto>')
        ..writeln('    <titolo>${_escapeXml(p.titolo)}</titolo>')
        ..writeln('    <minsan>${_escapeXml(p.minsan)}</minsan>')
        ..writeln('    <quantita>${p.pezzi.value}</quantita>')
        ..writeln('  </prodotto>');
    }
    buffer.writeln('</lista>');
    final file = await _saveContent(buffer.toString(), ext: 'xml');
    _showSavedSnack(file);
  }

  String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  Future<File> _saveContent(String content, {required String ext}) async {
    final dir = await getApplicationDocumentsDirectory();
    final safeTitle = widget.titolo.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final filename = 'lista_${safeTitle}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content);
    return file;
  }

  Future<void> _shareTxt() async {
    final prodotti = Carrello.instance.prodotti.value;
    final buffer = StringBuffer()
      ..writeln('Lista: ${widget.titolo}')
      ..writeln('Prodotti: ${prodotti.length}')
      ..writeln('');
    for (final p in prodotti) {
      buffer.writeln('- ${p.titolo} | Minsan: ${p.minsan} | Quantità: ${p.pezzi.value}');
    }
    final file = await _saveContent(buffer.toString(), ext: 'txt');
    await Share.shareXFiles([XFile(file.path)], text: 'Lista ${widget.titolo}');
  }

  void _showSavedSnack(File file) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('File salvato: ${file.path}')),
    );
  }*/

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
                (a, b) =>
                    a.titolo.toLowerCase().compareTo(b.titolo.toLowerCase()),
              );
              final bottomInset = MediaQuery.of(context).padding.bottom;
              return ListView.builder(
                padding: EdgeInsets.only(bottom: bottomInset + 45),
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  final prodotto = sorted[index];
                  // print("lista prodotti - ${prodotto.titolo}");
                  return InkWell(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    splashFactory: NoSplash.splashFactory,
                    onTap: () async {
                      setState(() => _highlightedIndex = index);
                      // Mostra l'evidenziazione prima di navigare
                      await Future.delayed(const Duration(milliseconds: 120));
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ProductDetails(
                                title: prodotto.titolo,
                                nrListe: widget.nrListe,
                                prodotto: prodotto,
                                popOnAdd: false,
                              ),
                        ),
                      );
                      if (mounted) setState(() => _highlightedIndex = null);
                    },
                    child: ValueListenableBuilder<int>(
                      valueListenable: prodotto.pezzi,
                      builder: (context, value, _) {
                        return ProdottoCell(
                          prodotto: prodotto,
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
        ),
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 45),
          child: ValueListenableBuilder<List<Prodotto>>(
            valueListenable: Carrello.instance.prodotti,
            builder: (context, prodotti, _) {
              return CustomButton(
                title: kScarica,
                titleColor: kWhite,
                backgroundColor: kPrimary,
                onPressed:
                    () {}, //prodotti.isEmpty ? null : () => _showExportSheet(context),
              );
            },
          ),
        ),
      ],
    );
  }
}
