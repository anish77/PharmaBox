import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/widgets/custom_button.dart';

class NonAutorizzato extends StatelessWidget {
  const NonAutorizzato({super.key});

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
          const Spacer(),
          Text(
            'Piano annuale 199€/anno',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 16,
                  color: kBluScuro,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            title: 'Diventa membro',
            titleColor: Colors.white,
            backgroundColor: kPrimary,
            onPressed: () => _showPaymentOptions(context),
          ),
        ],
      ),
    );
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
                onTap: () => Navigator.of(bottomSheetContext)
                    .pop(_PaymentOption.paypal),
              ),
              ListTile(
                leading: const Icon(Icons.credit_card),
                title: const Text('Carta di credito'),
                onTap: () => Navigator.of(bottomSheetContext)
                    .pop(_PaymentOption.creditCard),
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
        const SnackBar(
          content: Text('Reindirizzamento a PayPal...'),
        ),
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
                    decoration: const InputDecoration(labelText: 'Numero carta'),
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
                    decoration: const InputDecoration(labelText: 'Intestatario'),
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
                    decoration: const InputDecoration(labelText: 'Scadenza (MM/AA)'),
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
        const SnackBar(
          content: Text('Pagamento con carta in elaborazione...'),
        ),
      );
      debugPrint(
        'Dati carta -> numero: $cardNumber, intestatario: $holderName, scadenza: $expiration, cvv: $cvv',
      );
      // TODO: integrare la chiamata al gateway di pagamento per carte.
    }
  }
}

enum _PaymentOption { paypal, creditCard }
