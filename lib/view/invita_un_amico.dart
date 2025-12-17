import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/widgets/custom_button.dart';
import 'package:share_plus/share_plus.dart';

class InvitaUnAmicoPage extends StatelessWidget {
  final String referralCode;

  const InvitaUnAmicoPage({super.key, required this.referralCode});

  Widget _buildStep({
    required Widget indicator,
    required String label,
    bool isLast = false,
  }) {
    const double circleSize = 36;
    const double connectorHeight = 36;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: circleSize,
              height: circleSize,
              decoration: const BoxDecoration(
                color: kPrimary,
                shape: BoxShape.circle,
              ),
              child: Center(child: indicator),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: kBluScuro,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (!isLast)
          Padding(
            padding: EdgeInsets.only(left: circleSize / 2 - 1),
            child: Container(
              width: 2,
              height: connectorHeight,
              color: kPrimary.withValues(alpha: 0.4),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          kInvitaAmico,
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    const Icon(Icons.card_giftcard, size: 100, color: kPrimary),
                    const SizedBox(height: 20),
                    const Text(
                      kSconto,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: kBluScuro,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 30),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      decoration: BoxDecoration(
                        color: kBluScuro.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStep(
                            indicator: const Text(
                              '1',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            label: kLinkRiferimento,
                          ),
                          _buildStep(
                            indicator: const Text(
                              '2',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            label: kInvitaAmici,
                          ),
                          _buildStep(
                            indicator: const Icon(
                              Icons.card_giftcard,
                              color: Colors.white,
                            ),
                            label: kGuadagna,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            Builder(
              builder:
                  (buttonContext) => CustomButton(
                    title: 'Condividi ora',
                    titleColor: Colors.white,
                    backgroundColor: kPrimary,
                    onPressed: () {
                      final box =
                          buttonContext.findRenderObject() as RenderBox?;
                      final origin =
                          box != null
                              ? box.localToGlobal(Offset.zero) & box.size
                              : const Rect.fromLTWH(0, 0, 1, 1);

                      final message =
                          'Registrati su $kAppName e usa il mio codice $referralCode per ricevere 1 mese gratuito!';
                      SharePlus.instance.share(
                        ShareParams(
                          text: message,
                          subject: kAppName,
                          sharePositionOrigin: origin,
                        ),
                      );
                    },
                  ),
            ),
            const SizedBox(height: 45),
          ],
        ),
      ),
    );
  }
}
