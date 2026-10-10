import 'package:cardabase/pages/home/form_fields/password_form_field.dart';
import 'package:cardabase/pages/home/home_page.dart';
import 'package:cardabase/util/vibration_provider.dart';
import 'package:cardabase/util/widgets/cdb_app_bar.dart';
import 'package:cardabase/util/widgets/custom_snack_bar.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
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
  final _usernameController = TextEditingController(text: 'Cardabase App');
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
    _usernameController.dispose();
    super.dispose();
  }

  bool get _hasPassword {
    final storedPassword = _passwordBox.get('PW');
    return storedPassword is String && storedPassword.isNotEmpty;
  }

  Future<bool> _authenticateWithBiometrics() async {
    final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
    final isDeviceSupported = await _auth.isDeviceSupported();

    if (!canAuthenticateWithBiometrics && !isDeviceSupported) {
      debugPrint('LockScreen: biometrics not supported or available');
      return false;
    }

    try {
      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to continue',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );
      if (didAuthenticate) {
        return true;
      }
    } catch (e) {
      debugPrint('LockScreen: primary biometric error: $e');
      try {
        final didAuthenticate = await _auth.authenticate(
          localizedReason: 'Please authenticate to continue',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
            useErrorDialogs: true,
          ),
        );
        if (didAuthenticate) {
          return true;
        }
      } catch (e2) {
        debugPrint('LockScreen: secondary biometric error: $e2');
      }
    }
    return false;
  }

  Future<void> _maybeAutoUnlock() async {
    if (!_hasPassword) {
      if (!mounted) {
        return;
      }
      _goToHome();
      return;
    }

    final useBiometric =
        _passwordBox.get('use_biometric', defaultValue: false);
    if (!useBiometric) {
      return;
    }

    final didAuth = await _authenticateWithBiometrics();
    if (didAuth && mounted) {
      _goToHome();
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
    TextInput.finishAutofillContext(shouldSave: true);
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) {
      return;
    }
    _goToHome();
  }

  Future<void> _unlockWithBiometric() async {
    final useBiometric =
        _passwordBox.get('use_biometric', defaultValue: false);
    if (!useBiometric) {
      showCustomSnackBar(
        context,
        'Biometric authentication is not enabled',
        false,
      );
      return;
    }

    final didAuth = await _authenticateWithBiometrics();
    if (didAuth && mounted) {
      _goToHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final useBiometric =
        _passwordBox.get('use_biometric', defaultValue: false);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: theme.colorScheme.surface,
      appBar: CdbAppBar(
        onBackPressed: Navigator.of(context).canPop()
            ? () => Navigator.of(context).pop()
            : null,
        title: 'Locked',
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: AutofillGroup(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Offstage(
                    child: TextField(
                      controller: _usernameController,
                      autofillHints: const [AutofillHints.username],
                    ),
                  ),
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
      ),
    );
  }
}
