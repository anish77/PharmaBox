import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/features/subscribtions/offerings_cubit.dart';
import 'package:pharma_box/features/subscribtions/offerings_state.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class Abbonamento extends StatelessWidget {
  const Abbonamento({super.key, this.withScaffold = false});

  final bool withScaffold;

  Future<void> _handlePurchase(BuildContext context, Package package) async {
    final offeringsCubit = context.read<OfferingsCubit>();

    offeringsCubit.purchasePackage(package, () async {
      if (context.mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = BlocBuilder<OfferingsCubit, OfferingsState>(
      builder: (context, state) {
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
            shrinkWrap: true,
            physics:
                withScaffold
                    ? const AlwaysScrollableScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
            itemCount: packages.length,
            itemBuilder: (context, i) {
              final package = packages[i];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        kAbbonamentoPremium,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(kAbbonamentoPremiumDescrizione),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(
                          Icons.star,
                          color: Colors.yellow,
                          size: 18,
                        ),
                        onPressed: () => _handlePurchase(context, package),
                        label: Text(
                          '${package.storeProduct.priceString} / anno',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );

    // 🔥 QUI LA DIFFERENZA
    if (!withScaffold) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(
          "Abbonamento Premium",
          style: TextStyle(
            color: kBluScuro,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: kBluScuro),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: Padding(padding: const EdgeInsets.all(16), child: content),
    );
  }
}
