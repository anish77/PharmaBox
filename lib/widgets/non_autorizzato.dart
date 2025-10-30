import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/widgets/custom_button.dart';
import 'package:url_launcher/url_launcher.dart';

enum _CouponStatus { idle, validating, valid, invalid, error }

enum _PaymentOption { paypal, creditCard }

class NonAutorizzato extends StatefulWidget {
  const NonAutorizzato({super.key});

  @override
  State<NonAutorizzato> createState() => _NonAutorizzatoState();
}

class _NonAutorizzatoState extends State<NonAutorizzato> {
  // 🔹 Endpoint Firebase Functions
  static const String _paypalCreateOrderEndpoint =
      'https://europe-west1-pharmabox-1c149.cloudfunctions.net/createPaypalOrder';
  static const String _stripeCreateIntentEndpoint =
      'https://europe-west1-pharmabox-1c149.cloudfunctions.net/createStripePaymentIntent';
  static const String _paypalRedirectTarget = 'pharmabox://payment/paypal';

  // 🔹 Coupon e utente
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _couponController = TextEditingController();
  final FocusNode _couponFocusNode = FocusNode();

  _CouponStatus _couponStatus = _CouponStatus.idle;
  String? _couponStatusMessage;
  String? _inviterUid;
  String? _couponFirstName;
  String? _couponLastName;
  bool _isProcessingPayment = false;

  static const double _discountPercent = 0.10;
  double get _basePrice => kAbbonamento.toDouble();
  double get _effectivePrice =>
      _couponValid ? _basePrice * (1 - _discountPercent) : _basePrice;

  bool get _couponValid => _couponStatus == _CouponStatus.valid;
  bool get _isValidatingCoupon => _couponStatus == _CouponStatus.validating;

  @override
  void dispose() {
    _couponController.dispose();
    _couponFocusNode.dispose();
    super.dispose();
  }

