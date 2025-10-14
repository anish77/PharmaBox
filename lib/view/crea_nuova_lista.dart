import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/web.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/data/models/prodotto_isar.dart';
import 'package:pharma_box/domain/models/lists.dart';
import 'package:pharma_box/presentation/lists_cubit.dart';
import 'package:pharma_box/view/info.dart';
import 'package:pharma_box/view/invita_un_amico.dart';
import 'package:pharma_box/view/selected_list_page.dart';
import 'package:pharma_box/view/stato_inviti.dart';
import 'package:pharma_box/domain/repository/carrello.dart';
import 'package:pharma_box/widgets/crea_lista_popup.dart';
import 'package:pharma_box/widgets/log_out_popup.dart';

class CreaNuovaLista extends StatefulWidget {
  const CreaNuovaLista({super.key});

  @override
  State<CreaNuovaLista> createState() => _CreaNuovaListaState();
}

class _ListaViewData {
  const _ListaViewData({required this.lista, required this.totalePezzi});

  final Lists lista;
  int get id => lista.id;
  String get nome => lista.nameList;
  final int totalePezzi;
}

class _CreaNuovaListaState extends State<CreaNuovaLista> {
  final Logger _logger = Logger(printer: PrettyPrinter());
  int? selectedIndex;
  String referralCode = '';

  @override
  void initState() {
    super.initState();
    // Carica le liste salvate in Isar
    context.read<ListsCubit>().loadLists();
  }

  List<_ListaViewData> _toViewData(List<Lists> liste) {
    return liste
        .map(
          (lista) => _ListaViewData(
            lista: lista,
            totalePezzi: lista.products.fold<int>(
              0,
              (sum, prodotto) => sum + prodotto.pezzi,
            ),
          ),
        )
        .toList();
  }

  Future<void> _eliminaLista(BuildContext context, Lists lista) async {
    try {
      await context.read<ListsCubit>().deleteList(lista);
    } catch (errore, stack) {
      _logger.e(
        'Errore nel cancellare la lista ${lista.nameList}, $errore',
        stackTrace: stack,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore durante l’eliminazione della lista'),
        ),
      );
    }
  }

  Future<void> _rinominaLista(
    BuildContext context,
    Lists lista,
    String nuovoNome,
  ) async {
    final trimmed = nuovoNome.trim();
    if (trimmed.isEmpty) return;

    final listsCubit = context.read<ListsCubit>();
    final state = listsCubit.state;

    final alreadyExists = state.any(
      (element) =>
          element.id != lista.id &&
          element.nameList.toLowerCase() == trimmed.toLowerCase(),
    );

    if (alreadyExists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esiste già una lista con questo nome')),
      );
      return;
    }

    final updated = Lists(
      id: lista.id,
      nameList: trimmed,
      date: lista.date,
      products: List<ProdottoIsar>.from(lista.products),
      isCompleted: lista.isCompleted,
    );

    try {
      await listsCubit.listsRepo.updateLista(updated);
      await listsCubit.loadLists();
    } catch (errore, stack) {
      _logger.e(
        'Errore nel rinominare la lista ${lista.nameList}, $errore',
        stackTrace: stack,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossibile rinominare la lista')),
      );
    }
  }

  /// 🔹 Apri lista → carica prodotti in CarrelloIsar
  Future<void> _apriLista(
    BuildContext context,
    Lists lista,
    int numeroListe,
  ) async {
    try {
      final carrello = CarrelloIsar.instance;
      carrello.usaLista(lista.nameList);

      final prodottiDomain = lista.products.map((p) => p.toDomain()).toList();
      carrello.sostituisciProdottiCorrenti(prodottiDomain);
    } catch (errore, stack) {
      _logger.e(
        'Errore nel preparare la lista ${lista.nameList}, $errore',
        stackTrace: stack,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossibile aprire la lista')),
      );
      return;
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                SelectedListPage(titolo: lista.nameList, nrListe: numeroListe),
      ),
    );
    // al ritorno ricarica le liste da Isar
    if (context.mounted) {
      await context.read<ListsCubit>().loadLists();
    }
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
                  icon: const Padding(
                    padding: EdgeInsets.only(right: 16),
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
            const DrawerHeader(
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
              title: const Text(
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
                      icon: const Icon(
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
                child: BlocBuilder<ListsCubit, List<Lists>>(
                  builder: (context, state) {
                    final listeView = _toViewData(state);
                    final totaleGlobal = listeView.fold<int>(
                      0,
                      (sum, entry) => sum + entry.totalePezzi,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child:
                              listeView.isEmpty
                                  ? const Center(
                                    child: Text('Nessuna lista disponibile'),
                                  )
                                  : ListView.builder(
                                    itemCount: listeView.length,
                                    itemBuilder: (context, index) {
                                      final entry = listeView[index];
                                      final lista = entry.lista;
                                      final nomeLista = entry.nome;
                                      final totalePezzi = entry.totalePezzi;
                                      final isSelected = selectedIndex == index;

                                      return Dismissible(
                                        key: ValueKey(entry.id),
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
                                                      controller: controller,
                                                      decoration:
                                                          const InputDecoration(
                                                            labelText:
                                                                'Nuovo nome',
                                                          ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        child: const Text(
                                                          'Annulla',
                                                        ),
                                                        onPressed:
                                                            () => Navigator.of(
                                                              context,
                                                            ).pop(null),
                                                      ),
                                                      TextButton(
                                                        child: const Text(
                                                          'Salva',
                                                        ),
                                                        onPressed:
                                                            () => Navigator.of(
                                                              context,
                                                            ).pop(
                                                              controller.text
                                                                  .trim(),
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                            );

                                            if (nuovoNome != null &&
                                                nuovoNome.isNotEmpty) {
                                              await _rinominaLista(
                                                context,
                                                lista,
                                                nuovoNome,
                                              );
                                            }
                                            return false;
                                          }

                                          if (direction ==
                                              DismissDirection.endToStart) {
                                            final conferma = await showDialog<
                                              bool
                                            >(
                                              context: context,
                                              builder:
                                                  (context) => AlertDialog(
                                                    title: const Text(
                                                      'Conferma eliminazione',
                                                    ),
                                                    content: Text(
                                                      'Vuoi davvero cancellare la lista "$nomeLista"?',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        child: const Text(
                                                          'Annulla',
                                                        ),
                                                        onPressed:
                                                            () => Navigator.of(
                                                              context,
                                                            ).pop(false),
                                                      ),
                                                      TextButton(
                                                        child: const Text(
                                                          'Elimina',
                                                        ),
                                                        onPressed:
                                                            () => Navigator.of(
                                                              context,
                                                            ).pop(true),
                                                      ),
                                                    ],
                                                  ),
                                            );
                                            return conferma ?? false;
                                          }
                                          return false;
                                        },
                                        onDismissed: (direction) async {
                                          if (direction ==
                                              DismissDirection.endToStart) {
                                            await _eliminaLista(context, lista);
                                            if (!mounted) return;
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
                                        },
                                        child: ListTile(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 8,
                                              ), // sinistra/destra
                                          title: Text(nomeLista),
                                          trailing: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: kSecondary.withValues(
                                                alpha: .6,
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
                                                    alpha: .3,
                                                  )
                                                  : null,
                                          onTap: () async {
                                            setState(
                                              () => selectedIndex = index,
                                            );
                                            await _apriLista(
                                              context,
                                              lista,
                                              listeView.length,
                                            );
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
