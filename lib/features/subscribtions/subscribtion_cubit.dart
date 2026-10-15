/* Checks if user is pro or not */

import 'dart:async';

import 'package:pharma_box/features/subscribtions/revenuecat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharma_box/features/subscribtions/subscribtion_state.dart';
import 'package:pharma_box/include/general_functions.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionCubit extends Cubit<SubscribtionState> {
  SubscriptionCubit() : super(SubscribtionInitial()) {
    Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((_) {
      emit(SubscribtionInitial());
      checkProStatus();
    });
  }

  late final StreamSubscription<User?> _authSubscription;
  Future<void> _pending = Future<void>.value();
  bool _checking = false;

  void _onCustomerInfoUpdated(CustomerInfo info) {
    // getCustomerInfo/logIn may notify listeners while a check is running.
    if (!_checking) checkProStatus();
  }

  /// Serialize checks so account switches cannot mix RevenueCat identities.
  Future<void> checkProStatus() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _pending = _pending.then((_) => _checkProStatus(uid));
    return _pending;
  }

  Future<void> _checkProStatus(String? uid) async {
    if (isClosed || FirebaseAuth.instance.currentUser?.uid != uid) return;
    if (uid == null) {
      emit(SubscribtionLoaded(false));
      return;
    }
    _checking = true;
    try {
      final info = await RevenuecatService.getCustomerInfo();
      if (isClosed || FirebaseAuth.instance.currentUser?.uid != uid) return;
      final isPro = info.entitlements.all['Premium']?.isActive ?? false;
      emit(SubscribtionLoaded(isPro));
      try {
        await syncSubscriptionWithFirebase(info, expectedUid: uid);
      } catch (error) {
        // A Firestore failure must not revoke a verified store entitlement.
        logger.e('Errore sincronizzazione abbonamento: $error');
      }
    } catch (error) {
      logger.e('Errore in checkProStatus: $error');
      // A failed request says nothing about whether the subscription expired.
      if (!isClosed &&
          FirebaseAuth.instance.currentUser?.uid == uid &&
          state is! SubscribtionLoaded) {
        emit(
          SubscribtionError('Impossibile verificare l’abbonamento. Riprova.'),
        );
      }
    } finally {
      _checking = false;
    }
  }

  Future<void> syncSubscriptionWithFirebase(
    CustomerInfo info, {
    String? expectedUid,
  }) async {
    final entitlement = info.entitlements.all['Premium'];
    final user = FirebaseAuth.instance.currentUser;
    if (user == null ||
        !user.emailVerified ||
        (expectedUid != null && user.uid != expectedUid)) {
      return;
    }

    // RevenueCat supplies ISO 8601 dates; store both as Firestore timestamps.
    // originalPurchaseDate is the first activation, not the latest renewal.
    final activatedAt =
        entitlement == null
            ? null
            : Timestamp.fromDate(
              DateTime.parse(entitlement.originalPurchaseDate),
            );
    final expiration = entitlement?.expirationDate;
    final expirationTs =
        expiration == null
            ? null
            : Timestamp.fromDate(DateTime.parse(expiration));

    final latestPurchaseAt =
        entitlement == null
            ? null
            : Timestamp.fromDate(
              DateTime.parse(entitlement.latestPurchaseDate),
            );
    final firestore = FirebaseFirestore.instance;
    final profile = firestore.collection('users').doc(user.uid);
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(profile);
      final data = snapshot.data();
      final values = <String, dynamic>{
        'isPro': entitlement?.isActive ?? false,
        if (entitlement != null) ...{
          // Preserve the first activation across checks and renewals.
          if (data?['subscriptionActivatedAt'] == null)
            'subscriptionActivatedAt': activatedAt,
          'expirationDate': expirationTs,
          'willRenew': entitlement.willRenew,
          'platform': entitlement.store.name,
          // This is the store purchase/renewal time, not the time of a check.
          'updatedAt': latestPurchaseAt,
        },
      };
      final changes = <String, dynamic>{
        for (final entry in values.entries)
          if (data == null ||
              !data.containsKey(entry.key) ||
              data[entry.key] != entry.value)
            entry.key: entry.value,
      };
      if (changes.isEmpty) return;
      transaction.set(profile, changes, SetOptions(merge: true));
    });
  }

  @override
  Future<void> close() async {
    Purchases.removeCustomerInfoUpdateListener(_onCustomerInfoUpdated);
    await _authSubscription.cancel();
    return super.close();
  }
}
