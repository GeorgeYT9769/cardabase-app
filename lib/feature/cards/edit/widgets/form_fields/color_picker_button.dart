import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';

class ColorPickerButton extends StatelessWidget {
  const ColorPickerButton({
    super.key,
    required this.onPressed,
    required this.color,
  });

  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hexCode = '#${color.toARGB32().toRadixString(16).toUpperCase().padLeft(8, '0').substring(2)}';
    return Bounceable(
      onTap: () {},
      child: SizedBox(
        height: 60,
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
          onPressed: onPressed,
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Text(
                'Card Color',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.inverseSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const Spacer(),
              Text(
                hexCode,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.tertiary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 5),
              Icon(
                Icons.arrow_drop_down,
                color: theme.colorScheme.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
