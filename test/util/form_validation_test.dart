import 'package:cardabase/util/form_validation.dart' as validation;
import 'package:cardabase/util/form_validation.dart'
    show FormValidationExtensions;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isNotEmpty', () {
    test('refuses nothing at all', () {
      expect(validation.isNotEmpty<String>()(null), isNotNull);
    });

    test('refuses an empty or blank string', () {
      expect(validation.isNotEmpty<String>()(''), isNotNull);
      expect(validation.isNotEmpty<String>()('   '), isNotNull);
    });

    test('accepts a string with something in it', () {
      expect(validation.isNotEmpty<String>()('a'), isNull);
    });

    test('refuses an empty list and accepts a filled one', () {
      expect(validation.isNotEmpty<List>()([]), isNotNull);
      expect(validation.isNotEmpty<List>()(['a']), isNull);
    });

    test('refuses an empty map and accepts a filled one', () {
      expect(validation.isNotEmpty<Map>()({}), isNotNull);
      expect(validation.isNotEmpty<Map>()({'a': 1}), isNull);
    });

    test('accepts a value it cannot look inside', () {
      expect(validation.isNotEmpty<int>()(0), isNull);
    });
  });

  group('hasLength', () {
    test('refuses nothing at all', () {
      expect(validation.hasLength<String>(3)(null), isNotNull);
    });

    test('accepts a string of exactly that length', () {
      expect(validation.hasLength<String>(3)('abc'), isNull);
    });

    test('refuses a string which is too short or too long', () {
      expect(validation.hasLength<String>(3)('ab'), isNotNull);
      expect(validation.hasLength<String>(3)('abcd'), isNotNull);
    });

    test('measures lists and maps as well', () {
      expect(validation.hasLength<List>(2)(['a', 'b']), isNull);
      expect(validation.hasLength<List>(2)(['a']), isNotNull);
      expect(validation.hasLength<Map>(1)({'a': 1}), isNull);
      expect(validation.hasLength<Map>(1)({}), isNotNull);
    });

    test('says which length it wanted', () {
      expect(validation.hasLength<String>(13)('abc'), contains('13'));
    });
  });

  group('isDigits', () {
    test('accepts digits', () {
      expect(validation.isDigits()('0123456789'), isNull);
    });

    test('refuses anything which is not a digit', () {
      expect(validation.isDigits()('12a45'), isNotNull);
      expect(validation.isDigits()('12 45'), isNotNull);
      expect(validation.isDigits()('12.45'), isNotNull);
      expect(validation.isDigits()('-1245'), isNotNull);
    });

    test('leaves an empty value to isNotEmpty', () {
      expect(validation.isDigits()(null), isNull);
      expect(validation.isDigits()(''), isNull);
    });
  });

  group('hasValidGs1Checksum', () {
    test('accepts numbers whose check digit adds up', () {
      // real barcodes: an ean-13, an ean-8 and a upc-a.
      expect(validation.hasValidGs1Checksum()('9780201379624'), isNull);
      expect(validation.hasValidGs1Checksum()('4006381333931'), isNull);
      expect(validation.hasValidGs1Checksum()('96385074'), isNull);
      expect(validation.hasValidGs1Checksum()('036000291452'), isNull);
    });

    test('refuses a number with a mistyped digit', () {
      expect(validation.hasValidGs1Checksum()('9780201379625'), isNotNull);
      expect(validation.hasValidGs1Checksum()('9780201379634'), isNotNull);
    });

    test('needs at least two digits to have a check digit', () {
      expect(validation.hasValidGs1Checksum()('1'), isNotNull);
      expect(validation.hasValidGs1Checksum()(''), isNotNull);
    });

    test('leaves nothing at all to isNotEmpty', () {
      expect(validation.hasValidGs1Checksum()(null), isNull);
    });
  });

  group('and', () {
    test('accepts a value both validators accept', () {
      final validator =
          validation.isNotEmpty<String>().and(validation.isDigits());

      expect(validator('123'), isNull);
    });

    test('reports the first validator which refuses', () {
      final validator =
          validation.isNotEmpty<String>().and(validation.isDigits());

      expect(validator(''), validation.isNotEmpty<String>()(''));
    });

    test('reports the second validator when the first accepts', () {
      final validator =
          validation.isNotEmpty<String>().and(validation.isDigits());

      expect(validator('abc'), validation.isDigits()('abc'));
    });
  });
}
