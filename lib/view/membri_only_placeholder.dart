import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class MembersOnlyPlaceholder extends StatelessWidget {
  const MembersOnlyPlaceholder({super.key});
  Future<void> _askForMembership(BuildContext context) async {
    const subject = 'Richiesta accesso membri';
    const body = 'Ciao, vorrei diventare membro di PharmaBox.';

    final uri = Uri.parse(
      'mailto:$kMembershipEmail'
      '?subject=${Uri.encodeComponent(subject)}'
      '&body=${Uri.encodeComponent(body)}',
    );

    if (await canLaunchUrl(uri)) {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched || !context.mounted) return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impossibile aprire l\'app email.')),
    );
    debugPrint('canLaunch: ${await canLaunchUrl(uri)}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackGround,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: kBluScuro),
            const SizedBox(height: 16),
            const Text(
              kDisponibileMembri,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kBluScuro,
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => _askForMembership(context),
              style: TextButton.styleFrom(
                foregroundColor: kBluScuro,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: Text(kDiventaMembro, style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      ),
    );
  }
}
