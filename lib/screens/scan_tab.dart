import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';

class ScanTab extends StatelessWidget {
  const ScanTab({super.key});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return Align(
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: h * 0.10), // sposta il contenuto più in alto
          SizedBox(
            height: h * 0.30,
            child: Image.asset(
              kScanCode,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Scan code',
            style: TextStyle(
              fontSize: 16,
              color: kBluScuro,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
