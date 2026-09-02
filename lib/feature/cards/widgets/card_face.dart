import 'package:barcode_widget/barcode_widget.dart';
import 'package:cardabase/feature/cards/widgets/full_screen_card_face_page.dart';
import 'package:flutter/material.dart';

class CardFace extends StatelessWidget {
  const CardFace({
    super.key,
    required this.cardTileColor,
    required this.fullScreenBuilder,
    required this.child,
    required this.showWhiteOutline,
    this.showLeftTriangle = false,
    this.showRightTriangle = false,
  });

  factory CardFace.barcode({
    Key? key,
    required Color? cardTileColor,
    required String cardData,
    required BarcodeType barcodeType,
    required bool showWhiteOutline,
    bool showLeftTriangle = false,
    bool showRightTriangle = false,
  }) {
    return CardFace(
      key: key,
      cardTileColor: cardTileColor,
      showWhiteOutline: showWhiteOutline,
      showLeftTriangle: showLeftTriangle,
      showRightTriangle: showRightTriangle,
      fullScreenBuilder: (context) => FullScreenCardFacePage.barcode(
        cardData: cardData,
        barcodeType: barcodeType,
      ),
      child: BarcodeWidget(
        padding: const EdgeInsets.all(10),
        data: cardData,
        barcode: Barcode.fromType(barcodeType),
        style: const TextStyle(color: Colors.black),
        errorBuilder: (context, error) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_2,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                cardData,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  factory CardFace.image({
    Key? key,
    required Color? cardTileColor,
    required ImageProvider image,
    required bool showWhiteOutline,
    bool showLeftTriangle = false,
    bool showRightTriangle = false,
  }) {
    return CardFace(
      key: key,
      cardTileColor: cardTileColor,
      showWhiteOutline: showWhiteOutline,
      showLeftTriangle: showLeftTriangle,
      showRightTriangle: showRightTriangle,
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

  final Color? cardTileColor;
  final WidgetBuilder fullScreenBuilder;
  final Widget child;
  final bool showWhiteOutline;
  final bool showLeftTriangle;
  final bool showRightTriangle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: fullScreenBuilder),
      ),
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            decoration: BoxDecoration(
              color: cardTileColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: showWhiteOutline
                ? Container(
                    height: 120,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color: Colors.white,
                    ),
                    child: child,
                  )
                : child,
          ),
          if (showLeftTriangle)
            Positioned(
              left: 5,
              child: CustomPaint(
                size: const Size(8, 12),
                painter: _TrianglePainter(
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                  isLeft: true,
                ),
              ),
            ),
          if (showRightTriangle)
            Positioned(
              right: 5,
              child: CustomPaint(
                size: const Size(8, 12),
                painter: _TrianglePainter(
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                  isLeft: false,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  final bool isLeft;

  _TrianglePainter({required this.color, required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    if (isLeft) {
      path.moveTo(size.width, 0);
      path.lineTo(0, size.height / 2);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(0, size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
