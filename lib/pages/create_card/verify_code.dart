import 'package:barcode_widget/barcode_widget.dart';
import 'package:cardabase/util/form_validation.dart';
import 'package:flutter/widgets.dart';

FormFieldValidator<String> validBarcode(BarcodeType type) {
  return switch (type) {
    BarcodeType.Itf =>
      hasLength<String>(14).and(isDigits()).and(hasValidGs1Checksum()),
    BarcodeType.CodeITF16 =>
      hasLength<String>(16).and(isDigits()).and(hasValidGs1Checksum()),
    BarcodeType.CodeITF14 =>
      hasLength<String>(14).and(isDigits()).and(hasValidGs1Checksum()),
    BarcodeType.CodeEAN13 =>
      hasLength<String>(13).and(isDigits()).and(hasValidGs1Checksum()),
    BarcodeType.CodeEAN8 =>
      hasLength<String>(8).and(isDigits()).and(hasValidGs1Checksum()),
    BarcodeType.CodeEAN5 => hasLength<String>(5).and(isDigits()),
    BarcodeType.CodeEAN2 => hasLength<String>(2).and(isDigits()),
    BarcodeType.CodeISBN => (_) => null,
    BarcodeType.Code39 => (_) => null,
    BarcodeType.Code93 => (_) => null,
    BarcodeType.CodeUPCA =>
      hasLength<String>(12).and(isDigits()).and(hasValidGs1Checksum()),
    BarcodeType.CodeUPCE =>
      hasLength<String>(8).and(isDigits()).and(hasValidGs1Checksum()),
    BarcodeType.Code128 => (_) => null,
    BarcodeType.GS128 => (_) => null,
    BarcodeType.Telepen => (_) => null,
    BarcodeType.QrCode => (_) => null,
    BarcodeType.Codabar => (_) => null,
    BarcodeType.PDF417 => (_) => null,
    BarcodeType.DataMatrix => (_) => null,
    BarcodeType.Aztec => (_) => null,
    BarcodeType.Rm4scc => (_) => null,
    BarcodeType.Postnet => (_) => null,
  };
}
