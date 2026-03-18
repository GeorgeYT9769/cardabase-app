import 'package:cardabase/feature/authentication/widgets/password_dialog.dart';
import 'package:cardabase/util/vibration_provider.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';

/// [requirePassword] shows a dialog which prompts the user to enter their
/// password. If the password is correct [true] is returned, else [false].
Future<bool> requirePassword(BuildContext context) async {
  final passwordBox = GetIt.I<Box>(instanceName: 'passwordBox');
  final dynamic storedPassword = passwordBox.get('PW');
  final bool hasPassword =
      storedPassword is String && storedPassword.isNotEmpty;
  if (!hasPassword) {
    // if no password is stored, don't ask to verify it.
    GetIt.I<VibrationProvider>().vibrateSuccess();
    return true;
  }

  return await showDialog<bool>(
        context: context,
        builder: (context) => const PasswordDialog(),
      ) ==
      true;
}
