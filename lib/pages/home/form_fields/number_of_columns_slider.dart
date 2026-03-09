import 'package:cardabase/util/vibration_provider.dart';
import 'package:flutter/material.dart';

class NumberOfColumnsSlider extends StatelessWidget {
  const NumberOfColumnsSlider({
    super.key,
    required this.controller,
  });

  final ValueNotifier<int> controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, _) => Slider(
        year2023: false,
        value: value.toDouble(),
        min: 1,
        max: 5,
        divisions: 4,
        onChanged: (double newValue) {
          VibrationProvider.vibrateSuccess();
          controller.value = newValue.round();
        },
      ),
    );
  }
}
