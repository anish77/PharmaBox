import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';

class CercaProdottoField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final String? initialValue;
  final TextEditingController? controller;
  final double bottomPadding;

  const CercaProdottoField({
    super.key,
    required this.onChanged,
    this.onFieldSubmitted,
    this.initialValue,
    this.controller,
    this.bottomPadding = 20,
  });

  @override
  State<CercaProdottoField> createState() => _CercaProdottoFieldState();
}

class _CercaProdottoFieldState extends State<CercaProdottoField> {
  late String _text;

  @override
  void initState() {
    super.initState();
    _text = widget.controller?.text ?? widget.initialValue ?? '';
    widget.controller?.addListener(_syncController);
  }

  void _syncController() {
    final value = widget.controller?.text ?? '';
    if (mounted && value != _text) setState(() => _text = value);
  }

  @override
  void didUpdateWidget(covariant CercaProdottoField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_syncController);
      widget.controller?.addListener(_syncController);
      _syncController();
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_syncController);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = _text.trim().length;
    final canSearch = count >= 3;
    final fieldColor = canSearch ? kPrimary : const Color(0xFF9CA0AC);
    return Padding(
      padding: EdgeInsets.only(bottom: widget.bottomPadding, top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Cerca prodotto',
              style: TextStyle(color: kBluScuro, fontWeight: FontWeight.w600),
            ),
          ),
          TextFormField(
            initialValue:
                widget.controller == null ? widget.initialValue : null,
            controller: widget.controller,
            decoration: InputDecoration(
              hintText: 'Nome prodotto',
              prefixIcon: Icon(Icons.search_rounded, color: fieldColor),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: fieldColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: fieldColor, width: 1.5),
              ),
            ),
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.search,
            autocorrect: false,
            validator:
                (value) =>
                    (value ?? '').trim().length < 3
                        ? 'Inserisci almeno 3 caratteri'
                        : null,
            onChanged: (value) {
              setState(() => _text = value);
              widget.onChanged(value);
            },
            onFieldSubmitted: widget.onFieldSubmitted,
          ),
          if (!canSearch) ...[
            const SizedBox(height: 7),
            const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 15,
                  color: Color(0xFF8589A7),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Inserisci almeno 3 caratteri per cercare',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8589A7),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class CercaProdottoBottomBar extends StatelessWidget {
  final String query;
  final VoidCallback? onPressed;
  final String title;

  const CercaProdottoBottomBar({
    super.key,
    required this.query,
    this.onPressed,
    this.title = kOpzioni,
  });

  @override
  Widget build(BuildContext context) {
    final isValid = query.trim().length >= 3;
    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.only(
          top: 18,
          bottom: 16,
          left: 24,
          right: 24,
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isValid ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              disabledBackgroundColor: const Color(0xFFDADBE1),
              disabledForegroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 9),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
