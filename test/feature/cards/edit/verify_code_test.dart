import 'package:cardabase/feature/cards/edit/verify_code.dart';
import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validBarcode', () {
    group('EAN-13', () {
      final validator = validBarcode(BarcodeType.CodeEAN13);

      test('accepts a real barcode', () {
        expect(validator('9780201379624'), isNull);
      });

      test('refuses a number of the wrong length', () {
        expect(validator('978020137962'), isNotNull);
        expect(validator('97802013796244'), isNotNull);
      });

      test('refuses a number with a mistyped digit', () {
        expect(validator('9780201379625'), isNotNull);
      });

      test('refuses letters', () {
        expect(validator('978020137962X'), isNotNull);
      });
    });

    group('EAN-8', () {
      final validator = validBarcode(BarcodeType.CodeEAN8);

      test('accepts a real barcode', () {
        expect(validator('96385074'), isNull);
      });

      test('refuses a number of the wrong length', () {
        expect(validator('9638507'), isNotNull);
      });
    });

    group('UPC-A', () {
      final validator = validBarcode(BarcodeType.CodeUPCA);

      test('accepts a real barcode', () {
        expect(validator('036000291452'), isNull);
      });

      test('refuses a number with a mistyped digit', () {
        expect(validator('036000291453'), isNotNull);
      });
    });

    group('UPC-E', () {
      final validator = validBarcode(BarcodeType.CodeUPCE);

      test('accepts a number of eight digits which adds up', () {
        expect(validator('96385074'), isNull);
      });

      test('refuses a number of the wrong length', () {
        expect(validator('0963850'), isNotNull);
      });
    });

    group('ITF-14 and ITF-16', () {
      test('ITF-14 wants fourteen digits which add up', () {
        final validator = validBarcode(BarcodeType.CodeITF14);

        expect(validator('10614141000415'), isNull);
        expect(validator('1061414100041'), isNotNull);
        expect(validator('10614141000416'), isNotNull);
      });

      test('ITF-16 wants sixteen digits which add up', () {
        final validator = validBarcode(BarcodeType.CodeITF16);

        expect(validator('1234567890123452'), isNull);
        expect(validator('123456789012345'), isNotNull);
      });
    });

    group('EAN-5 and EAN-2', () {
      test('EAN-5 wants five digits, and does not check them', () {
        final validator = validBarcode(BarcodeType.CodeEAN5);

        expect(validator('52495'), isNull);
        expect(validator('5249'), isNotNull);
        expect(validator('5249a'), isNotNull);
      });

      test('EAN-2 wants two digits, and does not check them', () {
        final validator = validBarcode(BarcodeType.CodeEAN2);

        expect(validator('12'), isNull);
        expect(validator('1'), isNotNull);
      });
    });

    group('ITF', () {
      final validator = validBarcode(BarcodeType.Itf);

      test('takes digits of any length', () {
        expect(validator('1234'), isNull);
        expect(validator('123456789012345678'), isNull);
      });

      test('refuses anything which is not a digit', () {
        expect(validator('12a4'), isNotNull);
      });
    });

    group('the free-form types', () {
      test('accept whatever the scanner read', () {
        // these carry no checksum the app could verify, and a code 128 may hold
        // letters and punctuation.
        const anything = 'Whatever-1234 :)';
        for (final type in [
          BarcodeType.Code39,
          BarcodeType.Code93,
          BarcodeType.Code128,
          BarcodeType.CodeISBN,
          BarcodeType.GS128,
          BarcodeType.Telepen,
          BarcodeType.QrCode,
          BarcodeType.Codabar,
          BarcodeType.PDF417,
          BarcodeType.DataMatrix,
          BarcodeType.Aztec,
          BarcodeType.Rm4scc,
          BarcodeType.Postnet,
        ]) {
          expect(validBarcode(type)(anything), isNull, reason: '$type');
        }
      });
    });

    test('a card without a barcode type takes anything', () {
      expect(validBarcode(null)('whatever the user typed'), isNull);
    });

    test('every barcode type has a validator', () {
      // the switch in validBarcode is exhaustive today; this notices when a new
      // type is added to the package and nobody says what a valid value is.
      for (final type in BarcodeType.values) {
        expect(() => validBarcode(type), returnsNormally, reason: '$type');
      }
    });
  });
}
