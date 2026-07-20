import 'package:cardabase/pages/home/form_fields/password_form_field.dart';
import 'package:cardabase/pages/home/home_page.dart';
import 'package:cardabase/util/vibration_provider.dart';
import 'package:cardabase/util/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:local_auth/local_auth.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _passwordBox = GetIt.I<Box>(instanceName: 'passwordBox');
  final _passwordController = TextEditingController();
  final _auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeAutoUnlock();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  bool get _hasPassword {
    final storedPassword = _passwordBox.get('PW');
    return storedPassword is String && storedPassword.isNotEmpty;
  }

  Future<void> _maybeAutoUnlock() async {
    if (!_hasPassword) {
      if (!mounted) {
        return;
      }
      _goToHome();
      return;
    }

    final useBiometric = _passwordBox.get('use_biometric', defaultValue: false);
    if (!useBiometric) {
      return;
    }

    final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
    final canAuthenticate =
        canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

    if (!canAuthenticate || !mounted) {
      return;
    }

    try {
      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to continue',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (didAuthenticate && mounted) {
        _goToHome();
      }
    } catch (_) {
      // Fallback to password entry.
    }
  }

  void _goToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const Homepage(),
      ),
    );
  }

  Future<void> _unlock() async {
    final expectedPassword = _passwordBox.get('PW');
    if (_passwordController.text != expectedPassword) {
      GetIt.I<VibrationProvider>().vibrateError();
      showCustomSnackBar(context, 'Incorrect password!', false);
      return;
    }

    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) {
      return;
    }
    _goToHome();
  }

  Future<void> _unlockWithBiometric() async {
    final useBiometric = _passwordBox.get('use_biometric', defaultValue: false);
    if (!useBiometric) {
      return;
    }

    final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
    final canAuthenticate =
        canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

    if (!canAuthenticate || !mounted) {
      return;
    }

    try {
      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to continue',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (didAuthenticate && mounted) {
        _goToHome();
      }
    } catch (_) {
      // Keep the password field available as a fallback.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final useBiometric = _passwordBox.get('use_biometric', defaultValue: false);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: theme.colorScheme.secondary,
                ),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          'Locked',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.tertiary,
          ),
        ),
        centerTitle: true,
        elevation: 0.0,
        backgroundColor: theme.colorScheme.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Enter your password to continue',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.inverseSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                PasswordFormField(
                  controller: _passwordController,
                  suffixIcon: useBiometric
                      ? IconButton(
                          onPressed: _unlockWithBiometric,
                          icon: Icon(
                            Icons.fingerprint,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 20),
                Bounceable(
                  onTap: () {},
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: 60,
                    child: OutlinedButton(
                      onPressed: _unlock,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                        backgroundColor: Colors.transparent,
                        elevation: 0.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'UNLOCK',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 18,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                if (!_hasPassword) ...[
                  const SizedBox(height: 16),
                  Text(
                    'No password is set, so the app will continue automatically.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

