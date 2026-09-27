import 'package:cardabase/theme/theme.dart';
import 'package:cardabase/util/vibration_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:password_strength_checker/password_strength_checker.dart';

import '../util/widgets/cdb_app_bar.dart';
import '../util/widgets/custom_snack_bar.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final passwordbox = Hive.box('password');

  bool hidePassword = true;
  bool hideConfirmPassword = true;

  TextEditingController password = TextEditingController();
  TextEditingController confirmPassword = TextEditingController();
  TextEditingController resetPassword = TextEditingController();
  final usernameController = TextEditingController(text: 'Cardabase App');

  @override
  void dispose() {
    password.dispose();
    confirmPassword.dispose();
    resetPassword.dispose();
    usernameController.dispose();
    super.dispose();
  }

  void setPasswordFunc(ThemeData theme) {
    if (password.text.isNotEmpty && confirmPassword.text.isNotEmpty) {
      if (password.text == confirmPassword.text) {
        passwordbox.put('PW', password.text);

        FocusScope.of(context).unfocus();
        TextInput.finishAutofillContext(shouldSave: true);

        setState(() {
          password.text = '';
          confirmPassword.text = '';
          hidePassword = true;
          hideConfirmPassword = true;
        });

        showCustomSnackBar(context, 'Password created successfully!', true);
      } else {
        GetIt.I<VibrationProvider>().vibrateError();
        showCustomSnackBar(context, 'Passwords do not match!', false);
      }
    } else {
      GetIt.I<VibrationProvider>().vibrateError();
      showCustomSnackBar(context, 'Password cannot be empty!', false);
    }
  }

  void resetPasswordFunc(ThemeData theme) {
    if (resetPassword.text == passwordbox.get('PW')) {
      passwordbox.clear();

      FocusScope.of(context).unfocus();
      TextInput.finishAutofillContext(shouldSave: true);

      setState(() {
        password.text = '';
        hidePassword = true;
        resetPassword.text = '';
      });

      showCustomSnackBar(context, 'Password reset successfully!', true);
    } else {
      GetIt.I<VibrationProvider>().vibrateError();
      showCustomSnackBar(context, 'Incorrect password!', false);
    }
  }

  void showPasswordFunc() {
    setState(() {
      hidePassword = !hidePassword;
    });
  }

  void showConfirmPasswordFunc() {
    setState(() {
      hideConfirmPassword = !hideConfirmPassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final passNotifier = ValueNotifier<PasswordStrength?>(null);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: theme.colorScheme.surface,
      appBar: CdbAppBar(
        title: 'Password',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: ValueListenableBuilder(
        valueListenable: passwordbox.listenable(),
        builder: (context, box, _) {
          final hasPassword = box.containsKey('PW') &&
              box.get('PW') is String &&
              (box.get('PW') as String).isNotEmpty;

          final topPadding =
              MediaQuery.of(context).padding.top + kToolbarHeight + 10;

          return AutofillGroup(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, topPadding, 20, 30),
              child: !hasPassword
                  ? _buildCreatePasswordContent(theme, passNotifier)
                  : _buildManagePasswordContent(theme),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCreatePasswordContent(
    ThemeData theme,
    ValueNotifier<PasswordStrength?> passNotifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Offstage(
          child: TextField(
            controller: usernameController,
            autofillHints: const [AutofillHints.username],
          ),
        ),
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_reset,
              size: 56,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Set Up App Password',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Give your cards a password. Once set up, you may use it to safeguard your cards.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: password,
          autofillHints: const [AutofillHints.newPassword],
          decoration: InputDecoration(
            labelText: 'New Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                hidePassword ? Icons.visibility_off : Icons.visibility,
                color: theme.colorScheme.secondary,
              ),
              onPressed: showPasswordFunc,
            ),
          ),
          style: theme.inputTextStyle,
          keyboardType: TextInputType.visiblePassword,
          obscureText: hidePassword,
          onChanged: (value) {
            passNotifier.value = PasswordStrength.calculate(text: value);
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: confirmPassword,
          autofillHints: const [AutofillHints.newPassword],
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            prefixIcon: const Icon(Icons.check_circle_outline),
            suffixIcon: IconButton(
              icon: Icon(
                hideConfirmPassword ? Icons.visibility_off : Icons.visibility,
                color: theme.colorScheme.secondary,
              ),
              onPressed: showConfirmPasswordFunc,
            ),
          ),
          style: theme.inputTextStyle,
          keyboardType: TextInputType.visiblePassword,
          obscureText: hideConfirmPassword,
        ),
        const SizedBox(height: 16),
        PasswordStrengthChecker(
          strength: passNotifier,
          configuration: PasswordStrengthCheckerConfiguration(
            borderColor: theme.colorScheme.tertiary,
            inactiveBorderColor: theme.colorScheme.tertiary,
            borderWidth: 1,
            statusWidgetAlignment: MainAxisAlignment.center,
          ),
        ),
        const SizedBox(height: 24),
        Bounceable(
          onTap: () {},
          child: SizedBox(
            height: 56,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: theme.colorScheme.primary, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => setPasswordFunc(theme),
              child: Text(
                'SET PASSWORD',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManagePasswordContent(ThemeData theme) {
    final useBiometric = passwordbox.get('use_biometric', defaultValue: false);
    final lockApp = passwordbox.get('lock_app', defaultValue: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Offstage(
          child: TextField(
            controller: usernameController,
            autofillHints: const [AutofillHints.username],
          ),
        ),
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              size: 56,
              color: Colors.green,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Password Protection Active',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Your cards are secured. You can configure security options or reset your password below.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                CheckboxListTile(
                  title: Text(
                    'Use biometric authentication',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text('Unlock using fingerprint or face'),
                  value: useBiometric,
                  onChanged: (value) {
                    passwordbox.put('use_biometric', value);
                  },
                  activeColor: theme.colorScheme.primary,
                  checkColor: theme.colorScheme.onPrimary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                const Divider(height: 1),
                CheckboxListTile(
                  title: Text(
                    'Lock app on startup',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text('Require password when launching app'),
                  value: lockApp,
                  onChanged: (value) {
                    passwordbox.put('lock_app', value);
                  },
                  activeColor: theme.colorScheme.primary,
                  checkColor: theme.colorScheme.onPrimary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'RESET PASSWORD',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: resetPassword,
          autofillHints: const [AutofillHints.password],
          decoration: InputDecoration(
            labelText: 'Current Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                hidePassword ? Icons.visibility_off : Icons.visibility,
                color: theme.colorScheme.secondary,
              ),
              onPressed: showPasswordFunc,
            ),
          ),
          style: theme.inputTextStyle,
          keyboardType: TextInputType.visiblePassword,
          obscureText: hidePassword,
        ),
        const SizedBox(height: 16),
        Bounceable(
          onTap: () {},
          child: SizedBox(
            height: 56,
            child: OutlinedButton(
              style: theme.destructiveButtonStyle,
              onPressed: () => resetPasswordFunc(theme),
              child: const Text('RESET PASSWORD'),
            ),
          ),
        ),
      ],
    );
  }
}
