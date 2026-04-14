import 'package:cardabase/feature/cards/export/export_cards.dart';
import 'package:cardabase/feature/cards/export/widgets/export_button.dart';
import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/feature/settings/get_it.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:cardabase/util/string_extensions.dart';
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

  Future<void> saveCustomExportPath(String? path) async {
    final settings = settingsBox.value.editable();
    settings.customExportPath.value = path?.trim().nullWhenEmpty;
    await settingsBox.save(settings.seal());
  }

  Future<void> exportToFile() async {
    Navigator.of(context).pop();
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
              : 'ExportedexportDirectoryPathController to Custom Path',
          true,
        ),
      );
    } on NoPermissionToExternalStorageException catch (_) {
      GetIt.I<VibrationProvider>().vibrateError();
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar('No permission!', false),
      );
    }
  }

  Future<void> exportToClipboard() async {
    Navigator.of(context).pop();

    await exportCardsToClipboard(cardsBox.values);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      buildCustomSnackBar('Copied to Clipboard!', true),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        height: 210,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExportButton(
              onPressed: exportToClipboard,
              icon: const Icon(Icons.text_fields),
              label: 'TEXT',
            ),
            const SizedBox(height: 40),
            ExportButton(
              onPressed: exportToFile,
              icon: const Icon(Icons.file_copy),
              label: 'FILE',
            ),
            const SizedBox(height: 5),
            _customPathTextField(theme),
          ],
        ),
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
                icon: const Icon(Icons.clear, size: 18),
                tooltip: 'Reset to base path',
                onPressed: () async {
                  exportDirectoryPath.text = '';
                  await saveCustomExportPath('');
                },
              )
            : IconButton(
                icon: const Icon(Icons.transit_enterexit, size: 18),
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
