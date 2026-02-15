import 'package:hive_ce/hive.dart';

class DeveloperOptionsProvider {
  static final _bbox = Hive.box('settingsBox');

  static bool get developerOptions =>
      _bbox.get('developerOptions', defaultValue: false) as bool;

  static Future<void> toggleDeveloperOptions() {
    return _bbox.put('developerOptions', !developerOptions);
  }
}
