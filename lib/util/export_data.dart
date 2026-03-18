import 'dart:io';

import 'package:cardabase/util/vibration_provider.dart';
import 'package:cardabase/util/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

final cardBox = Hive.box('mybox');

Future<bool> requestStoragePermission() async {
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

Future<void> exportCardList(
  BuildContext context, {
  required bool toFile,
}) async {
  final theme = Theme.of(context);
  if (await requestStoragePermission() || !toFile) {
    try {
      final directory = Directory('/storage/emulated/0/Download');
      final cardList = cardBox.get('CARDLIST') as List?;
      if (cardList == null || cardList.isEmpty) {
        GetIt.I<VibrationProvider>().vibrateSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          buildCustomSnackBar('No data!', false),
        );
        return;
      }

      // Generate timestamp in yyyymmddhhmmss format
      final now = DateTime.now();
      final timestamp = '${now.year.toString().padLeft(4, '0')}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}'
          '${now.second.toString().padLeft(2, '0')}';

      final StringBuffer txtBuffer = StringBuffer();
      txtBuffer.writeln(
        'If you do not know what are you doing, please do not touch this file. One mistake and you can lose all your data! Copy everything under === line and paste them into import window.',
      );
      txtBuffer.writeln('Timestamp: $timestamp');
      txtBuffer.writeln(
        '=======================================================================',
      );
      for (final card in cardList) {
        if (card is List) {
          txtBuffer.writeln('[${card.map((e) => e.toString()).join(', ')}]');
        } else if (card is Map) {
          txtBuffer.writeln('{'
              'cardName: ${card['cardName'] ?? ''}, '
              'cardId: ${card['cardId'] ?? ''}, '
              'redValue: ${card['redValue'] ?? ''}, '
              'greenValue: ${card['greenValue'] ?? ''}, '
              'blueValue: ${card['blueValue'] ?? ''}, '
              'cardType: ${card['cardType'] ?? ''}, '
              'hasPassword: ${card['hasPassword'] ?? ''}, '
              'uniqueId: ${card['uniqueId'] ?? ''}, '
              'note: ${card['note'] ?? ''}, '
              'pointsAmount: ${card['pointsAmount'] ?? ''}'
              '}');
        }
      }

      if (toFile) {
        final filePath =
            '${directory.path}/Cardabase/Cardabase_backup_$timestamp.txt';
        final file = File(filePath);
        await file.writeAsString(txtBuffer.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          buildCustomSnackBar('Exported to Downloads', true),
        );
      } else {
        await Clipboard.setData(ClipboardData(text: txtBuffer.toString()));
        ScaffoldMessenger.of(context).showSnackBar(
          buildCustomSnackBar('Copied to Clipboard!', true),
        );
      }
    } catch (e) {
      GetIt.I<VibrationProvider>().vibrateSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar('Error!', false),
      );
    }
  } else {
    GetIt.I<VibrationProvider>().vibrateSuccess();
    ScaffoldMessenger.of(context).showSnackBar(
      buildCustomSnackBar('No permission!', false),
    );
  }
}

Future<void> showExportTypeDialog(BuildContext context) async {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      final theme = Theme.of(context);
      return AlertDialog(
        title: Text(
          'Export As:',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.inverseSurface,
            fontSize: 30,
          ),
        ),
        content: SizedBox(
          height: 150,
          child: Column(
            children: [
              OutlinedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  exportCardList(context, toFile: false);
                },
                style: OutlinedButton.styleFrom(
                  elevation: 0.0,
                  side: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.text_fields),
                    const SizedBox(width: 10),
                    Text(
                      'TEXT',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  exportCardList(context, toFile: true);
                },
                style: OutlinedButton.styleFrom(
                  elevation: 0.0,
                  side: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.file_copy),
                    const SizedBox(width: 10),
                    Text(
                      'FILE',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
