import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:hive_ce/hive.dart';

class VibrationProvider {
  static final _bbox = Hive.box('settingsBox');

  static bool get vibrate =>
      _bbox.get('setVibration', defaultValue: true) as bool;

  static Future<void> toggleVibration() {
    return _bbox.put('setVibration', !vibrate);
  }

  static Future<void> vibrateSelection() async {
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate && _bbox.get('setVibration', defaultValue: true) == true) {
      await Haptics.vibrate(HapticsType.selection);
    }
  }

  static Future<void> vibrateError() async {
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate && _bbox.get('setVibration', defaultValue: true) == true) {
      await Haptics.vibrate(HapticsType.error);
    }
  }

  static Future<void> vibrateSuccess() async {
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate && _bbox.get('setVibration', defaultValue: true) == true) {
      await Haptics.vibrate(HapticsType.success);
    }
  }

  static Future<void> vibrateWarning() async {
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate && _bbox.get('setVibration', defaultValue: true) == true) {
      await Haptics.vibrate(HapticsType.warning);
    }
  }

  static Future<void> vibrateHeavy() async {
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate && _bbox.get('setVibration', defaultValue: true) == true) {
      await Haptics.vibrate(HapticsType.heavy);
    }
  }

  static Future<void> vibrateMedium() async {
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate && _bbox.get('setVibration', defaultValue: true) == true) {
      await Haptics.vibrate(HapticsType.medium);
    }
  }

  static Future<void> vibrateLight() async {
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate && _bbox.get('setVibration', defaultValue: true) == true) {
      await Haptics.vibrate(HapticsType.light);
    }
  }

  static Future<void> vibrateRigid() async {
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate && _bbox.get('setVibration', defaultValue: true) == true) {
      await Haptics.vibrate(HapticsType.rigid);
    }
  }

  static Future<void> vibrateSoft() async {
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate && _bbox.get('setVibration', defaultValue: true) == true) {
      await Haptics.vibrate(HapticsType.soft);
    }
  }
}
