import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:get_it/get_it.dart';
import '../../../../util/vibration_provider.dart';
import '../../../../util/widgets/custom_snack_bar.dart';

class IODialogButton extends StatelessWidget {
  const IODialogButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.aboutText,
  });

  final VoidCallback onPressed;
  final Widget icon;
  final String label;
  final String aboutText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Bounceable(
      onTap: () {},
      child: GestureDetector(
        onLongPress: () {
          GetIt.I<VibrationProvider>().vibrateSelection();
          showCustomSnackBar(context, aboutText, true);
        },
        child: OutlinedButton(
          onPressed: onPressed,
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 10),
              Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
