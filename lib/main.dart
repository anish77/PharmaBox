import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:pharma_box/db/firebase_options.dart';
import 'package:provider/provider.dart' as legacy_provider;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:pharma_box/db/isar_service.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/data/repository/lists_isar_repo.dart';
import 'package:pharma_box/domain/repository/lists_repo.dart';
import 'package:pharma_box/domain/models/prodotto.dart';
import 'package:pharma_box/presentation/lists_cubit.dart';
import 'package:pharma_box/view/login_page.dart';
import 'package:pharma_box/view/crea_nuova_lista.dart';
import 'package:pharma_box/widgets/carrello.dart';

final bleScanningProvider = StateProvider<bool>((ref) => false);
final bleStatusProvider = StateProvider<String>((ref) => '');
final scannedBarcodeProvider = StateProvider<String?>((ref) => null);
final bleConnected = StateProvider<bool>((ref) => false);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: PharmaBoxApp()));
}

class PharmaBoxApp extends StatefulWidget {
  const PharmaBoxApp({super.key});

  @override
  State<PharmaBoxApp> createState() => _PharmaBoxAppState();
}

class _PharmaBoxAppState extends State<PharmaBoxApp> {
  Isar? _isar;
  ListsRepo? _listsRepo;
  bool _loading = true;
  StreamSubscription<User?>? _authSubscription;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (user) async {
        if (_isDisposed) return;
        await _handleAuthChange(user);
      },
      onError: (err) async {
        debugPrint('Errore stream auth: $err');
        if (_isDisposed) return;
        await _handleAuthChange(null);
      },
    );

    // Avvio iniziale
    _handleAuthChange(FirebaseAuth.instance.currentUser);
  }

  Future<void> _handleAuthChange(User? user) async {
    if (_isDisposed) return;

    // Mostra loader
    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      // 🔹 Chiudi eventuale DB precedente
      await IsarService.instance.closeCurrent();
      CarrelloIsar.instance.detachDb();

      final userId = user?.uid ?? 'guest';

      // 🔹 Apri Isar per l’utente
      final isar = await IsarService.instance.openForUser(userId);
      if (_isDisposed || !mounted) {
        await isar.close();
        return;
      }

      final listsRepo = ListsIsarRepo(isar);

      // 🔹 Reinizializza carrello
      CarrelloIsar.instance.attachDb(isar);
      CarrelloIsar.instance.sostituisciProdottiCorrenti(const <Prodotto>[]);

      if (_isDisposed || !mounted) return;

      // 🔹 Aggiorna stato UI
      setState(() {
        _isar = isar;
        _listsRepo = listsRepo;
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('Errore _handleAuthChange: $e\n$st');
      if (!_isDisposed && mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _authSubscription?.cancel();
    IsarService.instance.closeCurrent();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mostra loader durante l’apertura DB
    if (_loading || _isar == null || _listsRepo == null) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    final home = user == null ? const LoginPage() : const CreaNuovaLista();

    return legacy_provider.MultiProvider(
      providers: [
        legacy_provider.Provider<Isar>.value(value: _isar!),
        legacy_provider.Provider<ListsRepo>.value(value: _listsRepo!),
        legacy_provider.Provider<CarrelloIsar>.value(
          value: CarrelloIsar.instance,
        ),
        BlocProvider<ListsCubit>(
          key: ValueKey(user?.uid),
          create: (_) => ListsCubit(_listsRepo!),
        ),
      ],
      child: MaterialApp(
        title: 'Pharma Box',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: kBackGround,
          appBarTheme: const AppBarTheme(
            backgroundColor: kBackGround,
            foregroundColor: kPrimary,
          ),
        ),
        home: home,
      ),
    );
  }
}
