import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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

class ZipImportResult {
  ZipImportResult({
    required this.cards,
    required this.settings,
  });

  final List<LoyaltyCard> cards;
  final Settings settings;
}

Future<ZipImportResult> importDataFromZip(List<int> bytes) async {
  final archive = ZipDecoder().decodeBytes(bytes);

  // 1. Load cards
  final cardsFile = archive.findFile('cards/cards');
  if (cardsFile == null) {
    throw Exception('ZIP is missing cards/cards file');
  }
  final cardsJson = utf8.decode(cardsFile.content as List<int>);
  final cardsList = deserializeLoyaltyCards(cardsJson);

  // 2. Load settings
  final settingsFile = archive.findFile('settings');
  if (settingsFile == null) {
    throw Exception('ZIP is missing settings file');
  }
  final settingsJson = utf8.decode(settingsFile.content as List<int>);
  final settings = Settings.fromJsonMap(jsonDecode(settingsJson) as Map<String, dynamic>);

  // 3. Extract images
  final appDocDir = await getApplicationDocumentsDirectory();
  final cardsWithImages = <LoyaltyCard>[];

  for (final card in cardsList) {
    String? frontPath;
    String? backPath;

    // Search for images in ZIP
    for (final file in archive.files) {
      if (file.name.startsWith('images/${card.id}-f.')) {
        final ext = p.extension(file.name);
        final outPath = p.join(appDocDir.path, '${card.id}-f$ext');
        await File(outPath).writeAsBytes(file.content as List<int>);
        frontPath = outPath;
      } else if (file.name.startsWith('images/${card.id}-b.')) {
        final ext = p.extension(file.name);
        final outPath = p.join(appDocDir.path, '${card.id}-b$ext');
        await File(outPath).writeAsBytes(file.content as List<int>);
        backPath = outPath;
      }
    }

    cardsWithImages.add(
      LoyaltyCard(
        id: card.id,
        barcode: card.barcode,
        name: card.name,
        color: card.color,
        tags: card.tags,
        notes: card.notes,
        frontImagePath: frontPath,
        backImagePath: backPath,
        useFrontImageOverlay: card.useFrontImageOverlay,
        points: card.points,
        requiresAuth: card.requiresAuth,
        hideName: card.hideName,
        createdAt: card.createdAt,
        lastModifiedAt: card.lastModifiedAt,
      ),
    );
  }

  return ZipImportResult(
    cards: cardsWithImages,
    settings: settings,
  );
}

Future<ZipImportResult> importDataFromFilePath(String path) async {
  final bytes = await File(path).readAsBytes();
  return importDataFromZip(bytes);
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
