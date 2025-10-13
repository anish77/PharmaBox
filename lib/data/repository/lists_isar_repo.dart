import 'package:isar/isar.dart';
import 'package:pharma_box/data/models/lists_isar.dart';
import 'package:pharma_box/domain/models/lists.dart';
import 'package:pharma_box/domain/repository/lists_repo.dart';

class ListsIsarRepo implements ListsRepo {
  final Isar db;
  ListsIsarRepo(this.db);

  @override
  Future<void> addLista(Lists newLista) async {
    final entity = ListsIsar.fromPureObject(newLista);
    return db.writeTxn(() async {
      await db.listsIsars.put(entity);
    });
  }

  @override
  Future<void> deleteLista(Lists lista) async {
    final entity = ListsIsar.fromPureObject(lista);
    return db.writeTxn(() async {
      await db.listsIsars.delete(entity.id);
    });
  }

  @override
  Future<List<Lists>> getListe() async {
    final listeIsar = await db.listsIsars.where().findAll();
    return listeIsar.map((e) => e.toPureObject()).toList();
  }

  @override
  Future<void> updateLista(Lists lista) async {
    final entity = ListsIsar.fromPureObject(lista);
    return db.writeTxn(() async {
      await db.listsIsars.put(entity);
    });
  }
}
