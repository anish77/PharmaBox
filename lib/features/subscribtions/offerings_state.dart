import 'package:purchases_flutter/models/package_wrapper.dart';

abstract class OfferingsState {}

class OfferingsInitial extends OfferingsState {}

class OfferingsLoading extends OfferingsState {}

class OfferingsLoaded extends OfferingsState {
  //final Package? package;
  final List<Package> packages; //final List<Package?> packages;
  OfferingsLoaded(this.packages);
}

class OfferingsError extends OfferingsState {
  final String message;
  OfferingsError(this.message);
}

class PurchaseLoading extends OfferingsState {
  final List<Package> packages;
  PurchaseLoading(this.packages);
}

class PurchaseError extends OfferingsState {
  final String message;
  final List<Package> packages;

  PurchaseError(this.message, this.packages);
}
