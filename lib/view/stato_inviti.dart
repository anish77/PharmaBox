import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/widgets/custom_button.dart';

class StatoInvitiPage extends StatefulWidget {
  const StatoInvitiPage({super.key});

  @override
  State<StatoInvitiPage> createState() => _StatoInvitiPageState();
}

class _StatoInvitiPageState extends State<StatoInvitiPage> {
  bool _omaggioAttivato = false;
  bool _freezeSnapshot = false;
  DocumentSnapshot<Object?>? _cachedSnapshot;
  String? _formattedDateOld;
  String? _formattedDateNew;

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError && _cachedSnapshot == null) {
          return const Scaffold(
            body: Center(child: Text('Si è verificato un errore.')),
          );
        }

        DocumentSnapshot<Object?>? effectiveSnapshot;
        if (_freezeSnapshot && _cachedSnapshot != null) {
          effectiveSnapshot = _cachedSnapshot;
        } else if (snapshot.hasData) {
          effectiveSnapshot = snapshot.data!;
          _cachedSnapshot = effectiveSnapshot;
        } else if (_cachedSnapshot != null) {
          effectiveSnapshot = _cachedSnapshot;
        }

        if (effectiveSnapshot == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final DocumentSnapshot<Object?> currentSnapshot = effectiveSnapshot;

        final data =
            currentSnapshot.data() as Map<String, dynamic>? ??
            <String, dynamic>{};

        // Recupero amiciInvitati come lista di stringhe
        final List<String> invitedFriendsNames =
            List<String>.from(data['amiciInvitati'] ?? []).map((amico) {
              final parts = amico.split(' - ');
              return parts.first;
            }).toList();

        final int invitedFriends = invitedFriendsNames.length;

        // 👉 Recupero expirationDate come Timestamp e lo converto
        final Timestamp? ts = data['expirationDate'];
        final DateTime? expirationDate = ts?.toDate();
        final DateTime? extendedExpirationDate = expirationDate?.add(
          const Duration(days: 365),
        );

        String? computedFormattedDateOld;
        if (expirationDate != null) {
          computedFormattedDateOld = _formatDate(expirationDate);
        }

        String? computedFormattedDate;
        if (extendedExpirationDate != null) {
          computedFormattedDate = _formatDate(extendedExpirationDate);
        }

        final String? displayFormattedDateOld =
            _formattedDateOld ?? computedFormattedDateOld;
        final String? displayFormattedDate =
            _formattedDateNew ?? computedFormattedDate;
        // Calcolo sconto
        final double discountPerFriend = kSconto10; // es. 0.1 = 10%
        double discount = invitedFriends * discountPerFriend;
        if (discount > 1) discount = 1; // max 100%

        final double toPay = 1 - discount;
        final double percentToPay = toPay.clamp(0.0, 1.0).toDouble();
        final bool canPop = Navigator.of(context).canPop();

        final showsCongratulation = percentToPay <= 0.0;

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
              kInviti,
              style: TextStyle(
                color: kBluScuro,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            centerTitle: false,
            iconTheme: const IconThemeData(color: kBluScuro),
            scrolledUnderElevation: 0,
            titleSpacing: 0,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (showsCongratulation)
                  Column(
                    children: [
                      Image.asset(kCongratulazioni, height: 250, width: 250),
                      SizedBox(height: 12),
                      Text(
                        kAbbonamentoOmaggio,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kBluScuro,
                        ),
                      ),
                      const SizedBox(height: 40),
                      CustomButton(
                        title: "Attiva omaggio",
                        titleColor: kWhite,
                        backgroundColor: kPrimary,
                        onPressed:
                            _omaggioAttivato
                                ? null
                                : () async {
                                  final DateTime baseExpiration =
                                      expirationDate ?? DateTime.now();
                                  final DateTime newExpirationDate =
                                      baseExpiration.add(
                                        const Duration(days: 365),
                                      );
                                  final String? oldDateText =
                                      expirationDate != null
                                          ? _formatDate(baseExpiration)
                                          : null;
                                  final String newDateText = _formatDate(
                                    newExpirationDate,
                                  );

                                  setState(() {
                                    _omaggioAttivato = true;
                                    _freezeSnapshot = true;
                                    _formattedDateOld = oldDateText;
                                    _formattedDateNew = newDateText;
                                    _cachedSnapshot ??= currentSnapshot;
                                  });

                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(uid)
                                        .update({
                                          'amiciInvitati': [],
                                          'expirationDate': Timestamp.fromDate(
                                            newExpirationDate,
                                          ),
                                        });
                                    debugPrint(
                                      'Inviti azzerati, nuova scadenza: $newDateText',
                                    );
                                  } catch (error) {
                                    if (!mounted) return;
                                    setState(() {
                                      _omaggioAttivato = false;
                                      _freezeSnapshot = false;
                                      _formattedDateOld = null;
                                      _formattedDateNew = null;
                                      _cachedSnapshot = null;
                                    });
                                    debugPrint(
                                      'Errore durante il reset degli inviti: $error',
                                    );
                                  }
                                },
                      ),
                      if (_omaggioAttivato)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 12,
                            left: 24,
                            right: 24,
                          ),
                          child:
                              displayFormattedDate != null
                                  ? Table(
                                    columnWidths: const {
                                      0: IntrinsicColumnWidth(),
                                    },
                                    defaultVerticalAlignment:
                                        TableCellVerticalAlignment.middle,
                                    children: [
                                      TableRow(
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.only(bottom: 4),
                                            child: Text(
                                              'Scadenza precedente: ',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: kBluScuro,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 4,
                                            ),
                                            child: Text(
                                              displayFormattedDateOld ?? '-',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: kBluScuro,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      TableRow(
                                        children: [
                                          const Text(
                                            'Nuova scadenza:',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: kBluScuro,
                                            ),
                                          ),
                                          Text(
                                            displayFormattedDate,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: kBluScuro,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                  : const Text(
                                    "La data di scadenza dell'abbonamento non è disponibile.",
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: kBluScuro,
                                    ),
                                  ),
                        ),
                    ],
                  )
                else
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

                const SizedBox(height: 10),

                if (!showsCongratulation)
                  // Testo sotto il cerchio
                  Text(
                    invitedFriends == 0
                        ? kNessunInvito
                        : "Hai invitato $invitedFriends amic${invitedFriends == 1 ? 'o' : 'i'}",
                    style: const TextStyle(fontSize: 18),
                  ),

                if (!showsCongratulation) const SizedBox(height: 20),

                // Lista amici invitati
                if (invitedFriendsNames.isNotEmpty && !showsCongratulation)
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
                            subtitle: const Text(kRegCompletata),
                          ),
                        );
                      },
                    ),
                  )
                else
                  const Spacer(),

                const SizedBox(height: 20),

                if (!showsCongratulation)
                  Text(
                    kInvitaAltriAmici,
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
