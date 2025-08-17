import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';

class ContainerOpzione extends StatefulWidget {
  const ContainerOpzione({super.key, required this.nomeOpione});

  final String nomeOpione;

  @override
  State<ContainerOpzione> createState() => _ContainerOpzioneState();
}

class _ContainerOpzioneState extends State<ContainerOpzione> {
  bool showClose = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
   
      onTap:
          showClose
              ? null // disabilito il tap quando c’è la X
              : () {
                setState(() {
                  showClose = true;
                });
              },
      child: Container(
        decoration: BoxDecoration(
          color: showClose ? kPrimary : kSecondary,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(10.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.nomeOpione,
              style: TextStyle(
                color: showClose ? kWhite : kBluScuro,
                fontWeight: FontWeight.w500, // Medium
                fontSize: 16, // Body
              ),
            ),
            if (showClose) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    // se vuoi che sparisca del tutto puoi rimuoverlo da lista parent
                    // oppure solo resettare lo stato:
                    showClose = false;
                  });
                },
                child: const Icon(Icons.close, color: kWhite, size: 18),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
