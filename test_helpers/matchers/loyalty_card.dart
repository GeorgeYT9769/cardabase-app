import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:flutter_test/flutter_test.dart';

Matcher loyaltyCard({
  LoyaltyCard? expected,
  Matcher? id,
  Matcher? barcode,
  Matcher? name,
  Matcher? color,
  Matcher? tags,
  Matcher? notes,
  Matcher? frontImagePath,
  Matcher? backImagePath,
  Matcher? useFrontImageOverlay,
  Matcher? points,
  Matcher? requiresAuth,
  Matcher? hideName,
  Matcher? createdAt,
  Matcher? lastModifiedAt,
  Matcher? usePoints,
}) {
  return _LoyaltyCardMatcher(
    expected: expected,
    id: id,
    barcode: barcode,
    name: name,
    color: color,
    tags: tags,
    notes: notes,
    frontImagePath: frontImagePath,
    backImagePath: backImagePath,
    useFrontImageOverlay: useFrontImageOverlay,
    points: points,
    requiresAuth: requiresAuth,
    hideName: hideName,
    createdAt: createdAt,
    lastModifiedAt: lastModifiedAt,
    usePoints: usePoints,
  );
}

class _LoyaltyCardMatcher extends Matcher {
  _LoyaltyCardMatcher({
    required LoyaltyCard? expected,
    required Matcher? id,
    required Matcher? barcode,
    required Matcher? name,
    required Matcher? color,
    required Matcher? tags,
    required Matcher? notes,
    required Matcher? frontImagePath,
    required Matcher? backImagePath,
    required Matcher? useFrontImageOverlay,
    required Matcher? points,
    required Matcher? requiresAuth,
    required Matcher? hideName,
    required Matcher? createdAt,
    required Matcher? lastModifiedAt,
    required Matcher? usePoints,
  }) {
    if (expected != null) {
      id = id ?? equals(expected.id);
      barcode = barcode ?? equals(expected.barcode);
      name = name ?? equals(expected.name);
      color = color ?? equals(expected.color);
      tags = tags ?? equals(expected.tags);
      notes = notes ?? equals(expected.notes);
      frontImagePath = frontImagePath ?? equals(expected.frontImagePath);
      backImagePath = backImagePath ?? equals(expected.backImagePath);
      useFrontImageOverlay =
          useFrontImageOverlay ?? equals(expected.useFrontImageOverlay);
      points = points ?? equals(expected.points);
      requiresAuth = requiresAuth ?? equals(expected.requiresAuth);
      hideName = hideName ?? equals(expected.hideName);
      createdAt = createdAt ?? equals(expected.createdAt);
      lastModifiedAt = lastModifiedAt ?? equals(expected.lastModifiedAt);
      usePoints = usePoints ?? equals(expected.usePoints);
    }

    _matchers = [
      if (id != null) _FieldMatcher('id', (card) => card.id, id),
      if (barcode != null)
        _FieldMatcher('barcode', (card) => card.barcode, barcode),
      if (name != null) _FieldMatcher('name', (card) => card.name, name),
      if (color != null) _FieldMatcher('color', (card) => card.color, color),
      if (tags != null) _FieldMatcher('tags', (card) => card.tags, tags),
      if (notes != null) _FieldMatcher('notes', (card) => card.notes, notes),
      if (frontImagePath != null)
        _FieldMatcher(
          'frontImagePath',
          (card) => card.frontImagePath,
          frontImagePath,
        ),
      if (backImagePath != null)
        _FieldMatcher(
          'backImagePath',
          (card) => card.backImagePath,
          backImagePath,
        ),
      if (useFrontImageOverlay != null)
        _FieldMatcher(
          'useFrontImageOverlay',
          (card) => card.useFrontImageOverlay,
          useFrontImageOverlay,
        ),
      if (points != null)
        _FieldMatcher('points', (card) => card.points, points),
      if (requiresAuth != null)
        _FieldMatcher(
          'requiresAuth',
          (card) => card.requiresAuth,
          requiresAuth,
        ),
      if (hideName != null)
        _FieldMatcher('hideName', (card) => card.hideName, hideName),
      if (createdAt != null)
        _FieldMatcher('createdAt', (card) => card.createdAt, createdAt),
      if (lastModifiedAt != null)
        _FieldMatcher(
          'lastModifiedAt',
          (card) => card.lastModifiedAt,
          lastModifiedAt,
        ),
      if (usePoints != null)
        _FieldMatcher('usePoints', (card) => card.usePoints, usePoints),
    ];
  }

  late final List<_FieldMatcher> _matchers;

  @override
  Description describe(Description description) {
    description.add('a loyalty card with');
    for (final entry in _matchers) {
      description.add(' ${entry.fieldName} ').addDescriptionOf(entry.matcher);
    }
    return description;
  }

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! LoyaltyCard) {
      matchState[_stateKey] = 'is not a loyalty card';
      return false;
    }

    for (final entry in _matchers) {
      final value = entry.field(item);
      if (!entry.matcher.matches(value, matchState)) {
        matchState[_stateKey] = 'has a ${entry.fieldName} of '
            '${_describe(value)} instead of ${_describe(entry.matcher)}';
        return false;
      }
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

  static String _describe(Object? value) {
    return StringDescription().addDescriptionOf(value).toString();
  }

  static const String _stateKey = 'loyaltyCard.reason';
}

class _FieldMatcher {
  const _FieldMatcher(this.fieldName, this.field, this.matcher);

  final String fieldName;
  final Object? Function(LoyaltyCard card) field;
  final Matcher matcher;
}
