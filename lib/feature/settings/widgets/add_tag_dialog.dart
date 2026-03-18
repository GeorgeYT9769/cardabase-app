import 'package:flutter/material.dart';

class AddTagDialog extends StatefulWidget {
  const AddTagDialog({super.key});

  @override
  State<AddTagDialog> createState() => _AddTagDialogState();
}

class _AddTagDialogState extends State<AddTagDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        'Add a tag',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.inverseSurface,
          fontSize: 30,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _controller,
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
                Icons.label,
                color: theme.colorScheme.secondary,
              ),
              labelText: 'Tag',
            ),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.tertiary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: OutlinedButton(
              onPressed: () {
                final trimmed = _controller.text.trim();
                if (trimmed.isEmpty) {
                  return;
                }
                Navigator.of(context).pop(
                  _controller.text.trim(),
                );
              },
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
                'ADD',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: theme.colorScheme.tertiary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
