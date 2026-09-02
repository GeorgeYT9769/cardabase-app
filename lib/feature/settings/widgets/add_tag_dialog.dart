import 'package:cardabase/theme/theme.dart';
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
      title: const Text('Add a tag'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _controller,
            onChanged: _validate,
            decoration: InputDecoration(
              errorText: _errorText,
              prefixIcon: const Icon(Icons.label),
              labelText: 'Tag',
            ),
            style: theme.inputTextStyle,
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
                child: const Text('ADD'),
              ),
            ),
        ],
      ),
    );
  }
}
