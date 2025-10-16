import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/widgets/manual_counter_dialog.dart';

class CounterButton extends StatefulWidget {
  final int initialValue;
  final Function(int)? onChanged;
  final double height;
  final double width;

  const CounterButton({
    super.key,
    this.initialValue = 1,
    this.onChanged,
    this.height = 40.0, // 👈 altezza predefinita
    this.width = 120.0, // 👈 larghezza predefinita
  });

  @override
  State<CounterButton> createState() => _CounterButtonState();
}

class _CounterButtonState extends State<CounterButton> {
  late int _counter;

  @override
  void initState() {
    super.initState();
    _counter = widget.initialValue;
  }

  @override
  void didUpdateWidget(covariant CounterButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      setState(() {
        _counter = widget.initialValue;
      });
    }
  }

  void _increment() {
    setState(() {
      _counter++;
      widget.onChanged?.call(_counter);
    });
  }

  void _decrement() {
    if (_counter > 0) {
      setState(() {
        _counter--;
        widget.onChanged?.call(_counter);
      });
    }
  }

  Future<void> _showManualEntryDialog() async {
    final previousValue = _counter;

    final newValue = await showDialog<int>(
      context: context,
      builder: (_) => ManualCounterDialog(initialValue: _counter),
    );

    if (!mounted) return;

    if (newValue == null) {
      setState(() => _counter = previousValue);
      return;
    }

    setState(() => _counter = newValue);
    if (newValue != previousValue) {
      widget.onChanged?.call(_counter);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: widget.width, // ✅ larghezza fissa,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: [
          // Button -
          Expanded(
            child: GestureDetector(
              onTap: _decrement,
              child: Container(
                height: widget.height,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: kSecondary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                  ),
                  border: Border.all(color: kPrimary, width: 1),
                ),
                child: const Text(
                  '-',
                  style: TextStyle(fontSize: 20, color: kBluScuro),
                ),
              ),
            ),
          ),

          // Counter (centrale)
          Expanded(
            child: GestureDetector(
              onTap: _showManualEntryDialog,
              child: Container(
                height: widget.height,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: kPrimary,
                  border: Border.all(color: kPrimary, width: 1),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$_counter',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: kWhite),
                  ),
                ),
              ),
            ),
          ),

          // Button +
          Expanded(
            child: GestureDetector(
              onTap: _increment,
              child: Container(
                height: widget.height,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: kSecondary,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  border: Border.all(color: kPrimary, width: 1),
                ),
                child: const Text(
                  '+',
                  style: TextStyle(fontSize: 20, color: kBluScuro),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
