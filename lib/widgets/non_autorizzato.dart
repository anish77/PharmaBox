import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/widgets/custom_button.dart';

class NonAutorizzato extends StatefulWidget {
  const NonAutorizzato({super.key});

  @override
  State<NonAutorizzato> createState() => _NonAutorizzatoState();
}

class _NonAutorizzatoState extends State<NonAutorizzato> {
  static const double _discountPercent = 0.10;

  final TextEditingController _couponController = TextEditingController();
  bool _couponValid = false;
  String? _couponMessage;
  String? _couponFirstName;
  String? _couponLastName;
  String? _inviterUid;
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

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
            onSubmitted: (value) {
              _validateCoupon(value);
            },
            decoration: InputDecoration(
              labelText: 'Inserisci il codice invito',
              labelStyle: const TextStyle(color: kBluScuro),
              hintText: 'Codice invito',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: _buildBorder(color: kPrimary),
              enabledBorder: _effectiveBorder(),
              focusedBorder: _effectiveBorder(width: 1),
              suffixIcon:
                  _couponValid
                      ? const Icon(Icons.check_circle, color: kGreen)
                      : null,
            ),
          ),
          if (_couponMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _couponMessage!,
                style: TextStyle(
                  color: _couponValid ? kGreen : kRed,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const Spacer(),
          Text(
            _buildPriceLabel(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              color: _couponValid ? kGreen : kBluScuro,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          CustomButton(
            title: 'Diventa membro',
            titleColor: kWhite,
            backgroundColor: kPrimary,
            onPressed: () => _handleSubscription(context),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubscription(BuildContext context) async {
    await _validateCoupon(_couponController.text);

    final hasCode = _couponController.text.trim().isNotEmpty;
    if (hasCode && !_couponValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Il codice non è corretto.')),
      );
      return;
    }

    if (_couponValid) {
      await _loadCurrentUserData();
      await _addAmiciInvitati();
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

    //dopo
    // await _showPaymentOptions(context);
  }

  Future<void> _loadCurrentUserData() async {
    if (uid == null) return;
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!doc.exists) return;
      final data = doc.data();
      if (data == null) return;
      final firstName = (data['firstName'] as String?) ?? '';
      final lastName = (data['lastName'] as String?) ?? '';

      setState(() {
        _couponFirstName = firstName;
        _couponLastName = lastName;
      });
    } catch (_) {
      // ignora errori di caricamento
    }
  }

  Future<void> _addAmiciInvitati() async {
    final inviterUid = _inviterUid;
    if (inviterUid == null || inviterUid.isEmpty) return;

    final nomeAmico = '$_couponFirstName $_couponLastName - ${DateTime.now()}';

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(inviterUid);

    await docRef.update({
      'amiciInvitati': FieldValue.arrayUnion([nomeAmico]),
    });
  }

  Future<void> _validateCoupon(String value) async {
    final rawInput = value.trim();
    final upperInput = rawInput.toUpperCase();
    final lowerInput = rawInput.toLowerCase();

    if (rawInput.isEmpty) {
      setState(() {
        _couponValid = false;
        _couponMessage = null;
      });
      return;
    }

    try {
      final users = FirebaseFirestore.instance.collection('users');

      QuerySnapshot<Map<String, dynamic>> query =
          await users.where('codiceInvito', isEqualTo: rawInput).limit(1).get();

      if (query.docs.isEmpty && upperInput != rawInput) {
        query =
            await users
                .where('codiceInvito', isEqualTo: upperInput)
                .limit(1)
                .get();
      }
      if (query.docs.isEmpty &&
          lowerInput != rawInput &&
          lowerInput != upperInput) {
        query =
            await users
                .where('codiceInvito', isEqualTo: lowerInput)
                .limit(1)
                .get();
      }

      final isValid = query.docs.isNotEmpty;

      if (isValid) {
        setState(() {
          _couponValid = true;
          final inviterDoc = query.docs.first;
          _inviterUid = inviterDoc.id;
          _couponMessage = 'Buono applicato (-10%)';
          _couponController.value = _couponController.value.copyWith(
            text: upperInput,
            selection: TextSelection.collapsed(offset: upperInput.length),
          );
        });
      } else {
        setState(() {
          _inviterUid = "";
          _couponValid = false;
          _couponMessage = 'Il codice non è corretto';
        });
      }
    } catch (errore) {
      setState(() {
        _inviterUid = "";
        _couponValid = false;
        _couponMessage = 'Errore nella verifica, riprova.';
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
      color = kGreen;
    } else if (_couponMessage != null) {
      color = kRed;
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
