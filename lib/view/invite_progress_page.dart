import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:pharma_box/data/constants.dart';

class InviteProgressPage extends StatelessWidget {
  final int invitedFriends; // numero di amici invitati
  final int totalFriendsNeeded; // per esempio 5 amici per avere 100% gratis

  const InviteProgressPage({
    super.key,
    required this.invitedFriends,
    this.totalFriendsNeeded = 5,
  });

  @override
  Widget build(BuildContext context) {
    // Calcolo dello sconto
    final double discountPerFriend = 0.20; // 20% per amico
    double discount = invitedFriends * discountPerFriend;
    if (discount > 1) discount = 1; // massimo 100%

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
        title: const Text("I miei inviti"),
        centerTitle: true,
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
                  : "Hai invitato $invitedFriends amico${invitedFriends > 1 ? 'i' : ''}",
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 20),

            // Lista amici invitati (se ce ne sono)
            if (invitedFriends > 0)
              Expanded(
                child: ListView.builder(
                  itemCount: invitedFriends,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text("Amico #${index + 1}"),
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
  }
}
