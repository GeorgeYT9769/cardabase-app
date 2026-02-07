import 'package:cardabase/util/vibration_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:password_strength_checker/password_strength_checker.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Row(
              children: [
                const Icon(
                  Icons.check,
                  size: 15,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Text(
                  'Success!',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            duration: const Duration(milliseconds: 3000),
            padding: const EdgeInsets.all(5.0),
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
            behavior: SnackBarBehavior.floating,
            dismissDirection: DismissDirection.vertical,
            backgroundColor: const Color.fromARGB(255, 92, 184, 92),
          ),
        );
      } else {
        VibrationProvider.vibrateSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Row(
              children: [
                const Icon(
                  Icons.error,
                  size: 15,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Text(
                  'Passwords does not match!',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            duration: const Duration(milliseconds: 3000),
            padding: const EdgeInsets.all(5.0),
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
            behavior: SnackBarBehavior.floating,
            dismissDirection: DismissDirection.vertical,
            backgroundColor: const Color.fromARGB(255, 237, 67, 55),
          ),
        );
      }
    } else {
      VibrationProvider.vibrateSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: [
              const Icon(
                Icons.error,
                size: 15,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Text(
                'Password cannot be empty!',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 3000),
          padding: const EdgeInsets.all(5.0),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
          behavior: SnackBarBehavior.floating,
          dismissDirection: DismissDirection.vertical,
          backgroundColor: const Color.fromARGB(255, 237, 67, 55),
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: [
              const Icon(
                Icons.check,
                size: 15,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Text(
                'Success!',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 3000),
          padding: const EdgeInsets.all(5.0),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
          behavior: SnackBarBehavior.floating,
          dismissDirection: DismissDirection.vertical,
          backgroundColor: const Color.fromARGB(255, 92, 184, 92),
        ),
      );
    } else {
      VibrationProvider.vibrateSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: [
              const Icon(
                Icons.error,
                size: 15,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Text(
                'Incorrect password!',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 3000),
          padding: const EdgeInsets.all(5.0),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
          behavior: SnackBarBehavior.floating,
          dismissDirection: DismissDirection.vertical,
          backgroundColor: const Color.fromARGB(255, 237, 67, 55),
        ),
      );
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
          theme.colorScheme.surface, // - BACKGROUND COLOR (DEFAULT)
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: theme.colorScheme.secondary,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
        title: Text(
          'Password',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            fontFamily: 'xirod',
            letterSpacing: 5,
            color: theme.colorScheme.tertiary,
          ),
        ),
        centerTitle: true,
        elevation: 0.0,
        backgroundColor: theme.colorScheme.surface,
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(width: 2.0),
                      ),
                      focusColor: theme.colorScheme.primary,
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: theme.colorScheme.primary),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelText: 'Password',
                      labelStyle: theme.textTheme.bodyLarge
                          ?.copyWith(color: theme.colorScheme.secondary),
                      prefixIcon: Icon(
                        Icons.password,
                        color: theme.colorScheme.secondary,
                      ),
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
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.bold,
                    ),
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(width: 2.0),
                      ),
                      focusColor: theme.colorScheme.primary,
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: theme.colorScheme.primary),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelText: 'Password again',
                      labelStyle: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                      prefixIcon: Icon(
                        Icons.password,
                        color: theme.colorScheme.secondary,
                      ),
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
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(15),
                          side: BorderSide(
                            color: theme.colorScheme.primary,
                          ),
                          backgroundColor: Colors.transparent,
                          elevation: 0.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: const Size.fromHeight(100),
                        ),
                        onPressed: () => setPasswordFunc(theme),
                        child: Text(
                          'SET',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.inverseSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(width: 2.0),
                      ),
                      focusColor: theme.colorScheme.primary,
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: theme.colorScheme.primary),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelText: 'Password',
                      labelStyle: theme.textTheme.bodyLarge
                          ?.copyWith(color: theme.colorScheme.inverseSurface),
                      prefixIcon: Icon(
                        Icons.password,
                        color: theme.colorScheme.secondary,
                      ),
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
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(15),
                          side: BorderSide(
                            color: theme.colorScheme.primary,
                          ),
                          backgroundColor: Colors.transparent,
                          elevation: 0.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: const Size.fromHeight(100),
                        ),
                        onPressed: () => resetPasswordFunc(theme),
                        child: Text(
                          'RESET',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.inverseSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
