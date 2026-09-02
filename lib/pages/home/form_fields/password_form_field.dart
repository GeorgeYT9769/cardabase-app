import 'package:cardabase/theme/theme.dart';
import 'package:flutter/material.dart';

class PasswordFormField extends StatelessWidget {
  const PasswordFormField({
    super.key,
    required this.controller,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.password),
        labelText: 'Password',
        suffixIcon: suffixIcon,
      ),
      style: theme.inputTextStyle,
    );
  }
}
