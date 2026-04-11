import 'package:cardabase/data/cardabase_db.dart';
import 'package:cardabase/feature/authentication/widgets/require_password_dialog.dart';
import 'package:cardabase/feature/settings/get_it.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:cardabase/feature/settings/widgets/auto_update_settings_dialog.dart';
import 'package:cardabase/feature/settings/widgets/bug_report_dialog.dart';
import 'package:cardabase/feature/settings/widgets/card_effect_settings_dialog.dart';
import 'package:cardabase/feature/settings/widgets/clear_cards_dialog.dart';
import 'package:cardabase/feature/settings/widgets/tags_page.dart';
import 'package:cardabase/pages/cloud_backup.dart';
import 'package:cardabase/pages/info.dart';
import 'package:cardabase/pages/password.dart';
import 'package:cardabase/util/export_data.dart';
import 'package:cardabase/util/import_data.dart';
import 'package:cardabase/util/setting_tile.dart';
import 'package:cardabase/util/widgets/custom_snack_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settings = const Settings.defaultValue().editable();
  final _settingsBox = GetIt.I<SettingsBox>();
  final _cdb = CardabaseDb();

  bool didImport = false;
  bool didReset = false;
  double columnAmountDouble = 1;
  int columnAmount = 1;

  @override
  void initState() {
    super.initState();
    loadSettingsFromBox();
  }

  Future<void> loadSettingsFromBox() async {
    final settings = _settingsBox.value;
    _settings.loadValue(settings);
  }

  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> setAutoBackupsState(bool isEnabled, Duration interval) async {
    _settings.autoBackups.isEnabled.value = isEnabled;
    _settings.autoBackups.interval.value = interval;
    await _settingsBox.save(_settings.seal());
    if (!mounted) {
      return;
    }
    if (isEnabled) {
      await exportCardList(context, toFile: true);
      _settings.autoBackups.lastUpdate.value = DateTime.now().toUtc();
    }
    await _settingsBox.save(_settings.seal());
  }

  Future<void> setEffectsState(bool isEnabled, LoyaltyCardEffect effect) {
    _settings.theme.loyaltyCardEffect.isEnabled.value = isEnabled;
    _settings.theme.loyaltyCardEffect.effect.value = effect;
    return _settingsBox.save(_settings.seal());
  }

  void resetCardabase(ThemeData theme) {
    setState(() {
      _cdb.myShops.removeRange(0, _cdb.myShops.length);
      _cdb.myShops.clear();
      Hive.box('mybox').clear();
      _cdb.updateDataBase();
      didReset = true;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(buildCustomSnackBar('Cardabase was reset!', true));
    Navigator.of(context).pop(true);
  }

  Future<void> showCardEffectsDialog() async {
    final newSettings = await showDialog<LoyaltyCardEffectSettings>(
      context: context,
      builder: (context) => CardEffectSettingsDialog(
        initialValue: _settings.theme.loyaltyCardEffect.seal(),
      ),
    );
    if (newSettings != null) {
      _settings.theme.loyaltyCardEffect.loadValue(newSettings);
      await _settingsBox.save(_settings.seal());
    }
  }

  Future<void> showAutoUpdateDialog() async {
    final success = await requirePassword(context);
    if (!mounted || !success) {
      return;
    }

    final newSettings = await showDialog<AutoBackupSettings>(
      context: context,
      builder: (context) => AutoUpdateSettingsDialog(
        initialValue: _settings.autoBackups.seal(),
      ),
    );
    if (newSettings != null) {
      _settings.autoBackups.loadValue(newSettings);
      await _settingsBox.save(_settings.seal());
    }
  }

  //TODO: add fingerprint verification

  Future<void> showClearCardsDialog() async {
    final success = await requirePassword(context);
    if (!mounted || !success) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => const ClearCardsDialog(),
    );
    if (!mounted) {
      return;
    }

    if (shouldDelete == true) {
      resetCardabase(Theme.of(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop(didImport || didReset);
        }
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(
            decelerationRate: ScrollDecelerationRate.fast,
          ),
          slivers: [
            _appBar(theme),
            SliverList(
              delegate: SliverChildListDelegate([
                _subtitle(
                  theme,
                  'App Settings',
                   theme.colorScheme.inverseSurface,
                ),
                _themeSetting(theme),
                _extraDarkSetting(theme),
                _autoBrightnessSettingsButton(theme),
                _vibrationSettingsButton(theme),
                _fontSettingsButton(theme),
                _effectsButton(theme),
                _passwordButton(theme),
                _tagsButton(theme),
                _importCardsButton(theme),
                _exportCardsButton(theme),
                _cloudBackupSettingsButton(theme),
                _autoBackupSettingsButton(theme),
                const SizedBox(height: 10),
                _subtitle(
                  theme,
                  '! Danger Zone !',
                  Colors.red,
                ),
                _deleteDatabaseButton(theme),
                const SizedBox(height: 10),
                _subtitle(
                  theme,
                  'Social Networks',
                  theme.colorScheme.inverseSurface,
                ),
                _aboutButton(theme),
                _discordLink(theme),
                _bugReportButton(theme),
                _githubLink(theme),
                _fdroidLink(theme),
                _websiteLink(theme),
                //uncomment this to enable dev options in the settings
                // const SizedBox(height: 10),
                // _subtitle(
                //   theme,
                //   'Other',
                // ),
                //MySetting(
                //  aboutSettingHeader:
                //  'Toggle developer options',
                //  settingAction: toggleDeveloperOptions,
                //  settingHeader: 'DEV Options',
                //  settingIcon:Icons.developer_mode,
                //  iconColor: devOptions ? Colors.green : Colors.red,
                //  borderColor: theme.colorScheme.primary,
                //),
                const SizedBox(height: 100),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _subtitle(ThemeData theme, String title, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(top: 10, left: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 23,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _appBar(ThemeData theme) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: theme.colorScheme.secondary,
          ),
          onPressed: () => Navigator.of(context).pop(didImport || didReset),
        ),
      ],
      title: Text(
        'Settings',
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.tertiary,
        ),
      ),
      centerTitle: true,
      elevation: 0.0,
      backgroundColor: theme.colorScheme.surface,
      floating: true,
      snap: true,
    );
  }

  Widget _themeSetting(ThemeData theme) {
    return ValueListenableBuilder(
      valueListenable: _settings.theme.useDarkMode,
      builder: (context, useDarkMode, _) => MySetting(
        aboutSettingHeader: 'Switch theme between blue and white',
        settingAction: () async {
          _settings.theme.useDarkMode.value = !useDarkMode;
          await _settingsBox.save(_settings.seal());
        },
        settingHeader: 'Switch Themes',
        settingIcon: Icons.palette,
        iconColor: theme.colorScheme.tertiary,
        borderColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _extraDarkSetting(ThemeData theme) {
    return ValueListenableBuilder(
      valueListenable: _settings.theme.useExtraDark,
      builder: (context, useExtraDark, _) => MySetting(
        aboutSettingHeader: 'Use true black color for dark mode background',
        settingAction: () async {
          _settings.theme.useExtraDark.value = !useExtraDark;
          await _settingsBox.save(_settings.seal());
        },
        settingHeader: 'Extra Dark Mode',
        iconColor:
            useExtraDark ? Colors.green : Colors.red, // Indicate active state
        settingIcon: Icons.brightness_2, // Moon icon for dark mode
        borderColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _autoBrightnessSettingsButton(ThemeData theme) {
    return ValueListenableBuilder(
      valueListenable: _settings.useAutoBrightness,
      builder: (context, isEnabled, _) => MySetting(
        aboutSettingHeader: 'Automatic brightness in card details',
        settingAction: () async {
          _settings.useAutoBrightness.value = !isEnabled;
          return _settingsBox.save(_settings.seal());
        },
        settingHeader: 'AUTO Brightness',
        iconColor: isEnabled ? Colors.red : Colors.green,
        settingIcon: isEnabled ? Icons.lightbulb_outline : Icons.lightbulb,
        borderColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _vibrationSettingsButton(ThemeData theme) {
    return ValueListenableBuilder(
      valueListenable: _settings.vibrateOnDifferentActions,
      builder: (context, isEnabled, _) => MySetting(
        aboutSettingHeader: 'Vibrate on different actions',
        settingAction: () async {
          _settings.vibrateOnDifferentActions.value = !isEnabled;
          await _settingsBox.save(_settings.seal());
        },
        settingHeader: 'Vibrate',
        iconColor: isEnabled ? Colors.green : Colors.red,
        settingIcon: isEnabled ? Icons.vibration : Icons.phone_android_sharp,
        borderColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _fontSettingsButton(ThemeData theme) {
    return ValueListenableBuilder(
      valueListenable: _settings.theme.useSystemFont,
      builder: (context, useSystemFont, _) => MySetting(
        aboutSettingHeader: 'Use System font everywhere',
        settingAction: () async {
          _settings.theme.useSystemFont.value = !useSystemFont;
          await _settingsBox.save(_settings.seal());
        },
        settingHeader: 'Use System Font',
        iconColor: useSystemFont ? Colors.green : Colors.red,
        settingIcon:
            useSystemFont ? Icons.font_download : Icons.font_download_outlined,
        borderColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _effectsButton(ThemeData theme) {
    return ValueListenableBuilder(
      valueListenable: _settings.theme.loyaltyCardEffect.isEnabled,
      builder: (context, useEffects, _) => MySetting(
        aboutSettingHeader: 'Add special effects to Card Tile',
        settingAction: showCardEffectsDialog,
        settingHeader: 'Card Tile effects',
        iconColor: useEffects ? Colors.green : Colors.red,
        settingIcon: CupertinoIcons.sparkles,
        borderColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _passwordButton(ThemeData theme) {
    return MySetting(
      aboutSettingHeader: 'Protect your cards by using password',
      settingAction: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PasswordScreen()),
      ),
      settingHeader: 'Password',
      settingIcon: Icons.password,
      iconColor: theme.colorScheme.tertiary,
      borderColor: theme.colorScheme.primary,
    );
  }

  Widget _tagsButton(ThemeData theme) {
    return MySetting(
      aboutSettingHeader: 'Categorize your cards by using tags',
      settingAction: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TagsPage()),
      ),
      settingHeader: 'Tags',
      settingIcon: Icons.label,
      iconColor: theme.colorScheme.tertiary,
      borderColor: theme.colorScheme.primary,
    );
  }

  Widget _importCardsButton(ThemeData theme) {
    return MySetting(
      aboutSettingHeader: 'Load all your cards from the export',
      settingAction: () async {
        final imported = await showImportDialog(context);
        if (!mounted || imported != true) {
          return;
        }
        setState(() => didImport = true);
        Navigator.of(context).pop(true);
      },
      settingHeader: 'Import Cardabase',
      settingIcon: Icons.save_alt,
      iconColor: theme.colorScheme.tertiary,
      borderColor: theme.colorScheme.primary,
    );
  }

  Widget _exportCardsButton(ThemeData theme) {
    return MySetting(
      aboutSettingHeader: 'Backup all your cards into one file',
      settingAction: () async {
        final success = await requirePassword(context);
        if (!mounted || !success) {
          return;
        }
        await showExportTypeDialog(context);
      },
      settingHeader: 'Export Cardabase',
      settingIcon: Icons.upload,
      iconColor: theme.colorScheme.tertiary,
      borderColor: theme.colorScheme.primary,
    );
  }

  Widget _cloudBackupSettingsButton(ThemeData theme) {
    return MySetting(
      aboutSettingHeader: 'Backup your cards into self-hosted cloud storage',
      settingAction: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CloudBackup()),
      ),
      settingHeader: 'Cloud Backup',
      iconColor: Theme.of(context).colorScheme.tertiary,
      settingIcon: Icons.cloud,
      borderColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _autoBackupSettingsButton(ThemeData theme) {
    return ValueListenableBuilder(
      valueListenable: _settings.autoBackups.isEnabled,
      builder: (context, isEnabled, _) => MySetting(
        aboutSettingHeader: 'Do backups automatically on app start',
        settingAction: showAutoUpdateDialog,
        settingHeader: 'AUTO Backups',
        iconColor: isEnabled ? Colors.green : Colors.red,
        settingIcon: Icons.upload,
        borderColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _deleteDatabaseButton(ThemeData theme) {
    return MySetting(
      aboutSettingHeader: 'Remove all cards from the app',
      settingAction: () => showClearCardsDialog(),
      settingHeader: 'Delete Cardabase',
      settingIcon: Icons.delete_outline,
      iconColor: Colors.red,
      borderColor: Colors.red,
    );
  }

  Widget _aboutButton(ThemeData theme) {
    return MySetting(
      aboutSettingHeader: 'About Cardabase',
      settingAction: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const InfoScreen(),
          ),
        );
      },
      settingHeader: 'App INFO',
      settingIcon: Icons.info,
      iconColor: theme.colorScheme.tertiary,
      borderColor: theme.colorScheme.primary,
    );
  }

  Widget _discordLink(ThemeData theme) {
    return MySetting(
      aboutSettingHeader: 'Join Cardabase Discord community',
      settingAction: () => _launchUrl(
        Uri.parse('https://discord.com/invite/fZNDfG2xv3'),
      ),
      settingHeader: 'Discord',
      settingIcon: Icons.discord,
      iconColor: theme.colorScheme.tertiary,
      borderColor: theme.colorScheme.primary,
    );
  }

  Widget _bugReportButton(ThemeData theme) {
    return MySetting(
      aboutSettingHeader: 'Report a bug anonymously',
      settingAction: () => showDialog(
        context: context,
        builder: (context) => const BugReportDialog(),
      ),
      settingHeader: 'Bug report',
      settingIcon: Icons.bug_report,
      iconColor: theme.colorScheme.tertiary,
      borderColor: theme.colorScheme.primary,
    );
  }

  Widget _githubLink(ThemeData theme) {
    return MySetting(
      aboutSettingHeader: 'Visit source code of this project',
      settingAction: () => _launchUrl(
        Uri.parse('https://github.com/GeorgeYT9769/cardabase-app'),
      ),
      settingHeader: 'GitHub',
      settingIcon: Icons.code,
      iconColor: theme.colorScheme.tertiary,
      borderColor: theme.colorScheme.primary,
    );
  }

  Widget _fdroidLink(ThemeData theme) {
    return MySetting(
      aboutSettingHeader: 'Visit F-Droid page of this project',
      settingAction: () => _launchUrl(
        Uri.parse(
          'https://f-droid.org/en/packages/com.georgeyt9769.cardabase/',
        ),
      ),
      settingHeader: 'F-Droid',
      settingIcon: Icons.store,
      iconColor: theme.colorScheme.tertiary,
      borderColor: theme.colorScheme.primary,
    );
  }

  Widget _websiteLink(ThemeData theme) {
    return MySetting(
      aboutSettingHeader: 'Check out the website for this project',
      settingAction: () => _launchUrl(
        Uri.parse('https://georgeyt9769.github.io/cardabase/'),
      ),
      settingHeader: 'Website',
      settingIcon: Icons.web,
      iconColor: theme.colorScheme.tertiary,
      borderColor: theme.colorScheme.primary,
    );
  }
}
