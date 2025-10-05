import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/view/info.dart';
import 'package:pharma_box/view/invita_un_amico.dart';
import 'package:pharma_box/view/stato_inviti.dart';
import 'package:pharma_box/view/selected_list_page.dart';
import 'package:pharma_box/widgets/carrello.dart';
import 'package:pharma_box/widgets/crea_lista_popup.dart';
import 'package:pharma_box/widgets/log_out_popup.dart';

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

class _CreaNuovaListaState extends State<CreaNuovaLista> {
  final Logger _logger = Logger(printer: PrettyPrinter());
  int? selectedIndex;

  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;
  String referralCode = "";

  @override
  void initState() {
    super.initState();
    _caricaReferralCode();
  }

  Future<void> _caricaReferralCode() async {
    final uid = _currentUid;
    if (uid == null) {
      _logger.w('_caricaReferralCode invoked without authenticated user');
      return;
    }

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!snapshot.exists) return;

      final data = snapshot.data();
      final rawCode = data?['codiceInvito'];
      final codice = rawCode is String ? rawCode : rawCode?.toString() ?? '';

      if (!mounted) return;
      setState(() {
        referralCode = codice;
      });
    } catch (errore, stackTrace) {
      _logger.e('Errore nel recuperare il codice invito, $errore, $stackTrace');
    }
  }

  Stream<List<_ListaViewData>> getListeStream() {
    final uid = _currentUid;
    if (uid == null) {
      _logger.w('getListeStream invoked without authenticated user');
      return Stream<List<_ListaViewData>>.value(const []);
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return const <_ListaViewData>[];
          final data = doc.data();
          final rawListe = data?['liste'] ?? [];
          final liste = List<Map<String, dynamic>>.from(rawListe);
          return liste
              .map((l) {
                final nomeLista = (l['nomeLista'] ?? '') as String;
                if (nomeLista.isEmpty) return null;
                final totaleItems = _sommaQuantita(l['items']);
                final totaleProdotti = _sommaQuantita(l['prodotti']);
                final totale =
                    totaleItems > 0 ? totaleItems : totaleProdotti;
                return _ListaViewData(
                  nome: nomeLista,
                  totalePezzi: totale,
                );
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
          final map =
              element.map((key, value) => MapEntry(key.toString(), value));
          final quantity = map['quantity'] ??
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

  int _parseQuantity(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Future<void> eliminaLista(String nomeLista) async {
    final uid = _currentUid;
    if (uid == null) {
      _logger.w('eliminaLista invoked without authenticated user');
      return;
    }

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (!doc.exists) return;

    final data = doc.data();
    final rawListe = data?['liste'] ?? [];
    final liste = List<Map<String, dynamic>>.from(rawListe);

    final listaDaEliminare = liste.firstWhere(
      (l) => l['nomeLista'] == nomeLista,
      orElse: () => <String, dynamic>{},
    );

    if (listaDaEliminare.isEmpty) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'liste': FieldValue.arrayRemove([listaDaEliminare]),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // niente icona automatica a sinistra
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
                  ), // colore che vuoi
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
              child: Text(
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
                  MaterialPageRoute(builder: (context) => StatoInvitiPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info, color: kPrimary),
              title: const Text('Info', style: TextStyle(color: kBluScuro)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => InfoPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: kRed),
              title: Text(
                'Log out',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: kRed,
                ),
              ),
              onTap: () {
                LogoutPopup().showLogout(context);
              },
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
              const SizedBox(height: 45),
              // Intestazione Liste
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
                      "Liste",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kBluScuro,
                      ),
                    ),
                    IconButton(
                      icon: Text(
                        '+',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: kGreen,
                        ),
                      ),
                      tooltip: "Crea nuova lista",
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => CreaListaPopup().showPopup(context),
                    ),
                  ],
                ),
              ),

              // Lista
              Expanded(
                child: Builder(
                  builder: (scaffoldContext) {
                    // context sicuro
                    return StreamBuilder<List<_ListaViewData>>(
                      stream: getListeStream(),
                      builder: (context, snapshot) {
                        final liste = snapshot.data ?? const <_ListaViewData>[];
                        final totaleGlobal =
                            liste.fold<int>(0, (sum, e) => sum + e.totalePezzi);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: liste.isEmpty
                                  ? const Center(
                                      child: Text('Nessuna lista disponibile'),
                                    )
                                  : ListView.builder(
                                      itemCount: liste.length,
                                      itemBuilder: (context, index) {
                                        final entry = liste[index];
                                        final nomeLista = entry.nome;
                                        final totalePezzi = entry.totalePezzi;
                                        final isSelected = selectedIndex == index;
                                        return Dismissible(
                                          key: Key(nomeLista),
                                          direction: DismissDirection.horizontal,
                                          background: Container(
                                            alignment: Alignment.centerLeft,
                                            padding: const EdgeInsets.symmetric(
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                color: Colors.red,
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                if (direction == DismissDirection.startToEnd) {
                                  // Edit lista
                                  final TextEditingController controller =
                                      TextEditingController(text: nomeLista);
                                  final nuovoNome = await showDialog<String>(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: const Text(
                                            "Modifica nome lista",
                                          ),
                                          content: TextField(
                                            controller: controller,
                                            decoration: const InputDecoration(
                                              labelText: "Nuovo nome",
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              child: const Text("Annulla"),
                                              onPressed:
                                                  () => Navigator.of(
                                                    context,
                                                  ).pop(null),
                                            ),
                                            TextButton(
                                              child: const Text("Salva"),
                                              onPressed:
                                                  () => Navigator.of(
                                                    context,
                                                  ).pop(controller.text.trim()),
                                            ),
                                          ],
                                        ),
                                  );

                                  if (nuovoNome != null &&
                                      nuovoNome.isNotEmpty) {
                                    final currentUid = _currentUid;
                                    if (currentUid == null && context.mounted) {
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
                                    final docRef = FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(currentUid);
                                    final doc = await docRef.get();
                                    if (doc.exists) {
                                      final data = doc.data()!;
                                      final liste =
                                          List<Map<String, dynamic>>.from(
                                            data['liste'] ?? [],
                                          );
                                      final indexLista = liste.indexWhere(
                                        (l) => l['nomeLista'] == nomeLista,
                                      );
                                      if (indexLista >= 0) {
                                        liste[indexLista]['nomeLista'] =
                                            nuovoNome;
                                        await docRef.update({'liste': liste});
                                      }
                                    }
                                  }
                                  return false; // importante: non chiudere il Dismissible
                                }

                                // Se swipe verso sinistra → conferma eliminazione
                                if (direction == DismissDirection.endToStart) {
                                  return await showDialog(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: const Text(
                                            "Conferma eliminazione",
                                          ),
                                          content: Text(
                                            'Vuoi davvero cancellare la lista "$nomeLista"?',
                                          ),
                                          actions: [
                                            TextButton(
                                              child: const Text("Annulla"),
                                              onPressed:
                                                  () => Navigator.of(
                                                    context,
                                                  ).pop(false),
                                            ),
                                            TextButton(
                                              child: const Text("Elimina"),
                                              onPressed:
                                                  () => Navigator.of(
                                                    context,
                                                  ).pop(true),
                                            ),
                                          ],
                                        ),
                                  );
                                }

                                return false;
                              },
                              onDismissed: (direction) async {
                                if (direction == DismissDirection.endToStart) {
                                  await eliminaLista(nomeLista);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Lista "$nomeLista" eliminata',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: ListTile(
                                title: Text(nomeLista),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: kSecondary.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(16),
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
                                        ? kSecondary.withValues(alpha: 0.3)
                                        : null,
                                onTap: () async {
                                  setState(() {
                                    selectedIndex = index;
                                  });
                                  // Imposta la lista corrente nel carrello
                                  Carrello.instance.usaLista(nomeLista);
                                  // Carica prodotti salvati su Firestore per questa lista
                                  final uid = _currentUid;
                                  if (uid != null) {
                                    await Carrello.instance.caricaListaDaCloud(
                                      uid,
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
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
                                            (context) => SelectedListPage(
                                              titolo: nomeLista,
                                              nrListe: liste.length,
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
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: kSecondary.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Totale pezzi in tutte le liste: $totaleGlobal',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: kBluScuro,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
