import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';

class ShareCardDialog extends StatelessWidget {
  const ShareCardDialog({
    super.key,
    required this.data,
  });

  final String data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        'Share',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.inverseSurface,
          fontSize: 30,
        ),
      ),
      content: Container(
        height: 200,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: Colors.white,
        ),
        child: BarcodeWidget(
          padding: const EdgeInsets.all(10),
          data: data,
          barcode: Barcode.qrCode(),
          style: const TextStyle(color: Colors.black),
        ),
      ),
      actions: [
        Center(
          child: OutlinedButton(
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
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'DONE',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: theme.colorScheme.tertiary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
