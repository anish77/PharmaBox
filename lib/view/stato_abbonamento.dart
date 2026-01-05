import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/include/general_functions.dart';

class StatoAbbonamentoPageState extends State<StatoAbbonamentoPage> {
  // 🔹 Costruttore visivo delle sezioni
  Widget _buildSection({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Color? color,
    Color? iconColor,
  }) {
    final isDestructive = icon == Icons.delete_forever;

    final Color resolvedIconColor =
        iconColor ?? (isDestructive ? kRed : kPrimary);

    final Color avatarColor =
        color ?? resolvedIconColor.withValues(alpha: 0.12);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: avatarColor,
          child: Icon(icon, color: resolvedIconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
      ),
    );
  }

  Future<void> _rinnovoAutomatico() async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'rinnovoAutomatico': false},
      );
    } catch (e) {
      logger.e('Errore aggiornando Firestore: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = auth.FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Abbonamento')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            user == null
                ? const Center(child: Text('Utente non loggato'))
                : StreamBuilder<DocumentSnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .snapshots(),
                  builder: (context, snapshot) {
                    DateTime? expirationDate;
                    bool autoRenew = false;

                    if (snapshot.hasData) {
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>? ?? {};
                      expirationDate =
                          (data['expirationDate'] as Timestamp?)?.toDate();
                      autoRenew = data['rinnovoAutomatico'] as bool? ?? false;
                    }

                    String expirationSubtitle;
                    if (!snapshot.hasData) {
                      expirationSubtitle = 'Caricamento in corso...';
                    } else if (expirationDate == null) {
                      expirationSubtitle =
                          'Nessuna data di scadenza disponibile.';
                    } else {
                      final d = expirationDate.toLocal();
                      final formatted =
                          '${d.day.toString().padLeft(2, '0')}/'
                          '${d.month.toString().padLeft(2, '0')}/'
                          '${d.year}';

                      expirationSubtitle =
                          autoRenew
                              ? 'Rinnovo il $formatted'
                              : 'Valido fino al $formatted';
                    }

                    return ListView(
                      children: [
                        _buildSection(
                          icon: Icons.workspace_premium,
                          title: 'Piano Premium',
                          subtitle:
                              'Con PharmaBox Premium puoi collegare uno o più scanner.',
                        ),
                        _buildSection(
                          icon: Icons.autorenew_outlined,
                          title: 'Prossimo rinnovo',
                          subtitle: expirationSubtitle,
                          iconColor: autoRenew ? kPrimary : Colors.grey,
                        ),
                        _buildSection(
                          icon: Icons.delete_forever,
                          title: 'Cancella abbonamento',
                          iconColor: autoRenew ? kRed : Colors.grey,
                          subtitle:
                              'L’abbonamento resterà attivo fino alla fine del periodo già pagato.',
                          onTap:
                              autoRenew
                                  ? () {
                                    showDialog(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            title: const Text(
                                              'Conferma operazione',
                                            ),
                                            content: const Text(
                                              'Vuoi davvero disattivare il rinnovo automatico?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () =>
                                                        Navigator.pop(context),
                                                child: const Text('Annulla'),
                                              ),
                                              TextButton(
                                                onPressed: () async {
                                                  final navigator =
                                                      Navigator.of(context);

                                                  await _rinnovoAutomatico();
                                                  navigator.pop();
                                                },
                                                child: const Text('Conferma'),
                                              ),
                                            ],
                                          ),
                                    );
                                  }
                                  : null,
                        ),
                      ],
                    );
                  },
                ),
      ),
    );
  }
}

class StatoAbbonamentoPage extends StatefulWidget {
  const StatoAbbonamentoPage({super.key});

  @override
  StatoAbbonamentoPageState createState() => StatoAbbonamentoPageState();
}
