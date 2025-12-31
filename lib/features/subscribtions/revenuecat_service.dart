import 'package:pharma_box/include/general_functions.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenuecatService {
  //configure rev cat
  static Future<void> configurRevenuecat(String apiKey) async {
    // Your configuration code here
    try {
      await Purchases.configure(PurchasesConfiguration(apiKey));

      logger.i('✅ RevenueCat configurato con successo');
    } catch (e) {
      logger.e('❌ Errore nella configurazione di RevenueCat: $e');
    }
  }

  // fetch offerings
  static Future<Offerings?> fetchOfferings() async {
    try {
      Offerings offerings = await Purchases.getOfferings();
      logger.i('✅ Offerte recuperate con successo');
      logger.i('Offerings object: $offerings');
      logger.i('offerings.current: ${offerings.current}');
      logger.i('offerings.all keys: ${offerings.all.keys}');
      logger.i('---------- 1111 ${offerings.all.keys.first}');
      return offerings;
    } catch (e) {
      logger.e('❌ Errore nel recupero delle offerte: $e');
      return null;
    }
  }

  // purchase package
  static Future<CustomerInfo?> purchasePackage(Package package) async {
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      final CustomerInfo customerInfo = result.customerInfo;

      logger.i('✅ Acquisto completato con successo: $customerInfo');
      return customerInfo;
    } catch (e) {
      logger.e('❌ Errore generico per purchasePackage: $e');
      return null;
    }
  }

  // is pro user ?
  static Future<bool> isProUser() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      //bool isPro = customerInfo.entitlements.all['pro']?.isActive ?? false;
      bool isPro = customerInfo.entitlements.active.containsKey(
        'PharmaBox Pro',
      );
      logger.i('✅ Verifica stato pro user: $isPro');
      return isPro;
    } catch (e) {
      logger.e('❌ Errore nella verifica dello stato pro user: $e');
      return false;
    }
  }
}
