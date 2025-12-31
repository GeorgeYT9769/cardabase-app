import 'package:cardabase/util/vibration_provider.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

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

Future<void> exportCardList(BuildContext context, {required bool toFile}) async {
  if (await requestStoragePermission() || !toFile) {
    try {
      final directory = Directory('/storage/emulated/0/Download');
      final List<dynamic>? cardList = cardBox.get('CARDLIST');
      if (cardList == null || cardList.isEmpty) {
        VibrationProvider.vibrateSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)
            ),
            content: Row(
              children: [
                Icon(Icons.error, size: 15, color: Colors.white,),
                SizedBox(width: 10,),
                Text('No data!', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            duration: const Duration(milliseconds: 3000),
            padding: const EdgeInsets.all(5.0),
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
            behavior: SnackBarBehavior.floating,
            dismissDirection: DismissDirection.vertical,
            backgroundColor: const Color.fromARGB(255, 237, 67, 55),
          ));
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
      txtBuffer.writeln('If you do not know what are you doing, please do not touch this file. One mistake and you can lose all your data! Copy everything under === line and paste them into import window.');
      txtBuffer.writeln('Timestamp: $timestamp');
      txtBuffer.writeln('=======================================================================');
      for (var card in cardList) {
        if (card is List) {
          txtBuffer.writeln('[${card.map((e) => e.toString()).join(', ')}]');
        } else if (card is Map) {
          txtBuffer.writeln(
            '{'
            'cardName: ${card['cardName'] ?? ''}, '
            'cardId: ${card['cardId'] ?? ''}, '
            'redValue: ${card['redValue'] ?? ''}, '
            'greenValue: ${card['greenValue'] ?? ''}, '
            'blueValue: ${card['blueValue'] ?? ''}, '
            'cardType: ${card['cardType'] ?? ''}, '
            'hasPassword: ${card['hasPassword'] ?? ''}, '
            'uniqueId: ${card['uniqueId'] ?? ''}, '
            'note: ${card['note'] ?? ''}, '
            '}');
        }
      }

      if (toFile) {
        final filePath = '${directory.path}/Cardabase_backup_$timestamp.txt';
        final file = File(filePath);
        await file.writeAsString(txtBuffer.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)
            ),
            content: Row(
              children: [
                Icon(Icons.check, size: 15, color: Colors.white,),
                SizedBox(width: 10,),
                Text('Exported to Downloads!', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            duration: const Duration(milliseconds: 3000),
            padding: const EdgeInsets.all(5.0),
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
            behavior: SnackBarBehavior.floating,
            dismissDirection: DismissDirection.vertical,
            backgroundColor: const Color.fromARGB(255, 92, 184, 92),
          ));
      } else {
        await Clipboard.setData(ClipboardData(text: txtBuffer.toString()));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)
            ),
            content: Row(
              children: [
                Icon(Icons.copy, size: 15, color: Colors.white,),
                SizedBox(width: 10,),
                Text('Copied to clipboard!', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            duration: const Duration(milliseconds: 3000),
            padding: const EdgeInsets.all(5.0),
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
            behavior: SnackBarBehavior.floating,
            dismissDirection: DismissDirection.vertical,
            backgroundColor: const Color.fromARGB(255, 92, 184, 92),
          ));
      }
    } catch (e) {
      VibrationProvider.vibrateSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)
          ),
          content: Row(
            children: [
              Icon(Icons.error, size: 15, color: Colors.white,),
              SizedBox(width: 10,),
              Text('Error!', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          duration: const Duration(milliseconds: 3000),
          padding: const EdgeInsets.all(5.0),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
          behavior: SnackBarBehavior.floating,
          dismissDirection: DismissDirection.vertical,
          backgroundColor: const Color.fromARGB(255, 237, 67, 55),
        ));
    }
  } else {
    VibrationProvider.vibrateSuccess();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)
        ),
        content: Row(
          children: [
            Icon(Icons.error, size: 15, color: Colors.white,),
            SizedBox(width: 10,),
            Text('No permission!', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        duration: const Duration(milliseconds: 3000),
        padding: const EdgeInsets.all(5.0),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.vertical,
        backgroundColor: const Color.fromARGB(255, 237, 67, 55),
      ));
  }
}

Future<void> showExportTypeDialog(BuildContext context) async {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text('Export As:', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.inverseSurface, fontSize: 30)),
        content: SizedBox(
          height: 150,
          child: ListView(
            children: [
              OutlinedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  exportCardList(context, toFile: false);
                },
                style: OutlinedButton.styleFrom(elevation: 0.0, side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.text_fields),
                    SizedBox(width: 10),
                    Text(
                      'TEXT',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  exportCardList(context, toFile: true);
                },
                style: OutlinedButton.styleFrom(elevation: 0.0, side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.file_copy),
                    SizedBox(width: 10),
                    Text(
                      'FILE',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
