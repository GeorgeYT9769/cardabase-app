import 'dart:convert';

import 'package:cardabase/feature/cards/loyalty_card.dart';

List<LoyaltyCard> deserializeLoyaltyCards(String input) {
  try {
    return _deserializeJsonExport(input);
  } catch (_) {
    // if new parse did not work, try the legacy one
  }

  return _deserializeLegacyExport(input);
}

List<LoyaltyCard> _deserializeLegacyExport(String input) {
  final cards = <LoyaltyCard>[];
  for (final line in input.split('\n')) {
    if (line.startsWith('{') || line.startsWith('[')) {
      try {
        cards.add(LoyaltyCard.fromLegacyExport(line));
      } catch (_) {
        // Skip cards that fail to parse
        continue;
      }
    }
  }
  return cards;
}

List<LoyaltyCard> _deserializeJsonExport(String input) {
  final jsonList = jsonDecode(input);
  if (jsonList is! List) {
    throw Exception('input is no a json list');
  } else {
    final cards = <LoyaltyCard>[];
    for (final item in jsonList.whereType<Map<String, dynamic>>()) {
      try {
        cards.add(LoyaltyCard.fromJsonMap(item));
      } catch (_) {
        // Skip cards that fail to parse
        continue;
      }
    }
    return cards;
  }
}

class LoyaltyCardDeserializationException implements Exception {
  const LoyaltyCardDeserializationException({
    required this.jsonException,
    required this.legacyException,
  });

  final Object jsonException;
  final Object legacyException;

  @override
  String toString() {
    return 'Failed to deserialize loyalty cards:\r\n'
        '- Json failure: ${jsonException.toString()}\r\n'
        '- Legacy exception: ${legacyException.toString()}';
  }
}
