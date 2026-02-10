import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    surface: Color(0xFFFDFBFF),
    primary: Color(0xFF1960A5),
    secondary: Color(0xFF295EA7),
    tertiary: Color(0xFF0062A1),
  ),
);

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    surface: Color(0xFF001B3D), //background
    primary: Color(0xFFA4C9FF), //shades
    secondary: Color(0xFFA9C7FF), //buttons
    tertiary: Color(0xFF9CCAFF), //text
  ),
);
