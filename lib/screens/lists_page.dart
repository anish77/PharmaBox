import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/screens/selected_list_page.dart';
import 'package:pharma_box/widgets/crea_lista_popup.dart';
import 'package:pharma_box/widgets/custom_button.dart';
import 'package:pharma_box/widgets/log_out_popup.dart';

class ListsPage extends StatefulWidget {
  const ListsPage({super.key});

  @override
  State<ListsPage> createState() => _ListsPageState();
}

class _ListsPageState extends State<ListsPage> {
  var logger = Logger(printer: PrettyPrinter());
  int? selectedIndex;
  final uid = FirebaseAuth.instance.currentUser!.uid;

  Stream<List<String>> getListeStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return [];
          final data = doc.data();
          final liste = data?['liste'] ?? [];
          return List<String>.from(liste.map((l) => l['nomeLista']));
        });
  }

  Future<void> eliminaLista(String nomeLista) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (!doc.exists) return;

    final data = doc.data();
    final liste = data?['liste'] ?? [];

    // Trova la lista da cancellare
    final listaDaEliminare = liste.firstWhere(
      (l) => l['nomeLista'] == nomeLista,
      orElse: () => null,
    );

    if (listaDaEliminare != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'liste': FieldValue.arrayRemove([listaDaEliminare]),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // niente icona automatica a sinistra
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
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            ListTile(
              // leading: Icon(Icons.settings),
              title: Text('Opzione 1'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
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
              // Bottone
              CustomButton(
                title: "Crea Nuova Lista",
                titleColor: Colors.white,
                backgroundColor: kPrimary,
                onPressed: () {
                  CreaListaPopup().showPopup(context);
                },
              ),
              const SizedBox(height: 45),
              // Intestazione Liste
              Container(
                width: double.infinity,
                color: kSecondary,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                child: const Text(
                  "Liste",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kBluScuro,
                  ),
                ),
              ),

              // Lista
              Expanded(
                child: Builder(
                  builder: (scaffoldContext) {
                    // context sicuro
                    return StreamBuilder<List<String>>(
                      stream: getListeStream(),
                      builder: (context, snapshot) {
                        final items = snapshot.data ?? [];

                        return ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final isSelected = selectedIndex == index;
                            return Dismissible(
                              key: Key(items[index]),
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
                                      TextEditingController(text: items[index]);
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
                                    final docRef = FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(uid);
                                    final doc = await docRef.get();
                                    if (doc.exists) {
                                      final data = doc.data()!;
                                      final liste =
                                          List<Map<String, dynamic>>.from(
                                            data['liste'] ?? [],
                                          );
                                      final indexLista = liste.indexWhere(
                                        (l) => l['nomeLista'] == items[index],
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
                                            'Vuoi davvero cancellare la lista "${items[index]}"?',
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
                                  await eliminaLista(items[index]);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Lista "${items[index]}" eliminata',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: ListTile(
                                title: Text(items[index]),
                                tileColor:
                                    isSelected
                                        ? kSecondary.withValues(alpha: 0.3)
                                        : null,
                                onTap: () {
                                  setState(() {
                                    selectedIndex = index;
                                  });
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => SelectedListPage(
                                            titolo: items[index],
                                            nrListe: items.length,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
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
