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
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Text(
        'Pick a color!',
        style: TextStyle(color: Theme.of(context).colorScheme.inverseSurface, fontFamily: 'Roboto-Regular.ttf',),
      ),
      content: SingleChildScrollView(
        child: ColorPicker(
          labelTypes: const [ColorLabelType.rgb],
          displayThumbColor: true,
          hexInputBar: true,
          pickerAreaBorderRadius: BorderRadius.circular(10.0),
          paletteType: PaletteType.hsv,
          enableAlpha: false,
          pickerColor: currentColor!,
          portraitOnly: true,
          onColorChanged: (value) {
            if (mounted) {
              setState(() {
                currentColor = value;
              });
            }
          },
        ),
      ),
      actions: <Widget>[
        Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context, currentColor);
            },
            style: ElevatedButton.styleFrom(elevation: 0.0),
            child: Text(
              'Got it',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto-Regular.ttf',
                fontSize: 15,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}