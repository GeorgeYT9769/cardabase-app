import 'package:cardabase/pages/home/form_fields/password_form_field.dart';
import 'package:cardabase/util/vibration_provider.dart';
import 'package:cardabase/util/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometric();
    });
  }

  Future<void> _checkBiometric() async {
    final useBiometric = passwordBox.get('use_biometric', defaultValue: false);
    if (useBiometric) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      final canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (canAuthenticate) {
        try {
          final didAuthenticate = await auth.authenticate(
            localizedReason: 'Please authenticate to proceed',
            options: const AuthenticationOptions(
              stickyAuth: true,
              biometricOnly: true,
            ),
          );
          if (didAuthenticate && mounted) {
            Navigator.pop(context, true);
          }
        } catch (e) {
          // Fallback to password
        }
      }
    }
  }

  Future<void> onChallengeButtonPressed() async {
    // TODO(wim): use proper password validation
    final expectedPassword = passwordBox.get('PW');
    if (password.text != expectedPassword) {
      GetIt.I<VibrationProvider>().vibrateError();
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar('Incorrect password!', false),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) {
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        'Enter Password',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.inverseSurface,
          fontSize: 30,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PasswordFormField(
            controller: password,
            suffixIcon: passwordBox.get('use_biometric', defaultValue: false)
                ? IconButton(
                    onPressed: _checkBiometric,
                    icon: Icon(
                      Icons.fingerprint,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 20),
          Center(
            child: _challengeButton(theme),
          ),
        ],
      ),
    );
  }

  Widget _challengeButton(ThemeData theme) {
    return OutlinedButton(
      onPressed: onChallengeButtonPressed,
      style: OutlinedButton.styleFrom(
        elevation: 0.0,
        side: BorderSide(
          color: theme.colorScheme.primary,
          width: 2.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
        ),
      ),
      child: widget.challengeButtonChild,
    );
  }
}
