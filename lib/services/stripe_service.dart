import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:pharma_box/include/ble_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      Navigator.of(context).pop(true);
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
      final dio = Dio();
      final response = await dio.post(
        'https://europe-west1-pharmabox-1c149.cloudfunctions.net/createStripePaymentIntent',
        options: Options(
          contentType: Headers.jsonContentType,
          headers: {'Accept': 'application/json'},
        ),
        data: {
          'amount': _calculateAmount(amount), // centesimi
          'currency': currency,
          'mode': 'test', // <- invia test
        },
      );

      if (response.statusCode == 200) {
        logger.i("✅ Payment Intent creato tramite Cloud Function");

        // assicurati che sia una Map
        final data =
            response.data is String
                ? Map<String, dynamic>.from(jsonDecode(response.data))
                : Map<String, dynamic>.from(response.data);

        logger.i("📦 PaymentIntent ricevuto: $data");

        return data;
      } else {
        logger.e("❌ Errore: ${response.data}");
        return null;
      }
    } catch (e) {
      logger.e("Errore chiamando la funzione Cloud: $e");
      return null;
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
    } catch (e) {
      logger.e('Errore aggiornando Firestore: $e');
    }
  }
}
