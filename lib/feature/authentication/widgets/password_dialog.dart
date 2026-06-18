import 'package:cardabase/pages/home/form_fields/password_form_field.dart';
import 'package:cardabase/util/vibration_provider.dart';
import 'package:cardabase/util/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:local_auth/local_auth.dart';

class PasswordDialog extends StatefulWidget {
  const PasswordDialog({super.key});

  @override
  State<PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {
  final _passwordBox = GetIt.I<Box>(instanceName: 'passwordBox');
  final _password = TextEditingController();
  final auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometric();
    });
  }

  Future<void> _checkBiometric() async {
    final useBiometric = _passwordBox.get('use_biometric', defaultValue: false);
    if (useBiometric) {
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

  Future<void> onExportPressed() async {
    if (_password.text != _passwordBox.get('PW')) {
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
            controller: _password,
            suffixIcon: _passwordBox.get('use_biometric', defaultValue: false)
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
            child: _exportButton(theme),
          ),
        ],
      ),
    );
  }

  Widget _exportButton(ThemeData theme) {
    return Bounceable(
      onTap: () {},
      child: OutlinedButton(
        onPressed: onExportPressed,
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
        child: Text(
          'AUTHORIZE',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: theme.colorScheme.inverseSurface,
          ),
        ),
      ),
    );
  }
}
