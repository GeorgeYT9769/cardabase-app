import 'dart:io';

import 'package:cardabase/feature/cards/import_export/import_cards.dart';
import 'package:cardabase/feature/cards/import_export/widgets/io_dialog_button.dart';
import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:cardabase/util/vibration_provider.dart';
import 'package:cardabase/util/widgets/custom_snack_bar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

Future<bool> showImportCardsDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) => const ImportDialog(),
  ).then((result) => result == true);
}

class ImportDialog extends StatefulWidget {
  const ImportDialog({super.key});

  @override
  State<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<ImportDialog> {
  final cardsBox = GetIt.I<LoyaltyCardsBox>();
  final settingsBox = GetIt.I<SettingsBox>();
  final textController = TextEditingController();

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  Future<void> onImportClicked() async {
    final input = textController.text.trim();
    if (input.isEmpty) {
      GetIt.I<VibrationProvider>().vibrateError();
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar('No data!', false),
      );
      return;
    }

    final List<LoyaltyCard> cards;
    try {
      cards = deserializeLoyaltyCards(input);
    } catch (e) {
      GetIt.I<VibrationProvider>().vibrateError();
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar('Failed to parse data!', false),
      );
      return;
    }

    if (cards.isNotEmpty) {
      await cardsBox.clear();
      await cardsBox
          .putAll(cards.asMap().map((_, value) => MapEntry(value.id, value)));
    }
    textController.text = '';

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      buildCustomSnackBar('Imported cards!', true),
    );
  }

  Future<void> importFromZipFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['cdb', 'zip'],
    );

    if (result == null || result.files.single.path == null) {
      return;
    }

    final path = result.files.single.path!;
    // Fallback: check extension manually if system picker is being difficult
    if (!path.toLowerCase().endsWith('.cdb') && !path.toLowerCase().endsWith('.zip')) {
      GetIt.I<VibrationProvider>().vibrateError();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          buildCustomSnackBar('Please select a CDB file!', false),
        );
      }
      return;
    }

    try {
      final bytes = await File(path).readAsBytes();
      final importResult = await importDataFromZip(bytes);

      if (importResult.cards.isNotEmpty) {
        await cardsBox.clear();
        await cardsBox.putAll(
          importResult.cards
              .asMap()
              .map((_, value) => MapEntry(value.id, value)),
        );
      }

      final settings = importResult.settings;
      if (settingsBox.isEmpty) {
        await settingsBox.add(settings);
      } else {
        await settingsBox.putAt(0, settings);
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar('Imported all data from CDB!', true),
      );
    } catch (e) {
      GetIt.I<VibrationProvider>().vibrateError();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          buildCustomSnackBar('Failed to import CDB: $e', false),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      scrollable: true,
      title: Text(
        'Import:',
        style: theme.textTheme.bodyLarge
            ?.copyWith(color: theme.colorScheme.inverseSurface, fontSize: 30),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _inputField(theme),
          SizedBox(height: 5),
          IODialogButton(
            onPressed: importFromZipFile,
            icon: Icon(Icons.folder_zip),
            label: 'Import CDB File',
            aboutText: 'Import all your data from one CDB file',
          ),
        ],
      ),
      actions: [
        _cancelButton(theme),
        _importButton(theme),
      ],
    );
  }

  Widget _inputField(ThemeData theme) {
    return TextField(
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
    );
  }

  Widget _cancelButton(ThemeData theme) {
    return OutlinedButton(
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
    );
  }

  Widget _importButton(ThemeData theme) {
    return OutlinedButton(
      onPressed: onImportClicked,
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
    );
  }
}
