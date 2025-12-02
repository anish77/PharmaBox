import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';

class CustomTextFormField extends StatefulWidget {
  final String label;
  final bool obscureText;
  final bool enableVisibilityToggle;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;
  final void Function(String)? onChanged;
  final TextStyle? labelStyle;
  final TextStyle? floatingLabelStyle;
  final TextStyle? textStyle;
  final Color? cursorColor;
  final TextEditingController? controller;

  const CustomTextFormField({
    super.key,
    required this.label,
    this.obscureText = false,
    this.enableVisibilityToggle = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onSaved,
    this.onChanged,
    this.labelStyle,
    this.floatingLabelStyle,
    this.textStyle,
    this.cursorColor,
    this.controller,
  });

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  void didUpdateWidget(covariant CustomTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText &&
        !widget.enableVisibilityToggle) {
      _obscureText = widget.obscureText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final shouldToggle = widget.enableVisibilityToggle;
    return TextFormField(
      controller: widget.controller,
      obscureText: shouldToggle ? _obscureText : widget.obscureText,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      onSaved: widget.onSaved,
      onChanged: widget.onChanged,
      style: widget.textStyle ?? const TextStyle(color: kBluScuro),
      cursorColor: widget.cursorColor ?? (widget.textStyle?.color ?? kPrimary),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: widget.labelStyle ?? const TextStyle(color: kBluScuro),
        floatingLabelStyle:
            widget.floatingLabelStyle ?? const TextStyle(color: kPrimary),
        suffixIcon: shouldToggle
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: widget.textStyle?.color ?? kPrimary,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,
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
