import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';

class ShareCardDialog extends StatelessWidget {
  const ShareCardDialog({
    super.key,
    required this.data,
  });

  final String data;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Share'),
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
          child: Bounceable(
            onTap: () {},
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('DONE'),
            ),
          ),
        ),
      ],
    );
  }
}
