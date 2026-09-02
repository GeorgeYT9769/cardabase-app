import 'package:cardabase/theme/theme.dart';
import 'package:cardabase/util/vibration_provider.dart';
import 'package:flutter/material.dart';
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

  void setPasswordFunc(ThemeData theme) {
    if (password.text.isNotEmpty && confirmPassword.text.isNotEmpty) {
      if (password.text == confirmPassword.text) {
        passwordbox.put('PW', password.text);
        setState(() {
          password.text = '';
          confirmPassword.text = '';
          hidePassword = true;
          hideConfirmPassword = true;
        });
        Navigator.pop(context);
        showCustomSnackBar(context, 'Success!', true);
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
      setState(() {
        passwordbox.clear();
        password.text = '';
        hidePassword = true;
        resetPassword.text = '';
      });
      Navigator.pop(context);
      showCustomSnackBar(context, 'Success!', true);
    } else {
      GetIt.I<VibrationProvider>().vibrateSuccess();
      showCustomSnackBar(context, 'Incorrect password!', false);
    }
  }

  void showPasswordFunc() {
    if (hidePassword == false) {
      setState(() {
        hidePassword = true;
      });
    } else {
      setState(() {
        hidePassword = false;
      });
    }
  }

  void showConfirmPasswordFunc() {
    if (hideConfirmPassword == false) {
      setState(() {
        hideConfirmPassword = true;
      });
    } else {
      setState(() {
        hideConfirmPassword = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final passNotifier = ValueNotifier<PasswordStrength?>(null);

    return Scaffold(
      backgroundColor:
          theme.colorScheme.surface,
      appBar: CdbAppBar(
        title: 'Password',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: passwordbox.isEmpty == true
          // NO PWD
          ? Container(
              padding: const EdgeInsets.all(20),
              child: ListView(
                children: [
                  Text(
                    'CREATE A PASSWORD',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: theme.colorScheme.inverseSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Give your cards a password. Once you have set it up, you may use that password to safeguard your cards.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      //cardTypeText
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: theme.colorScheme.inverseSurface,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: password,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.password),
                      suffixIcon: IconButton(
                        icon: Icon(
                          hidePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: theme.colorScheme.secondary,
                        ),
                        onPressed: showPasswordFunc,
                      ),
                    ),
                    style: theme.inputTextStyle,
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: hidePassword,
                    onChanged: (value) {
                      passNotifier.value =
                          PasswordStrength.calculate(text: value);
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: confirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Password again',
                      prefixIcon: Icon(Icons.password),
                      suffixIcon: IconButton(
                        icon: Icon(
                          hideConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: theme.colorScheme.secondary,
                        ),
                        onPressed: showConfirmPasswordFunc,
                      ),
                    ),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.inverseSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: hideConfirmPassword,
                  ),
                  const SizedBox(height: 20),
                  PasswordStrengthChecker(
                    strength: passNotifier,
                    configuration: PasswordStrengthCheckerConfiguration(
                      borderColor: theme.colorScheme.tertiary,
                      inactiveBorderColor: theme.colorScheme.tertiary,
                      borderWidth: 1,
                      statusWidgetAlignment: MainAxisAlignment.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Bounceable(
                    onTap: () {},
                    child: SizedBox(
                      height: 70,
                      child: OutlinedButton(
                        style: theme.tileButtonStyle(),
                        onPressed: () => setPasswordFunc(theme),
                        child: const Text('SET'),
                      ),
                    ),
                  ),
                ],
              ),
            )
          //PWD
          : Container(
              padding: const EdgeInsets.all(20),
              child: ListView(
                children: [
                  Text(
                    'RESET PASSWORD',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: theme.colorScheme.inverseSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'If you wish to change your password or stop using it, you may do so here.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: theme.colorScheme.inverseSurface,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: resetPassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: theme.textTheme.bodyLarge
                          ?.copyWith(color: theme.colorScheme.inverseSurface),
                      prefixIcon: Icon(Icons.password),
                      suffixIcon: IconButton(
                        icon: Icon(
                          hidePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: theme.colorScheme.secondary,
                        ),
                        onPressed: showPasswordFunc,
                      ),
                    ),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.inverseSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: hidePassword,
                  ),
                  const SizedBox(height: 20),
                  Bounceable(
                    onTap: () {},
                    child: SizedBox(
                      height: 70,
                      child: OutlinedButton(
                        style: theme.tileButtonStyle(),
                        onPressed: () => resetPasswordFunc(theme),
                        child: const Text('RESET'),
                      ),
                    ),
                  ),
                  SizedBox(height: 10,),
                  const Divider(),
                  ValueListenableBuilder(
                    valueListenable: passwordbox.listenable(keys: ['use_biometric']),
                    builder: (context, box, _) {
                      final useBiometric = box.get('use_biometric', defaultValue: false);
                      return CheckboxListTile(
                        title: Text(
                          'Use biometric authentication',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: theme.colorScheme.inverseSurface,
                          ),
                        ),
                        value: useBiometric,
                        onChanged: (value) {
                          passwordbox.put('use_biometric', value);
                        },
                        activeColor: theme.colorScheme.primary,
                        checkColor: theme.colorScheme.onPrimary,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        side: BorderSide(
                          color: theme.colorScheme.primary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      );
                    },
                  ),
                  //const SizedBox(height: 20),
                  ValueListenableBuilder(
                    valueListenable: passwordbox.listenable(keys: ['lock_app']),
                    builder: (context, box, _) {
                      final lock_app = box.get('lock_app', defaultValue: false);
                      return CheckboxListTile(
                        title: Text(
                          'Lock app',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: theme.colorScheme.inverseSurface,
                          ),
                        ),
                        value: lock_app,
                        onChanged: (value) {
                          passwordbox.put('lock_app', value);
                        },
                        activeColor: theme.colorScheme.primary,
                        checkColor: theme.colorScheme.onPrimary,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        side: BorderSide(
                          color: theme.colorScheme.primary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
