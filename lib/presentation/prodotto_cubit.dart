import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharma_box/domain/models/prodotto.dart';
import 'package:pharma_box/domain/repository/prodotto_repo.dart';

class ProdottoCubit extends Cubit<List<Prodotto>> {
  final ProdottoRepo prodottoRepo;

  //Constructor inizialize with empty product
  ProdottoCubit(this.prodottoRepo) : super(const []) {
    loadProdotti();
  }

  Future<void> loadProdotti() async {
    final prodottiList = await prodottoRepo.getProdotti();
    emit(prodottiList);
  }

  Future<void> addProdotto(
    String nome,
    String minsan,
    String immagine,
    int pezzi,
    int vendibile,
    String description,
    String ingredients,
    String howToTake,
    String codice,
  ) async {
    final newProdotto = Prodotto(
      id: DateTime.now().millisecondsSinceEpoch,
      nome: nome,
      minsan: minsan,
      immagine: immagine,
      pezzi: pezzi,
      vendibile: vendibile,
      description: description,
      ingredients: ingredients,
      howToTake: howToTake,
      codice: codice,
    );
    await prodottoRepo.addProdotto(newProdotto);
    loadProdotti();
  }

  Future<void> deleteProdotto(Prodotto prodotto) async {
    await prodottoRepo.deleteProdotto(prodotto);
    loadProdotti();
  }

  Future<void> toogleCompletion(Prodotto prodotto) async {
    final updateProdotto = prodotto.toogleCompletion();
    await prodottoRepo.updateProdotto(prodotto);
    loadProdotti();
  }
}
