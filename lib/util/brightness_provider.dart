import 'package:hive/hive.dart';

class BrightnessProvider {
  static final _bbox = Hive.box('settingsBox');

  static bool get brightness => _bbox.get('setBrightness', defaultValue: true);

  static void toggleBrightness() {
    _bbox.put('setBrightness', !brightness);
  }
}
