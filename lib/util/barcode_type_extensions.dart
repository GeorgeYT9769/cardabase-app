import 'package:barcode_widget/barcode_widget.dart';

BarcodeType parseBarcodeTypeStringFromDb(String value) {
  // TODO(wim): move this in a database wrapper
  return switch (value) {
    'CardType.itf' => BarcodeType.Itf,
    'CardType.itf16' => BarcodeType.CodeITF16,
    'CardType.itf14' => BarcodeType.CodeITF14,
    'CardType.ean13' => BarcodeType.CodeEAN13,
    'CardType.ean8' => BarcodeType.CodeEAN8,
    'CardType.ean5' => BarcodeType.CodeEAN5,
    'CardType.ean2' => BarcodeType.CodeEAN2,
    'CardType.code39' => BarcodeType.Code39,
    'CardType.code93' => BarcodeType.Code93,
    'CardType.code128' => BarcodeType.Code128,
    'CardType.upca' => BarcodeType.CodeUPCA,
    'CardType.upce' => BarcodeType.CodeUPCE,
    'CardType.qrcode' => BarcodeType.QrCode,
    'CardType.codabar' => BarcodeType.Codabar,
    'CardType.datamatrix' => BarcodeType.DataMatrix,
    _ => BarcodeType.values.firstWhere(
        (type) => type.toString() == value,
        orElse: () => throw Exception('unknown barcode type: $value'),
      ),
  };
}

extension BarcodeTypeExtensions on BarcodeType {
  String getLabel() {
    return switch (this) {
      BarcodeType.Itf => 'ITF',
      BarcodeType.CodeITF16 => 'ITF-16',
      BarcodeType.CodeITF14 => 'ITF-14',
      BarcodeType.CodeEAN13 => 'EAN-13',
      BarcodeType.CodeEAN8 => 'EAN-8',
      BarcodeType.CodeEAN5 => 'EAN-5',
      BarcodeType.CodeEAN2 => 'EAN-2',
      BarcodeType.CodeISBN => 'ISBN',
      BarcodeType.Code39 => 'Code 39',
      BarcodeType.Code93 => 'Code 93',
      BarcodeType.Code128 => 'Code 128',
      BarcodeType.CodeUPCA => 'UPC-A',
      BarcodeType.CodeUPCE => 'UPC-E',
      BarcodeType.GS128 => 'GS-128',
      BarcodeType.Telepen => 'Telepen',
      BarcodeType.QrCode => 'QR-Code',
      BarcodeType.Codabar => 'Codabar',
      BarcodeType.PDF417 => 'PDF-417',
      BarcodeType.DataMatrix => 'Data Matrix',
      BarcodeType.Aztec => 'Aztec',
      BarcodeType.Rm4scc => 'RM4SCC',
      BarcodeType.Postnet => 'Postnet',
    };
  }

  String getDbStringValue() {
    // TODO(wim): move this to a database wrapper
    return switch (this) {
      BarcodeType.Itf => 'CardType.itf',
      BarcodeType.CodeITF16 => 'CardType.itf16',
      BarcodeType.CodeITF14 => 'CardType.itf14',
      BarcodeType.CodeEAN13 => 'CardType.ean13',
      BarcodeType.CodeEAN8 => 'CardType.ean8',
      BarcodeType.CodeEAN5 => 'CardType.ean5',
      BarcodeType.CodeEAN2 => 'CardType.ean2',
      BarcodeType.Code39 => 'CardType.code39',
      BarcodeType.Code93 => 'CardType.code93',
      BarcodeType.Code128 => 'CardType.code128',
      BarcodeType.CodeUPCA => 'CardType.upca',
      BarcodeType.CodeUPCE => 'CardType.upce',
      BarcodeType.QrCode => 'CardType.qrcode',
      BarcodeType.Codabar => 'CardType.codabar',
      BarcodeType.DataMatrix => 'CardType.datamatrix',
      _ => toString(),
    };
  }
}
