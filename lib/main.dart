import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/firebase/firebase_options.dart';
import 'package:pharma_box/view/login_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_links/uni_links.dart';

// Provider globali BLE
final bleScanningProvider = StateProvider<bool>((ref) => false);
final bleStatusProvider = StateProvider<String>((ref) => "");
final scannedBarcodeProvider = StateProvider<String?>((ref) => null);
final bleConnected = StateProvider<bool>((ref) => false);

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _setup();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _setup() async {
  // Inizializza Stripe
  Stripe.publishableKey = stripePublishableKey;
  await Stripe.instance.applySettings();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _linkSub;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _initDeepLinkListener();
  }

  /// 🔹 Ascolta i deep link come pharmabox://payment/paypal?status=success
  Future<void> _initDeepLinkListener() async {
    try {
      // Gestisce il link se l'app è aperta da PayPal
      final initialUri = await getInitialUri();
      if (initialUri != null) {
        await _handleUri(initialUri);
      }
    } catch (e) {
      debugPrint('Errore iniziale URI: $e');
    }

    // Gestisce i link mentre l'app è in esecuzione
    _linkSub = uriLinkStream.listen((uri) async {
      if (uri != null) {
        await _handleUri(uri);
      }
    }, onError: (err) => debugPrint('Errore deep link: $err'));
  }

  /// 🔹 Gestisce la logica di redirect da PayPal
  Future<void> _handleUri(Uri uri) async {
    debugPrint('Deep link ricevuto: $uri');

    if (uri.scheme == 'pharmabox' &&
        uri.host == 'payment' &&
        uri.path == '/paypal') {
      final status = uri.queryParameters['status'];
      final orderId = uri.queryParameters['orderId'];

      if (status == 'success') {
        await _activateSubscription(orderId);
        _showSnack('✅ Pagamento completato! Abbonamento attivato.');
      } else if (status == 'cancelled') {
        _showSnack('⚠️ Pagamento annullato.');
      } else {
        _showSnack('❌ Errore durante il pagamento.');
      }
    }
  }

  /// 🔹 Aggiorna Firestore con i dati dell'abbonamento
  Future<void> _activateSubscription(String? orderId) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('Nessun utente loggato, impossibile aggiornare Firestore.');
      return;
    }

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'isActive': true,
        'activationDate': DateTime.now(),
        'expirationDate': DateTime.now().add(const Duration(days: 365)),
        if (orderId != null) 'orderId': orderId,
      });
      debugPrint('✅ Abbonamento attivato per ${user.uid}');
    } catch (e, st) {
      debugPrint('Errore aggiornando Firestore: $e\n$st');
    }
  }

  /// 🔹 Mostra un messaggio
  void _showSnack(String message) {
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      ScaffoldMessenger.of(ctx)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(message), backgroundColor: kPrimary),
        );
    } else {
      debugPrint('⚠️ Nessun contesto disponibile per mostrare SnackBar.');
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'PharmaBox',
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
