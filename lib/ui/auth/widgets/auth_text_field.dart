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
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      autofillHints: keyboardType == TextInputType.emailAddress
          ? const [AutofillHints.email]
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        suffixIcon: suffixIcon,
      ),
      onSubmitted: onSubmitted,
    );
  }
}
