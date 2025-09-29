import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:pharma_box/data/constants.dart';

class StatoInvitiPage extends StatelessWidget {
  const StatoInvitiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

        // Recupero amiciInvitati come lista di stringhe
        final List<String> invitedFriendsNames =
            List<String>.from(data['amiciInvitati'] ?? []).map((amico) {
              final parts = amico.split(' - ');
              return parts.first;
            }).toList();

        final int invitedFriends = invitedFriendsNames.length;

        // Calcolo sconto
        final double discountPerFriend = kSconto10; // es. 0.1 = 10%
        double discount = invitedFriends * discountPerFriend;
        if (discount > 1) discount = 1; // max 100%

        final double toPay = 1 - discount;
        final double percentToPay = toPay.clamp(0.0, 1.0).toDouble();
        final bool canPop = Navigator.of(context).canPop();

        return Scaffold(
          appBar: AppBar(
            leading:
                canPop
                    ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).maybePop(),
                    )
                    : null,
            title: const Text(
              "I miei inviti",
              style: TextStyle(
                color: kBluScuro,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            centerTitle: false,
            iconTheme: const IconThemeData(color: kBluScuro),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 30),

                // Cerchio di progresso
                CircularPercentIndicator(
                  radius: 100.0,
                  lineWidth: 16.0,
                  percent: percentToPay,
                  center: Text(
                    "${(percentToPay * 100).toInt()}%",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  progressColor: kPrimary,
                  backgroundColor: Colors.deepPurple.shade100,
                  circularStrokeCap: CircularStrokeCap.round,
                ),

                const SizedBox(height: 20),

                // Testo sotto il cerchio
                Text(
                  invitedFriends == 0
                      ? "Non hai ancora invitato nessuno"
                      : "Hai invitato $invitedFriends amic${invitedFriends == 1 ? 'o' : 'i'}",
                  style: const TextStyle(fontSize: 18),
                ),

                const SizedBox(height: 20),

                // Lista amici invitati
                if (invitedFriendsNames.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: invitedFriendsNames.length,
                      itemBuilder: (context, index) {
                        final name = invitedFriendsNames[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(name),
                            subtitle: const Text("Registrazione completata ✅"),
                          ),
                        );
                      },
                    ),
                  )
                else
                  const Spacer(),

                const SizedBox(height: 20),

                // Messaggio motivazionale
                Text(
                  "Invita altri amici per ridurre ancora il costo dell’abbonamento!",
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
