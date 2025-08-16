import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/screens/selected_list_page.dart';
import 'package:pharma_box/widgets/crea_lista_popup.dart';
import 'package:pharma_box/widgets/custom_button.dart';

class ListsPage extends StatefulWidget {
  const ListsPage({super.key});

  @override
  State<ListsPage> createState() => _ListsPageState();
}

class _ListsPageState extends State<ListsPage> {
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 45, left: 24, right: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo + titolo
              Row(
                children: [
                  Image.asset(kLogo, height: 25, width: 25),
                  const SizedBox(width: 8),
                  const Text(
                    kAppName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: kPrimary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

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
                child: StreamBuilder<List<String>>(
                  stream: getListeStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("Errore: ${snapshot.error}"));
                    }

                    final items = snapshot.data ?? [];

                    if (items.isEmpty) {
                      return const Center(child: Text("Nessuna lista trovata"));
                    }

                    return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final isSelected = selectedIndex == index;
                        return Dismissible(
                          key: Key(items[index]),
                          direction:
                              DismissDirection
                                  .endToStart, // swipe verso sinistra
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            color: Colors.red,
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            // Popup di conferma
                            return await showDialog(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text("Conferma eliminazione"),
                                    content: Text(
                                      "Vuoi davvero cancellare la lista \"${items[index]}\"?",
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
                                            () =>
                                                Navigator.of(context).pop(true),
                                      ),
                                    ],
                                  ),
                            );
                          },
                          onDismissed: (direction) async {
                            final nomeListaCancellata =
                                items[index]; // salva il nome
                            await eliminaLista(nomeListaCancellata);
                            Future.delayed(Duration.zero, () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Lista \"$nomeListaCancellata\" eliminata",
                                  ),
                                ),
                              );
                            });
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
