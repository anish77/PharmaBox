import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';

class ContainerOpzione extends StatefulWidget {
  const ContainerOpzione({
    super.key,
    required this.nomeOpione,
    this.hideWhenUnselected = false, required Null Function(dynamic isSel) onSelectedChanged, required bool selected,
  });

  final String nomeOpione;
  final bool hideWhenUnselected;

  @override
  State<ContainerOpzione> createState() => _ContainerOpzioneState();
}

class _ContainerOpzioneState extends State<ContainerOpzione> {
  bool showClose = false;

  @override
  Widget build(BuildContext context) {
    // Se richiesto, nasconde l'opzione quando non è selezionata
    if (widget.hideWhenUnselected && !showClose) {
      return const SizedBox.shrink();
    }
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
            if (!widget.hideWhenUnselected || showClose)
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
