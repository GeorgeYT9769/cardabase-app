import 'package:cardabase/pages/edit_card/error_snack_bar.dart';
import 'package:cardabase/pages/home/form_fields/password_form_field.dart';
import 'package:cardabase/util/vibration_provider.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

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

  final password = TextEditingController();

  Future<void> onChallengeButtonPressed() async {
    // TODO(wim): use proper password validation
    final expectedPassword = passwordBox.get('PW');
    if (password.text != expectedPassword) {
      VibrationProvider.vibrateSuccess();
      showErrorSnackBar(context, 'Incorrect password!');
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
          PasswordFormField(controller: password),
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
