import 'dart:convert';

import 'package:cardabase/feature/cards/loyalty_card.dart';

List<LoyaltyCard> deserializeLoyaltyCards(String input) {
  final Object jsonException;
  final Object legacyException;

  try {
    return _deserializeJsonExport(input);
  } catch (e) {
    jsonException = e;
  }

  // if new parse did not work, try the legacy one
  try {
    return _deserializeLegacyExport(input);
  } catch (e) {
    legacyException = e;
  }

  throw LoyaltyCardDeserializationException(
    jsonException: jsonException,
    legacyException: legacyException,
  );
}

List<LoyaltyCard> _deserializeLegacyExport(String input) {
  return input
      .split('\n')
      .where((line) => line.startsWith('{') || line.startsWith('['))
      .map(LoyaltyCard.fromLegacyExport)
      .toList(growable: false);
}

List<LoyaltyCard> _deserializeJsonExport(String input) {
  final jsonList = jsonDecode(input);
  if (jsonList is! List) {
    throw Exception('input is no a json list');
  } else {
    return jsonList
        .whereType<Map<String, dynamic>>()
        .map(LoyaltyCard.fromJsonMap)
        .toList(growable: false);
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
