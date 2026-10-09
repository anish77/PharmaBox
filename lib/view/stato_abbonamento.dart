import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/in_app_purchase/abbonamento.dart';
import 'package:pharma_box/logic/open_email.dart';
import 'package:pharma_box/view/annullare_abbonamento.dart';

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

  @override
  Widget build(BuildContext context) {
    final user = auth.FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(
          "Abbonamento & Scanner",
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
                ? const Center(child: Text('Utente non loggato'))
                : StreamBuilder<DocumentSnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .snapshots(),
                  builder: (context, snapshot) {
                    bool isPro = false;
                    if (snapshot.hasData) {
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>? ?? {};
                      isPro = data['isPro'] as bool? ?? false;
                    }

                    return ListView(
                      children: [
                        _buildSection(
                          icon:
                              isPro
                                  ? Icons.check_circle_sharp
                                  : Icons.subtitles_off_sharp,
                          title: 'Stato abbonamento',
                          subtitle: isPro ? 'Attivo' : 'Non attivo',
                          iconColor: isPro ? kGreen : kRed,
                          onTap:
                              isPro
                                  ? null
                                  : () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder:
                                            (_) => const Abbonamento(
                                              withScaffold: true,
                                            ),
                                      ),
                                    );
                                  },
                        ),

                        _buildSection(
                          icon: Icons.qr_code_scanner,
                          title: 'Acquista uno scanner',
                          subtitle:
                              'Per utilizzare PharmaBox è necessario uno scanner compatibile',
                          iconColor: kPrimary,
                          onTap: () {
                            OpenEmail().openWebsite(kLinkScanner);
                          },
                        ),

                        _buildSection(
                          icon: Icons.delete_forever_outlined,
                          title: "Come annullare l'abbonamento",

                          onTap:
                              () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AnnullareAbbonamento(),
                                ),
                              ),
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
