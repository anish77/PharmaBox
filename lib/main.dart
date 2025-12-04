import 'dart:async';
import 'dart:convert';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/firebase/firebase_options.dart';
import 'package:pharma_box/view/login_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

// Provider BLE globali
final bleScanningProvider = StateProvider<bool>((ref) => false);
final bleStatusProvider = StateProvider<String>((ref) => "");
final scannedBarcodeProvider = StateProvider<String?>((ref) => null);
final bleConnected = StateProvider<bool>((ref) => false);

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _setupStripe(mode: 'live'); // ✅ inizializzazione dinamica
  runApp(const ProviderScope(child: MyApp()));
  debugPrint("🔧 Stripe.publishableKey: ${Stripe.publishableKey}");
}

/// ✅ Ottiene la chiave pubblica Stripe dal backend in modo sicuro
Future<void> _setupStripe({String mode = 'test'}) async {
  String? publishableKey;
  try {
    final uri = Uri.parse(
      'https://europe-west1-pharmabox-1c149.cloudfunctions.net/getStripePublishableKey',
    ).replace(queryParameters: {'mode': mode});

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Errore ottenendo la chiave Stripe: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    publishableKey = data['key']?.toString().trim();

    if (publishableKey == null ||
        publishableKey.isEmpty ||
        publishableKey.startsWith('sk_')) {
      throw Exception('Chiave Stripe non valida dal server.');
    }

    Stripe.publishableKey = publishableKey;
    await Stripe.instance.applySettings();
    debugPrint('✅ Stripe inizializzato con chiave $mode.');
  } catch (e, st) {
    debugPrint(
      '❌ Impossibile inizializzare Stripe ($mode): $e Key: ${publishableKey ?? '<unset>'}',
    );
    debugPrint('$st');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AppLinks? _appLinks;
  StreamSubscription<Uri>? _linkSub;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _initDeepLinkListener();
  }

  /// 🔹 Ascolta deep link (PayPal o Stripe)
  Future<void> _initDeepLinkListener() async {
    _appLinks ??= AppLinks();
    try {
      final initialUri = await _appLinks!.getInitialLink();
      if (initialUri != null) await _handleUri(initialUri);
    } catch (e) {
      debugPrint('Errore iniziale URI: $e');
    }

    await _linkSub?.cancel();
    _linkSub = _appLinks!.uriLinkStream.listen(
      (uri) async => _handleUri(uri),
      onError: (err) => debugPrint('Errore deep link: $err'),
    );
  }

  /// 🔹 Gestisce i deep link
  Future<void> _handleUri(Uri uri) async {
    debugPrint('Deep link ricevuto: $uri');

    if (uri.scheme != 'pharmabox' || uri.host != 'payment') return;

    final status = uri.queryParameters['status'];
    final orderId = uri.queryParameters['orderId'];
    final paymentIntent = uri.queryParameters['payment_intent'];

    if (status == 'success') {
      if (uri.path == '/paypal') {
        await _activateSubscription('PayPal', orderId);
        _closeActiveFlow(true);
      } else if (uri.path == '/stripe') {
        await _verifyStripePayment(paymentIntent);
      }
      _showSnack('✅ Pagamento completato! Abbonamento attivato.');
    } else if (status == 'cancelled') {
      _showSnack('⚠️ Pagamento annullato.');
    } else {
      _showSnack('❌ Errore durante il pagamento.');
    }
  }

  /// 🔒 Verifica pagamento Stripe via backend
  Future<void> _verifyStripePayment(String? paymentIntentId) async {
    if (paymentIntentId == null) return;

    try {
      final response = await http.post(
        Uri.parse(
          'https://europe-west1-pharmabox-1c149.cloudfunctions.net/verifyStripePaymentIntent',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'paymentIntentId': paymentIntentId, 'mode': 'test'}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        await _activateSubscription('Stripe', paymentIntentId);
        _showSnack('✅ Pagamento completato! Abbonamento attivato.');
      } else {
        debugPrint('❌ Pagamento non completato: ${data['status']}');
        _showSnack('❌ Pagamento non completato: ${data['status']}');
      }
    } catch (e) {
      debugPrint('Errore verifica Stripe: $e');
      _showSnack('❌ Errore durante la verifica del pagamento.');
    }
  }

  /// 🔹 Aggiorna Firestore con i dati dell’abbonamento
  Future<void> _activateSubscription(String provider, String? id) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'isActive': true,
        'activationDate': DateTime.now(),
        'expirationDate': DateTime.now().add(const Duration(days: 365)),
        'paymentProvider': provider,
        'newMember': false,
        'amiciInvitati': <String>[],
        if (id != null) 'paymentId': id,
      });
      debugPrint('✅ Abbonamento attivato con $provider per ${user.uid}');
    } catch (e) {
      debugPrint('Errore aggiornando Firestore: $e');
    }
  }

  void _showSnack(String message) {
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      ScaffoldMessenger.of(ctx)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(message), backgroundColor: kPrimary),
        );
    }
  }

  void _closeActiveFlow([bool activated = true]) {
    final nav = navigatorKey.currentState;
    if (nav != null && nav.canPop()) {
      nav.maybePop(activated);
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
