import 'package:flutter/material.dart';

class ClearCardsDialog extends StatefulWidget {
  const ClearCardsDialog({super.key});

  @override
  State<ClearCardsDialog> createState() => _ClearCardsDialogState();
}

class _ClearCardsDialogState extends State<ClearCardsDialog> {
  Future<void> onDeleteButtonPressed() async {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) {
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        'Are you sure?',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.inverseSurface,
          fontSize: 30,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'This action cannot be undone!',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.tertiary,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: _deleteButton(theme),
          ),
        ],
      ),
    );
  }

  Widget _deleteButton(ThemeData theme) {
    return OutlinedButton(
      onPressed: onDeleteButtonPressed,
      style: OutlinedButton.styleFrom(
        elevation: 0.0,
        side: BorderSide(
          color: theme.colorScheme.primary,
          width: 2.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
        ),
      ),
      child: Text(
        'DELETE',
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: theme.colorScheme.inverseSurface,
        ),
      ),
    );
  }
}
