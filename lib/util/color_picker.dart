import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ColorPickerSecondDialog extends StatefulWidget {
  ColorPickerSecondDialog({super.key, required this.cardColor});

  Color cardColor;

  @override
  State<ColorPickerSecondDialog> createState() =>
      _ColorPickerSecondDialogState();
}

class _ColorPickerSecondDialogState extends State<ColorPickerSecondDialog> with ChangeNotifier {

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.background,
      title: const Text('Pick a color!', style: TextStyle(fontFamily: 'Roboto-Regular.ttf',),),
      content: SingleChildScrollView(
          child: ColorPicker(
            enableAlpha: false,
            pickerColor: widget.cardColor,
            portraitOnly: true,
            onColorChanged: (value) {
              setState(() {
                widget.cardColor = value;
              });
            },
          )),
      actions: <Widget>[
        ElevatedButton(
          child: const Text('Got it', style: TextStyle(fontFamily: 'Roboto-Regular.ttf',),),
          onPressed: () {
            Navigator.pop(context, widget.cardColor);
          },
        ),
      ],
    );
  }
}