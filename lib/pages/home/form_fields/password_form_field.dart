import 'package:cardabase/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PasswordFormField extends StatelessWidget {
  const PasswordFormField({
    super.key,
    required this.controller,
    this.suffixIcon,
    this.autofillHints = const [AutofillHints.password],
  });

  final TextEditingController controller;
  final Widget? suffixIcon;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      obscureText: true,
      autofillHints: autofillHints,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.password),
        labelText: 'Password',
        suffixIcon: suffixIcon,
      ),
      style: theme.inputTextStyle,
    );
  }
}
