import 'dart:math' show pi;

import 'package:barcode_widget/barcode_widget.dart'; // Import the barcode library
import 'package:flutter/material.dart';

class FullScreenCardFacePage extends StatelessWidget {
  const FullScreenCardFacePage({
    super.key,
    required this.child,
  });

  factory FullScreenCardFacePage.barcode({
    required String cardData,
    required BarcodeType barcodeType,
  }) {
    return FullScreenCardFacePage(
      child: _buildBarcodeWidget(cardData, barcodeType),
    );
  }

  factory FullScreenCardFacePage.image({
    required ImageProvider image,
  }) {
    return FullScreenCardFacePage(
      child: SizedBox.expand(
        child: Transform.rotate(
          angle: pi / 2,
          child: Image(
            image: image,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background for better visibility
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black), // Black back icon
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Center(
        child: child,
      ),
    );
  }

  static Widget _buildBarcodeWidget(String data, BarcodeType type) {
    double? width;
    double? height;

    switch (type) {
      // 2D barcodes
      case BarcodeType.QrCode || BarcodeType.DataMatrix || BarcodeType.Aztec:
        width = 300; // Slightly larger for better full-screen display
        height = 300;
      default:
        // Assume other types are 1D barcodes
        width = 400; // Wider for 1D barcodes to fill more space
        height = 200;
    }

    return Transform.rotate(
      angle: pi / 2,
      child: SizedBox(
        // Wrap in SizedBox to give explicit size to the barcode
        width: width,
        height: height,
        child: BarcodeWidget(
          barcode: Barcode.fromType(type),
          // Use the determined barcode object
          data: data,
          backgroundColor: Colors.white,
          // Background color
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
          ),
          // Style for human-readable text
          errorBuilder: (context, error) => Center(
            child: Text(
              'Error rendering barcode: $error\nData: $data',
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
