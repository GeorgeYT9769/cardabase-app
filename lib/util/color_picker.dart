import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ColorPickerSecondDialog extends StatefulWidget {
  ColorPickerSecondDialog({super.key, required this.cardColor});

  Color cardColor;

  @override
  State<ColorPickerSecondDialog> createState() =>
      _ColorPickerSecondDialogState();
}

class _ColorPickerSecondDialogState extends State<ColorPickerSecondDialog> {
  Color? currentColor;

  @override
  void initState() {
    super.initState();
    currentColor = widget.cardColor; // Initialize the local color variable
  }

  @override
  void dispose() {
    super.dispose(); // Call super.dispose() to ensure proper cleanup
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.background,
      title: const Text(
        'Pick a color!',
        style: TextStyle(fontFamily: 'Roboto-Regular.ttf'),
      ),
      content: SingleChildScrollView(
        child: ColorPicker(
          enableAlpha: false,
          pickerColor: currentColor!,
          portraitOnly: true,
          onColorChanged: (value) {
            if (mounted) { // Check if the widget is still mounted
              setState(() {
                currentColor = value; // Update the local color variable
              });
            }
          },
        ),
      ),
      actions: <Widget>[
        ElevatedButton(
          child: const Text(
            'Got it',
            style: TextStyle(fontFamily: 'Roboto-Regular.ttf'),
          ),
          onPressed: () {
            Navigator.pop(context, currentColor); // Pass the current color
          },
        ),
      ],
    );
  }
}