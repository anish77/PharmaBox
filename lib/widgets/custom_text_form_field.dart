import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';

class CustomTextFormField extends StatelessWidget {
  final String label;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;

  const CustomTextFormField({
    super.key,
    required this.label,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: kPrimary),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: kPrimary),
        ),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red), // bordo rosso su errore
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
        errorStyle: const TextStyle(color: Colors.red, fontSize: 14),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      autocorrect: false,
      validator: validator,
      onSaved: onSaved,
    );
  }
}
