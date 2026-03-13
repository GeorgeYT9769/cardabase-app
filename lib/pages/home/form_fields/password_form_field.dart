import 'package:flutter/material.dart';

class PasswordFormField extends StatelessWidget {
  const PasswordFormField({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(width: 2.0),
        ),
        focusColor: theme.colorScheme.primary,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        labelStyle: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.secondary,
        ),
        prefixIcon: Icon(
          Icons.password,
          color: theme.colorScheme.secondary,
        ),
        labelText: 'Password',
      ),
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.tertiary,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
