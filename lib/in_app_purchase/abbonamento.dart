import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharma_box/features/subscribtions/offerings_cubit.dart';
import 'package:pharma_box/features/subscribtions/offerings_state.dart';
import 'package:pharma_box/features/subscribtions/subscribtion_cubit.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class AbbonamentoList extends StatelessWidget {
  const AbbonamentoList({super.key});

  @override
  Widget build(BuildContext context) {
    final offeringsCubit = context.read<OfferingsCubit>();

    return BlocBuilder<OfferingsCubit, OfferingsState>(
      builder: (context, state) {
        // 🔹 LOADING INIZIALE (solo qui il loader)
        if (state is OfferingsLoading || state is OfferingsInitial) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // 🔹 ERRORE OFFERTE / ACQUISTO
        if (state is OfferingsError || state is PurchaseError) {
          final msg =
              state is OfferingsError
                  ? state.message
                  : (state as PurchaseError).message;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('Errore: $msg'),
          );
        }

        // 🔹 MOSTRA SEMPRE I PACCHETTI SOLO SE LOADED
        if (state is OfferingsLoaded || state is PurchaseLoading) {
          final List<Package> packages =
              state is OfferingsLoaded
                  ? state.packages.whereType<Package>().toList()
                  : (state as PurchaseLoading).packages
                      .whereType<Package>()
                      .toList();

          if (packages.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Nessun abbonamento disponibile.'),
            );
          }

          final bool isPurchasing = false;

          return Column(
            children:
                packages.map((package) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          package.storeProduct.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('Prezzo: ${package.storeProduct.priceString}'),
                        const SizedBox(height: 8),

                        // 🔹 BOTTONE SEMPRE VISIBILE
                        ElevatedButton.icon(
                          onPressed: () {
                            offeringsCubit.purchasePackage(package, () {
                              context
                                  .read<SubscribtionCubit>()
                                  .checkProStatus();
                            });
                          },
                          icon: const Icon(Icons.star, color: Colors.yellow),
                          label: const Text(
                            'Attiva',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          );
        }

        // 🔹 FALLBACK (mai loader infinito)
        return const SizedBox.shrink();
      },
    );
  }
}



/*
class Abbonamento extends StatefulWidget {
  const Abbonamento({super.key});

  @override
  State<Abbonamento> createState() => _AbbonamentoState();
}

class _AbbonamentoState extends State<Abbonamento> {
  bool _loaded = false;

  // helper method to handle the purchase flow
  Future<void> _handlePurchase(BuildContext context, Package package) async {
    final offeringsCubit = context.read<OfferingsCubit>();
    final subscriptionCubit = context.read<SubscribtionCubit>();

    // initiate purchase
    offeringsCubit.purchasePackage(package, () {
      // after successful purchase, refresh subscription status
      subscriptionCubit.checkProStatus();

      // wait until subscription state shows user is pro, then close the page
      subscriptionCubit.stream
          .firstWhere(
            (subState) => subState is SubscribtionLoaded && subState.isPro,
          )
          .then((value) => Navigator.pop(context));
    });
  }

  @override
  void initState() {
    super.initState();
    // Check current subscription state after first frame — covers case where
    // SubscribtionLoaded was emitted before this widget was built.
    
    Future.microtask(() {
      try {
        if (!mounted) return;
        final s = context.read<SubscribtionCubit>().state;
        if (s is SubscribtionLoaded && s.isPro == false && !_loaded) {
          context.read<OfferingsCubit>().loadOfferings();
          _loaded = true;
        }
      } catch (e, st) {
        // ignore: avoid_print
        print('Error in Abbonamento microtask: $e\n$st');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final subscribtionCubit = context.read<SubscribtionCubit>();
    final abbonamentoCubit = context.read<OfferingsCubit>();

    //load the offerings when this widget is built

    return BlocListener<SubscribtionCubit, SubscribtionState>(
      listener: (context, state) {
        if (state is SubscribtionLoaded && state.isPro == false && !_loaded) {
          context.read<OfferingsCubit>().loadOfferings();
          _loaded = true;
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Abbonamento PharmaBox Pro')),
        body: BlocBuilder<OfferingsCubit, OfferingsState>(
          builder: (context, state) {
            //loaded ing ...
            if (state is OfferingsLoading || state is OfferingsInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            // error ...

            if (state is OfferingsError || state is PurchaseError) {
              final errorMsg =
                  state is OfferingsError
                      ? state.message
                      : (state as PurchaseError).message;
              return Center(child: Text("Error: $errorMsg"));
            }
            // loaded!
            if (state is OfferingsLoaded) {
              // get available packages
              final packages = state.packages;

              // no packages available
              if (packages.isEmpty) {
                return const Center(
                  child: Text('Nessun abbonamento disponibile al momento.'),
                );
              }

              // packages available
              return ListView.builder(
                itemCount: packages.length,
                itemBuilder: (context, index) {
                  //get each individual package
                  final package = packages[index];

                  // get subscription duration
                  final duration =
                      package!.identifier.contains('annual')
                          ? 'Annuale'
                          : 'Mensile';

                  // return UI for each package
                  return Card(
                    child: Column(
                      children: [
                        Text(
                          package.storeProduct.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Prezzo: ${package.storeProduct.priceString} per $duration',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        MaterialButton(
                          color: Colors.blue,
                          textColor: Colors.white,
                          onPressed: () async {
                            await abbonamentoCubit.purchasePackage(package, () {
                              // on success, reload subscription state
                              //subscribtionCubit.loadSubscribtion();
                              _handlePurchase(context, package);
                            });
                          },
                          child: const Text('Acquista'),
                        ),
                      ],
                    ),
                  );
                },
              );

              // default fallback ...
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}*/

