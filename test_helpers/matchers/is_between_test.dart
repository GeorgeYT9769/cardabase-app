import 'package:flutter_test/flutter_test.dart';

import 'is_between.dart';

void main() {
  group('isBetween', () {
    final start = DateTime.utc(2024, 1, 1, 12);
    final end = DateTime.utc(2024, 1, 1, 13);

    test('matches a value inside the range', () {
      expect(DateTime.utc(2024, 1, 1, 12, 30), isBetween(start, end));
    });

    test('matches the ends of the range', () {
      expect(start, isBetween(start, end));
      expect(end, isBetween(start, end));
    });

    test('does not match a value outside the range', () {
      expect(DateTime.utc(2024, 1, 1, 11, 59), isNot(isBetween(start, end)));
      expect(DateTime.utc(2024, 1, 1, 13, 1), isNot(isBetween(start, end)));
    });

    test('works for anything which compares to itself', () {
      expect(5, isBetween(1, 10));
      expect(0, isNot(isBetween(1, 10)));
      expect('b', isBetween('a', 'c'));
      expect(
        const Duration(seconds: 30),
        isBetween(Duration.zero, const Duration(minutes: 1)),
      );
    });

    test('does not match a value of another type', () {
      expect('not a date', isNot(isBetween(start, end)));
      expect(null, isNot(isBetween(start, end)));
    });

    test('says what it wanted', () {
      expect(
        isBetween(1, 10).describe(StringDescription()).toString(),
        'a value between <1> and <10>',
      );
    });

    test('says what was wrong with the value', () {
      String mismatchOf(Object? value) {
        final matcher = isBetween(start, end);
        final matchState = <dynamic, dynamic>{};
        matcher.matches(value, matchState);
        return matcher
            .describeMismatch(
              value,
              StringDescription(),
              matchState,
              false,
            )
            .toString();
      }

      expect(mismatchOf(DateTime.utc(2023)), 'is before the start');
      expect(mismatchOf(DateTime.utc(2025)), 'is after the end');
      expect(mismatchOf('not a date'), contains('does not compare'));
      expect(mismatchOf(null), 'is not comparable to anything');
    });
  });
}
