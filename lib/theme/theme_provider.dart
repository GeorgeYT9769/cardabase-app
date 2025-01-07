import 'package:hive/hive.dart';

class ThemeProvider {
  static final _box = Hive.box('settingsBox');

  static bool get isDarkMode => _box.get('isDarkMode', defaultValue: false);

  static void toggleTheme() {
    _box.put('isDarkMode', !isDarkMode);
  }
}
