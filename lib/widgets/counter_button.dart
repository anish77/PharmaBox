import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';

class CounterButton extends StatefulWidget {
  final int initialValue;
  final Function(int)? onChanged;
  final double? height;
  final double? width;

  const CounterButton({
    super.key,
    this.initialValue = 1,
    this.onChanged,
    this.height,
    this.width,
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
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Button -
        GestureDetector(
          onTap: _decrement,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
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

        // Counter
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          decoration: BoxDecoration(
            color: kPrimary,
            border: Border.all(color: kPrimary, width: 1),
          ),
          child: Text(
            '$_counter',
            style: const TextStyle(fontSize: 18, color: kWhite),
          ),
        ),

        // Button +
        GestureDetector(
          onTap: _increment,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
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
      ],
    );

    if (widget.height != null || widget.width != null) {
      return SizedBox(
        height: widget.height,
        width: widget.width,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: row,
        ),
      );
    }

    return row;
  }
}
