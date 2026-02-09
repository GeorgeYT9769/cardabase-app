import 'package:cardabase/util/ean.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('verifyEan', () {
    const validCodes = [
      _ValidEanCodeTestCase(code: '2292302559524', length: 13),
    ];

    for (final testCase in validCodes) {
      test('valid: ${testCase.code}', () {
        final exception = verifyEan(testCase.code, testCase.length);
        expect(exception, isNull);
      });
    }

    const invalidCodes = [
      _InvalidEanCodeTestCase(
        code: '2292302559523',
        length: 13,
        exception: EanCheckSumIncorrectException(),
      ),
      _InvalidEanCodeTestCase(
        code: '123467891011',
        length: 13,
        exception: EanCodeInvalidLengthException(),
      ),
      _InvalidEanCodeTestCase(
        code: '12345678910111',
        length: 13,
        exception: EanCodeInvalidLengthException(),
      ),
    ];

    for (final testCase in invalidCodes) {
      test('valid: ${testCase.code}', () {
        final exception = verifyEan(testCase.code, testCase.length);
        expect(exception, testCase.exception);
      });
    }
  });
}

class _ValidEanCodeTestCase {
  const _ValidEanCodeTestCase({
    required this.code,
    required this.length,
  });
  final String code;
  final int length;
}

class _InvalidEanCodeTestCase {
  const _InvalidEanCodeTestCase({
    required this.code,
    required this.length,
    required this.exception,
  });
  final String code;
  final int length;
  final Exception exception;
}
