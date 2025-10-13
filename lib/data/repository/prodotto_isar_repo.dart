/*
DATABASE REPO

this implements the prodotto repo and handles storing, retrieving, updating, 
deleting in the isar database

*/

import 'package:isar/isar.dart';
import 'package:pharma_box/data/models/prodotto_isar.dart';
import 'package:pharma_box/domain/models/prodotto.dart';
import 'package:pharma_box/domain/repository/prodotto_repo.dart';

class ProdottoIsarRepo implements ProdottoRepo {
  final Isar db;
  ProdottoIsarRepo(this.db);

  @override
  Future<void> addProdotto(Prodotto newProdotto) async {
    final entity = ProdottoIsar.fromDomain(newProdotto);
    return db.writeTxn(() async {
      await db.prodottoIsars.put(entity);
    });
  }

  @override
  Future<void> deleteProdotto(Prodotto prodotto) async {
    return db.writeTxn(() async {
      await db.prodottoIsars.delete(prodotto.id);
    });
  }

  @override
  Future<List<Prodotto>> getProdotti() async {
    final prodottiIsar = await db.prodottoIsars.where().findAll();
    return prodottiIsar.map((e) => e.toDomain()).toList();
  }

  @override
  Future<void> updateProdotto(Prodotto prodotto) async {
    final entity = ProdottoIsar.fromDomain(prodotto);
    return db.writeTxn(() async {
      await db.prodottoIsars.put(entity);
    });
  }
}
