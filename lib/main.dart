import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/firebase/firebase_options.dart';
import 'package:pharma_box/view/login_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bleScanningProvider = StateProvider<bool>((ref) => false);
final bleStatusProvider = StateProvider<String>((ref) => "");
// Stato dell'ultimo barcode acquisito dal BLE (event-based)
final scannedBarcodeProvider = StateProvider<String?>((ref) => null);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
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
