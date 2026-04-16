import 'dart:io';

import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:flutter/services.dart';
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

  final serializedCards = cards.serializeForExport();
  final now = DateTime.now();
  final strTimestamp =
      '${now.year}${now.month}${now.day}_${now.hour}${now.minute}${now.second}';

  final filePath = '${directory.path}/Cardabase_backup_$strTimestamp.txt';
  final file = File(filePath);
  await file.writeAsString(serializedCards);
}

Future<void> exportCardsToClipboard(Iterable<LoyaltyCard> cards) async {
  final serializedCards = cards.serializeForExport();
  await Clipboard.setData(ClipboardData(text: serializedCards));
}

// ------------------------------------------------------
// EXCEPTIONS
// ------------------------------------------------------

class NoPermissionToExternalStorageException implements Exception {}
