import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';

class CustomTextFormField extends StatelessWidget {
  final String label;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final TextStyle? labelStyle;
  final TextStyle? floatingLabelStyle;
  final TextStyle? textStyle;
  final Color? cursorColor;
  final TextEditingController? controller;

  const CustomTextFormField({
    super.key,
    required this.label,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onSaved,
    this.onChanged,
    this.onFieldSubmitted,
    this.labelStyle,
    this.floatingLabelStyle,
    this.textStyle,
    this.cursorColor,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onSaved: onSaved,
      onChanged: onChanged,
      style: textStyle ?? const TextStyle(color: kBluScuro),
      cursorColor: cursorColor ?? (textStyle?.color ?? kPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: labelStyle ?? const TextStyle(color: kBluScuro),
        floatingLabelStyle:
            floatingLabelStyle ?? const TextStyle(color: kPrimary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kPrimary, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kPrimary, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kPrimary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kRed, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kRed, width: 1.8),
        ),
      ),
    );
  }
}
