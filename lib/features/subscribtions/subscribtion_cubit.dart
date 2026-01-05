/* Checks if user is pro or not */

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharma_box/features/subscribtions/subscribtion_state.dart';
import 'package:pharma_box/include/general_functions.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscribtionCubit extends Cubit<SubscribtionState> {
  SubscribtionCubit() : super(SubscribtionInitial());

  /// 🔹 Chiamare dopo login, app start, acquisto, restore
  Future<void> checkProStatus() async {
    logger.i('🔥 checkProStatus CALLED');

    final info = await Purchases.getCustomerInfo();
    logger.i('🔥 CustomerInfo received');

    await syncSubscriptionWithFirebase(info);

    final isPro = info.entitlements.active['Premium']?.isActive ?? false;

    logger.i('🔥 isPro = $isPro');
    final e = info.entitlements.all['Premium'];
    logger.i('isActive: ${e?.isActive}');
    logger.i('willRenew: ${e?.willRenew}');
    logger.i('expirationDate: ${e?.expirationDate}');

    emit(SubscribtionLoaded(isPro));
  }

  /// 🔹 Sincronizza lo stato dell'abbonamento con Firestore
  Future<void> syncSubscriptionWithFirebase(CustomerInfo info) async {
    final entitlement = info.entitlements.active['Premium'];
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'isPro': entitlement?.isActive ?? false,
      'subscriptionActivatedAt': entitlement?.latestPurchaseDate,
      'expirationDate': entitlement?.expirationDate,
      'willRenew': entitlement?.willRenew,
      'platform': entitlement?.store.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
