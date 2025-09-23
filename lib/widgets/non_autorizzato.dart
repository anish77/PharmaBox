import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/widgets/custom_button.dart';

class NonAutorizzato extends StatefulWidget {
  const NonAutorizzato({super.key});

  @override
  State<NonAutorizzato> createState() => _NonAutorizzatoState();
}

class _NonAutorizzatoState extends State<NonAutorizzato> {
  static const String _validCoupon = '123SCONTO';
  static const double _discountPercent = 0.10;

  final TextEditingController _couponController = TextEditingController();
  bool _couponValid = false;
  String? _couponMessage;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            kNotAuthorized,
            height: 120,
            width: 120,
            color: kBluScuro,
          ),
          const SizedBox(height: 16),
          Text(
            kUtenteNonAutorizzato,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: kBluScuro,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _couponController,
            textInputAction: TextInputAction.done,
            onChanged: (_) {
              if (_couponValid || _couponMessage != null) {
                setState(() {
                  _couponValid = false;
                  _couponMessage = null;
                });
              }
            },
            onSubmitted: _validateCoupon,
            decoration: InputDecoration(
              labelText: 'Inserisci il buono sconto',
              labelStyle: const TextStyle(color: kBluScuro),
              hintText: 'Codice buono',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: _buildBorder(color: kPrimary),
              enabledBorder: _effectiveBorder(),
              focusedBorder: _effectiveBorder(width: 2),
              suffixIcon:
                  _couponValid
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
            ),
          ),
          if (_couponMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _couponMessage!,
                style: TextStyle(
                  color: _couponValid ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const Spacer(),
          Text(
            _buildPriceLabel(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              color: _couponValid ? Colors.green : kBluScuro,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          CustomButton(
            title: 'Diventa membro',
            titleColor: Colors.white,
            backgroundColor: kPrimary,
            onPressed: () => _handleSubscription(context),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubscription(BuildContext context) async {
    _validateCoupon(_couponController.text);

    final hasCode = _couponController.text.trim().isNotEmpty;
    if (hasCode && !_couponValid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Il buono non è corretto.')));
      return;
    }

    if (_couponValid) {
      final double basePrice = kAbbonamento.toDouble();
      final double discountedPrice = basePrice * (1 - _discountPercent);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Buono applicato: da ${basePrice.toStringAsFixed(2)}€ a ${discountedPrice.toStringAsFixed(2)}€',
          ),
        ),
      );
    }

    await _showPaymentOptions(context);
  }

  void _validateCoupon(String value) {
    final code = value.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _couponValid = false;
        _couponMessage = null;
      });
      return;
    }

    if (code == _validCoupon) {
      setState(() {
        _couponValid = true;
        _couponMessage = 'Buono applicato (-10%)';
        _couponController.value = _couponController.value.copyWith(
          text: code,
          selection: TextSelection.collapsed(offset: code.length),
        );
      });
    } else {
      setState(() {
        _couponValid = false;
        _couponMessage = 'Il buono non è corretto';
      });
    }
  }

  OutlineInputBorder _buildBorder({required Color color, double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  OutlineInputBorder _effectiveBorder({double width = 1}) {
    final Color color;
    if (_couponValid) {
      color = Colors.green;
    } else if (_couponMessage != null) {
      color = Colors.red;
    } else {
      color = kPrimary;
    }
    return _buildBorder(color: color, width: width);
  }

  String _buildPriceLabel() {
    final double basePrice = kAbbonamento.toDouble();
    if (_couponValid) {
      final double discountedPrice = basePrice * (1 - _discountPercent);
      return 'Piano annuale ${basePrice.toStringAsFixed(2)}€ → ${discountedPrice.toStringAsFixed(2)}€';
    }
    return 'Piano annuale ${basePrice.toStringAsFixed(2)}€';
  }

  Future<void> _showPaymentOptions(BuildContext context) async {
    final option = await _choosePaymentMethod(context);
    if (option == null) {
      return;
    }

    switch (option) {
      case _PaymentOption.paypal:
        await _startPaypalPayment(context);
        break;
      case _PaymentOption.creditCard:
        await _startCreditCardPayment(context);
        break;
    }
  }

  Future<_PaymentOption?> _choosePaymentMethod(BuildContext context) {
    return showModalBottomSheet<_PaymentOption>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Scegli il metodo di pagamento',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: kBluScuro,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('PayPal'),
                onTap:
                    () => Navigator.of(
                      bottomSheetContext,
                    ).pop(_PaymentOption.paypal),
              ),
              ListTile(
                leading: const Icon(Icons.credit_card),
                title: const Text('Carta di credito'),
                onTap:
                    () => Navigator.of(
                      bottomSheetContext,
                    ).pop(_PaymentOption.creditCard),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _startPaypalPayment(BuildContext context) async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Pagamento con PayPal'),
          content: const Text(
            'Verrai reindirizzato al portale PayPal per completare il pagamento.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Procedi'),
            ),
          ],
        );
      },
    );

    if (proceed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reindirizzamento a PayPal...')),
      );
      // TODO: integrare la chiamata al gateway PayPal.
    }
  }

  Future<void> _startCreditCardPayment(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    String cardNumber = '';
    String holderName = '';
    String expiration = '';
    String cvv = '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Pagamento con carta'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Numero carta',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 19,
                    validator: (value) {
                      if (value == null || value.trim().length < 16) {
                        return 'Inserisci un numero di carta valido';
                      }
                      return null;
                    },
                    onSaved: (value) => cardNumber = value!.trim(),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Intestatario',
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Inserisci il nome dell\'intestatario';
                      }
                      return null;
                    },
                    onSaved: (value) => holderName = value!.trim(),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Scadenza (MM/AA)',
                    ),
                    keyboardType: TextInputType.datetime,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Inserisci la data di scadenza';
                      }
                      return null;
                    },
                    onSaved: (value) => expiration = value!.trim(),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'CVV'),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    validator: (value) {
                      if (value == null || value.trim().length < 3) {
                        return 'Inserisci un CVV valido';
                      }
                      return null;
                    },
                    onSaved: (value) => cvv = value!.trim(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  formKey.currentState?.save();
                  Navigator.of(dialogContext).pop(true);
                }
              },
              child: const Text('Paga'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pagamento con carta in elaborazione...')),
      );
      debugPrint(
        'Dati carta -> numero: $cardNumber, intestatario: $holderName, scadenza: $expiration, cvv: $cvv',
      );
      // TODO: integrare la chiamata al gateway di pagamento per carte.
    }
  }
}

enum _PaymentOption { paypal, creditCard }
