import 'dart:ui';
import 'dart:convert';

import 'package:cardabase/data/unique_id.dart';
import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/util/barcode_type_extensions.dart';
import 'package:hive_ce/hive.dart';

Future<void> migrateCardsBoxTo202603(Box oldBox, LoyaltyCardsBox newBox) async {
  if (newBox.isNotEmpty) {
    return Future.value();
  }

  final oldCards = _extractLegacyCards(oldBox);
  if (oldCards.isEmpty) {
    return Future.value();
  }

  try {
    // Map all old entries to LoyaltyCard instances and perform a single
    // putAll operation to avoid awaiting many small writes on the main
    // isolate which can block startup and cause a black screen during
    // large migrations.
    final Map<String, LoyaltyCard> map = {};
    for (final raw in oldCards) {
      final card = _mapDynamicToCard(raw);
      if (card == null) {
        continue;
      }
      map[card.id] = card;
    }

    if (map.isNotEmpty) {
      await newBox.putAll(map);
    }
  } catch (e, s) {
    // Don't rethrow - log and continue. An exception here should not
    // prevent the app from starting.
    // ignore: avoid_print
    print('Failed to migrate cards to cards202603: $e\n$s');
  }
}

List<dynamic> _extractLegacyCards(Box oldBox) {
  final cardList = oldBox.get('CARDLIST');
  if (cardList is List) {
    return cardList;
  }

  // Some older versions may have used a different key or stored cards directly
  // as box values. Try to recover these formats too.
  for (final value in oldBox.values) {
    if (value is List) {
      return value;
    }
  }

  // Last-resort fallback: if individual entries look like cards, migrate them.
  final values = oldBox.values.toList(growable: false);
  final hasCardLikeValues = values.any((value) =>
      value is LoyaltyCard ||
      value is Map ||
      value is String);
  if (hasCardLikeValues) {
    return values;
  }

  return const [];
}

LoyaltyCard? _mapDynamicToCard(dynamic value) {
  if (value == null) {
    return null;
  }

  // If the old box already stores typed cards, reuse them directly.
  if (value is LoyaltyCard) {
    return value;
  }

  if (value is String) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) {
        return LoyaltyCard.fromJsonMap(decoded);
      }
    } catch (_) {
      return null;
    }
  }

  if (value is! Map) {
    return null;
  }
  final map = value;

  int? r;
  int? g;
  int? b;
  String? cardType;
  String? cardName;
  String? cardId;
  bool? hasPassword;
  String? uniqueId;
  List? tags;
  String? note;
  String? frontImagePath;
  String? backImagePath;
  bool? useFrontFaceOverlay;
  bool? hideTitle;
  int? pointsAmount;

  for (final entry in map.entries) {
    switch (entry.key) {
      case 'redValue':
        r = _asInt(entry.value);
      case 'greenValue':
        g = _asInt(entry.value);
      case 'blueValue':
        b = _asInt(entry.value);
      case 'cardType':
        cardType = _asString(entry.value);
      case 'cardName':
        cardName = _asString(entry.value);
      case 'cardId':
        cardId = _asString(entry.value);
      case 'hasPassword':
        hasPassword = _asBool(entry.value);
      case 'uniqueId':
        uniqueId = _asString(entry.value);
      case 'tags':
        tags = entry.value as List?;
      case 'note':
        note = _asString(entry.value);
      case 'imagePathFront':
        frontImagePath = _asString(entry.value);
      case 'imagePathBack':
        backImagePath = _asString(entry.value);
      case 'useFrontFaceOverlay':
        useFrontFaceOverlay = _asBool(entry.value);
      case 'hideTitle':
        hideTitle = _asBool(entry.value);
      case 'pointsAmount':
        pointsAmount = _asInt(entry.value);
    }
  }

  Color? color;
  if (r != null && g != null && b != null) {
    color = Color.fromARGB(255, r, g, b);
  }

  return LoyaltyCard(
    id: uniqueId ?? generateUniqueId(),
    barcode: Barcode(
      data: cardId ?? '',
      type: cardType == null
          ? BarcodeType.CodeEAN13
          : parseBarcodeTypeStringFromDb(cardType),
    ),
    name: cardName ?? '',
    color: color,
    tags: tags?.whereType<String>().toSet() ?? {},
    notes: note,
    frontImagePath: frontImagePath,
    backImagePath: backImagePath,
    useFrontImageOverlay: useFrontFaceOverlay ?? false,
    points: pointsAmount ?? 0,
    requiresAuth: hasPassword ?? false,
    hideName: hideTitle ?? false,
    createdAt: DateTime.now().toUtc(),
    lastModifiedAt: DateTime.now().toUtc(),
    usePoints: pointsAmount != null && pointsAmount != 0,
  );
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

bool? _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is String) {
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;
  }
  return null;
}

String? _asString(dynamic value) {
  if (value is String) return value;
  return null;
}

