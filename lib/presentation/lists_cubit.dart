import 'package:pharma_box/domain/models/lists.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharma_box/domain/repository/lists_repo.dart';

class ListsCubit extends Cubit<List<Lists>> {
  final ListsRepo listsRepo;

  //Constructor inizialize with empty list
  ListsCubit(this.listsRepo) : super(const []) {
    loadLists();
  }

  Future<void> loadLists() async {
    final lists = await listsRepo.getListe();
    emit(lists);
  }

  Future<void> addNewList(String name) async {
    final newList = Lists(
      id: DateTime.now().millisecondsSinceEpoch,
      nameList: name,
      date: DateTime.now().toString(),
      products: [],
    );

    await listsRepo.addLista(newList);
    loadLists(); //reload the list
  }

  Future<void> deleteList(Lists lista) async {
    await listsRepo.deleteLista(lista);
    loadLists(); //reload the list
  }

  Future<void> toogleCompletion(Lists list) async {
    final updateLists = list.toogleCompletion();
    await listsRepo.updateLista(updateLists);
    loadLists(); //reload the list
  }
}
