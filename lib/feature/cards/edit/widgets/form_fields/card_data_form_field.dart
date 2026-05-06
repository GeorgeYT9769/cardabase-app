import 'package:barcode_widget/barcode_widget.dart';
import 'package:cardabase/feature/cards/edit/verify_code.dart';
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
  final BarcodeType barcodeType;
  final VoidCallback onScanButtonPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      validator: isNotEmpty<String>().and(validBarcode(barcodeType)),
      inputFormatters: barcodeType == BarcodeType.QrCode
          ? null
          : [
              FilteringTextInputFormatter.deny(
                RegExp(r'[ \.,\-]'),
              ),
            ],
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(width: 2.0),
        ),
        focusColor: theme.colorScheme.primary,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        labelText: 'Card ID',
        labelStyle: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.inverseSurface,
          fontWeight: FontWeight.bold,
          fontSize: 17,
        ),
        prefixIcon: Icon(
          Icons.numbers,
          color: theme.colorScheme.secondary,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            Icons.photo_camera_rounded,
            color: theme.colorScheme.secondary,
          ),
          onPressed: onScanButtonPressed,
        ),
      ),
      keyboardType: TextInputType.text,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.tertiary,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
