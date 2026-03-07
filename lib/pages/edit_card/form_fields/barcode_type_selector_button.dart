import 'package:barcode_widget/barcode_widget.dart';
import 'package:cardabase/util/barcode_type_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';

class BarcodeTypeSelectorButton extends StatelessWidget {
  const BarcodeTypeSelectorButton({
    super.key,
    required this.barcodeType,
    required this.onPressed,
  });

  final BarcodeType barcodeType;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          child: Text(
            barcodeType.getLabel(),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.inverseSurface,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
        ),
      ),
    );
  }
}
