import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../../settings/get_it.dart';
import '../../settings/model.dart';

class FullScreenCardFacePage extends StatelessWidget {
  const FullScreenCardFacePage({
    super.key,
    required this.child,
    this.backgroundColor,
  });

  factory FullScreenCardFacePage.barcode({
    required String cardData,
    required BarcodeType barcodeType,
  }) {
    return FullScreenCardFacePage(
      backgroundColor: Colors.white,
      child: _buildBarcodeWidget(cardData, barcodeType),
    );
  }

  factory FullScreenCardFacePage.image({
    required ImageProvider image,
  }) {
    return FullScreenCardFacePage(
      child: SizedBox.expand(
        child: Image(
          image: image,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  final Widget child;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor =
        backgroundColor ?? theme.colorScheme.surface;

    return ValueListenableBuilder(
      valueListenable: GetIt.I<SettingsBox>().listenable(),
      builder: (context, box, _) {
        final settings = box.value;
        final rightBackButton = settings.theme.rightBackButton;
        final backButton = IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: effectiveBackgroundColor == Colors.white
                ? Colors.black
                : theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        );

        return Scaffold(
          backgroundColor: effectiveBackgroundColor,
          appBar: AppBar(
            backgroundColor: effectiveBackgroundColor,
            automaticallyImplyLeading: false,
            leading: !rightBackButton ? backButton : null,
            actions: [
              if (rightBackButton) backButton,
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: child,
            ),
          ),
        );
      },
    );
  }

  static Widget _buildBarcodeWidget(String data, BarcodeType type) {
    double? width;
    double? height;

    switch (type) {
      case BarcodeType.QrCode || BarcodeType.DataMatrix || BarcodeType.Aztec:
        width = 300;
        height = 300;
      default:
        width = 400;
        height = 200;
    }

    return RotatedBox(
      quarterTurns: 1,
      child: SizedBox(
        width: width,
        height: height,
        child: BarcodeWidget(
          barcode: Barcode.fromType(type),
          data: data,
          backgroundColor: Colors.white,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
          ),
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