  // ---------------------------- UI ----------------------------

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: kBluScuro),
        titleSpacing: 0,
        centerTitle: false,
        title: const Text(
          'Diventa membro',
          style: TextStyle(
            color: kBluScuro,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      kUtenteNonAutorizzato,
                      style: textTheme.bodyMedium?.copyWith(
                        color: kBluScuro,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildCouponSection(context),
                  ],
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              fillOverscroll: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPriceSummary(context),
                    const SizedBox(height: 16),
                    CustomButton(
                      title:
                          _isProcessingPayment
                              ? 'Attendere...'
                              : 'Diventa membro',
                      titleColor: kWhite,
                      backgroundColor: kPrimary,
                      onPressed:
                          _isProcessingPayment
                              ? null
                              : () => _handleSubscription(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Hai un codice invito?',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: kBluScuro,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Inseriscilo qui sotto per ottenere subito uno sconto del 10% sul primo anno.',
          style: textTheme.bodySmall?.copyWith(
            color: kBluScuro.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _couponController,
          focusNode: _couponFocusNode,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          onChanged: _onCouponChanged,
          onSubmitted: (value) => _validateCoupon(value),
          decoration: InputDecoration(
            labelText: 'Codice invito',
            hintText: 'ABC123',
            labelStyle: const TextStyle(color: kBluScuro),
            border: _inputBorder(kPrimary),
            enabledBorder: _effectiveBorder(),
            focusedBorder: _effectiveBorder(width: 1.4),
            suffixIcon: _buildCouponSuffix(),
          ),
        ),
        if (_couponStatusMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _couponStatusMessage!,
              style: textTheme.bodyMedium?.copyWith(
                color: _statusMessageColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPriceSummary(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final basePrice = _basePrice;
    final effectivePrice = _effectivePrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Piano annuale',
          style: textTheme.labelSmall?.copyWith(
            letterSpacing: 0.4,
            color: kBluScuro.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          _couponValid
              ? '${basePrice.toStringAsFixed(2)}€ → ${effectivePrice.toStringAsFixed(2)}€'
              : '${effectivePrice.toStringAsFixed(2)}€',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: _couponValid ? kGreen : kBluScuro,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ---------------------------- LOGICA ----------------------------

  Future<void> _handleSubscription(BuildContext context) async {
    FocusScope.of(context).unfocus();

    if (_couponController.text.trim().isNotEmpty) {
      await _validateCoupon(_couponController.text);
      if (!_couponValid) {
        _showSnack('Il codice invito non è valido.');
        return;
      }
    }

    final option = await _choosePaymentMethod(context);
    if (option == null) return;

    switch (option) {
      case _PaymentOption.paypal:
        await _startPaypalPayment(context);
        break;
      case _PaymentOption.creditCard:
        await _startStripePayment(context);
        break;
    }
  }

  Future<_PaymentOption?> _choosePaymentMethod(BuildContext context) async {
    return showModalBottomSheet<_PaymentOption>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Scegli il metodo di pagamento',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: kBluScuro,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: const Text('PayPal'),
                  onTap: () => Navigator.pop(ctx, _PaymentOption.paypal),
                ),
                ListTile(
                  leading: const Icon(Icons.credit_card),
                  title: const Text('Carta di credito'),
                  onTap: () => Navigator.pop(ctx, _PaymentOption.creditCard),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _startStripePayment(BuildContext context) async {
    setState(() => _isProcessingPayment = true);

    final amount = (_effectivePrice * 100).toInt();

    try {
      final response = await http.post(
        Uri.parse(_stripeCreateIntentEndpoint),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': amount, 'currency': 'EUR'}),
      );

      if (response.statusCode != 200) {
        _showSnack('Errore nella creazione del pagamento.');
        return;
      }

      final data = jsonDecode(response.body);
      final clientSecret = data['client_secret'];

      if (clientSecret == null) {
        _showSnack('Errore: client_secret mancante.');
        return;
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'PharmaBox',
        ),
      );

      await Stripe.instance.presentPaymentSheet();
      _showSnack('✅ Pagamento completato!');
    } catch (e) {
      _showSnack('Errore durante il pagamento con carta.');
      debugPrint('Stripe error: $e');
    } finally {
      setState(() => _isProcessingPayment = false);
    }
  }

  Future<void> _startPaypalPayment(BuildContext context) async {
    setState(() => _isProcessingPayment = true);
    final amount = _effectivePrice.toStringAsFixed(2);

    try {
      final response = await http.post(
        Uri.parse(_paypalCreateOrderEndpoint),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': amount, 'currency': 'EUR'}),
      );

      final data = jsonDecode(response.body);
      final approvalUrl =
          data['approvalUrl'] ??
          (data['links'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .firstWhere(
                (link) => link['rel'] == 'approve',
                orElse: () => const {},
              )['href'];

      if (approvalUrl != null) {
        await launchUrl(
          Uri.parse(approvalUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showSnack('Errore nel pagamento PayPal.');
      }
    } catch (e) {
      _showSnack('Errore durante la connessione a PayPal.');
      debugPrint('PayPal error: $e');
    } finally {
      setState(() => _isProcessingPayment = false);
    }
  }

  // ---------------------------- UTIL ----------------------------

  OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );

  OutlineInputBorder _effectiveBorder({double width = 1}) {
    if (_couponStatus == _CouponStatus.valid) {
      return _inputBorder(kGreen, width: width);
    } else if (_couponStatus == _CouponStatus.invalid ||
        _couponStatus == _CouponStatus.error) {
      return _inputBorder(kRed, width: width);
    }
    return _inputBorder(kPrimary, width: width);
  }

  Widget? _buildCouponSuffix() {
    if (_isValidatingCoupon) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_couponStatus == _CouponStatus.valid) {
      return const Icon(Icons.check_circle, color: kGreen);
    }
    if (_couponStatus == _CouponStatus.invalid) {
      return const Icon(Icons.error_outline, color: kRed);
    }
    if (_couponController.text.trim().isEmpty) return null;
    return IconButton(
      icon: const Icon(Icons.check_circle_outline),
      color: kPrimary,
      onPressed: () => _validateCoupon(_couponController.text),
    );
  }

  Color _statusMessageColor() {
    switch (_couponStatus) {
      case _CouponStatus.valid:
        return kGreen;
      case _CouponStatus.validating:
        return kBluScuro;
      default:
        return kRed;
    }
  }

  void _onCouponChanged(String value) {
    setState(() {
      _couponStatus = _CouponStatus.idle;
      _couponStatusMessage = null;
      _inviterUid = null;
    });
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
  }

  // ---------------------------- FIRESTORE ----------------------------

  Future<void> _validateCoupon([String? input]) async {
    final rawInput = (input ?? _couponController.text).trim();
    if (rawInput.isEmpty) return;
    setState(() {
      _couponStatus = _CouponStatus.validating;
      _couponStatusMessage = 'Verifico il codice...';
    });

    try {
      final snapshot =
          await _firestore
              .collection('users')
              .where('codiceInvito', isEqualTo: rawInput.toUpperCase())
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _couponStatus = _CouponStatus.valid;
          _couponStatusMessage = 'Codice valido! -10% applicato';
        });
      } else {
        setState(() {
          _couponStatus = _CouponStatus.invalid;
          _couponStatusMessage = 'Codice non valido.';
        });
      }
    } catch (e) {
      _couponStatus = _CouponStatus.error;
      _couponStatusMessage = 'Errore durante la verifica.';
      debugPrint('Coupon error: $e');
    }
  }
}
