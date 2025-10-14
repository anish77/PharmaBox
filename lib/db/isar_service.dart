import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pharma_box/data/models/lists_isar.dart';
import 'package:pharma_box/data/models/prodotto_isar.dart';

class IsarService {
  IsarService._();
  static final IsarService instance = IsarService._();

  Future<Isar>? _dbFuture;

  Future<Isar> get db {
    _dbFuture ??= _openDb();
    return _dbFuture!;
  }

  Future<Isar> _openDb() async {
    final existing = Isar.getInstance();
    if (existing != null) return existing;

    final dir = await getApplicationDocumentsDirectory();
    return Isar.open(
      [ListsIsarSchema, ProdottoIsarSchema],
      directory: dir.path,
      inspector: true,
    );
  }
}
