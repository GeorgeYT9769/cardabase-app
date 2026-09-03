import 'package:cardabase/theme/theme.dart';
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
        labelText: 'Card Name',
        labelStyle: theme.emphasizedInputLabelStyle,
        prefixIcon: const Icon(Icons.abc),
      ),
      style: theme.inputTextStyle,
    );
  }
}
