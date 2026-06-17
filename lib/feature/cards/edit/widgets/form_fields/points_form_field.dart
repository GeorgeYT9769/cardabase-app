import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

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
  Timer? _incrementTimer;
  Timer? _decrementTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(onWidgetControllerValueChanged);
    _textController.text = widget.controller.value.toString();
  }

  @override
  void didUpdateWidget(covariant PointsFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(onWidgetControllerValueChanged);
      widget.controller.addListener(onWidgetControllerValueChanged);
      _textController.text = widget.controller.value.toString();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(onWidgetControllerValueChanged);
    _textController.dispose();
    _incrementTimer?.cancel();
    _decrementTimer?.cancel();
    super.dispose();
  }

  void onWidgetControllerValueChanged() {
    final strValue = widget.controller.value.toString();
    if (strValue == _textController.text) {
      return;
    }
    _textController.text = strValue;
  }

  void _incrementValue() {
    if (widget.controller.value < 9999999999) {
      widget.controller.value = widget.controller.value + 1;
    }
  }

  void _decrementValue() {
    if (widget.controller.value > 0) {
      widget.controller.value = widget.controller.value - 1;
    } else {
      widget.controller.value = 0;
    }
  }

  void _startIncrementTimer() {
    _incrementTimer?.cancel();
    _incrementValue(); // First increment immediately
    _incrementTimer = Timer.periodic(Duration(milliseconds: 100), (_) {
      _incrementValue();
    });
  }

  void _stopIncrementTimer() {
    _incrementTimer?.cancel();
    _incrementTimer = null;
  }

  void _startDecrementTimer() {
    _decrementTimer?.cancel();
    _decrementValue(); // First decrement immediately
    _decrementTimer = Timer.periodic(Duration(milliseconds: 100), (_) {
      _decrementValue();
    });
  }

  void _stopDecrementTimer() {
    _decrementTimer?.cancel();
    _decrementTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      textAlign: TextAlign.center,
      controller: _textController,
      onChanged: (strValue) {
        if (strValue.isEmpty) {
          _textController.text = '0';
          _textController.selection = const TextSelection.collapsed(offset: 1);
          widget.controller.value = 0;
          return;
        }

        final intValue = int.tryParse(strValue);
        if (intValue != null) {
          widget.controller.value = intValue;
          final cleanStr = intValue.toString();
          if (strValue != cleanStr) {
            _textController.text = cleanStr;
            _textController.selection = TextSelection.collapsed(offset: cleanStr.length);
          }
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
        prefixIcon: GestureDetector(
          onTap: _decrementValue,
          onLongPressStart: (_) => _startDecrementTimer(),
          onLongPressEnd: (_) => _stopDecrementTimer(),
          child: Icon(
            Icons.remove,
            color: theme.colorScheme.secondary,
            size: 30,
          ),
        ),
        suffixIcon: GestureDetector(
          onTap: _incrementValue,
          onLongPressStart: (_) => _startIncrementTimer(),
          onLongPressEnd: (_) => _stopIncrementTimer(),
          child: Icon(
            Icons.add,
            color: theme.colorScheme.secondary,
            size: 30,
          ),
        ),
      ),
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.tertiary,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
