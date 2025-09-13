import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';

class ContainerOpzione extends StatefulWidget {
  const ContainerOpzione({
    super.key,
    required this.nomeOpione,
    this.hideWhenUnselected = false,
    this.selected = false,
    this.onSelectedChanged,
  });

  final String nomeOpione;
  final bool hideWhenUnselected;
  final bool selected;
  final ValueChanged<bool>? onSelectedChanged;

  @override
  State<ContainerOpzione> createState() => _ContainerOpzioneState();
}

class _ContainerOpzioneState extends State<ContainerOpzione> {
  late bool _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
  }

  @override
  void didUpdateWidget(covariant ContainerOpzione oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      _selected = widget.selected;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Nasconde completamente se richiesto e non selezionato
    if (widget.hideWhenUnselected && !_selected) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: _selected
          ? null
          : () {
              setState(() => _selected = true);
              widget.onSelectedChanged?.call(true);
            },
      child: Container(
        decoration: BoxDecoration(
          color: _selected ? kPrimary : kSecondary,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.hideWhenUnselected || _selected)
              Text(
                widget.nomeOpione,
                style: TextStyle(
                  color: _selected ? kWhite : kBluScuro,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            if (_selected) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() => _selected = false);
                  widget.onSelectedChanged?.call(false);
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
