import 'package:cardabase/pages/home/form_fields/password_form_field.dart';
import 'package:cardabase/util/vibration_provider.dart';
import 'package:cardabase/util/widgets/custom_snack_bar.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:local_auth/local_auth.dart';

class PasswordChallengeDialog extends StatefulWidget {
  const PasswordChallengeDialog({
    super.key,
    required this.challengeButtonChild,
  });

  final Widget challengeButtonChild;

  @override
  State<PasswordChallengeDialog> createState() =>
      _PasswordChallengeDialogState();
}

class _PasswordChallengeDialogState extends State<PasswordChallengeDialog> {
  final passwordBox = Hive.box('password');
  final auth = LocalAuthentication();

  final password = TextEditingController();
  final usernameController = TextEditingController(text: 'Cardabase App');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometric();
    });
  }

  Future<bool> _authenticateWithBiometrics() async {
    final canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
    final isDeviceSupported = await auth.isDeviceSupported();

    if (!canAuthenticateWithBiometrics && !isDeviceSupported) {
      return false;
    }

    try {
      final didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to proceed',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );
      if (didAuthenticate) return true;
    } catch (_) {
      try {
        final didAuthenticate = await auth.authenticate(
          localizedReason: 'Please authenticate to proceed',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
            useErrorDialogs: true,
          ),
        );
        if (didAuthenticate) return true;
      } catch (_) {}
    }
    return false;
  }

  Future<void> _checkBiometric() async {
    final useBiometric = passwordBox.get('use_biometric', defaultValue: false);
    if (useBiometric) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      final didAuth = await _authenticateWithBiometrics();
      if (didAuth && mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> onChallengeButtonPressed() async {
    final expectedPassword = passwordBox.get('PW');
    if (password.text != expectedPassword) {
      GetIt.I<VibrationProvider>().vibrateError();
      showCustomSnackBar(context, 'Incorrect password!', false);
      return;
    }

    FocusScope.of(context).unfocus();
    TextInput.finishAutofillContext(shouldSave: true);
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) {
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    password.dispose();
    usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter Password'),
      content: AutofillGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Offstage(
              child: TextField(
                controller: usernameController,
                autofillHints: const [AutofillHints.username],
              ),
            ),
            PasswordFormField(
              controller: password,
              suffixIcon: passwordBox.get('use_biometric', defaultValue: false)
                  ? IconButton(
                      onPressed: _checkBiometric,
                      icon: Icon(
                        Icons.fingerprint,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 20),
            Center(
              child: _challengeButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _challengeButton() {
    return OutlinedButton(
      onPressed: onChallengeButtonPressed,
      child: widget.challengeButtonChild,
    );
  }
}
