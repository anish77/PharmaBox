import 'package:flutter/services.dart';
import 'package:pharma_box/include/general_functions.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenuecatService {
  /// 🔹 Configure RevenueCat
  static Future<void> configurRevenuecat(String apiKey) async {
    try {
      await Purchases.configure(PurchasesConfiguration(apiKey));
      logger.i('✅ RevenueCat configurato con successo');
    } catch (e) {
      logger.e('❌ Errore configurazione RevenueCat: $e');
      rethrow;
    }
  }

  /// 🔹 Fetch offerings
  static Future<Offerings?> fetchOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      logger.i('✅ Offerte recuperate');
      return offerings;
    } catch (e) {
      logger.e('❌ Errore recupero offerte: $e');
      return null;
    }
  }

  static Future<CustomerInfo?> purchasePackage(Package package) async {
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));

      logger.i('✅ Acquisto completato');
      return result.customerInfo;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);

      // 🔹 Utente ha annullato
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        logger.i('ℹ️ Acquisto annullato dall’utente');
        return null;
      }

      // 🔹 Già acquistato (NON È ERRORE)
      if (code == PurchasesErrorCode.productAlreadyPurchasedError) {
        logger.i('ℹ️ Abbonamento già attivo, recupero CustomerInfo');
        return await Purchases.getCustomerInfo();
      }

      logger.e('❌ Errore RevenueCat: ${e.message}');
      rethrow;
    }
  }

  /// 🔹 Get latest CustomerInfo (single source of truth)
  static Future<CustomerInfo> getCustomerInfo() async {
    final info = await Purchases.getCustomerInfo();
    return info;
  }

  /// 🔹 Restore purchases for the current user
  static Future<CustomerInfo?> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      logger.i('✅ Acquisti ripristinati con successo');
      return customerInfo;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      logger.e('❌ Errore durante il ripristino: ${e.message} (Code: $code)');
      rethrow;
    }
  }
}
