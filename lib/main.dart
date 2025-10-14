import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharma_box/widgets/carrello.dart';
import 'package:provider/provider.dart' as legacy_provider;

import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/data/models/lists_isar.dart';
import 'package:pharma_box/data/models/prodotto_isar.dart';
import 'package:pharma_box/data/repository/lists_isar_repo.dart';
import 'package:pharma_box/domain/repository/lists_repo.dart';
import 'package:pharma_box/db/firebase_options.dart';
import 'package:pharma_box/presentation/lists_cubit.dart';
import 'package:pharma_box/view/login_page.dart';

final bleScanningProvider = StateProvider<bool>((ref) => false);
final bleStatusProvider = StateProvider<String>((ref) => "");
final scannedBarcodeProvider = StateProvider<String?>((ref) => null);
final bleConnected = StateProvider<bool>((ref) => false);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 1. Inizializza Firebase SOLO per il login
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🔹 2. Ottieni la directory per il DB locale
  final appDirectory = await getApplicationDocumentsDirectory();

  // 🔹 3. Apri Isar
  final isar = await Isar.open([
    ListsIsarSchema,
    ProdottoIsarSchema,
  ], directory: appDirectory.path);

  // 🔹 4. Inizializza il carrello offline (Isar)
  //await CarrelloIsar.instance.init(isar);

  // 🔹 5. Inizializza i repository Isar
  final listsRepo = ListsIsarRepo(isar);

  // 🔹 6. Avvia l’app
  runApp(
    legacy_provider.MultiProvider(
      providers: [
        legacy_provider.Provider<Isar>.value(value: isar),
        legacy_provider.Provider<ListsRepo>.value(value: listsRepo),
        legacy_provider.Provider<CarrelloIsar>.value(
          value: CarrelloIsar.instance,
        ),
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
      title: 'Pharma Box',
      home: const LoginPage(), // 👈 il login resta basato su Firebase
      theme: ThemeData(
        scaffoldBackgroundColor: kBackGround,
        appBarTheme: const AppBarTheme(
          backgroundColor: kBackGround,
          foregroundColor: kPrimary,
        ),
      ),
    );
  }
}
