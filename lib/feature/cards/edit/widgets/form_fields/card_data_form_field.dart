import 'package:barcode_widget/barcode_widget.dart';
import 'package:cardabase/feature/cards/edit/verify_code.dart';
import 'package:cardabase/theme/theme.dart';
import 'package:cardabase/util/form_validation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CardDataFormField extends StatelessWidget {
  const CardDataFormField({
    super.key,
    required this.controller,
    required this.barcodeType,
    required this.onScanButtonPressed,
  });

  final TextEditingController controller;
  final BarcodeType? barcodeType;
  final VoidCallback onScanButtonPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      validator: barcodeType == null ? null : isNotEmpty<String>().and(validBarcode(barcodeType)),
      inputFormatters: barcodeType == BarcodeType.QrCode || barcodeType == null
          ? null
          : [
              FilteringTextInputFormatter.deny(
                RegExp(r'[ \.,\-]'),
              ),
            ],
      decoration: InputDecoration(
        labelText: 'Card ID',
        labelStyle: theme.emphasizedInputLabelStyle,
        prefixIcon: const Icon(Icons.numbers),
        suffixIcon: IconButton(
          icon: Icon(
            Icons.photo_camera_rounded,
            color: theme.colorScheme.secondary,
          ),
          onPressed: onScanButtonPressed,
        ),
      ),
      keyboardType: TextInputType.text,
      style: theme.inputTextStyle,
    );
  }
}
