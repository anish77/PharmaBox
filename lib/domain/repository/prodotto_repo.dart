import 'package:pharma_box/domain/models/prodotto.dart';

abstract class ProdottoRepo {
  Future<List<Prodotto>> getProdotti();
  Future<void> addProdotto(Prodotto newProdotto);
  Future<void> updateProdotto(Prodotto prodotto);
  Future<void> deleteProdotto(Prodotto prodotto);
}
