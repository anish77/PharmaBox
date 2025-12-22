import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/firebase/firebase_options.dart';
import 'package:pharma_box/view/login_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharma_box/in_app_purchase/billing_service.dart';

// Provider BLE globali
final bleScanningProvider = StateProvider<bool>((ref) => false);
final bleStatusProvider = StateProvider<String>((ref) => "");
final scannedBarcodeProvider = StateProvider<String?>((ref) => null);
final bleConnected = StateProvider<bool>((ref) => false);

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await BillingService.instance.initialize();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      navigatorKey: navigatorKey,
      title: 'PharmaBox',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: kBackGround,
        appBarTheme: const AppBarTheme(
          backgroundColor: kBackGround,
          foregroundColor: kPrimary,
        ),
      ),
      home: const LoginPage(),
    );
  }
}
