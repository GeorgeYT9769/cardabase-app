import 'package:hive_ce/hive.dart';

class ThemeProvider {
  static final _box = Hive.box('settingsBox');

  static bool get isDarkMode =>
      _box.get('isDarkMode', defaultValue: false) as bool;

  static Future<void> toggleTheme() {
    return _box.put('isDarkMode', !isDarkMode);
  }
}
