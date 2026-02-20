import 'package:barcode_widget/barcode_widget.dart';
import 'package:cardabase/pages/full_screen_card_face/full_screen_card_face_page.dart';
import 'package:flutter/material.dart';

class CardFace extends StatelessWidget {
  const CardFace({
    super.key,
    required this.cardTileColor,
    required this.fullScreenBuilder,
    required this.child,
  });

  factory CardFace.barcode({
    required Color cardTileColor,
    required String cardData,
    required BarcodeType barcodeType,
  }) {
    return CardFace(
      cardTileColor: cardTileColor,
      fullScreenBuilder: (context) => FullScreenCardFacePage.barcode(
        cardData: cardData,
        barcodeType: barcodeType,
      ),
      child: BarcodeWidget(
        padding: const EdgeInsets.all(10),
        data: cardData,
        barcode: Barcode.fromType(barcodeType),
        style: const TextStyle(color: Colors.black),
        errorBuilder: (context, error) => Center(
          child: Text(
            'Invalid barcode data',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  factory CardFace.image({
    required Color cardTileColor,
    required ImageProvider image,
  }) {
    return CardFace(
      cardTileColor: cardTileColor,
      fullScreenBuilder: (context) => FullScreenCardFacePage.image(
        image: image,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image(
          image: image,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }

  final Color cardTileColor;
  final WidgetBuilder fullScreenBuilder;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: fullScreenBuilder),
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          color: cardTileColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            color: Colors.white,
          ),
          child: child,
        ),
      ),
    );
  }
}

BarcodeType parseBarcodeType(String cardType) {
  return switch (cardType) {
    'CardType.code39' => BarcodeType.Code39,
    'CardType.code93' => BarcodeType.Code93,
    'CardType.code128' => BarcodeType.Code128,
    'CardType.ean13' => BarcodeType.CodeEAN13,
    'CardType.ean8' => BarcodeType.CodeEAN8,
    'CardType.ean5' => BarcodeType.CodeEAN5,
    'CardType.ean2' => BarcodeType.CodeEAN2,
    'CardType.itf' => BarcodeType.Itf,
    'CardType.itf14' => BarcodeType.CodeITF14,
    'CardType.itf16' => BarcodeType.CodeITF16,
    'CardType.upca' => BarcodeType.CodeUPCA,
    'CardType.upce' => BarcodeType.CodeUPCE,
    'CardType.codabar' => BarcodeType.Codabar,
    'CardType.qrcode' => BarcodeType.QrCode,
    'CardType.datamatrix' => BarcodeType.DataMatrix,
    'CardType.aztec' => BarcodeType.Aztec,
    _ => BarcodeType.CodeEAN13
  };
}
