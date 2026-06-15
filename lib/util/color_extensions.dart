import 'package:flutter/material.dart';

extension ColorExtensions on Color {
  Color get contrastingTextColor {
    return computeLuminance() > 0.7 ? Colors.black : Colors.white;
  }
}
