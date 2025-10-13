import 'package:pharma_box/domain/models/lists.dart';

abstract class ListsRepo {
  Future<List<Lists>> getListe();
  Future<void> addLista(Lists newLista);
  Future<void> updateLista(Lists lista);
  Future<void> deleteLista(Lists lista);
}
