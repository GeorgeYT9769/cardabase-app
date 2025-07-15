import 'package:cardabase/util/vibration_provider.dart';
import 'package:flutter/material.dart';
import '../data/cardabase_db.dart';// Import your CardType enum if needed

cardabase_db cdb = cardabase_db();

Future<bool> showImportDialog(BuildContext context) async {
  final TextEditingController textController = TextEditingController();

  bool imported = false;

  final result = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Import Card Data', style: TextStyle(color: Theme.of(context).colorScheme.inverseSurface, fontFamily: 'Roboto-Regular.ttf',),),
      content: SizedBox(
        width: double.maxFinite,
        child: TextField(
          controller: textController,
          maxLines: 10,
          decoration: InputDecoration(
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.inverseSurface, fontFamily: 'Roboto-Regular.ttf', fontSize: 15),
            hintText: 'This action will rewrite existing cards!\n \nPaste your Cardabase here:',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(width: 2.0)),
            focusColor: Theme.of(context).colorScheme.primary,
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.0), borderRadius: BorderRadius.circular(10)),
          ),
          style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontWeight: FontWeight.bold),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(elevation: 0.0),
          child: Text(
            'Cancel',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto-Regular.ttf',
              fontSize: 15,
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            final input = textController.text.trim();
            if (input.isEmpty) {
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

            final lines = input.split('\n');
            List<Map<String, dynamic>> newCards = [];
            int importedCount = 0;

            for (final line in lines) {
              final trimmed = line.trim();

              // Map-style: {key: value, ...}
              if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
                final cleaned = trimmed.substring(1, trimmed.length - 1); // remove { }
                final fields = cleaned.split(',').map((e) => e.trim()).toList();
                Map<String, dynamic> cardMap = {};
                for (final field in fields) {
                  final kv = field.split(':');
                  if (kv.length >= 2) {
                    final key = kv[0].trim();
                    final value = kv.sublist(1).join(':').trim(); // in case value contains ':'
                    cardMap[key] = value;
                  }
                }
                if (cardMap.isNotEmpty) {
                  try {
                    final newMap = {
                      'cardName': cardMap['cardName'] ?? '',
                      'cardId': cardMap['cardId'] ?? '',
                      'redValue': int.tryParse(cardMap['redValue'] ?? '0') ?? 0,
                      'greenValue': int.tryParse(cardMap['greenValue'] ?? '0') ?? 0,
                      'blueValue': int.tryParse(cardMap['blueValue'] ?? '0') ?? 0,
                      'cardType': cardMap['cardType'] ?? '',
                      'hasPassword': (cardMap['hasPassword']?.toLowerCase() == 'true'),
                      'uniqueId': cardMap['uniqueId'] ?? '',
                    };
                    newCards.add(newMap);
                    importedCount++;
                  } catch (e) {
                    // Optionally handle parse errors
                  }
                }
              }

              // List-style: [value, value, ...]
              else if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
                final cleaned = trimmed.substring(1, trimmed.length - 1);
                final values = cleaned.split(',').map((e) => e.trim()).toList();
                if (values.length >= 7) {
                  try {
                    final now = DateTime.now();
                    final uniqueId = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
                    final newMap = {
                      'cardName': values[0],
                      'cardId': values[1],
                      'redValue': int.tryParse(values[2]) ?? 0,
                      'greenValue': int.tryParse(values[3]) ?? 0,
                      'blueValue': int.tryParse(values[4]) ?? 0,
                      'cardType': values[5],
                      'hasPassword': values[6].toLowerCase() == 'true',
                      'uniqueId': uniqueId + importedCount.toString(),
                    };
                    newCards.add(newMap);
                    importedCount++;
                  } catch (e) {
                    // Optionally handle parse errors
                  }
                }
              }
            }

            // Replace existing cards with imported ones
            if (newCards.isNotEmpty) {
              cdb.myShops.clear();
              cdb.myShops.addAll(newCards);
              cdb.updateDataBase();
            }
            textController.text = "";

            Navigator.of(context).pop(true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)
                ),
                content: Row(
                  children: [
                    Icon(Icons.check, size: 15, color: Colors.white,),
                    SizedBox(width: 10,),
                    Text('Imported $importedCount cards!', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                duration: const Duration(milliseconds: 3000),
                padding: const EdgeInsets.all(5.0),
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                behavior: SnackBarBehavior.floating,
                dismissDirection: DismissDirection.vertical,
                backgroundColor: const Color.fromARGB(255, 92, 184, 92),
              )
            );
          },
          style: ElevatedButton.styleFrom(elevation: 0.0),
          child: Text(
            'Import',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto-Regular.ttf',
              fontSize: 15,
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ),
        ),
      ],
    ),
  );
  return result == true;
}