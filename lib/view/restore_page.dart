import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/features/subscribtions/revenuecat_service.dart';
import 'package:pharma_box/features/subscribtions/subscribtion_cubit.dart';
import 'package:pharma_box/widgets/custom_button.dart';

class RestorePage extends StatefulWidget {
  const RestorePage({super.key});

  @override
  State<RestorePage> createState() => _RestorePageState();
}

class _RestorePageState extends State<RestorePage> {
  bool _isRestoring = false;
  String? _statusMessage;
  bool _showSuccess = false;

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _handleRestore() async {
    setState(() {
      _isRestoring = true;
      _statusMessage = 'Ripristino degli acquisti in corso...';
      _showSuccess = false;
    });

    try {
      // Call RevenueCat restore
      final customerInfo = await RevenuecatService.restorePurchases();

      if (customerInfo == null) {
        setState(() {
          _isRestoring = false;
          _statusMessage = null;
        });
        _showSnackBar(
          'Nessun acquisto trovato da ripristinare.',
          isError: true,
        );
        return;
      }

      // Check if Premium entitlement is active
      final entitlement = customerInfo.entitlements.active['Premium'];

      if (entitlement != null && entitlement.isActive) {
        // Update subscription status in Firebase and local state
        await context.read<SubscriptionCubit>().checkProStatus();

        final expirationDateStr =
            entitlement.expirationDate ?? 'Data non disponibile';

        setState(() {
          _isRestoring = false;
          _statusMessage =
              'Abbonamento ripristinato con successo!\nScadenza: $expirationDateStr';
          _showSuccess = true;
        });

        _showSnackBar('✅ Acquisti ripristinati con successo!', isError: false);

        // Auto-dismiss after 3 seconds
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _isRestoring = false;
          _statusMessage = null;
        });
        _showSnackBar('Nessun abbonamento attivo trovato.', isError: true);
      }
    } catch (e) {
      setState(() {
        _isRestoring = false;
        _statusMessage = null;
      });
      _showSnackBar('Errore durante il ripristino: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: const Text(
          'Ripristina Acquisti',
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
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: kPrimary.withAlpha((0.1 * 255).toInt()),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.restore, size: 64, color: kPrimary),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  'Ripristina i tuoi Acquisti',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: kBluScuro,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  'Se hai precedentemente acquistato un abbonamento su un altro dispositivo o '
                  'hai reinstallato l\'app, puoi ripristinare i tuoi acquisti toccando il pulsante sottostante.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Status message or success message
                if (_statusMessage != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          _showSuccess
                              ? Colors.green.shade50
                              : Colors.blue.shade50,
                      border: Border.all(
                        color:
                            _showSuccess
                                ? Colors.green.shade300
                                : Colors.blue.shade300,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _statusMessage!,
                      style: TextStyle(
                        color:
                            _showSuccess
                                ? Colors.green.shade700
                                : Colors.blue.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 32),

                // Restore Button
                CustomButton(
                  title:
                      _isRestoring
                          ? 'Ripristino in corso...'
                          : 'Ripristina Acquisti',
                  titleColor: Colors.white,
                  backgroundColor: kPrimary,
                  onPressed: _isRestoring ? null : _handleRestore,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
