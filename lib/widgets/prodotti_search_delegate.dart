import 'package:flutter/material.dart';
import 'package:pharma_box/domain/models/prodotto.dart';

class ProdottiSearchDelegate extends SearchDelegate<Prodotto?> {
  ProdottiSearchDelegate({required this.onSearch});

  final Future<List<Prodotto>> Function(String query) onSearch;

  @override
  String? get searchFieldLabel => 'Cerca prodotto…';
  @override
  TextInputAction get textInputAction => TextInputAction.search;

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(
      icon: const Icon(Icons.search),
      onPressed: () => showResults(context), // 👈 tasto lente avvia risultati
    ),
    if (query.isNotEmpty)
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildSuggestions(BuildContext context) {
    // 👇 Se arrivo già con una query (da showSearch(query: ...)),
    // mostra SUBITO i risultati al primo frame.
    final q = query.trim();
    if (q.length >= 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).mounted) {
          showResults(context);
        }
      });
    }
    return const Center(child: Text('Scrivi almeno 3 caratteri e premi Invio'));
  }

  @override
  Widget buildResults(BuildContext context) {
    final q = query.trim();
    if (q.length < 3) {
      return const Center(child: Text('Inserisci almeno 3 caratteri'));
    }
    return FutureBuilder<List<Prodotto>>(
      key: ValueKey(q), // forza il refresh quando cambia query
      future: onSearch(q),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return const Center(child: Text('Errore durante la ricerca'));
        }
        final results = snap.data ?? [];
        if (results.isEmpty) {
          return const Center(child: Text('Nessun risultato'));
        }
        if (results.length == 1) {
          // Un solo risultato: selezionalo automaticamente
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.of(context).mounted) {
              close(context, results.first);
            }
          });
          return const SizedBox.shrink();
        }
        return ListView.separated(
          itemCount: results.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final p = results[i];
            return ListTile(
              dense: true,
              title: Text(
                p.nome ?? "",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                p.codice,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => close(context, p),
            );
          },
        );
      },
    );
  }
}
