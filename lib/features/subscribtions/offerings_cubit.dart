/* 
This cubit is responsible for fetching & purchasing offerings from revcat
*/

import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharma_box/features/subscribtions/offerings_state.dart';
import 'package:pharma_box/features/subscribtions/revenuecat_service.dart';
import 'package:pharma_box/features/subscribtions/subscribtion_cubit.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class OfferingsCubit extends Cubit<OfferingsState> {
  OfferingsCubit(this._subscribtionCubit) : super(OfferingsInitial());

  final SubscribtionCubit _subscribtionCubit;

  // catch the loaded packages
  List<Package> _packages = [];

  //load offerings from revcat
  Future<void> loadOfferings() async {
    emit(OfferingsLoading());
    try {
      Offerings? offerings = await RevenuecatService.fetchOfferings();
      // Check if are any offerings available
      if (offerings == null) {
        _packages = [];
        throw Exception('Nessuna offerta disponibile');
      }

      // Prefer the `current` offering, but if it's null pick the first
      // available offering from `offerings.all` so sandbox/test offerings
      // (with custom identifiers) are handled as well.
      Offering? chosen = offerings.current;
      if (chosen == null && offerings.all.isNotEmpty) {
        chosen = offerings.all.values.first;
      }

      _packages = [];
      if (chosen != null) {
        // `availablePackages` contains all packages for the offering
        // (weekly/monthly/annual etc.). Use them instead of only `annual`.
        try {
          _packages.addAll(chosen.availablePackages);
        } catch (_) {
          // Fallback to checking specific package fields if `availablePackages`
          // is not present on the Offering implementation used.
          if (chosen.annual != null) _packages.add(chosen.annual!);
          if (chosen.monthly != null) _packages.add(chosen.monthly!);
          if (chosen.weekly != null) _packages.add(chosen.weekly!);
        }
      }

      if (_packages.isEmpty) {
        throw Exception('Nessuna offerta disponibile');
      }
      emit(OfferingsLoaded(_packages));
    } catch (e) {
      emit(OfferingsError('Errore nel caricamento delle offerte: $e'));
    }
  }

  Future<void> purchasePackage(Package package, VoidCallback onSuccess) async {
    emit(PurchaseLoading(_packages));

    try {
      final customerInfo = await RevenuecatService.purchasePackage(package);

      if (customerInfo == null) {
        emit(OfferingsLoaded(_packages));
        return;
      }

      final entitlement = customerInfo.entitlements.active['Premium'];

      if (entitlement == null || !entitlement.isActive) {
        emit(OfferingsLoaded(_packages));
        return;
      }

      // 🔹 DELEGA TUTTO al SubscribtionCubit
      await _subscribtionCubit.checkProStatus();

      emit(OfferingsLoaded(_packages));
      onSuccess();
    } catch (e) {
      emit(PurchaseError('Errore durante l\'acquisto: $e'));
    }
  }
}
