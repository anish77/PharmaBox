import 'package:pharma_box/data/models/prodotto_isar.dart';

class Lists {
  final int id;
  final String nameList;
  final String date;
  final List<ProdottoIsar> products; // Lista di prodotti
  final bool isCompleted;

  Lists({
    required this.id,
    required this.nameList,
    required this.date,
    required this.products,
    this.isCompleted = false, //initially false
  });

  Lists toogleCompletion() {
    return Lists(
      id: id,
      nameList: nameList,
      date: date,
      products: products,
      isCompleted: !isCompleted,
    );
  }
}
