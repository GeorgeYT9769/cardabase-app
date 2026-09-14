import 'package:flutter_test/flutter_test.dart';

/// Matches a value which lies between [start] and [end], both included.
///
/// It is meant for the values a test cannot know exactly: a timestamp the code
/// under test took itself is checked against the moments around the call.
///
/// ```dart
/// final start = DateTime.now().toUtc();
/// final card = LoyaltyCard.fromJson(json);
/// expect(card.createdAt, isBetween(start, DateTime.now().toUtc()));
/// ```
///
/// Anything which compares to itself works: a [DateTime], a number, a
/// [Duration] or a [String].
Matcher isBetween(Object start, Object end) => _IsBetween(start, end);

class _IsBetween extends Matcher {
  const _IsBetween(this.start, this.end);

  final Object start;
  final Object end;

  @override
  Description describe(Description description) {
    return description
        .add('a value between ')
        .addDescriptionOf(start)
        .add(' and ')
        .addDescriptionOf(end);
  }

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! Comparable) {
      matchState[_stateKey] = 'is not comparable to anything';
      return false;
    }

    final int fromStart;
    final int toEnd;
    try {
      fromStart = item.compareTo(start);
      toEnd = item.compareTo(end);
    } on TypeError {
      matchState[_stateKey] =
          'is a ${item.runtimeType}, which does not compare to '
          'a ${start.runtimeType}';
      return false;
    }

    if (fromStart < 0) {
      matchState[_stateKey] = 'is before the start';
      return false;
    }
    if (toEnd > 0) {
      matchState[_stateKey] = 'is after the end';
      return false;
    }
    return true;
  }

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    final reason = matchState[_stateKey];
    if (reason is! String) {
      return super
          .describeMismatch(item, mismatchDescription, matchState, verbose);
    }
    return mismatchDescription.add(reason);
  }

  static const String _stateKey = 'isBetween.reason';
}
