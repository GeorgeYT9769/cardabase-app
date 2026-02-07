import 'package:hive_ce/hive.dart';

class BrightnessProvider {
  static final _bbox = Hive.box('settingsBox');

  static bool get brightness => _bbox.get('setBrightness', defaultValue: true);

  static void toggleBrightness() {
    _bbox.put('setBrightness', !brightness);
  }
}
