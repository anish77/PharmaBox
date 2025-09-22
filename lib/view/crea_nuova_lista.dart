import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/view/invite_friend_page.dart';
import 'package:pharma_box/view/invite_progress_page.dart';
import 'package:pharma_box/view/selected_list_page.dart';
import 'package:pharma_box/widgets/carrello.dart';
import 'package:pharma_box/widgets/crea_lista_popup.dart';
import 'package:pharma_box/widgets/custom_button.dart';
import 'package:pharma_box/widgets/log_out_popup.dart';
import 'package:url_launcher/url_launcher.dart';

class CreaNuovaLista extends StatefulWidget {
  const CreaNuovaLista({super.key});

  @override
  State<CreaNuovaLista> createState() => _CreaNuovaListaState();
}

class _CreaNuovaListaState extends State<CreaNuovaLista> {
  final Logger _logger = Logger(printer: PrettyPrinter());
  int? selectedIndex;

  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _openContactEmail() async {
    const subject = 'Richiesta assistenza PharmaBox';
    const body = 'Ciao, avrei bisogno di supporto con la mia esperienza.';

    final Uri mailUri = Uri(
      scheme: 'mailto',
      path: kMembershipEmail,
      queryParameters: {'subject': subject, 'body': body},
    );

    if (await canLaunchUrl(mailUri)) {
      final launched = await launchUrl(
        mailUri,
        mode: LaunchMode.externalApplication,
      );
      if (launched || !mounted) return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impossibile aprire l\'app email.')),
    );
  }

  Stream<List<String>> getListeStream() {
    final uid = _currentUid;
    if (uid == null) {
      _logger.w('getListeStream invoked without authenticated user');
      return Stream<List<String>>.value(const []);
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return <String>[];
          final data = doc.data();
          final rawListe = data?['liste'] ?? [];
          final liste = List<Map<String, dynamic>>.from(rawListe);
          return List<String>.from(
            liste
                .map((l) => (l['nomeLista'] ?? '') as String)
                .where((nome) => nome.isNotEmpty),
          );
        });
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
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // niente icona automatica a sinistra
        leading:
            canPop
                ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: kPrimary),
                  onPressed: () => Navigator.of(context).maybePop(),
                )
                : null,
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
                            const InviteFriendPage(referralCode: '123'),
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
                    builder:
                        (context) =>
                            const InviteProgressPage(invitedFriends: 3),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.mail_outline, color: kPrimary),
              title: const Text(
                'Contattaci',
                style: TextStyle(color: kBluScuro),
              ),
              onTap: _openContactEmail,
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

                        if (items.isEmpty) {
                          return const Center(
                            child: Text('Nessuna lista disponibile'),
                          );
                        }

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
                                    final currentUid = _currentUid;
                                    if (currentUid == null) {
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
                                onTap: () async {
                                  setState(() {
                                    selectedIndex = index;
                                  });
                                  // Imposta la lista corrente nel carrello
                                  Carrello.instance.usaLista(items[index]);
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
