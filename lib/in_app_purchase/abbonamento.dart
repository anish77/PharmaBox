import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharma_box/features/subscribtions/offerings_cubit.dart';
import 'package:pharma_box/features/subscribtions/offerings_state.dart';
import 'package:pharma_box/features/subscribtions/subscribtion_cubit.dart';
import 'package:pharma_box/features/subscribtions/subscribtion_state.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class Abbonamento extends StatelessWidget {
  const Abbonamento({super.key});

  Future<void> _handlePurchase(BuildContext context, Package package) async {
    final offeringsCubit = context.read<OfferingsCubit>();
    final subscriptionCubit = context.read<SubscribtionCubit>();

    offeringsCubit.purchasePackage(package, () async {
      subscriptionCubit.checkProStatus();

      await subscriptionCubit.stream.firstWhere(
        (state) => state is SubscribtionLoaded && state.isPro,
      );

      if (context.mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OfferingsCubit, OfferingsState>(
      builder: (context, state) {
        debugPrint('🔥 OfferingsCubit state: $state');
        if (state is OfferingsLoading || state is OfferingsInitial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is PurchaseLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is OfferingsError || state is PurchaseError) {
          final msg =
              state is OfferingsError
                  ? state.message
                  : (state as PurchaseError).message;
          return Center(child: Text(msg));
        }

        if (state is OfferingsLoaded) {
          final packages = state.packages;
          if (packages.isEmpty) {
            return const Center(child: Text('Nessun abbonamento disponibile'));
          }

          return ListView.builder(
            shrinkWrap: true, // ⬅️ IMPORTANTE
            physics: const NeverScrollableScrollPhysics(), // ⬅️
            itemCount: packages.length,
            itemBuilder: (context, i) {
              final package = packages[i]!;
              return Card(
                color: Colors.transparent,
                elevation: 0,
                shadowColor: Colors.transparent,
                surfaceTintColor: Colors.transparent, // Material 3
                child: ListTile(
                  title: Text(package.storeProduct.title),
                  subtitle: Text(package.storeProduct.priceString),
                  trailing: ElevatedButton.icon(
                    icon: const Icon(Icons.star, color: Colors.yellow),
                    onPressed: () => _handlePurchase(context, package),
                    label: const Text(
                      'Attiva',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
