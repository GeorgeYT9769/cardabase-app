import 'package:cardabase/feature/settings/model.dart';
import 'package:flutter/material.dart';

import 'color_schemes.g.dart';

/// Corner radius of the outlined buttons used for dialog and page actions.
const _buttonBorderRadius = 11.0;

/// Corner radius of text fields and of the larger "tile" buttons.
const _inputBorderRadius = 10.0;

/// Width of the outline around buttons and text fields.
const _borderWidth = 2.0;

/// Colour used for destructive actions (delete, clear, ...).
const _destructiveColor = Colors.red;

ThemeData lightTheme(ThemeSettings settings) =>
    _theme(settings, lightColorScheme);

ThemeData darkTheme(ThemeSettings settings) => _theme(
      settings,
      settings.useExtraDark
          ? darkColorScheme.copyWith(surface: Colors.black)
          : darkColorScheme,
    );

ThemeData _theme(ThemeSettings settings, ColorScheme colorScheme) {
  final textFont = settings.useSystemFont ? null : 'Roboto';
  final textTheme = TextTheme(
    titleLarge: TextStyle(
      fontFamily: settings.useSystemFont ? null : 'xirod',
      letterSpacing: settings.useSystemFont ? 3 : 5,
      fontSize: settings.useSystemFont ? 25 : 17,
      fontWeight: FontWeight.w900,
      color: colorScheme.tertiary,
    ),
    bodyLarge: TextStyle(
      fontFamily: textFont,
      color: colorScheme.inverseSurface,
    ),
  );
  final bodyLarge = textTheme.bodyLarge!;

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
      },
    ),
    fontFamily: textFont,
    textTheme: textTheme,
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.tertiary,
        side: BorderSide(color: colorScheme.primary, width: _borderWidth),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_buttonBorderRadius),
        ),
        textStyle: bodyLarge.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_inputBorderRadius),
        borderSide: const BorderSide(width: _borderWidth),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_inputBorderRadius),
        borderSide: BorderSide(color: colorScheme.primary),
      ),
      focusColor: colorScheme.primary,
      labelStyle: bodyLarge.copyWith(color: colorScheme.secondary),
      hintStyle: bodyLarge.copyWith(
        color: colorScheme.inverseSurface,
        fontSize: 15,
      ),
      prefixIconColor: colorScheme.secondary,
      suffixIconColor: colorScheme.secondary,
    ),
    dialogTheme: DialogThemeData(
      titleTextStyle: bodyLarge.copyWith(
        color: colorScheme.inverseSurface,
        fontSize: 30,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.primary,
      thickness: 1.0,
    ),
  );
}

/// App wide styles that cannot be expressed as a component theme, but that are
/// still derived from the global [ThemeData].
extension CdbThemeStyles on ThemeData {
  /// Style of the value the user types into a text field.
  ///
  /// There is no component theme for this: a [TextField] falls back to
  /// [TextTheme.bodyLarge], which is also used for plain text.
  TextStyle? get inputTextStyle => textTheme.bodyLarge?.copyWith(
        color: colorScheme.tertiary,
        fontWeight: FontWeight.bold,
      );

  /// Emphasized [InputDecoration.labelStyle], used by the fields that make up
  /// the body of a page instead of a single field inside a dialog.
  TextStyle? get emphasizedInputLabelStyle => textTheme.bodyLarge?.copyWith(
        color: colorScheme.inverseSurface,
        fontWeight: FontWeight.bold,
        fontSize: 17,
      );

  /// Outlined button for a destructive action, e.g. deleting a card.
  ButtonStyle get destructiveButtonStyle => OutlinedButton.styleFrom(
        foregroundColor: _destructiveColor,
        side: const BorderSide(color: _destructiveColor, width: _borderWidth),
      );

  /// Outlined button that spans the full width of the page and acts as a tile,
  /// e.g. the buttons on the settings and cloud backup pages.
  ButtonStyle tileButtonStyle({Color? borderColor, Color? foregroundColor}) =>
      OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(15),
        foregroundColor: foregroundColor ?? colorScheme.inverseSurface,
        side: BorderSide(color: borderColor ?? colorScheme.primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_inputBorderRadius),
        ),
        minimumSize: const Size.fromHeight(100),
        textStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
      );
}
