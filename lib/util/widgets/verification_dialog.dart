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
          TextFormField(
            controller: controller,
            obscureText: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(width: 2.0),
              ),
              focusColor: theme.colorScheme.primary,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              labelStyle: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.secondary,
              ),
              prefixIcon: Icon(
                Icons.password,
                color: theme.colorScheme.secondary,
              ),
              labelText: 'Password',
            ),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.tertiary,
              fontWeight: FontWeight.bold,
            ),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    buildCustomSnackBar('Incorrect password!', false),
                  );
                }
              },
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
                'VERIFY',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  return result ?? false;
}
