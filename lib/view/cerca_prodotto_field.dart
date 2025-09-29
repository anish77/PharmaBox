import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';

class CercaProdottoField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding, top: 10),
      child: TextFormField(
        initialValue: controller == null ? initialValue : null,
        controller: controller,
        decoration: InputDecoration(
          labelText: kCercaProdotto,
          labelStyle: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: kBluScuro),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: kPrimary),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: kPrimary),
          ),
        ),
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.search,
        autocorrect: false,
        validator: (value) {
          if (value == null || value.trim().isEmpty || value.length < 3) {
            return kMsgErroreCercaProdotto;
          }
          return null;
        },
        onChanged: onChanged,
        onFieldSubmitted: onFieldSubmitted,
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
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 45, left: 24, right: 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isValid ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
