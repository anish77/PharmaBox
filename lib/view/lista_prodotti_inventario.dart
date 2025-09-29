import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/models/prodotto.dart';
import 'package:pharma_box/view/product_details.dart';
import 'package:pharma_box/widgets/carrello.dart';
import 'package:pharma_box/widgets/custom_button.dart';
import 'package:pharma_box/widgets/prodotto_cell.dart';
import 'package:share_plus/share_plus.dart';

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

class _ExportEntry {
  const _ExportEntry({
    required this.name,
    required this.minsan,
    required this.quantity,
  });

  final String name;
  final String minsan;
  final int quantity;
}

class _ListaProdottiInventarioState extends State<ListaProdottiInventario> {
  int? _highlightedIndex;

  Future<void> _showExportSheet(
    BuildContext context,
    List<Prodotto> prodotti,
  ) async {
    final exportItems = prodotti
        .map(
          (prodotto) => _ExportEntry(
            name: prodotto.nome,
            minsan:
                prodotto.codice.isNotEmpty ? prodotto.codice : prodotto.minsan,
            quantity: prodotto.pezzi.value,
          ),
        )
        .toList(growable: false);

    if (exportItems.isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Scarica PDF'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _handleExport(() => _exportAsPdf(exportItems));
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart_outlined),
                title: const Text('Scarica CSV'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _handleExport(() => _exportAsCsv(exportItems));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleExport(Future<void> Function() exporter) async {
    try {
      await exporter();
    } catch (error, stackTrace) {
      debugPrint('Errore esportazione: $error\n$stackTrace');
      if (!mounted) return;
      const snackBar = SnackBar(
        content: Text('Si è verificato un errore durante l\'esportazione.'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _exportAsPdf(List<_ExportEntry> items) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        build:
            (pw.Context context) => [
              pw.Text(
                widget.titolo,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.TableHelper.fromTextArray(
                headers: ['Nome prodotto', 'Minsan', 'Pezzi'],
                data:
                    items
                        .map(
                          (item) => [
                            item.name,
                            item.minsan,
                            item.quantity.toString(),
                          ],
                        )
                        .toList(),
              ),
            ],
      ),
    );

    final bytes = await document.save();
    await _saveAndShare(
      bytes,
      'lista_prodotti.pdf',
      mimeType: 'application/pdf',
    );
  }

  Future<void> _exportAsCsv(List<_ExportEntry> items) async {
    final buffer = StringBuffer()..writeln('Nome prodotto;Minsan;Pezzi');

    for (final item in items) {
      buffer.writeln(
        '${_escapeCsv(item.name)};${_escapeCsv(item.minsan)};${item.quantity}',
      );
    }

    final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
    await _saveAndShare(bytes, 'lista_prodotti.csv', mimeType: 'text/csv');
  }

  String _escapeCsv(String value) {
    if (value.isEmpty) return value;
    final escaped = value.replaceAll('"', '""');
    final needsQuotes =
        value.contains(';') || value.contains('"') || value.contains('\n');
    return needsQuotes ? '"$escaped"' : escaped;
  }

  Future<void> _saveAndShare(
    Uint8List bytes,
    String filename, {
    required String mimeType,
  }) async {
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$filename';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    final xFile = XFile(file.path, mimeType: mimeType, name: filename);

    await SharePlus.instance.share(
      ShareParams(files: [xFile], subject: widget.titolo),
    );
  }

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
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 45),
          child: ValueListenableBuilder<List<Prodotto>>(
            valueListenable: Carrello.instance.prodotti,
            builder: (context, prodotti, _) {
              final sorted = List<Prodotto>.from(prodotti)..sort(
                (a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()),
              );
              return CustomButton(
                title: kScarica,
                titleColor: kWhite,
                backgroundColor: kPrimary,
                onPressed:
                    sorted.isEmpty
                        ? null
                        : () => _showExportSheet(context, sorted),
              );
            },
          ),
        ),
      ],
    );
  }
}
