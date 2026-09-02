import 'package:cardabase/theme/theme.dart';
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
      title: const Text('Are you sure?'),
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
      style: theme.destructiveButtonStyle,
      child: const Text('DELETE'),
    );
  }
}
