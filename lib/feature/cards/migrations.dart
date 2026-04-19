import 'dart:ui';

import 'package:barcode_widget/barcode_widget.dart' show BarcodeType;
import 'package:cardabase/data/unique_id.dart';
import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/util/barcode_type_extensions.dart';
import 'package:hive_ce/hive.dart';

Future<void> migrateCardsBoxTo202603(Box oldBox, LoyaltyCardsBox newBox) async {
  if (newBox.isNotEmpty) {
    return Future.value();
  }

  final oldCards = oldBox.get('CARDLIST') as List?;
  if (oldCards == null) {
    return Future.value();
  }

  final cards = oldCards.map(_mapDynamicToCard).whereType<LoyaltyCard>();
  for (final card in cards) {
    await newBox.put(card.id, card);
  }
}

LoyaltyCard? _mapDynamicToCard(dynamic value) {
  if (value == null || value is! Map) {
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
        r = entry.value as int?;
      case 'greenValue':
        g = entry.value as int?;
      case 'blueValue':
        b = entry.value as int?;
      case 'cardType':
        cardType = entry.value as String?;
      case 'cardName':
        cardName = entry.value as String?;
      case 'cardId':
        cardId = entry.value as String?;
      case 'hasPassword':
        hasPassword = entry.value as bool?;
      case 'uniqueId':
        uniqueId = entry.value as String?;
      case 'tags':
        tags = entry.value as List?;
      case 'note':
        note = entry.value as String?;
      case 'imagePathFront':
        frontImagePath = entry.value as String?;
      case 'imagePathBack':
        backImagePath = entry.value as String?;
      case 'useFrontFaceOverlay':
        useFrontFaceOverlay = entry.value as bool?;
      case 'hideTitle':
        hideTitle = entry.value as bool?;
      case 'pointsAmount':
        pointsAmount = entry.value as int?;
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
  );
}
