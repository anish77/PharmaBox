import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart'; // per il colore kPrimary

class FullScreenLoader extends StatelessWidget {
  final bool isLoading;

  const FullScreenLoader({super.key, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return const SizedBox.shrink();

    return Container(
      color: Colors.black54,
      child: const Center(child: CircularProgressIndicator(color: kPrimary)),
    );
  }
}
