import 'package:cardabase/data/cardabase_db.dart';
import 'package:cardabase/util/vibration_provider.dart';
import 'package:cardabase/util/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

CardabaseDb cdb = CardabaseDb();

Future<bool> showImportDialog(BuildContext context) async {
  final theme = Theme.of(context);
  final TextEditingController textController = TextEditingController();

  final result = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Import Card Data',
        style: theme.textTheme.bodyLarge
            ?.copyWith(color: theme.colorScheme.inverseSurface, fontSize: 30),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: TextField(
          controller: textController,
          maxLines: 10,
          decoration: InputDecoration(
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.inverseSurface,
              fontSize: 15,
            ),
            hintText:
                'This action will rewrite existing cards!\n \nPaste your Cardabase here:',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(width: 2.0),
            ),
            focusColor: theme.colorScheme.primary,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: theme.colorScheme.primary),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.tertiary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            elevation: 0.0,
            side: BorderSide(color: theme.colorScheme.primary, width: 2.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
          child: Text(
            'Cancel',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: theme.colorScheme.tertiary,
            ),
          ),
        ),
        OutlinedButton(
          onPressed: () {
            final input = textController.text.trim();
            if (input.isEmpty) {
              GetIt.I<VibrationProvider>().vibrateError();
              ScaffoldMessenger.of(context).showSnackBar(
                buildCustomSnackBar('No data!', false),
              );
              return;
            }

            final lines = input.split('\n');
            final List<Map<String, dynamic>> newCards = [];
            int importedCount = 0;

            for (final line in lines) {
              final trimmed = line.trim();

              if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
                final cleaned =
                    trimmed.substring(1, trimmed.length - 1); // remove { }
                final fields = cleaned.split(',').map((e) => e.trim()).toList();
                final Map<String, dynamic> cardMap = {};
                for (final field in fields) {
                  final kv = field.split(':');
                  if (kv.length >= 2) {
                    final key = kv[0].trim();
                    final value = kv.sublist(1).join(':').trim();
                    cardMap[key] = value;
                  }
                }
                if (cardMap.isNotEmpty) {
                  try {
                    final now = DateTime.now();
                    final uniqueId =
                        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
                    final newMap = {
                      'cardName': cardMap['cardName'] ?? '',
                      'cardId': cardMap['cardId'] ?? '',
                      'redValue':
                          int.tryParse(cardMap['redValue'] as String? ?? '0') ??
                              0,
                      'greenValue': int.tryParse(
                            cardMap['greenValue'] as String? ?? '0',
                          ) ??
                          0,
                      'blueValue': int.tryParse(
                            cardMap['blueValue'] as String? ?? '0',
                          ) ??
                          0,
                      'cardType': cardMap['cardType'] ?? '',
                      'hasPassword':
                          ((cardMap['hasPassword'] as String?)?.toLowerCase() ==
                              'true'),
                      'uniqueId': uniqueId + importedCount.toString(),
                      'note': cardMap['note'] ?? '',
                      'pointsAmount': int.tryParse(
                            cardMap['pointsAmount'] as String? ?? '0',
                          ) ??
                          0,
                    };
                    newCards.add(newMap);
                    importedCount++;
                  } catch (e) {
                    // Optionally handle parse errors
                  }
                }
              } else if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
                final cleaned = trimmed.substring(1, trimmed.length - 1);
                final values = cleaned.split(',').map((e) => e.trim()).toList();
                if (values.length >= 7) {
                  try {
                    final now = DateTime.now();
                    final uniqueId =
                        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
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
                    // parse errors
                  }
                }
              }
            }

            if (newCards.isNotEmpty) {
              cdb.myShops.clear();
              cdb.myShops.addAll(newCards);
              cdb.updateDataBase();
            }
            textController.text = '';

            Navigator.of(context).pop(true);
            ScaffoldMessenger.of(context).showSnackBar(
              buildCustomSnackBar(
                'Imported $importedCount cards!',
                true,
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            elevation: 0.0,
            side: BorderSide(color: theme.colorScheme.primary, width: 2.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
          child: Text(
            'Import',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: theme.colorScheme.tertiary,
            ),
          ),
        ),
      ],
    ),
  );
  return result == true;
}
