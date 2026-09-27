import 'package:cardabase/theme/theme.dart';
import 'package:cardabase/util/vibration_provider.dart';
import 'package:cardabase/util/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

Future<bool> showPasswordVerificationDialog(BuildContext context) async {
  final theme = Theme.of(context);
  final TextEditingController controller = TextEditingController();
  final TextEditingController usernameController =
      TextEditingController(text: 'Cardabase App');
  final passwordbox = Hive.box('password');

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
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
            TextFormField(
              controller: controller,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.password),
                labelText: 'Password',
              ),
              style: theme.inputTextStyle,
            ),
            const SizedBox(height: 20),
            Center(
              child: OutlinedButton(
                onPressed: () {
                  if (controller.text == passwordbox.get('PW')) {
                    FocusScope.of(dialogContext).unfocus();
                    TextInput.finishAutofillContext(shouldSave: true);
                    // ignore: use_build_context_synchronously
                    Navigator.of(dialogContext).pop(true);
                  } else {
                    GetIt.I<VibrationProvider>().vibrateError();
                    // ignore: use_build_context_synchronously
                    showCustomSnackBar(
                      dialogContext,
                      'Incorrect password!',
                      false,
                    );
                  }
                },
                child: const Text('VERIFY'),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  return result ?? false;
}
