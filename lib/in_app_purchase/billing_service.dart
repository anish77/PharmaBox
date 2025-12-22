import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter/foundation.dart';
import 'package:pharma_box/data/constants.dart';
import 'dart:io' show Platform;

class BillingService {
  BillingService._();
  static final BillingService instance = BillingService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  /// Callback verso UI
  VoidCallback? onPurchasePending;
  VoidCallback? onPurchaseCompleted;
  VoidCallback? onPurchaseError;
  VoidCallback? onPurchaseCanceled;

  /// Subscription product ID
  static const String yearlySubId = kstoreKeySubscription;
  final Set<String> _productIds = {yearlySubId};
  final Set<String> _processedPurchases = {};

  /// True SOLO se l’utente ha cliccato “Attiva abbonamento”
  bool _userInitiatedPurchase = false;
  bool _initialized = false;

  // --------------------------------------------------
  // INIT
  // --------------------------------------------------
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final available = await _iap.isAvailable();
    if (!available) {
      throw Exception('Store non disponibile');
    }

    _subscription = _iap.purchaseStream.listen(_handlePurchaseUpdates);
  }

  // --------------------------------------------------
  // DISPOSE
  // --------------------------------------------------
  Future<void> dispose() async {
    await _subscription?.cancel();
  }

  // --------------------------------------------------
  // LOAD PRODUCTS
  // --------------------------------------------------
  Future<List<ProductDetails>> fetchProducts() async {
    log('📦 fetchProducts START');
    final response = await _iap.queryProductDetails(_productIds);
    log('📦 fetchProducts END');
    log('🟢 Found $response products');

    if (response.error != null) {
      log('❌ Product query error: ${response.error}');
      return [];
    }

    if (response.productDetails.isEmpty) {
      log('⚠️ Nessun prodotto trovato');
    }

    return response.productDetails;
  }

  // --------------------------------------------------
  // USER ACTION: BUY
  // --------------------------------------------------
  void buySubscription(ProductDetails product) {
    log('🟢 buySubscription START');
    log('🧾 productId: ${product.id}');
    log('💰 price: ${product.price}');
    log('📦 title: ${product.title}');
    log('📝 description: ${product.description}');

    _userInitiatedPurchase = true;
    onPurchasePending?.call();

    final param = PurchaseParam(productDetails: product);
    _iap.buyNonConsumable(purchaseParam: param);

    log('🟡 buyNonConsumable CALLED');
  }

  // --------------------------------------------------
  // USER ACTION: RESTORE
  // --------------------------------------------------
  Future<void> restorePurchases() async {
    if (Platform.isIOS) {
      await _iap.restorePurchases();
    } else {
      log('ℹ️ Restore non necessario su Android');
    }
  }

  // --------------------------------------------------
  // PURCHASE LISTENER
  // --------------------------------------------------
  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          log('⏳ Acquisto in corso...');
          onPurchasePending?.call();
          break;

        case PurchaseStatus.error:
          log('❌ Errore acquisto: ${purchase.error}');
          _userInitiatedPurchase = false;
          onPurchaseError?.call();
          break;

        case PurchaseStatus.canceled:
          log('🚫 Acquisto annullato');
          _userInitiatedPurchase = false;
          onPurchaseCanceled?.call();
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final id = purchase.purchaseID ?? purchase.productID;

          if (_processedPurchases.contains(id)) {
            log('🔁 Purchase già processata: $id');
            break;
          }

          _processedPurchases.add(id);

          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }

          final valid = await _verifyPurchase(purchase);
          if (valid) {
            await _deliverSubscription(purchase);
            onPurchaseCompleted?.call();
          }

          _userInitiatedPurchase = false;
          break;
      }
    }
  }

  // --------------------------------------------------
  // VERIFY (PLACEHOLDER)
  // --------------------------------------------------
  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    /// TODO: verifica receipt server-side
    return true;
  }

  // --------------------------------------------------
  // DELIVER (MVP)
  // --------------------------------------------------

  String getPaymentProvider() {
    if (Platform.isIOS) return 'apple';
    if (Platform.isAndroid) return 'google';
    return 'unknown';
  }

  Future<void> _deliverSubscription(PurchaseDetails purchase) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final idToken = await user.getIdToken();

    final url = Uri.parse(
      'https://us-central1-pharmabox-1c149.cloudfunctions.net/verifyPurchase',
    );

    final resp = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'platform': Platform.isIOS ? 'ios' : 'android',
        'productId': purchase.productID,
        // serverVerificationData su iOS = receipt/jws, su Android spesso contiene token
        'verificationData': purchase.verificationData.serverVerificationData,
      }),
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('verifyPurchase failed: ${resp.body}');
    }
  }
}
