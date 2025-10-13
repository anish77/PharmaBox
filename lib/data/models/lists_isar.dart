import 'package:isar/isar.dart';
import 'package:pharma_box/data/models/prodotto_isar.dart';
import 'package:pharma_box/domain/models/lists.dart';

// to genaerate isar todo object, run: dart run build_runner build
part 'lists_isar.g.dart';

@collection
class ListsIsar {
  Id id = Isar.autoIncrement;
  late String nameList;
  late String date;
  final products = IsarLinks<ProdottoIsar>();
  late bool isCompleted;

  Lists toPureObject() {
    products.loadSync(); // oppure await products.load()
    return Lists(
      id: id,
      nameList: nameList,
      date: date,
      products: products.toList(), // List<ProdottoIsar>
      isCompleted: isCompleted,
    );
  }

  static ListsIsar fromPureObject(Lists list) {
    final entity =
        ListsIsar()
          ..id = list.id
          ..nameList = list.nameList
          ..date = list.date
          ..isCompleted = list.isCompleted;

    entity.products.addAll(list.products);
    return entity;
  }
}
