import 'package:cardabase/feature/settings/get_it.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

class VibrationProvider {
  const VibrationProvider({
    required this.settingsBox,
  });

  final SettingsBox settingsBox;

  Future<void> vibrateSelection() async {
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate && settingsBox.value.vibrateOnDifferentActions) {
      await Haptics.vibrate(HapticsType.selection);
    }
  }

  Future<void> vibrateError() async {
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate && settingsBox.value.vibrateOnDifferentActions) {
      await Haptics.vibrate(HapticsType.error);
    }
  }

  Future<void> vibrateSuccess() async {
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate && settingsBox.value.vibrateOnDifferentActions) {
      await Haptics.vibrate(HapticsType.success);
    }
  }

  Future<void> vibrateWarning() async {
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate && settingsBox.value.vibrateOnDifferentActions) {
      await Haptics.vibrate(HapticsType.warning);
    }
  }

  Future<void> vibrateHeavy() async {
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate && settingsBox.value.vibrateOnDifferentActions) {
      await Haptics.vibrate(HapticsType.heavy);
    }
  }

  Future<void> vibrateMedium() async {
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate && settingsBox.value.vibrateOnDifferentActions) {
      await Haptics.vibrate(HapticsType.medium);
    }
  }

  Future<void> vibrateLight() async {
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate && settingsBox.value.vibrateOnDifferentActions) {
      await Haptics.vibrate(HapticsType.light);
    }
  }

  Future<void> vibrateRigid() async {
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate && settingsBox.value.vibrateOnDifferentActions) {
      await Haptics.vibrate(HapticsType.rigid);
    }
  }

  Future<void> vibrateSoft() async {
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate && settingsBox.value.vibrateOnDifferentActions) {
      await Haptics.vibrate(HapticsType.soft);
    }
  }
}
