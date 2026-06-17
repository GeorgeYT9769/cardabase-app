import 'package:cardabase/feature/cards/import_export/export_cards.dart';
import 'package:cardabase/feature/cards/import_export/widgets/io_dialog_button.dart';
import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/feature/settings/get_it.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:cardabase/util/vibration_provider.dart';
import 'package:cardabase/util/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

Future<void> showExportCardsDialog(BuildContext context) async {
  showDialog(
    context: context,
    builder: (context) => const ExportDialog(),
  );
}

class ExportDialog extends StatefulWidget {
  const ExportDialog({super.key});

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  final cardsBox = GetIt.I<LoyaltyCardsBox>();
  final settingsBox = GetIt.I<SettingsBox>();
  final exportDirectoryPath = TextEditingController();

  @override
  void initState() {
    super.initState();
    exportDirectoryPath.text = settingsBox.value.customExportPath;
  }

  @override
  void dispose() {
    exportDirectoryPath.dispose();
    super.dispose();
  }

  Future<void> saveCustomExportPath(String path) async {
    final settings = settingsBox.value.editable();
    settings.customExportPath.value = path.trim();
    await settingsBox.save(settings.seal());
  }

  Future<void> exportToFile() async {
    final dir = exportDirectoryPath.text.trim();
    try {
      await exportCardsAsFile(
        cardsBox.values,
        directoryPath: dir,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar(
          dir == Settings.defaultCardExportDirectoryPath
              ? 'Exported to Downloads'
              : 'Exported to Custom Path',
          true,
        ),
      );
    } on NoPermissionToExternalStorageException catch (_) {
      GetIt.I<VibrationProvider>().vibrateError();
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar('No permission!', false),
      );
    }
    Navigator.of(context).pop();
  }

  Future<void> exportToClipboard() async {
    await exportCardsToClipboard(cardsBox.values);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      buildCustomSnackBar('Copied to Clipboard!', true),
    );
    Navigator.of(context).pop();
  }

  Future<void> exportToZipFile() async {
    final dir = exportDirectoryPath.text.trim();
    try {
      await exportDataAsZip(
        cardsBox.values,
        settings: settingsBox.value,
        directoryPath: dir,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar(
          dir == Settings.defaultCardExportDirectoryPath
              ? 'CDB exported to Downloads'
              : 'CDB exported to Custom Path',
          true,
        ),
      );
    } on NoPermissionToExternalStorageException catch (_) {
      GetIt.I<VibrationProvider>().vibrateError();
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar('No permission!', false),
      );
    } catch (e) {
      GetIt.I<VibrationProvider>().vibrateError();
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar('Export failed: $e', false),
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      scrollable: true,
      title: Text(
        'Export:',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.inverseSurface,
          fontSize: 30,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IODialogButton(
            onPressed: exportToClipboard,
            icon: const Icon(Icons.text_fields),
            label: 'TEXT',
            aboutText: 'Export cards as plain text into your clipboard',
          ),
          const SizedBox(height: 40),
          IODialogButton(
            onPressed: exportToFile,
            icon: const Icon(Icons.file_copy),
            label: 'FILE',
            aboutText: 'Export cards as a single file',
          ),
          const SizedBox(height: 5),
          IODialogButton(
            onPressed: exportToZipFile,
            icon: const Icon(Icons.folder_zip),
            label: 'CDB FILE',
            aboutText: 'Export cards and all other stuff as a CDB file',
          ),
          const SizedBox(height: 5),
          _customPathTextField(theme),
        ],
      ),
    );
  }

  Widget _customPathTextField(ThemeData theme) {
    return TextField(
      controller: exportDirectoryPath,
      onChanged: saveCustomExportPath,
      style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
      decoration: InputDecoration(
        hintText: Settings.defaultCardExportDirectoryPath,
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
        suffixIcon: exportDirectoryPath.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, size: 18, color: theme.colorScheme.primary,),
                tooltip: 'Reset to base path',
                onPressed: () async {
                  exportDirectoryPath.text = '';
                  await saveCustomExportPath('');
                },
              )
            : IconButton(
                icon: Icon(Icons.transit_enterexit, size: 18, color: theme.colorScheme.primary,),
                tooltip: 'Set default custom path',
                onPressed: () async {
                  exportDirectoryPath.text =
                      Settings.defaultCardExportDirectoryPath;
                  await saveCustomExportPath(
                    Settings.defaultCardExportDirectoryPath,
                  );
                },
              ),
      ),
    );
  }
}
