import 'package:flutter/material.dart';

class AddTagDialog extends StatefulWidget {
  final List<String> existingTags;

  const AddTagDialog({super.key, this.existingTags = const []});

  @override
  State<AddTagDialog> createState() => _AddTagDialogState();
}

class _AddTagDialogState extends State<AddTagDialog> {
  final _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() => _errorText = null);
      return;
    }

    if (widget.existingTags.contains(trimmed)) {
      setState(() => _errorText = 'Tag already exists');
    } else {
      setState(() => _errorText = null);
    }
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
            onChanged: _validate,
            decoration: InputDecoration(
              errorText: _errorText,
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
          if (_errorText != 'Tag already exists')
            Center(
              child: OutlinedButton(
                onPressed: () {
                  final trimmed = _controller.text.trim();
                  if (trimmed.isEmpty) {
                    setState(() => _errorText = 'Tag cannot be empty');
                    return;
                  }
                  Navigator.of(context).pop(trimmed);
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
