import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PointsFormField extends StatefulWidget {
  const PointsFormField({
    super.key,
    required this.controller,
  });

  final ValueNotifier<int> controller;

  @override
  State<PointsFormField> createState() => _PointsFormFieldState();
}

class _PointsFormFieldState extends State<PointsFormField> {
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(onWidgetControllerValueChanged);
  }

  @override
  void didUpdateWidget(covariant PointsFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(onWidgetControllerValueChanged);
      widget.controller.addListener(onWidgetControllerValueChanged);
    }
  }

  void onWidgetControllerValueChanged() {
    final strValue = widget.controller.value.toString();
    if (strValue == _textController.text) {
      return;
    }
    _textController.text = strValue;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: _textController,
      onChanged: (strValue) {
        final intValue = int.tryParse(strValue);
        if (intValue != null) {
          widget.controller.value = intValue;
        }
      },
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      maxLength: 10,
      keyboardType: TextInputType.number,
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
        counterText: '',
        labelText: 'Points',
        labelStyle: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.inverseSurface,
          fontWeight: FontWeight.bold,
          fontSize: 17,
        ),
        prefixIcon: IconButton(
          icon: Icon(
            Icons.remove,
            color: theme.colorScheme.secondary,
          ),
          onPressed: () {
            if (widget.controller.value > 0) {
              widget.controller.value = (widget.controller.value) - 1;
            } else {
              widget.controller.value = 0;
            }
          },
        ),
        suffixIcon: IconButton(
          icon: Icon(
            Icons.add,
            color: theme.colorScheme.secondary,
          ),
          onPressed: () {
            if (widget.controller.value < 9999999999) {
              widget.controller.value = (widget.controller.value) + 1;
            } else {
              widget.controller.value = 0;
            }
          },
        ),
      ),
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.tertiary,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
