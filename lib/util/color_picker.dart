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
    currentColor = widget.cardColor;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Text(
        'Pick a color!',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.inverseSurface,fontSize: 30),
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
          child: OutlinedButton(
            onPressed: () {
              Navigator.pop(context, currentColor);
            },
            style: OutlinedButton.styleFrom(elevation: 0.0, side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
            child: Text(
              'Got it',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
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