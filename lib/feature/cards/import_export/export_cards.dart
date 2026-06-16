import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

Future<bool> _requestStoragePermission() async {
  if (Platform.isAndroid) {
    if (await Permission.manageExternalStorage.request().isGranted) {
      return true;
    } else if (await Permission.manageExternalStorage.isPermanentlyDenied) {
      openAppSettings();
      return false;
    }
  } else {
    if (await Permission.storage.request().isGranted) {
      return true;
    }
  }
  return false;
}

Future<void> exportCardsAsFile(
  Iterable<LoyaltyCard> cards, {
  required String directoryPath,
}) async {
  if (!await _requestStoragePermission()) {
    throw NoPermissionToExternalStorageException();
  }

  const rootDirectory = '/storage/emulated/0';
  final directory = directoryPath.startsWith('/')
      ? Directory('$rootDirectory$directoryPath')
      : Directory('$rootDirectory/$directoryPath');
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  final now = DateTime.now();
  final strTimestamp =
      '${now.year}${now.month}${now.day}_${now.hour}${now.minute}${now.second}';

  final filePath = '${directory.path}/Cardabase_backup_$strTimestamp.txt';
  final file = File(filePath);
  await file.writeAsString(cards.serializeToJson());
}

Future<void> exportDataAsZip(
  Iterable<LoyaltyCard> cards, {
  required Settings settings,
  required String directoryPath,
}) async {
  if (!await _requestStoragePermission()) {
    throw NoPermissionToExternalStorageException();
  }

  const rootDirectory = '/storage/emulated/0';
  final directory = directoryPath.startsWith('/')
      ? Directory('$rootDirectory$directoryPath')
      : Directory('$rootDirectory/$directoryPath');
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  final now = DateTime.now();
  final strTimestamp =
      '${now.year}${now.month}${now.day}_${now.hour}${now.minute}${now.second}';
  final zipFileName = 'Cardabase_backup_$strTimestamp.cdb';
  final zipFilePath = '${directory.path}/$zipFileName';

  final archive = Archive();

  // Cards: one folder will contain one file with all cards named cards
  final serializedCards = cards.serializeToJson();
  final cardsBytes = utf8.encode(serializedCards);
  archive.addFile(
    ArchiveFile('cards/cards', cardsBytes.length, cardsBytes),
  );

  // Settings: then settings named settings
  final serializedSettings = jsonEncode(settings.toJsonMap());
  final settingsBytes = utf8.encode(serializedSettings);
  archive.addFile(
    ArchiveFile('settings', settingsBytes.length, settingsBytes),
  );

  // Images: then images with their names being the unique IDs...
  for (final card in cards) {
    if (card.frontImagePath != null) {
      final file = File(card.frontImagePath!);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final ext = p.extension(card.frontImagePath!);
        archive.addFile(
          ArchiveFile('images/${card.id}-f$ext', bytes.length, bytes),
        );
      }
    }
    if (card.backImagePath != null) {
      final file = File(card.backImagePath!);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final ext = p.extension(card.backImagePath!);
        archive.addFile(
          ArchiveFile('images/${card.id}-b$ext', bytes.length, bytes),
        );
      }
    }
  }

  final zipData = ZipEncoder().encode(archive);
  await File(zipFilePath).writeAsBytes(zipData);
}

Future<void> exportCardsToClipboard(Iterable<LoyaltyCard> cards) async {
  final serializedCards = cards.serializeToJson();
  await Clipboard.setData(ClipboardData(text: serializedCards));
}

// ------------------------------------------------------
// EXCEPTIONS
// ------------------------------------------------------

class NoPermissionToExternalStorageException implements Exception {}
