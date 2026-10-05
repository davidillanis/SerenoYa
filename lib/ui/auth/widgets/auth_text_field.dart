import 'package:flutter/material.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction,
    this.prefixIcon,
    this.suffixIcon,
    this.onSubmitted,
    this.hintText,
    this.autofillHints,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;
  final String? hintText;
  final Iterable<String>? autofillHints;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      autofillHints:
          autofillHints ??
          (keyboardType == TextInputType.emailAddress
              ? const [AutofillHints.email]
              : null),
      autocorrect: keyboardType != TextInputType.emailAddress && !obscureText,
      enableSuggestions: !obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        suffixIcon: suffixIcon,
      ),
      onSubmitted: onSubmitted,
    );
  }
}
