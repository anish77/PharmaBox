import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/services/stripe_service.dart';
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
  static const double _discountPercent = 0.10;
  static const String _paypalCreateOrderEndpoint =
      'https://europe-west1-pharmabox-1c149.cloudfunctions.net/createPaypalOrder';
  static const String _paypalRedirectTarget = 'pharmabox://payment/paypal';

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

  bool get _couponValid => _couponStatus == _CouponStatus.valid;
  bool get _isValidatingCoupon => _couponStatus == _CouponStatus.validating;

  double get _basePrice => kAbbonamento.toDouble();
  double get _effectivePrice =>
      _couponValid ? _basePrice * (1 - _discountPercent) : _basePrice;

  @override
  void dispose() {
    _couponController.dispose();
    _couponFocusNode.dispose();
    super.dispose();
  }

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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
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
            color: kBluScuro.withValues(alpha: 0.7),
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
        if (_couponValid) ...[
          const SizedBox(height: 4),
          Text(
            'Codice invito applicato (-${(_discountPercent * 100).toStringAsFixed(0)}%)',
            style: textTheme.bodySmall?.copyWith(
              color: kGreen,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  OutlineInputBorder _effectiveBorder({double width = 1}) {
    if (_couponStatus == _CouponStatus.valid) {
      return _inputBorder(kGreen, width: width);
    }
    if (_couponStatus == _CouponStatus.invalid ||
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
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_couponStatus == _CouponStatus.valid) {
      return const Icon(Icons.check_circle, color: kGreen);
    }

    if (_couponStatus == _CouponStatus.invalid ||
        _couponStatus == _CouponStatus.error) {
      return const Icon(Icons.error_outline, color: kRed);
    }

    if (_couponController.text.trim().isEmpty) {
      return null;
    }

    return IconButton(
      tooltip: 'Verifica codice invito',
      color: kPrimary,
      icon: const Icon(Icons.check_circle_outline),
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
    final trimmed = value.trim();
    setState(() {
      if (trimmed.isEmpty) {
        _couponStatus = _CouponStatus.idle;
        _couponStatusMessage = null;
        _inviterUid = null;
      } else if (_couponStatus == _CouponStatus.valid ||
          _couponStatus == _CouponStatus.invalid ||
          _couponStatus == _CouponStatus.error) {
        _couponStatus = _CouponStatus.idle;
        _couponStatusMessage = null;
      }
    });
  }

  Future<void> _handleSubscription(BuildContext context) async {
    FocusScope.of(context).unfocus();

    final hasCoupon = _couponController.text.trim().isNotEmpty;
    if (hasCoupon) {
      await _validateCoupon(_couponController.text);
      if (!mounted) return;

      if (!_couponValid) {
        _showSnack('Il codice invito non è valido.');
        return;
      }

      await _ensureCurrentUserData();
      await _registerReferral();
    }

    if (!mounted) return;

    final selectedOption = await _choosePaymentMethod(context);
    if (!mounted || selectedOption == null) return;

    switch (selectedOption) {
      case _PaymentOption.paypal:
        await _startPaypalPayment(context);
        break;
      case _PaymentOption.creditCard:
        await StripeService.instance.makePayment(
          _effectivePrice.toInt(),
          context: context,
        );
        break;
    }
  }

  Future<_PaymentOption?> _choosePaymentMethod(BuildContext context) {
    return showModalBottomSheet<_PaymentOption>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
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
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('PayPal'),
                onTap:
                    () => Navigator.of(sheetContext).pop(_PaymentOption.paypal),
              ),
              ListTile(
                leading: const Icon(Icons.credit_card),
                title: const Text('Carta di credito'),
                onTap:
                    () => Navigator.of(
                      sheetContext,
                    ).pop(_PaymentOption.creditCard),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _validateCoupon([String? input]) async {
    final rawInput = (input ?? _couponController.text).trim();
    if (rawInput.isEmpty) {
      if (!mounted) return;
      setState(() {
        _couponStatus = _CouponStatus.idle;
        _couponStatusMessage = null;
        _inviterUid = null;
      });
      return;
    }

    setState(() {
      _couponStatus = _CouponStatus.validating;
      _couponStatusMessage = 'Verifico il codice...';
    });

    final candidates = <String>{
      rawInput,
      rawInput.toUpperCase(),
      rawInput.toLowerCase(),
    };

    try {
      QuerySnapshot<Map<String, dynamic>>? snapshot;
      for (final candidate in candidates) {
        snapshot =
            await _firestore
                .collection('users')
                .where('codiceInvito', isEqualTo: candidate)
                .limit(1)
                .get();

        if (snapshot.docs.isNotEmpty) {
          break;
        }
      }

      if (!mounted) return;

      if (snapshot != null && snapshot.docs.isNotEmpty) {
        final inviterDoc = snapshot.docs.first;
        final data = inviterDoc.data();
        final inviteCode =
            (data['codiceInvito'] as String? ?? rawInput).toUpperCase();

        setState(() {
          _couponStatus = _CouponStatus.valid;
          _couponStatusMessage = 'Buono applicato (-10%)';
          _inviterUid = inviterDoc.id;
          _couponController.value = _couponController.value.copyWith(
            text: inviteCode,
            selection: TextSelection.collapsed(offset: inviteCode.length),
          );
        });
      } else {
        setState(() {
          _couponStatus = _CouponStatus.invalid;
          _couponStatusMessage = 'Il codice non è corretto.';
          _inviterUid = null;
        });
      }
    } catch (error, stackTrace) {
      debugPrint('Coupon validation failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _couponStatus = _CouponStatus.error;
        _couponStatusMessage = 'Errore nella verifica, riprova più tardi.';
        _inviterUid = null;
      });
    }
  }

  Future<void> _ensureCurrentUserData() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final snapshot = await _firestore.collection('users').doc(userId).get();
      final data = snapshot.data();
      if (data == null) return;

      final first = (data['firstName'] as String?)?.trim();
      final last = (data['lastName'] as String?)?.trim();

      _couponFirstName = first?.isNotEmpty == true ? first : null;
      _couponLastName = last?.isNotEmpty == true ? last : null;
    } catch (error, stackTrace) {
      debugPrint('Unable to load current user data: $error\n$stackTrace');
    }
  }

  Future<void> _registerReferral() async {
    final inviterUid = _inviterUid;
    if (inviterUid == null || inviterUid.isEmpty) return;

    final parts = <String>[];
    final first = _couponFirstName;
    if (first != null && first.trim().isNotEmpty) {
      parts.add(first.trim());
    }
    final last = _couponLastName;
    if (last != null && last.trim().isNotEmpty) {
      parts.add(last.trim());
    }

    final friendName = parts.isEmpty ? 'Nuovo invito' : parts.join(' ');
    final entryLabel = '$friendName - ${DateTime.now().toIso8601String()}';

    try {
      await _firestore.collection('users').doc(inviterUid).update({
        'amiciInvitati': FieldValue.arrayUnion([entryLabel]),
      });
    } catch (error, stackTrace) {
      debugPrint('Unable to update amiciInvitati: $error\n$stackTrace');
    }
  }

  Future<void> _startPaypalPayment(BuildContext context) async {
    if (!mounted) return;

    setState(() {
      _isProcessingPayment = true;
    });

    final amount = _effectivePrice.toStringAsFixed(2);

    try {
      final response = await http.post(
        Uri.parse(_paypalCreateOrderEndpoint),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amount,
          'currency': 'EUR',
          'redirect': _paypalRedirectTarget,
          'cancelRedirect': _paypalRedirectTarget,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint(
          'PayPal order failed ${response.statusCode}: ${response.body}',
        );
        _showSnack('Errore nella creazione dell\'ordine PayPal.');
        return;
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final approvalUrl = payload['approvalUrl'] as String?;

      if (approvalUrl == null || approvalUrl.isEmpty) {
        debugPrint('PayPal response missing approvalUrl: $payload');
        _showSnack('Risposta PayPal non valida.');
        return;
      }

      final launched = await launchUrl(
        Uri.parse(approvalUrl),
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        _showSnack('Impossibile aprire PayPal.');
      }
    } catch (error, stackTrace) {
      debugPrint('PayPal order exception: $error\n$stackTrace');
      _showSnack('Errore di rete durante la creazione dell\'ordine PayPal.');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
