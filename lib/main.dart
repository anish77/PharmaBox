import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/features/subscribtions/offerings_cubit.dart';
import 'package:pharma_box/features/subscribtions/subscribtion_cubit.dart';
import 'package:pharma_box/features/subscribtions/revenuecat_service.dart';
import 'package:pharma_box/firebase/firebase_options.dart';
import 'package:pharma_box/view/login_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider BLE globali
final bleScanningProvider = StateProvider<bool>((ref) => false);
final bleStatusProvider = StateProvider<String>((ref) => "");
final scannedBarcodeProvider = StateProvider<String?>((ref) => null);
final bleConnected = StateProvider<bool>((ref) => false);

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔒 BLOCCA L’APP IN PORTRAIT
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitUp,
  ]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Inizializza RevenueCat con la chiave API appropriata per la piattaforma
  await RevenuecatService.configurRevenuecat(
    Platform.isAndroid ? kApiKeyGoogle : kApiKeyApple,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SubscriptionCubit()),
        BlocProvider(
          create:
              (context) =>
                  OfferingsCubit(context.read<SubscriptionCubit>())
                    ..loadOfferings(),
        ),
      ],
      child: MaterialApp(
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
      ),
    );
  }
}
