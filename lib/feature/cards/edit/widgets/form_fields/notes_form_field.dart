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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: null,
          decoration: InputDecoration(
            hintText: 'Add a note...',
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.outline,
              fontSize: 16,
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
