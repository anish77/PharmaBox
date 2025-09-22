import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/logic/open_email.dart';

class MembersOnlyPlaceholder extends StatefulWidget {
  const MembersOnlyPlaceholder({super.key});

  @override
  State<MembersOnlyPlaceholder> createState() => _MembersOnlyPlaceholderState();
}

class _MembersOnlyPlaceholderState extends State<MembersOnlyPlaceholder> {
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
              onPressed: OpenEmail().contattaci(
                context,
                kAccessoMembri,
                kDiventareMembro,
              ),
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
