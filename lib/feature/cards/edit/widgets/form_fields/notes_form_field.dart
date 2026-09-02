import 'package:cardabase/theme/theme.dart';
import 'package:flutter/material.dart';

class NotesFormField extends StatelessWidget {
  const NotesFormField({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      maxLines: 10,
      decoration: InputDecoration(
        hintText: 'Some notes...',
      ),
      style: theme.inputTextStyle,
    );
  }
}
