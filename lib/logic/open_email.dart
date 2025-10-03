import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class OpenEmail {
  const OpenEmail();

  VoidCallback contattaci(
    BuildContext context,
    String subject,
    String body, {
    String? fallbackMessage,
    VoidCallback? onFailure,
  }) {
    return () {
      _launchMail(
        context: context,
        subject: subject,
        body: body,
        fallbackMessage: fallbackMessage,
        onFailure: onFailure,
      );
    };
  }

  Future<void> _launchMail({
    required BuildContext context,
    required String subject,
    required String body,
    String? fallbackMessage,
    VoidCallback? onFailure,
  }) async {
    final uri = Uri.parse(
      'mailto:$kMembershipEmail'
      '?subject=${Uri.encodeComponent(subject)}'
      '&body=${Uri.encodeComponent(body)}',
    );

    final canLaunch = await canLaunchUrl(uri);
    if (canLaunch) {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched || !context.mounted) return;
    }

    if (!context.mounted) return;

    onFailure?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          fallbackMessage ??
              "Impossibile aprire l'app email.\nContattaci all'indirizzo: $kMembershipEmail",
        ),
      ),
    );
  }
}
