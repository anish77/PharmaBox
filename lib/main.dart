import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/data/models/lists_isar.dart';
import 'package:pharma_box/data/models/prodotto_isar.dart';
import 'package:pharma_box/data/repository/lists_isar_repo.dart';
import 'package:pharma_box/domain/repository/lists_repo.dart';
import 'package:pharma_box/firebase/firebase_options.dart';
import 'package:pharma_box/presentation/lists_cubit.dart';
import 'package:pharma_box/view/login_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy_provider;

final bleScanningProvider = StateProvider<bool>((ref) => false);
final bleStatusProvider = StateProvider<String>((ref) => "");
// Stato dell'ultimo barcode acquisito dal BLE (event-based)
final scannedBarcodeProvider = StateProvider<String?>((ref) => null);
final bleConnected = StateProvider<bool>((ref) => false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // get directory path for storing data
  final appDirectory = await getApplicationDocumentsDirectory();

  // open isar database
  final isar = await Isar.open([
    ListsIsarSchema,
    ProdottoIsarSchema,
  ], directory: appDirectory.path);

  // initialize the repo with isar database
  final listsRepo = ListsIsarRepo(isar);
  runApp(
    legacy_provider.MultiProvider(
      providers: [
        legacy_provider.Provider<Isar>.value(value: isar),
        legacy_provider.Provider<ListsRepo>.value(value: listsRepo),
        BlocProvider<ListsCubit>(create: (_) => ListsCubit(listsRepo)),
      ],
      child: const ProviderScope(child: MyApp()),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Great Places',
      home: LoginPage(),
      theme: ThemeData(
        scaffoldBackgroundColor: kBackGround, // Sfondo globale
        appBarTheme: const AppBarTheme(
          // Tema globale per le AppBar
          backgroundColor: kBackGround,
          foregroundColor: kPrimary,
        ),
      ),
    );
  }
}
