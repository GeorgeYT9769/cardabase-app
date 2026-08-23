import 'dart:io';

import 'package:cardabase/feature/cards/import_export/export_cards.dart';
import 'package:cardabase/feature/cards/import_export/import_cards.dart';
import 'package:cardabase/feature/cards/import_export/widgets/io_dialog_button.dart';
import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/feature/settings/editable_model.dart';
import 'package:cardabase/feature/settings/get_it.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:cardabase/util/vibration_provider.dart';
import 'package:cardabase/util/widgets/cdb_app_bar_sliver.dart';
import 'package:cardabase/util/widgets/custom_snack_bar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class ImportExportPage extends StatefulWidget {
  const ImportExportPage({super.key});

  @override
  State<ImportExportPage> createState() => _ImportExportPageState();
}

class _ImportExportPageState extends State<ImportExportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final cardsBox = GetIt.I<LoyaltyCardsBox>();
  final settingsBox = GetIt.I<SettingsBox>();

  // Import state
  final importTextController = TextEditingController();

  // Export state
  final exportDirectoryPath = TextEditingController();
  bool includeCards = true;
  bool includeSettings = true;
  bool includeImages = true;

  // Auto Backup state
  late final EditableAutoBackupSettings _autoBackupSettings;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    exportDirectoryPath.text = settingsBox.value.customExportPath;
    _autoBackupSettings =
        EditableAutoBackupSettings.fromValue(settingsBox.value.autoBackups);
  }

  @override
  void dispose() {
    _tabController.dispose();
    importTextController.dispose();
    exportDirectoryPath.dispose();
    super.dispose();
  }

  Future<void> onImportTextClicked() async {
    final input = importTextController.text.trim();
    if (input.isEmpty) {
      GetIt.I<VibrationProvider>().vibrateError();
      showCustomSnackBar(context, 'No data!', false);
      return;
    }

    final List<LoyaltyCard> cards;
    try {
      cards = deserializeLoyaltyCards(input);
    } catch (e) {
      GetIt.I<VibrationProvider>().vibrateError();
      showCustomSnackBar(context, 'Failed to parse data!', false);
      return;
    }

    if (cards.isNotEmpty) {
      await cardsBox.clear();
      await cardsBox
          .putAll(cards.asMap().map((_, value) => MapEntry(value.id, value)));
    }
    importTextController.text = '';

    if (!mounted) return;
    showCustomSnackBar(context, 'Imported cards!', true);
    Navigator.of(context).pop(true);
  }

  Future<void> importFromZipFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['cdb', 'zip'],
    );

    if (result == null || result.files.single.path == null) return;

    final path = result.files.single.path!;
    if (!path.toLowerCase().endsWith('.cdb') &&
        !path.toLowerCase().endsWith('.zip')) {
      GetIt.I<VibrationProvider>().vibrateError();
      if (mounted) showCustomSnackBar(context, 'Please select a CDB file!', false);
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
      final currentSettings = settingsBox.value.editable();
      currentSettings.loadValue(settings);
      await settingsBox.save(currentSettings.seal());

      if (!mounted) return;
      showCustomSnackBar(context, 'Imported all data from CDB!', true);
      Navigator.of(context).pop(true);
    } catch (e) {
      GetIt.I<VibrationProvider>().vibrateError();
      if (mounted) showCustomSnackBar(context, 'Failed to import CDB: $e', false);
    }
  }

  Future<void> exportToClipboard() async {
    await exportCardsToClipboard(cardsBox.values);
    if (!mounted) return;
    showCustomSnackBar(context, 'Copied to Clipboard!', true);
  }

  Future<void> exportToFile() async {
    final dir = exportDirectoryPath.text.trim();
    try {
      await exportCardsAsFile(
        cardsBox.values,
        directoryPath: dir,
      );
      if (!mounted) return;
      showCustomSnackBar(
        context,
        dir == Settings.defaultCardExportDirectoryPath
            ? 'Exported to Downloads'
            : 'Exported to Custom Path',
        true,
      );
    } on NoPermissionToExternalStorageException catch (_) {
      GetIt.I<VibrationProvider>().vibrateError();
      showCustomSnackBar(context, 'No permission!', false);
    }
  }

  Future<void> exportToCdbFile() async {
    final dir = exportDirectoryPath.text.trim();
    try {
      await exportDataAsZip(
        cardsBox.values,
        settings: settingsBox.value,
        directoryPath: dir,
        includeCards: includeCards,
        includeSettings: includeSettings,
        includeImages: includeImages,
      );
      if (!mounted) return;
      showCustomSnackBar(
        context,
        dir == Settings.defaultCardExportDirectoryPath
            ? 'CDB exported to Downloads'
            : 'CDB exported to Custom Path',
        true,
      );
    } on NoPermissionToExternalStorageException catch (_) {
      GetIt.I<VibrationProvider>().vibrateError();
      showCustomSnackBar(context, 'No permission!', false);
    } catch (e) {
      GetIt.I<VibrationProvider>().vibrateError();
      showCustomSnackBar(context, 'Export failed: $e', false);
    }
  }

  Future<void> saveCustomExportPath(String path) async {
    final settings = settingsBox.value.editable();
    settings.customExportPath.value = path.trim();
    await settingsBox.save(settings.seal());
  }

  Future<void> saveAutoBackupSettings() async {
    final settings = settingsBox.value.editable();
    settings.autoBackups.loadValue(_autoBackupSettings.seal());
    await settingsBox.save(settings.seal());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            CdbAppBarSliver(
              title: 'Import & Export',
              onBackPressed: () => Navigator.of(context).pop(),
            ),
            SliverToBoxAdapter(
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'IMPORT', icon: Icon(Icons.download)),
                  Tab(text: 'EXPORT', icon: Icon(Icons.upload)),
                ],
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.tertiary,
                indicatorColor: theme.colorScheme.primary,
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _importTab(theme),
            _exportTab(theme),
          ],
        ),
      ),
    );
  }

  Widget _importTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: importTextController,
            maxLines: 8,
            decoration: InputDecoration(
              hintText:
                  'This action will rewrite existing cards!\n\nPaste your Cardabase JSON here:',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.colorScheme.primary),
              ),
            ),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.tertiary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: onImportTextClicked,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: BorderSide(color: theme.colorScheme.primary, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            child: const Text('IMPORT FROM TEXT'),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          IODialogButton(
            onPressed: importFromZipFile,
            icon: const Icon(Icons.folder_zip),
            label: 'IMPORT CDB FILE',
            aboutText: 'Import all your data from one CDB file',
          ),
        ],
      ),
    );
  }

  Widget _exportTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(theme, 'What to include:'),
          CheckboxListTile(
            title: const Text('Cards Data'),
            value: includeCards,
            onChanged: (val) => setState(() => includeCards = val ?? true),
            activeColor: theme.colorScheme.primary,
          ),
          CheckboxListTile(
            title: const Text('Settings'),
            value: includeSettings,
            onChanged: (val) => setState(() => includeSettings = val ?? true),
            activeColor: theme.colorScheme.primary,
          ),
          CheckboxListTile(
            title: const Text('Pictures'),
            value: includeImages,
            onChanged: (val) => setState(() => includeImages = val ?? true),
            activeColor: theme.colorScheme.primary,
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          _sectionTitle(theme, 'Export to:'),
          const SizedBox(height: 10),
          IODialogButton(
            onPressed: exportToClipboard,
            icon: const Icon(Icons.copy),
            label: 'CLIPBOARD',
            aboutText: 'Export cards as plain text into your clipboard',
          ),
          const SizedBox(height: 10),
          IODialogButton(
            onPressed: exportToFile,
            icon: const Icon(Icons.file_copy),
            label: 'JSON FILE',
            aboutText: 'Export cards as a single JSON file',
          ),
          const SizedBox(height: 10),
          IODialogButton(
            onPressed: exportToCdbFile,
            icon: const Icon(Icons.folder_zip),
            label: 'CDB FILE',
            aboutText: 'Export selected data as a CDB file',
          ),
          const SizedBox(height: 20),
          _customPathTextField(theme),
          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 20),
          _sectionTitle(theme, 'Auto Backups:'),
          const SizedBox(height: 10),
          _autoBackupSettingsUI(theme),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    );
  }

  Widget _customPathTextField(ThemeData theme) {
    return TextField(
      controller: exportDirectoryPath,
      onChanged: saveCustomExportPath,
      style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
      decoration: InputDecoration(
        labelText: 'Custom Export Path',
        hintText: Settings.defaultCardExportDirectoryPath,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear, size: 18),
          onPressed: () {
            exportDirectoryPath.text = '';
            saveCustomExportPath('');
          },
        ),
      ),
    );
  }

  Widget _autoBackupSettingsUI(ThemeData theme) {
    return ValueListenableBuilder(
      valueListenable: _autoBackupSettings.isEnabled,
      builder: (context, isEnabled, _) => Column(
        children: [
          SwitchListTile(
            title: const Text('Enable Auto Backups'),
            subtitle: const Text('Backups are made on app start'),
            value: isEnabled,
            onChanged: (val) {
              _autoBackupSettings.isEnabled.value = val;
              saveAutoBackupSettings();
            },
            activeColor: theme.colorScheme.primary,
          ),
          if (isEnabled) ...[
            const SizedBox(height: 10),
            ValueListenableBuilder(
              valueListenable: _autoBackupSettings.interval,
              builder: (context, interval, _) => Column(
                children: [
                  Text('Interval: ${interval.inDays} days'),
                  Slider(
                    year2023: false,
                    value: interval.inDays.toDouble(),
                    min: 1,
                    max: 365,
                    divisions: 364,
                    label: '${interval.inDays} days',
                    activeColor: theme.colorScheme.primary,
                    onChanged: (val) {
                      _autoBackupSettings.interval.value =
                          Duration(days: val.round());
                    },
                    onChangeEnd: (val) => saveAutoBackupSettings(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
