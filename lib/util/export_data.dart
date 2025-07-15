import 'package:cardabase/util/vibration_provider.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
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

Future<void> exportCardList(BuildContext context) async {
  // Request storage permissions
  if (await requestStoragePermission()) {
    try {
      // Manually define the Downloads directory path for Android
      final directory = Directory('/storage/emulated/0/Download');
      if (!directory.existsSync()) {
        throw Exception("Unable to access Downloads directory.");
      }

      // Retrieve the card list from the Hive box
      final List<dynamic>? cardList = cardBox.get('CARDLIST');
      if (cardList == null || cardList.isEmpty) {
        VibrationProvider.vibrateSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)
            ),
            content: const Row(
              children: [
                Icon(Icons.error, size: 15, color: Colors.white,),
                SizedBox(width: 10,),
                Text('No data!', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
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

      // Create a text string
      final StringBuffer txtBuffer = StringBuffer();
      txtBuffer.writeln('If you don\'t know what are you doing, please don\'t touch this file');
      txtBuffer.writeln('[Shop Name, Card Number, Red, Green, Blue, Card Type, Has Password]');
      txtBuffer.writeln('=======================================================================');
      for (var card in cardList) {
        if (card is Map) {
          txtBuffer.writeln(
            '{'
            'cardName: ${card['cardName'] ?? ''}, '
            'cardId: ${card['cardId'] ?? ''}, '
            'redValue: ${card['redValue'] ?? ''}, '
            'greenValue: ${card['greenValue'] ?? ''}, '
            'blueValue: ${card['blueValue'] ?? ''}, '
            'cardType: ${card['cardType'] ?? ''}, '
            'hasPassword: ${card['hasPassword'] ?? ''}'
            'uniqueId: ${card['uniqueId'] ?? ''}'
            '}',
          );
        }
      }

      // Define the file path and write the TXT content
      final filePath = '${directory.path}/Cardabase_backup.txt';
      final file = File(filePath);
      await file.writeAsString(txtBuffer.toString());

      // Notify the user of success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)
          ),
          content: Row(
            children: [
              Icon(Icons.check, size: 15, color: Colors.white,),
              SizedBox(width: 10,),
              Text('Exported to Downloads!', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          duration: const Duration(milliseconds: 3000),
          padding: const EdgeInsets.all(5.0),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
          behavior: SnackBarBehavior.floating,
          dismissDirection: DismissDirection.vertical,
          backgroundColor: const Color.fromARGB(255, 92, 184, 92),
        ));
    } catch (e) {
      // Handle errors
      VibrationProvider.vibrateSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)
          ),
          content: const Row(
            children: [
              Icon(Icons.error, size: 15, color: Colors.white,),
              SizedBox(width: 10,),
              Text('Error!', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
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
    // Handle permission denial
    VibrationProvider.vibrateSuccess();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)
        ),
        content: const Row(
          children: [
            Icon(Icons.error, size: 15, color: Colors.white,),
            SizedBox(width: 10,),
            Text('No permission!', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
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
