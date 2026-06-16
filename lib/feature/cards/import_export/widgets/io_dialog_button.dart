import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:get_it/get_it.dart';

import '../../../../util/vibration_provider.dart';

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side:
                BorderSide(color: theme.colorScheme.tertiary, width: 2.0),
              ),
              content: Row(
                children: [
                  const SizedBox(width: 5),
                  Icon(
                    Icons.info,
                    size: 15,
                    color: theme.colorScheme.surface,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      aboutText,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 18,
                        color: theme.colorScheme.surface,
                        fontWeight: FontWeight.bold,
                      ),
                      softWrap: true,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 3000),
              padding: const EdgeInsets.all(5.0),
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              behavior: SnackBarBehavior.floating,
              dismissDirection: DismissDirection.vertical,
              backgroundColor: theme.colorScheme.tertiary,
              elevation: 0.0,
            ),
          );
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
