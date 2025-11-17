import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/web.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/view/info.dart';
import 'package:pharma_box/view/invita_un_amico.dart';
import 'package:pharma_box/view/selected_list_page.dart';
import 'package:pharma_box/view/stato_inviti.dart';
import 'package:pharma_box/widgets/carrello.dart';
import 'package:pharma_box/widgets/crea_lista_popup.dart';
import 'package:pharma_box/widgets/custom_button.dart';
import 'package:pharma_box/widgets/log_out_popup.dart';
import 'package:share_plus/share_plus.dart';

class CreaNuovaLista extends StatefulWidget {
  const CreaNuovaLista({super.key});

  @override
  State<CreaNuovaLista> createState() => _CreaNuovaListaState();
}

class _ListaViewData {
  const _ListaViewData({required this.nome, required this.totalePezzi});

  final String nome;
  final int totalePezzi;
}

class _ListExportData {
  const _ListExportData({required this.nome, required this.items});

  final String nome;
  final List<_ListExportItem> items;
}

class _ListExportItem {
  const _ListExportItem({
    required this.nome,
    required this.minsan,
    required this.quantity,
  });

  final String nome;
  final String minsan;
  final int quantity;
}

class _CreaNuovaListaState extends State<CreaNuovaLista> {
  final Logger _logger = Logger(printer: PrettyPrinter());
  final Set<String> _checkedLists = <String>{};
  int? selectedIndex;
  String referralCode = '';

  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _caricaReferralCode();
  }

  Future<void> _caricaReferralCode() async {
    final uid = _currentUid;
    if (uid == null) {
      _logger.w('_caricaReferralCode invocato senza utente autenticato');
      return;
    }

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!snapshot.exists) return;

      final rawCode = snapshot.data()?['codiceInvito'];
      final codice = rawCode is String ? rawCode : rawCode?.toString() ?? '';

      if (!mounted) return;
      setState(() => referralCode = codice);
    } catch (error, stackTrace) {
      _logger.e(
        'Errore nel recupero del codice invito: $error',
        stackTrace: stackTrace,
      );
    }
  }

  Stream<List<_ListaViewData>> getListeStream() {
    final uid = _currentUid;
    if (uid == null) {
      _logger.w('getListeStream invocato senza utente autenticato');
      return Stream<List<_ListaViewData>>.value(const []);
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return const <_ListaViewData>[];
          final rawListe = List<Map<String, dynamic>>.from(
            doc.data()?['liste'] ?? [],
          );
          return rawListe
              .map((lista) {
                final nome = (lista['nomeLista'] ?? '').toString();
                if (nome.isEmpty) return null;
                final totaleItems = _sommaQuantita(lista['items']);
                final totaleProdotti = _sommaQuantita(lista['prodotti']);
                final totale = totaleItems > 0 ? totaleItems : totaleProdotti;
                return _ListaViewData(nome: nome, totalePezzi: totale);
              })
              .whereType<_ListaViewData>()
              .toList(growable: false);
        });
  }

  int _sommaQuantita(dynamic rawItems) {
    if (rawItems is Iterable) {
      var totale = 0;
      for (final element in rawItems) {
        if (element is Map) {
          final map = element.map(
            (key, value) => MapEntry(key.toString(), value),
          );
          final quantity =
              map['quantity'] ??
              map['qty'] ??
              map['pezzi'] ??
              map['quantita'] ??
              map['qta'];
          totale += _parseQuantity(quantity);
        }
      }
      return totale;
    }
    return 0;
  }

  List<Map<String, dynamic>> _normalizeEntries(dynamic rawEntries) {
    if (rawEntries is Iterable) {
      return rawEntries
          .whereType<Map>()
          .map(
            (element) =>
                element.map((key, value) => MapEntry(key.toString(), value)),
          )
          .toList(growable: false);
    }
    return <Map<String, dynamic>>[];
  }

  int _parseQuantity(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Future<void> eliminaLista(String nomeLista) async {
    final uid = _currentUid;
    if (uid == null) {
      _logger.w('eliminaLista invocato senza utente autenticato');
      return;
    }

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!doc.exists) return;

    final rawListe = doc.data()?['liste'] ?? [];
    final liste = List<Map<String, dynamic>>.from(rawListe);
    final target = liste.firstWhere(
      (lista) => lista['nomeLista'] == nomeLista,
      orElse: () => <String, dynamic>{},
    );

    if (target.isEmpty) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'liste': FieldValue.arrayRemove([target]),
    });
  }

  Future<void> _scaricaListeSelezionate() async {
    if (_checkedLists.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona almeno una lista.')),
      );
      return;
    }

    final uid = _currentUid;
    if (uid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Effettua il login per scaricare le liste.'),
        ),
      );
      return;
    }

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!snapshot.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossibile recuperare le liste selezionate.'),
          ),
        );
        return;
      }

      final rawListe = List<Map<String, dynamic>>.from(
        snapshot.data()?['liste'] ?? [],
      );
      final exportListe = <_ListExportData>[];

      for (final rawLista in rawListe) {
        final nome = (rawLista['nomeLista'] ?? '').toString();
        if (!_checkedLists.contains(nome)) continue;

        var entries = _normalizeEntries(rawLista['items']);
        if (entries.isEmpty) entries = _normalizeEntries(rawLista['prodotti']);

        final items = entries
            .map((entry) {
              final rawNome =
                  entry['titolo'] ??
                  entry['title'] ??
                  entry['name'] ??
                  entry['nome'] ??
                  entry['description'] ??
                  '';
              final minsan = (entry['minsan'] ?? entry['id'] ?? '').toString();
              final quantity = _parseQuantity(
                entry['quantity'] ??
                    entry['qty'] ??
                    entry['pezzi'] ??
                    entry['quantita'] ??
                    entry['qta'],
              );
              return _ListExportItem(
                nome: rawNome.toString(),
                minsan: minsan,
                quantity: quantity,
              );
            })
            .where((item) => item.nome.isNotEmpty || item.minsan.isNotEmpty)
            .toList(growable: false);

        exportListe.add(_ListExportData(nome: nome, items: items));
      }

      if (exportListe.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nessuna lista selezionata disponibile.'),
          ),
        );
        return;
      }

      final hasItems = exportListe.any((lista) => lista.items.isNotEmpty);
      if (!hasItems) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le liste selezionate non contengono prodotti.'),
          ),
        );
        return;
      }

      if (!mounted) return;
      await _showExportSheet(exportListe);
    } catch (error, stackTrace) {
      _logger.e(
        'Errore nel preparare lo scaricamento delle liste: $error',
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Errore durante la preparazione delle liste selezionate.',
          ),
        ),
      );
    }
  }

  Future<void> _showExportSheet(List<_ListExportData> liste) async {
    if (!mounted) return;

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
                  await _handleExport(() => _exportListeAsPdf(liste));
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart_outlined),
                title: const Text('Scarica CSV'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _handleExport(() => _exportListeAsCsv(liste));
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
      _logger.e(
        'Errore durante l\'esportazione delle liste selezionate: $error',
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Si è verificato un errore durante l\'esportazione.'),
        ),
      );
    }
  }

  Future<void> _exportListeAsPdf(List<_ListExportData> liste) async {
    final document = pw.Document();
    final fontRegular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
    );
    final fontBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
    );

    document.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        build: (context) {
          final widgets = <pw.Widget>[
            pw.Text(
              'Liste selezionate',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),
          ];

          for (final lista in liste) {
            widgets.add(
              pw.Text(
                lista.nome,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
            widgets.add(pw.SizedBox(height: 8));

            if (lista.items.isEmpty) {
              widgets.add(
                pw.Text(
                  'Nessun prodotto nella lista',
                  style: pw.TextStyle(fontSize: 12),
                ),
              );
            } else {
              widgets.add(
                pw.TableHelper.fromTextArray(
                  headers: ['Nome prodotto', 'Minsan', 'Pezzi'],
                  data:
                      lista.items
                          .map(
                            (item) => [
                              item.nome,
                              item.minsan,
                              item.quantity.toString(),
                            ],
                          )
                          .toList(),
                ),
              );
            }

            widgets.add(pw.SizedBox(height: 16));
          }

          return widgets;
        },
      ),
    );

    final bytes = await document.save();
    await _saveAndShare(
      bytes,
      'liste_selezionate.pdf',
      mimeType: 'application/pdf',
    );
  }

  Future<void> _exportListeAsCsv(List<_ListExportData> liste) async {
    final buffer = StringBuffer()..writeln('Lista;Nome prodotto;Minsan;Pezzi');

    for (final lista in liste) {
      if (lista.items.isEmpty) {
        buffer.writeln('${_escapeCsv(lista.nome)};Nessun prodotto;;');
        continue;
      }
      for (final item in lista.items) {
        buffer.writeln(
          '${_escapeCsv(lista.nome)};${_escapeCsv(item.nome)};${_escapeCsv(item.minsan)};${item.quantity}',
        );
      }
    }

    final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
    await _saveAndShare(bytes, 'liste_selezionate.csv', mimeType: 'text/csv');
  }

  Future<void> _saveAndShare(
    Uint8List bytes,
    String filename, {
    required String mimeType,
  }) async {
    // Mostra il loader a schermo intero
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder:
          (_) =>
              const Center(child: CircularProgressIndicator(color: kPrimary)),
    );

    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$filename';
      final file = File(filePath);

      // Scrivi il file
      await file.writeAsBytes(bytes, flush: true);
      await Future.delayed(const Duration(milliseconds: 300)); // per sicurezza

      final xFile = XFile(file.path, mimeType: mimeType, name: filename);

      // Chiudi il loader PRIMA di aprire la share sheet
      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      // Apri la Share Sheet
      await Share.shareXFiles(
        [xFile],
        subject: 'Liste selezionate',
        text: 'Ecco le liste esportate da PharmaBox.',
      );

      // (opzionale) elimina dopo qualche secondo
      Future.delayed(const Duration(seconds: 10), () async {
        if (await file.exists()) await file.delete();
      });
    } catch (error, stack) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // chiudi loader
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore durante la condivisione.')),
        );
      }
      debugPrint('Errore share: $error\n$stack');
    }
  }

  String _escapeCsv(String value) {
    if (value.isEmpty) return value;
    final escaped = value.replaceAll('"', '""');
    final needsQuotes =
        value.contains(';') || value.contains('"') || value.contains('\n');
    return needsQuotes ? '"$escaped"' : value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        scrolledUnderElevation: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Row(
            children: [
              Image.asset(kLogo, height: 25, width: 25),
              const SizedBox(width: 8),
              const Text(
                kAppName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kPrimary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          Builder(
            builder:
                (context) => IconButton(
                  icon: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Icon(Icons.menu, color: kPrimary),
                  ),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: kPrimary),
              child: const Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.group_add, color: kPrimary),
              title: const Text(
                'Invita un amico',
                style: TextStyle(color: kBluScuro),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            InvitaUnAmicoPage(referralCode: referralCode),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.leaderboard, color: kPrimary),
              title: const Text(
                'Stato inviti',
                style: TextStyle(color: kBluScuro),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StatoInvitiPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info, color: kPrimary),
              title: const Text('Info', style: TextStyle(color: kBluScuro)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InfoPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: kRed),
              title: const Text(
                'Log out',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: kRed,
                ),
              ),
              onTap: () => LogoutPopup().showLogout(context),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                color: kSecondary,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Liste',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kBluScuro,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.addchart_outlined,
                        color: kBluScuro,
                        size: 35,
                      ),
                      tooltip: 'Crea nuova lista',
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => CreaListaPopup().showPopup(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (safeContext) {
                    return StreamBuilder<List<_ListaViewData>>(
                      stream: getListeStream(),
                      builder: (context, snapshot) {
                        final liste = snapshot.data ?? const <_ListaViewData>[];
                        final totaleGlobal = liste.fold<int>(
                          0,
                          (soma, entry) => soma + entry.totalePezzi,
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child:
                                  liste.isEmpty
                                      ? const Center(
                                        child: Text(
                                          'Nessuna lista disponibile',
                                        ),
                                      )
                                      : ListView.builder(
                                        itemCount: liste.length,
                                        itemBuilder: (context, index) {
                                          final entry = liste[index];
                                          final nomeLista = entry.nome;
                                          final totalePezzi = entry.totalePezzi;
                                          final isSelected =
                                              selectedIndex == index;
                                          final isChecked = _checkedLists
                                              .contains(nomeLista);

                                          return Dismissible(
                                            key: Key(nomeLista),
                                            direction:
                                                DismissDirection.horizontal,
                                            background: Container(
                                              alignment: Alignment.centerLeft,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 20,
                                                  ),
                                              color: Colors.green,
                                              child: const Icon(
                                                Icons.edit,
                                                color: Colors.white,
                                              ),
                                            ),
                                            secondaryBackground: Container(
                                              alignment: Alignment.centerRight,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 20,
                                                  ),
                                              color: Colors.red,
                                              child: const Icon(
                                                Icons.delete,
                                                color: Colors.white,
                                              ),
                                            ),
                                            confirmDismiss: (direction) async {
                                              if (direction ==
                                                  DismissDirection.startToEnd) {
                                                final controller =
                                                    TextEditingController(
                                                      text: nomeLista,
                                                    );
                                                final nuovoNome = await showDialog<
                                                  String
                                                >(
                                                  context: context,
                                                  builder:
                                                      (context) => AlertDialog(
                                                        title: const Text(
                                                          'Modifica nome lista',
                                                        ),
                                                        content: TextField(
                                                          controller:
                                                              controller,
                                                          decoration:
                                                              const InputDecoration(
                                                                labelText:
                                                                    'Nuovo nome',
                                                              ),
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed:
                                                                () =>
                                                                    Navigator.of(
                                                                      context,
                                                                    ).pop(null),
                                                            child: const Text(
                                                              'Annulla',
                                                            ),
                                                          ),
                                                          TextButton(
                                                            onPressed:
                                                                () => Navigator.of(
                                                                  context,
                                                                ).pop(
                                                                  controller
                                                                      .text
                                                                      .trim(),
                                                                ),
                                                            child: const Text(
                                                              'Salva',
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                );

                                                if (nuovoNome != null &&
                                                    nuovoNome.isNotEmpty) {
                                                  final currentUid =
                                                      _currentUid;
                                                  if (currentUid == null &&
                                                      context.mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Effettua il login per modificare le liste',
                                                        ),
                                                      ),
                                                    );
                                                    return false;
                                                  }

                                                  final docRef =
                                                      FirebaseFirestore.instance
                                                          .collection('users')
                                                          .doc(currentUid);
                                                  final doc =
                                                      await docRef.get();
                                                  if (doc.exists) {
                                                    final data = doc.data()!;
                                                    final liste = List<
                                                      Map<String, dynamic>
                                                    >.from(data['liste'] ?? []);
                                                    final indexLista = liste
                                                        .indexWhere(
                                                          (lista) =>
                                                              lista['nomeLista'] ==
                                                              nomeLista,
                                                        );

                                                    if (indexLista >= 0) {
                                                      final wasChecked =
                                                          _checkedLists.remove(
                                                            nomeLista,
                                                          );
                                                      liste[indexLista]['nomeLista'] =
                                                          nuovoNome;
                                                      await docRef.update({
                                                        'liste': liste,
                                                      });
                                                      if (wasChecked &&
                                                          mounted) {
                                                        setState(() {
                                                          _checkedLists.add(
                                                            nuovoNome,
                                                          );
                                                        });
                                                      }
                                                    }
                                                  }
                                                }
                                                return false;
                                              }

                                              if (direction ==
                                                  DismissDirection.endToStart) {
                                                return await showDialog<bool>(
                                                      context: context,
                                                      builder:
                                                          (
                                                            context,
                                                          ) => AlertDialog(
                                                            title: const Text(
                                                              'Conferma eliminazione',
                                                            ),
                                                            content: Text(
                                                              'Vuoi davvero cancellare la lista "$nomeLista"?',
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed:
                                                                    () => Navigator.of(
                                                                      context,
                                                                    ).pop(
                                                                      false,
                                                                    ),
                                                                child:
                                                                    const Text(
                                                                      'Annulla',
                                                                    ),
                                                              ),
                                                              TextButton(
                                                                onPressed:
                                                                    () => Navigator.of(
                                                                      context,
                                                                    ).pop(true),
                                                                child:
                                                                    const Text(
                                                                      'Elimina',
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                    ) ??
                                                    false;
                                              }

                                              return false;
                                            },
                                            onDismissed: (direction) async {
                                              if (direction ==
                                                  DismissDirection.endToStart) {
                                                await eliminaLista(nomeLista);
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Lista "$nomeLista" eliminata',
                                                      ),
                                                    ),
                                                  );
                                                }
                                                if (mounted) {
                                                  setState(
                                                    () => _checkedLists.remove(
                                                      nomeLista,
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                            child: ListTile(
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 1,
                                                  ),
                                              leading: Checkbox(
                                                value: isChecked,
                                                activeColor: kPrimary,
                                                onChanged: (value) {
                                                  if (value == null) return;
                                                  setState(() {
                                                    if (value) {
                                                      _checkedLists.add(
                                                        nomeLista,
                                                      );
                                                    } else {
                                                      _checkedLists.remove(
                                                        nomeLista,
                                                      );
                                                    }
                                                  });
                                                },
                                              ),
                                              title: Text(nomeLista),
                                              trailing: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: kSecondary.withValues(
                                                    alpha: 0.6,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                child: Text(
                                                  '$totalePezzi',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: kBluScuro,
                                                  ),
                                                ),
                                              ),
                                              tileColor:
                                                  isSelected
                                                      ? kSecondary.withValues(
                                                        alpha: 0.3,
                                                      )
                                                      : null,
                                              onTap: () async {
                                                setState(
                                                  () => selectedIndex = index,
                                                );
                                                Carrello.instance.usaLista(
                                                  nomeLista,
                                                );

                                                final uid = _currentUid;
                                                if (uid != null) {
                                                  await Carrello.instance
                                                      .caricaListaDaCloud(uid);
                                                } else {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Effettua il login per sincronizzare la lista',
                                                      ),
                                                    ),
                                                  );
                                                }

                                                if (context.mounted) {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (
                                                            context,
                                                          ) => SelectedListPage(
                                                            titolo: nomeLista,
                                                            nrListe:
                                                                liste.length,
                                                          ),
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          );
                                        },
                                      ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: kSecondary.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Totale pezzi in tutte le liste:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: kBluScuro,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: kSecondary.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      '$totaleGlobal',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: kBluScuro,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  title: 'Scarica liste selezionate',
                  titleColor: Colors.white,
                  backgroundColor: kPrimary,
                  onPressed:
                      _checkedLists.isEmpty ? null : _scaricaListeSelezionate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
