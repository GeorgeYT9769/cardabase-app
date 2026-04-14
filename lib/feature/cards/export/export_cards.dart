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

Future<void> exportCardsAsFile(Iterable<LoyaltyCard> cards) async {
  if (!await _requestStoragePermission()) {
    throw NoPermissionToExternalStorageException();
  }

  final directory = Directory('/storage/emulated/0/Download');
  final serializedCards = cards.serializeForExport();
  final timestamp = DateTime.now().toIso8601String();

  final filePath =
      '${directory.path}/Cardabase/Cardabase_backup_$timestamp.txt';
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
