import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
      surface: Color.fromARGB(255, 244, 249, 249),
      primary: Color.fromARGB(255, 20, 66, 114),
      secondary: Color.fromARGB(255, 32, 82, 149),
      tertiary: Color.fromARGB(255, 44, 116, 179)
  )
);

ThemeData darkMode = ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
        surface: Color.fromARGB(255, 10, 38, 71), //background
        primary: Color.fromARGB(255, 20, 66, 114), //shades
        secondary: Color.fromARGB(255, 32, 82, 149), //buttons
        tertiary: Color.fromARGB(255, 44, 116, 179), //text
    )
);