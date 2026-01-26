import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/view/login_page.dart';

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  // 🔹 Reimpostazione password
  Future<void> _handlePasswordReset(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final email = auth.FirebaseAuth.instance.currentUser?.email;

    if (email == null || email.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Indirizzo email non disponibile.')),
      );
      return;
    }

    try {
      await auth.FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      messenger.showSnackBar(SnackBar(content: Text('Email inviata a $email')));
    } on auth.FirebaseAuthException catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(error.message ?? 'Errore durante l\'invio.')),
      );
    }
  }

  // 🔹 Cambio email
  Future<void> _handleChangeEmail(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final auth.User? currentUser = auth.FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Devi essere loggato per cambiare email.'),
        ),
      );
      return;
    }

    final controller = TextEditingController(text: currentUser.email ?? '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Cambia email'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Nuovo indirizzo email',
                hintText: 'esempio@email.com',
              ),
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
    );

    if (confirmed != true) return;
    final newEmail = controller.text.trim();

    if (newEmail.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Inserisci un indirizzo email valido.')),
      );
      return;
    }

    // 🔹 Funzione che invia la mail di verifica e aggiorna Firestore
    Future<void> sendVerification() async {
      await currentUser.verifyBeforeUpdateEmail(newEmail);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({'email': newEmail});
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Ti abbiamo inviato un’email a $newEmail. Conferma il cambio dall’email ricevuta.',
          ),
        ),
      );
    }

    try {
      await sendVerification();
    } on auth.FirebaseAuthException catch (error) {
      if (error.code == 'requires-recent-login') {
        if (!context.mounted) return;
        final passwordController = TextEditingController();
        bool obscurePassword = true;
        final retry = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return StatefulBuilder(
              builder:
                  (context, setState) => AlertDialog(
                    title: const Text('Reinserisci la password'),
                    content: TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                      ),
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
            );
          },
        );

        if (retry == true) {
          try {
            final credential = auth.EmailAuthProvider.credential(
              email: currentUser.email!,
              password: passwordController.text.trim(),
            );
            await currentUser.reauthenticateWithCredential(credential);
            await sendVerification();
          } catch (_) {
            messenger.showSnackBar(
              const SnackBar(content: Text('Password errata o altro errore.')),
            );
          }
        }
      } else if (error.code == 'invalid-email') {
        messenger.showSnackBar(
          const SnackBar(content: Text('L\'indirizzo email non è valido.')),
        );
      } else if (error.code == 'email-already-in-use') {
        messenger.showSnackBar(
          const SnackBar(content: Text('Questa email è già in uso.')),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(error.message ?? 'Errore sconosciuto.')),
        );
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Errore imprevisto durante il cambio email.'),
        ),
      );
    }
  }

  // 🔹 Cancellazione account
  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final user = auth.FirebaseAuth.instance.currentUser;
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Conferma cancellazione'),
            content: const Text(
              'Sei sicuro di voler cancellare definitivamente il tuo account? '
              'Questa azione non è reversibile.',
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
    );

    if (confirmed != true) return;

    try {
      await user.delete();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();
      await auth.FirebaseAuth.instance.signOut();

      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Account cancellato con successo.')),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } on auth.FirebaseAuthException catch (error) {
      String message = 'Impossibile cancellare l\'account.';
      if (error.code == 'requires-recent-login') {
        message =
            'Per cancellare l\'account effettua nuovamente l\'accesso e riprova.';
      }
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Errore inatteso durante la cancellazione.'),
        ),
      );
    }
  }

  // 🔹 Costruttore visivo delle sezioni
  Widget _buildSection({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    final isDestructive = icon == Icons.delete_forever;
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
    final user = auth.FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(
          kInformazioni,
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
        padding: const EdgeInsets.all(16),
        child:
            user == null
                ? ListView(
                  children: [
                    _buildSection(
                      icon: Icons.mail_outline,
                      title: 'Contattaci',
                      subtitle: 'Scrivici a support@pharmabox.it',
                    ),
                    _buildSection(
                      icon: Icons.lock_reset,
                      title: 'Cambia password',
                      subtitle:
                          'Accedi al tuo account per aggiornare la password.',
                    ),
                    _buildSection(
                      icon: Icons.email_outlined,
                      title: 'Cambia email',
                      subtitle: 'Accedi per modificare la tua email.',
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
                    return ListView(
                      children: [
                        _buildSection(
                          icon: Icons.lock_reset,
                          title: 'Cambia password',
                          subtitle:
                              'Ti invieremo un\'email per reimpostare la password.',
                          onTap: () => _handlePasswordReset(context),
                        ),
                        _buildSection(
                          icon: Icons.email_outlined,
                          title: 'Cambia email',
                          subtitle:
                              'Aggiorna l\'indirizzo associato al tuo account.',
                          onTap: () => _handleChangeEmail(context),
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
