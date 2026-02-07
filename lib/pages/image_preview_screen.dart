import 'dart:io';
import 'dart:math' show pi;

import 'package:barcode_widget/barcode_widget.dart'; // Import the barcode library
import 'package:flutter/material.dart';

class ImagePreviewScreen extends StatelessWidget {
  final String? imagePath;
  final String? barcodeData;
  final String? barcodeType; // e.g., 'CardType.ean13' as a string

  const ImagePreviewScreen({
    super.key,
    this.imagePath,
    this.barcodeData,
    this.barcodeType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Dark background for better visibility
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black), // White back icon
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
      body: Center(
        child: imagePath != null && imagePath!.isNotEmpty
            ? SizedBox.expand(
                child: Transform.rotate(
                  angle: pi / 2,
                  child: Image.file(
                    File(imagePath!),
                    fit: BoxFit.contain,
                  ),
                ),
              ) // Display image if path is provided
            : barcodeData != null &&
                    barcodeData!.isNotEmpty &&
                    barcodeType != null
                ? _buildBarcodeWidget(barcodeData!,
                    barcodeType!) // Display barcode if data and type are provided
                : const Text(
                    'No preview available',
                    style: TextStyle(color: Colors.black, fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
      ),
    );
  }

  // Helper method to build the barcode widget based on type
  Widget _buildBarcodeWidget(String data, String type) {
    Barcode? barcode;
    double? width;
    double? height;

    // Map the string representation of CardType to Barcode library types
    switch (type) {
      case 'CardType.code39':
        barcode = Barcode.code39();
        break;
      case 'CardType.code93':
        barcode = Barcode.code93();
        break;
      case 'CardType.code128':
        barcode = Barcode.code128();
        break;
      case 'CardType.ean13':
        barcode = Barcode.ean13();
        break;
      case 'CardType.ean8':
        barcode = Barcode.ean8();
        break;
      case 'CardType.ean5':
        barcode = Barcode.ean5();
        break;
      case 'CardType.ean2':
        barcode = Barcode.ean2();
        break;
      case 'CardType.itf':
        barcode = Barcode.itf();
        break;
      case 'CardType.itf14':
        barcode = Barcode.itf14();
        break;
      case 'CardType.itf16':
        barcode = Barcode.itf();
        break; // ITF-16 is often treated as generic ITF
      case 'CardType.upca':
        barcode = Barcode.upcA();
        break;
      case 'CardType.upce':
        barcode = Barcode.upcE();
        break;
      case 'CardType.codabar':
        barcode = Barcode.codabar();
        break;
      case 'CardType.qrcode':
        barcode = Barcode.qrCode();
        break;
      case 'CardType.datamatrix':
        barcode = Barcode.dataMatrix();
        break;
      case 'CardType.aztec':
        barcode = Barcode.aztec();
        break;
      default:
        // Fallback for unsupported or unknown barcode types
        return Text(
          data,
          style: const TextStyle(color: Colors.black, fontSize: 40),
          textAlign: TextAlign.center,
        );
    }

    // Set default dimensions for 1D and 2D barcodes
    if (type == 'CardType.qrcode' ||
        type == 'CardType.datamatrix' ||
        type == 'CardType.aztec') {
      // 2D barcodes
      width = 300; // Slightly larger for better full-screen display
      height = 300;
    } else {
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
          barcode: barcode, // Use the determined barcode object
          data: data,
          color: Colors.black, // Barcode color
          backgroundColor: Colors.white, // Background color
          style: const TextStyle(
              color: Colors.black,
              fontSize: 16), // Style for human-readable text
          errorBuilder: (context, error) => Center(
              child: Text(
            'Error rendering barcode: $error\nData: $data',
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          )),
        ),
      ),
    );
  }
}
