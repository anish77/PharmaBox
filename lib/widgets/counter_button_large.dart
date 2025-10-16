import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/widgets/manual_counter_dialog.dart';

class CounterButtonLarge extends StatefulWidget {
  final int initialValue;
  final Function(int)? onChanged;

  const CounterButtonLarge({super.key, this.initialValue = 1, this.onChanged});

  @override
  State<CounterButtonLarge> createState() => _CounterButtonLargeState();
}

class _CounterButtonLargeState extends State<CounterButtonLarge> {
  late int _counter;

  @override
  void initState() {
    super.initState();
    _counter = widget.initialValue;
  }

  @override
  void didUpdateWidget(covariant CounterButtonLarge oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        // Button -
        Expanded(
          child: GestureDetector(
            onTap: _decrement,
            child: Container(
              height: 48,
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

        // Counter
        Expanded(
          child: GestureDetector(
            onTap: _showManualEntryDialog,
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: kPrimary,
                border: Border.all(color: kPrimary, width: 1),
              ),
              child: Text(
                '$_counter',
                style: const TextStyle(fontSize: 18, color: kWhite),
              ),
            ),
          ),
        ),

        // Button +
        Expanded(
          child: GestureDetector(
            onTap: _increment,
            child: Container(
              height: 48,
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
    );
  }

  Future<void> _showManualEntryDialog() async {
    final newValue = await showDialog<int>(
      context: context,
      builder: (_) => ManualCounterDialog(initialValue: _counter),
    );

    if (newValue != null && newValue != _counter) {
      setState(() {
        _counter = newValue;
        widget.onChanged?.call(_counter);
      });
    }
  }
}

