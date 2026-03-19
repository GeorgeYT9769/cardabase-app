import 'package:cardabase/feature/settings/model.dart';
import 'package:flutter/material.dart';

import 'color_schemes.g.dart';

ThemeData lightTheme(ThemeSettings settings) {
  final textFont = settings.useSystemFont ? null : 'Roboto';
  return ThemeData(
    useMaterial3: true,
    colorScheme: lightColorScheme,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
      },
    ),
    fontFamily: textFont,
    textTheme: TextTheme(
      titleLarge: TextStyle(
        fontFamily: settings.useSystemFont ? null : 'xirod',
        letterSpacing: settings.useSystemFont ? 3 : 5,
        fontSize: settings.useSystemFont ? 25 : 17,
        fontWeight: FontWeight.w900,
        color: const Color(0xFF0062A1), //tertiary
      ),
      bodyLarge: TextStyle(
        fontFamily: textFont,
        color: const Color(0xFF003062),
      ),
    ),
  );
}

ThemeData darkTheme(ThemeSettings settings) {
  final textFont = settings.useSystemFont ? null : 'Roboto';
  return ThemeData(
    useMaterial3: true,
    colorScheme: settings.useExtraDark
        ? darkColorScheme.copyWith(
            surface: Colors.black,
          )
        : darkColorScheme,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
      },
    ),
    fontFamily: textFont,
    textTheme: TextTheme(
      titleLarge: TextStyle(
        fontFamily: settings.useSystemFont ? null : 'xirod',
        letterSpacing: settings.useSystemFont ? 3 : 5,
        fontSize: settings.useSystemFont ? 25 : 17,
        fontWeight: FontWeight.w900,
        color: const Color(0xFF9CCAFF), //tertiary
      ),
      bodyLarge: TextStyle(
        fontFamily: textFont,
        color: const Color(0xFFD6E3FF), //inverseSurface
      ),
    ),
  );
}
