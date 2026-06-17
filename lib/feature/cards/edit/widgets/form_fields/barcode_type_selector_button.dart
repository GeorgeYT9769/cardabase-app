import 'package:barcode_widget/barcode_widget.dart';
import 'package:cardabase/util/barcode_type_extensions.dart';
import 'package:flutter/cupertino.dart';
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
    final isSquareCode = barcodeType == BarcodeType.QrCode ||
        barcodeType == BarcodeType.DataMatrix ||
        barcodeType == BarcodeType.Aztec;

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
              Icon(
                isSquareCode ? Icons.qr_code_2 : CupertinoIcons.barcode,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 15),
              Text(
                'Card Type',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.inverseSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const Spacer(),
              Text(
                barcodeType.getLabel(),
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
