import 'package:cardabase/util/form_validation.dart';
import 'package:flutter/material.dart';

class CardNameFormField extends StatelessWidget {
  const CardNameFormField({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      validator: isNotEmpty<String>(),
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
        labelText: 'Card Name',
        labelStyle: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.inverseSurface,
          fontWeight: FontWeight.bold,
          fontSize: 17,
        ),
        prefixIcon: Icon(
          Icons.abc,
          color: theme.colorScheme.secondary,
        ),
      ),
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.tertiary,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
