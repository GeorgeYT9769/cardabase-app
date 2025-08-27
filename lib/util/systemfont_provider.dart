import 'package:hive/hive.dart';

class SystemFontProvider {
  static const String systemFontKey = 'useSystemFont';

  static bool get useSystemFont {
    final box = Hive.box('settingsBox');
    return box.get(systemFontKey, defaultValue: false);
  }

  static void toggleSystemFont() {
    final box = Hive.box('settingsBox');
    bool current = box.get(systemFontKey, defaultValue: false);
    box.put(systemFontKey, !current);
  }
}