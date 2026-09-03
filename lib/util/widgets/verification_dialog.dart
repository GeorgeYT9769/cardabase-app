import 'package:cardabase/theme/theme.dart';
import 'package:cardabase/util/vibration_provider.dart';
import 'package:cardabase/util/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

Future<bool> showPasswordVerificationDialog(BuildContext context) async {
  final theme = Theme.of(context);
  final TextEditingController controller = TextEditingController();
  final passwordbox = Hive.box('password');

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Enter Password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: controller,
            obscureText: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.password),
              labelText: 'Password',
            ),
            style: theme.inputTextStyle,
          ),
          const SizedBox(height: 20),
          Center(
            child: OutlinedButton(
              onPressed: () {
                if (controller.text == passwordbox.get('PW')) {
                  FocusScope.of(context).unfocus();

                  Future.delayed(const Duration(milliseconds: 100), () {
                    Navigator.pop(context, true);
                  });
                } else {
                  GetIt.I<VibrationProvider>().vibrateError();
                  showCustomSnackBar(context, 'Incorrect password!', false);
                }
              },
              child: const Text('VERIFY'),
            ),
          ),
        ],
      ),
    ),
  );

  return result ?? false;
}
