import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';

class SaveButton extends StatelessWidget {
  const SaveButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Bounceable(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: SizedBox(
          height: 60,
          width: double.infinity,
          child: FloatingActionButton.extended(
            elevation: 0.0,
            heroTag: 'saveFAB',
            onPressed: onPressed,
            tooltip: 'SAVE',
            backgroundColor: Colors.green.shade700,
            icon: const Icon(
              Icons.check,
              color: Colors.white,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            label: Text(
              'SAVE',
              style: theme.textTheme.bodyLarge?.copyWith(
                //cardTypeText
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
