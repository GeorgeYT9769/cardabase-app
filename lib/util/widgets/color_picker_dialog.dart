import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ColorPickerDialog extends StatefulWidget {
  const ColorPickerDialog({super.key, required this.cardColor});

  final Color cardColor;

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
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
      title: const Text('Card Color'),
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
            child: const Text('Got it'),
          ),
        ),
      ],
    );
  }
}
