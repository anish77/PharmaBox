import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/widgets/custom_button.dart';

class InviteFriendPage extends StatelessWidget {
  final String referralCode;

  const InviteFriendPage({super.key, required this.referralCode});

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
      appBar: AppBar(title: const Text(kInvitaAmico), centerTitle: true),
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
            CustomButton(
              title: 'Invita ora',
              titleColor: Colors.white,
              backgroundColor: kPrimary,
              onPressed: () {},
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
