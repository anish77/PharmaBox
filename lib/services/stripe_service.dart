import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/include/ble_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pharma_box/view/selected_list_page.dart';

class StripeService {
  StripeService._(); //private constractor

  static final StripeService instance = StripeService._();

  Future<void> makePayment(int amount, {required BuildContext context}) async {
    try {
      Map<String, dynamic>? paymentIntent = await _createPaymentIntent(
        amount,
        'EUR',
      );

      if (paymentIntent == null) {
        logger.e("Impossibile creare il Payment Intent");
        return;
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'],
          merchantDisplayName: 'PharmaBox',
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      final paymentIntentId = paymentIntent['id'];
      await _activateStripeSubscription(paymentIntentId);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Pagamento completato! Abbonamento attivato.'),
        ),
      );
      Navigator.of(context).pop();
    } on StripeException catch (e) {
      logger.e("Stripe error: ${e.error.localizedMessage}");
    } catch (e) {
      logger.e("Errore durante il pagamento: $e");
    }
  }

  Future<Map<String, dynamic>?> _createPaymentIntent(
    int amount,
    String currency,
  ) async {
    try {
      final Dio dio = Dio();
      Map<String, dynamic> data = {
        'amount': _calculateAmount(amount),
        'currency': currency,
      };
      var response = await dio.post(
        'https://api.stripe.com/v1/payment_intents',
        data: data,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {'Authorization': 'Bearer $kStripeSecretKey'},
        ),
      );
      if (response.data != null) {
        logger.i("Payment Intent creato con successo");
        logger.d(response.data['client_secret']);
        return response.data;
      }
      return null;
    } catch (e) {
      logger.e("Errore durante la creazione del Payment Intent: $e");
      return null;
    }
  }

  Future<void> _processPayment() async {
    try {
      await Stripe.instance.presentPaymentSheet();
      logger.i("Pagamento completato con successo");
    } on StripeException catch (e) {
      logger.e("Stripe error: ${e.error.localizedMessage}");
    } catch (e) {
      logger.e("Errore durante il processo di pagamento: $e");
    }
  }

  String _calculateAmount(int amount) {
    final calculatedAmount =
        amount * 100; // Convert to the smallest currency unit
    return calculatedAmount.toString();
  }

  Future<void> _activateStripeSubscription(String paymentIntentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      logger.e('Nessun utente loggato, impossibile aggiornare Firestore.');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'isActive': true,
            'activationDate': DateTime.now(),
            'expirationDate': DateTime.now().add(const Duration(days: 365)),
            'paymentIntentId': paymentIntentId,
          });
      logger.i('✅ Abbonamento Stripe attivato per ${user.uid}');
    } catch (e, st) {
      logger.e('Errore aggiornando Firestore: $e');
    }
  }
}
