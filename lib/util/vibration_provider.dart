import 'package:hive/hive.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

class VibrationProvider {

  static final _bbox = Hive.box('settingsBox');

  static bool get vibrate => _bbox.get('setVibration', defaultValue: true);

  static void toggleVibration() {
    _bbox.put('setVibration', !vibrate);
  }

  static void vibrateSelection() async {
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate && _bbox.get('setVibration', defaultValue: true) == true) {
      await Haptics.vibrate(HapticsType.selection);
    }
  }

  static void vibrateError() async {
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate && _bbox.get('setVibration', defaultValue: true) == true) {
      await Haptics.vibrate(HapticsType.error);
    }
  }

  static void vibrateSuccess() async {
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate && _bbox.get('setVibration', defaultValue: true) == true) {
      await Haptics.vibrate(HapticsType.success);
    }
  }

  static void vibrateWarning() async {
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate && _bbox.get('setVibration', defaultValue: true) == true) {
      await Haptics.vibrate(HapticsType.warning);
    }
  }

  static void vibrateHeavy() async {
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate && _bbox.get('setVibration', defaultValue: true) == true) {
      await Haptics.vibrate(HapticsType.heavy);
    }
  }

  static void vibrateMedium() async {
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate && _bbox.get('setVibration', defaultValue: true) == true) {
      await Haptics.vibrate(HapticsType.medium);
    }
  }

  static void vibrateLight() async {
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate && _bbox.get('setVibration', defaultValue: true) == true) {
      await Haptics.vibrate(HapticsType.light);
    }
  }

  static void vibrateRigid() async {
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate && _bbox.get('setVibration', defaultValue: true) == true) {
      await Haptics.vibrate(HapticsType.rigid);
    }
  }

  static void vibrateSoft() async {
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate && _bbox.get('setVibration', defaultValue: true) == true) {
      await Haptics.vibrate(HapticsType.soft);
    }
  }
}
