import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';

class ButtonTile extends StatelessWidget {
  final String buttonText;
  final void Function() buttonAction;

  const ButtonTile({
    super.key,
    required this.buttonText,
    required this.buttonAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Bounceable(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.all(15),
            side: BorderSide(color: theme.colorScheme.primary, width: 2),
            backgroundColor: Colors.transparent,
            elevation: 0.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            minimumSize: const Size.fromHeight(65),
          ),
          onPressed: buttonAction,
          child: Text(
            buttonText,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.tertiary,
              fontSize: 20,
            ),
          ),
        ),
      ),
    );
  }
}
