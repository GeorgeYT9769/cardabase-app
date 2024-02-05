import 'package:flutter/material.dart';
import 'package:cardabase/theme/theme.dart';
import 'color_schemes.g.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

var themebox = Hive.box('mytheme');

class ThemeProvider with ChangeNotifier {
  ThemeData _themeData = ThemeData(useMaterial3: true, colorScheme: darkColorScheme); //

  ThemeData get themeData => _themeData;

  set themeData(ThemeData themeData) {
    _themeData = themeData;
    notifyListeners();
  }


  toggleTheme() {
    if (_themeData == ThemeData(useMaterial3: true, colorScheme: darkColorScheme)) {
      themeData = ThemeData(useMaterial3: true, colorScheme: lightColorScheme);
      themebox.put('apptheme', false);
      print(themebox.get('apptheme'));
    } else {
      themeData = ThemeData(useMaterial3: true, colorScheme: darkColorScheme);
      themebox.put('apptheme', true);
      print(themebox.get('apptheme'));
    }
  }
}