import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/in_app_purchase/billing_service.dart';
import 'package:pharma_box/widgets/custom_button.dart';

enum _CouponStatus { idle, validating, valid, invalid, error }

class NonAutorizzato extends StatefulWidget {
  const NonAutorizzato({super.key});

  @override
  State<NonAutorizzato> createState() => _NonAutorizzatoState();
}

class _NonAutorizzatoState extends State<NonAutorizzato> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _couponController = TextEditingController();
  final FocusNode _couponFocusNode = FocusNode();

  _CouponStatus _couponStatus = _CouponStatus.idle;
  String? _couponStatusMessage;
  bool _isProcessingPayment = false;

  int _bonusMonths = 0;
  List<String> _invitedFriends = [];

  DateTime? _appleExpiresAt;
  DateTime? _finalExpiresAt;

  static const int _maxBonusMonths = 12;

  @override
  void initState() {
    super.initState();
    _setupBilling();
  }

  void _setupBilling() {
    final billing = BillingService.instance;
    billing.onPurchasePending = () {
      if (!mounted) return;
      setState(() => _isProcessingPayment = true);
    };

    billing.onPurchaseCompleted = () async {
      if (!mounted) return;
      setState(() => _isProcessingPayment = false);

      _showSnack('Abbonamento attivato 🎉');
      if (mounted) Navigator.of(context).pop(true);
    };

    billing.onPurchaseCanceled = () {
      if (!mounted) return;
      setState(() => _isProcessingPayment = false);
      _showSnack('Pagamento annullato');
    };

    billing.onPurchaseError = () {
      if (!mounted) return;
      setState(() => _isProcessingPayment = false);
      _showSnack('Errore durante il pagamento');
    };
  }

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
        title: Text(
          kAttivaAbbonamento,
          style: const TextStyle(
            color: kBluScuro,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: kBluScuro),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(kUtenteNonAutorizzato, style: textTheme.bodyMedium),
                    const SizedBox(height: 24),

                    if (_bonusMonths > 0) _buildBonusProgress(),

                    const SizedBox(height: 32),

                    _buildCouponSection(),
                  ],
                ),
              ),
            ),

            _buildPriceInfo(),
            const SizedBox(height: 16),
            SafeArea(
              top: false,
              left: false,
              right: false,
              bottom: true,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    title:
                        _isProcessingPayment
                            ? 'Attendere...'
                            : kAttivaAbbonamento,
                    titleColor: kWhite,
                    backgroundColor: kPrimary,
                    onPressed: _isProcessingPayment ? null : _startPurchase,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBonusProgress() {
    final percent = (_bonusMonths / _maxBonusMonths).clamp(0.01, 1.0);

    return Column(
      children: [
        CircularPercentIndicator(
          radius: 90,
          lineWidth: 14,
          percent: percent,
          center: Text(
            '+$_bonusMonths mesi',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          progressColor: kPrimary,
          backgroundColor: Colors.deepPurpleAccent.shade100,
        ),
        const SizedBox(height: 12),
        Text(
          'Hai ottenuto $_bonusMonths mesi gratuiti',
          style: const TextStyle(fontSize: 16),
        ),
        if (_finalExpiresAt != null) ...[
          const SizedBox(height: 8),
          Text(
            'Scadenza stimata: ${_finalExpiresAt!.toLocal()}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildCouponSection() {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Hai un codice invito?', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Inseriscilo per ottenere 1 mese gratuito.',
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _couponController,
          focusNode: _couponFocusNode,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: 'Codice invito',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            suffixIcon: _buildCouponSuffix(),
          ),
          onSubmitted: (_) => _validateCoupon(),
        ),
        if (_couponStatusMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _couponStatusMessage!,
              style: TextStyle(
                color: _couponStatus == _CouponStatus.valid ? kGreen : kRed,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPriceInfo() {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Text('Abbonamento annuale', style: textTheme.labelSmall),
        const SizedBox(height: 4),
        Text(
          '$kAbbonamento € / anno',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (_bonusMonths > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+$_bonusMonths mesi gratuiti inclusi',
              style: textTheme.bodyMedium?.copyWith(color: kGreen),
            ),
          ),
      ],
    );
  }

  // ---------------------------- ACTIONS ----------------------------

  Future<void> _startPurchase() async {
    if (_isProcessingPayment) return;

    setState(() => _isProcessingPayment = true);
    /*
    final products = await BillingService.instance.fetchProducts();
    for (final p in products) {
      print('ID=${p.id} | type=${p.runtimeType}');
    }
*/
    try {
      final products = await BillingService.instance.fetchProducts().timeout(
        const Duration(seconds: 8),
      );

      if (products.isEmpty) {
        throw Exception('Prodotti non disponibili');
      }

      final product = products.firstWhere(
        (p) => p.id == BillingService.yearlySubId,
        orElse: () => throw Exception('Prodotto non trovato'),
      );

      // 🔓 RIABILITA SUBITO IL BOTTONE
      if (mounted) {
        setState(() => _isProcessingPayment = false);
      }

      // 👉 ORA avvia l’acquisto (asincrono)
      BillingService.instance.buySubscription(product);
    } on TimeoutException {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
      }
      _showSnack('Store non disponibile, riprova tra poco');
    } catch (e, stack) {
      debugPrint('❌ START PURCHASE ERROR: $e');
      debugPrintStack(stackTrace: stack);
      if (mounted) {
        setState(() => _isProcessingPayment = false);
      }
      _showSnack('Errore durante l’acquisto');
    }
  }

  Future<void> _validateCoupon() async {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _couponStatus = _CouponStatus.validating;
      _couponStatusMessage = 'Verifica in corso...';
    });

    try {
      final snapshot =
          await _firestore
              .collection('users')
              .where('codiceInvito', isEqualTo: code)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty && _bonusMonths < _maxBonusMonths) {
        await _firestore.collection('users').doc(_auth.currentUser!.uid).update(
          {'bonusMonths': FieldValue.increment(1)},
        );

        setState(() {
          _bonusMonths += 1;
          _couponStatus = _CouponStatus.valid;
          _couponStatusMessage = 'Codice valido! +1 mese gratuito';
        });
      } else {
        setState(() {
          _couponStatus = _CouponStatus.invalid;
          _couponStatusMessage = 'Codice non valido.';
        });
      }
    } catch (_) {
      setState(() {
        _couponStatus = _CouponStatus.error;
        _couponStatusMessage = 'Errore durante la verifica.';
      });
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget? _buildCouponSuffix() {
    if (_couponStatus == _CouponStatus.validating) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_couponStatus == _CouponStatus.valid) {
      return const Icon(Icons.check_circle, color: kGreen);
    }
    if (_couponStatus == _CouponStatus.invalid) {
      return const Icon(Icons.error_outline, color: kRed);
    }
    return IconButton(
      icon: const Icon(Icons.check_circle_outline),
      onPressed: _validateCoupon,
    );
  }
}
