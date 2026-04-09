import 'dart:io';

import 'package:cardabase/feature/settings/get_it.dart';
import 'package:cardabase/feature/settings/model.dart';
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
  String? customPath,
}) async {
  if (await requestStoragePermission() || !toFile) {
    try {
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
        final exportDir =
            (customPath != null && customPath.isNotEmpty)
                ? customPath
                : '/storage/emulated/0/Download/Cardabase';

        final directory = Directory(exportDir);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        final filePath = '$exportDir/Cardabase_backup_$timestamp.txt';
        final file = File(filePath);
        await file.writeAsString(txtBuffer.toString());

        final label =
            (customPath != null && customPath.isNotEmpty)
                ? 'Exported to Custom Path'
                : 'Exported to Downloads';
        ScaffoldMessenger.of(context).showSnackBar(
          buildCustomSnackBar(label, true),
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
    builder: (BuildContext dialogContext) =>
        _ExportDialog(parentContext: context),
  );
}

class _ExportDialog extends StatefulWidget {
  const _ExportDialog({required this.parentContext});

  final BuildContext parentContext;

  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  late final TextEditingController _pathController;
  final _settingsBox = GetIt.I<SettingsBox>();

  @override
  void initState() {
    super.initState();
    _pathController = TextEditingController(
      text: _settingsBox.value.customExportPath ?? '',
    );
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _savePath(String path) async {
    final current = _settingsBox.value;
    await _settingsBox.save(
      Settings(
        lastSeenAppVersion: current.lastSeenAppVersion,
        autoBackups: current.autoBackups,
        theme: current.theme,
        developerOptions: current.developerOptions,
        useAutoBrightness: current.useAutoBrightness,
        vibrateOnDifferentActions: current.vibrateOnDifferentActions,
        tags: current.tags,
        cardListViewOptions: current.cardListViewOptions,
        customExportPath: path.isEmpty ? null : path,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final buttonStyle = OutlinedButton.styleFrom(
      elevation: 0.0,
      side: BorderSide(color: theme.colorScheme.primary, width: 2.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
    );

    final labelStyle = theme.textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.bold,
      fontSize: 15,
    );

    return AlertDialog(
      title: Text(
        'Export As:',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.inverseSurface,
          fontSize: 30,
        ),
      ),
      content: SizedBox(
        height: 210,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                exportCardList(widget.parentContext, toFile: false);
              },
              style: buttonStyle,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.text_fields),
                  const SizedBox(width: 10),
                  Text('TEXT', style: labelStyle),
                ],
              ),
            ),
            const SizedBox(height: 15),
            OutlinedButton(
              onPressed: () {
                final path = _pathController.text.trim();
                Navigator.of(context).pop();
                exportCardList(
                  widget.parentContext,
                  toFile: true,
                  customPath: path.isEmpty ? null : path,
                );
              },
              style: buttonStyle,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.file_copy),
                  const SizedBox(width: 10),
                  Text('FILE', style: labelStyle),
                ],
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _pathController,
              onChanged: (value) => _savePath(value.trim()),
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
              decoration: InputDecoration(
                hintText: '/storage/emulated/0/SomeDir/...',
                hintStyle: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: theme.colorScheme.outline,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2.0,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2.0,
                  ),
                ),
                suffixIcon: _pathController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      tooltip: 'Clear custom path',
                      onPressed: () async {
                        setState(() => _pathController.clear());
                        await _savePath('');
                      },
                    )
                  : IconButton(
                      icon: const Icon(Icons.transit_enterexit, size: 18),
                      tooltip: 'Set default custom path',
                      onPressed: () async {
                        setState(() => _pathController.text = '/storage/emulated/0/');
                        await _savePath('/storage/emulated/0/');
                      },
                  ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
