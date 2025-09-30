import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/logic/open_email.dart';
import 'package:pharma_box/view/login_page.dart';

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  Future<void> _handlePasswordReset(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final email = FirebaseAuth.instance.currentUser?.email;

    if (email == null || email.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Indirizzo email non disponibile.')),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      messenger.showSnackBar(SnackBar(content: Text('Email inviata a $email')));
    } on FirebaseAuthException catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(error.message ?? 'Errore durante l\'invio.')),
      );
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final messenger = ScaffoldMessenger.of(context);

    if (user == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Devi effettuare il login per cancellare il tuo account.',
          ),
        ),
      );
      return;
    }

    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (dialogContext) => AlertDialog(
                title: const Text('Conferma cancellazione'),
                content: const Text(
                  'Sei sicuro di voler cancellare definitivamente il tuo account? Questa azione non è reversibile.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Annulla'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text('Conferma'),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirmed) return;

    bool accountDeleted = false;

    final String userId = user.uid;

    try {
      await user.delete();
      accountDeleted = true;
    } on FirebaseAuthException catch (error) {
      String message = 'Impossibile cancellare l\'account in questo momento.';
      if (error.code == 'requires-recent-login') {
        message =
            'Per cancellare l\'account effettua nuovamente l\'accesso e riprova.';
      }
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Si è verificato un errore inatteso durante la cancellazione.',
          ),
        ),
      );
    }

    if (!accountDeleted) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
    } catch (error) {
      debugPrint('Errore eliminando il documento utente: $error');
    }

    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Account cancellato con successo.')),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    final bool isDestructive = icon == Icons.delete_forever;
    final Color avatarColor =
        isDestructive ? kRed.withValues(alpha: 0.12) : kSecondary;
    final Color iconColor = isDestructive ? kRed : kPrimary;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: avatarColor,
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Informazioni'), centerTitle: false),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            user == null
                ? ListView(
                  children: [
                    _buildSection(
                      icon: Icons.mail_outline,
                      title: 'Contattaci',
                      subtitle:
                          'Scrivici a support@pharmabox.it oppure al numero 800 123 456.',
                    ),
                    _buildSection(
                      icon: Icons.lock_reset,
                      title: 'Cambia password',
                      subtitle:
                          'Accedi al tuo account per aggiornare la password.',
                    ),
                    _buildSection(
                      icon: Icons.calendar_today,
                      title: 'Quando scade l\'abbonamento',
                      subtitle:
                          'Accedi per visualizzare la tua data di scadenza.',
                    ),
                    _buildSection(
                      icon: Icons.delete_forever,
                      title: 'Cancella il mio account',
                      subtitle: 'Accedi per cancellare il tuo account.',
                    ),
                  ],
                )
                : StreamBuilder<DocumentSnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .snapshots(),
                  builder: (context, snapshot) {
                    DateTime? expirationDate;
                    if (snapshot.hasData) {
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>? ??
                          <String, dynamic>{};
                      final Timestamp? ts =
                          data['expirationDate'] as Timestamp?;
                      expirationDate = ts?.toDate();
                    }

                    String expirationSubtitle;
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      expirationSubtitle = 'Caricamento in corso...';
                    } else if (snapshot.hasError) {
                      expirationSubtitle =
                          'Impossibile recuperare la scadenza in questo momento.';
                    } else if (expirationDate == null) {
                      expirationSubtitle =
                          'Nessuna data di scadenza disponibile.';
                    } else {
                      expirationSubtitle =
                          'Il tuo abbonamento scade il ${_formatDate(expirationDate)}.';
                    }

                    return ListView(
                      children: [
                        _buildSection(
                          icon: Icons.mail_outline,
                          title: 'Contattaci',
                          subtitle: 'Scrivici a support@pharmabox.it',
                          onTap: OpenEmail().contattaci(
                            context,
                            kRichiestaAssistenza,
                            kSupporto,
                            fallbackMessage:
                                "Impossibile aprire l'app email.\nContattaci all'indirizzo: $kMembershipEmail",
                            onFailure: () => Navigator.of(context).maybePop(),
                          ),
                        ),
                        _buildSection(
                          icon: Icons.lock_reset,
                          title: 'Cambia password',
                          subtitle:
                              'Ti invieremo un\'email per reimpostare la password.',
                          onTap: () => _handlePasswordReset(context),
                        ),
                        _buildSection(
                          icon: Icons.calendar_today,
                          title: 'Quando scade l\'abbonamento',
                          subtitle: expirationSubtitle,
                        ),
                        _buildSection(
                          icon: Icons.delete_forever,
                          title: 'Cancella il mio account',
                          subtitle:
                              'Elimina definitivamente il tuo account e tutti i dati associati.',
                          onTap: () => _confirmDeleteAccount(context),
                        ),
                      ],
                    );
                  },
                ),
      ),
    );
  }
}
