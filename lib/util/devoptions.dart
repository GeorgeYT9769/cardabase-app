import 'package:hive/hive.dart';

class DeveloperOptionsProvider {
  static final _bbox = Hive.box('settingsBox');

  static bool get developerOptions => _bbox.get('developerOptions', defaultValue: false);

  static void toggleDeveloperOptions() {
    _bbox.put('developerOptions', !developerOptions);
  }
}
