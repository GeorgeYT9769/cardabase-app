import 'package:cardabase/feature/authentication/widgets/require_password_dialog.dart';
import 'package:cardabase/feature/cards/import_export/import_export_page.dart';
import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/feature/settings/get_it.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:cardabase/feature/settings/widgets/auto_update_settings_dialog.dart';
import 'package:cardabase/feature/settings/widgets/card_effect_settings_dialog.dart';
import 'package:cardabase/feature/settings/widgets/clear_cards_dialog.dart';
import 'package:cardabase/feature/settings/widgets/tags_page.dart';
import 'package:cardabase/pages/cloud_backup.dart';
import 'package:cardabase/pages/dev_tools.dart';
import 'package:cardabase/pages/info.dart';
import 'package:cardabase/pages/password.dart';
import 'package:cardabase/pages/terms_of_service.dart';
import 'package:cardabase/util/setting_tile.dart';
import 'package:cardabase/util/vibration_provider.dart';
import 'package:cardabase/util/widgets/cdb_app_bar_sliver.dart';
import 'package:cardabase/util/widgets/custom_snack_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../cards/import_export/export_cards.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settings = const Settings.defaultValue().editable();
  final _settingsBox = GetIt.I<SettingsBox>();

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
      final cards = GetIt.I<LoyaltyCardsBox>().values;
      try {
        await exportCardsAsFile(
          cards,
          directoryPath: _settingsBox.value.customExportPath,
        );
        _settings.autoBackups.lastUpdate.value = DateTime.now().toUtc();
      } on NoPermissionToExternalStorageException catch (_) {
        GetIt.I<VibrationProvider>().vibrateError();
        if (!mounted) {
          return;
        }
        showCustomSnackBar(context, 'No permission!', false);
      }
    }
    await _settingsBox.save(_settings.seal());
  }

  Future<void> setEffectsState(bool isEnabled, LoyaltyCardEffect effect) {
    _settings.theme.loyaltyCardEffect.isEnabled.value = isEnabled;
    _settings.theme.loyaltyCardEffect.effect.value = effect;
    return _settingsBox.save(_settings.seal());
  }

  Future<void> resetCardabase(ThemeData theme) async {
    await GetIt.I<LoyaltyCardsBox>().clear();
    if (!mounted) {
      return;
    }
    showCustomSnackBar(context, 'Cardabase was reset!', true);
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
            CdbAppBarSliver(
              title: 'Settings',
              onBackPressed: () =>
                  Navigator.of(context).pop(didImport || didReset),
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                _subtitle(
                  theme,
                  'App Settings',
                  theme.colorScheme.inverseSurface,
                ),
                _themeSetting(theme),
                _extraDarkSetting(theme),
                _backButtonSwitch(theme),
                _autoBrightnessSettingsButton(theme),
                _vibrationSettingsButton(theme),
                _fontSettingsButton(theme),
                _effectsButton(theme),
                _passwordButton(theme),
                _tagsButton(theme),
                _backupRestoreButton(theme),
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
                  'About',
                  theme.colorScheme.inverseSurface,
                ),
                _aboutButton(theme),
                _tosButton(theme),
                _keepAndroidOpen(theme),
                _discordLink(theme),
                _kofiLink(theme),
                _buymeacoffeeLink(theme),
                _githubLink(theme),
                _fdroidLink(theme),
                _websiteLink(theme),
                ValueListenableBuilder(
                  valueListenable: _settings.developerOptions.isEnabled,
                  builder: (context, isEnabled, _) {
                    if (!isEnabled) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        _subtitle(
                          theme,
                          'Tools',
                          theme.colorScheme.inverseSurface,
                        ),
                        _debugButton(theme),
                        _devToolsButton(theme),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _devToolsButton(ThemeData theme) {
    return SettingTile(
      aboutSettingHeader: 'App insights and developer utilities',
      settingAction: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DevToolsPage()),
      ),
      settingHeader: 'Developer Tools',
      settingIcon: Icons.developer_mode,
      iconColor: theme.colorScheme.tertiary,
      borderColor: theme.colorScheme.primary,
      showMore: true,
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

  Widget _themeSetting(ThemeData theme) {
    return ValueListenableBuilder(
      valueListenable: _settings.theme.useDarkMode,
      builder: (context, useDarkMode, _) => SettingTile(
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
      builder: (context, useExtraDark, _) => SettingTile(
        aboutSettingHeader: 'Use true black color for dark mode background',
        settingAction: () async {
          _settings.theme.useExtraDark.value = !useExtraDark;
          await _settingsBox.save(_settings.seal());
        },
        settingHeader: 'Extra Dark Mode',
        iconColor:
            useExtraDark ? Colors.green : Colors.red,
        settingIcon: Icons.brightness_2,
        borderColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _backButtonSwitch(ThemeData theme) {
    return ValueListenableBuilder(
      valueListenable: _settings.theme.rightBackButton,
      builder: (context, rightBackButton, _) => SettingTile(
        aboutSettingHeader: 'Switch back button on the right side',
        settingAction: () async {
          _settings.theme.rightBackButton.value = !rightBackButton;
          await _settingsBox.save(_settings.seal());
        },
        settingHeader: 'Right Back Button',
        settingIcon: Icons.arrow_back_ios_new,
        iconColor: rightBackButton ? Colors.green : Colors.red,
        borderColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _advancedTextures(ThemeData theme) {
    return ValueListenableBuilder(
      valueListenable: _settings.theme.advancedTextures,
      builder: (context, useAdvancedTextures, _) => SettingTile(
        aboutSettingHeader: 'Use advanced textures for some widgets. Might cause performance issues.',
        settingAction: () async {
          _settings.theme.advancedTextures.value = !useAdvancedTextures;
          await _settingsBox.save(_settings.seal());
        },
        settingHeader: 'Advanced Textures',
        settingIcon: Icons.texture,
        iconColor: useAdvancedTextures ? Colors.green : Colors.red,
        borderColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _autoBrightnessSettingsButton(ThemeData theme) {
    return ValueListenableBuilder(
      valueListenable: _settings.useAutoBrightness,
      builder: (context, isEnabled, _) => SettingTile(
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
      builder: (context, isEnabled, _) => SettingTile(
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
      builder: (context, useSystemFont, _) => SettingTile(
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
      builder: (context, useEffects, _) => SettingTile(
        aboutSettingHeader: 'Add special effects to Card Tile',
        settingAction: showCardEffectsDialog,
        settingHeader: 'Card Tile effects',
        iconColor: useEffects ? Colors.green : Colors.red,
        settingIcon: CupertinoIcons.sparkles,
        borderColor: theme.colorScheme.primary,
        showMore: true,
      ),
    );
  }

  Widget _passwordButton(ThemeData theme) {
    return SettingTile(
      aboutSettingHeader: 'Protect your cards by using a password',
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
    return SettingTile(
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

  Widget _backupRestoreButton(ThemeData theme) {
    return SettingTile(
      aboutSettingHeader: 'Backup or restore your cards and settings',
      settingAction: () async {
        final success = await requirePassword(context);
        if (!mounted || !success) {
          return;
        }
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ImportExportPage()),
        );
        if (result == true) {
          setState(() => didImport = true);
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        }
      },
      settingHeader: 'Backup/Restore',
      settingIcon: Icons.import_export,
      iconColor: theme.colorScheme.tertiary,
      borderColor: theme.colorScheme.primary,
      showMore: true,
    );
  }

  Widget _deleteDatabaseButton(ThemeData theme) {
    return SettingTile(
      aboutSettingHeader: 'Remove all cards from the app',
      settingAction: () => showClearCardsDialog(),
      settingHeader: 'Delete Cardabase',
      settingIcon: Icons.delete_outline,
      iconColor: Colors.red,
      borderColor: Colors.red,
      textColor: Colors.red,
    );
  }

  //for debug use
  Widget _debugButton(ThemeData theme) {
    return ValueListenableBuilder(
      valueListenable: _settings.developerOptions.isEnabled,
      builder: (context, isEnabled, _) => SettingTile(
        aboutSettingHeader: 'Debug some actions',
        settingAction: () async {
          _settings.developerOptions.isEnabled.value = !isEnabled;
          await _settingsBox.save(_settings.seal());
        },
        settingHeader: 'Developer options',
        iconColor: isEnabled ? Colors.green : Colors.red,
        settingIcon: isEnabled ? Icons.phonelink_setup : Icons.phonelink_setup,
        borderColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _aboutButton(ThemeData theme) {
    return SettingTile(
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

  Widget _tosButton(ThemeData theme) {
    return SettingTile(
      aboutSettingHeader: 'Legal terms and conditions',
      settingAction: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TermsOfServicePage(),
          ),
        );
      },
      settingHeader: 'Terms of Service',
      settingIcon: Icons.gavel,
      iconColor: theme.colorScheme.tertiary,
      borderColor: theme.colorScheme.primary,
    );
  }

  Widget _keepAndroidOpen(ThemeData theme) {
    return SettingTile(
      aboutSettingHeader: 'Your phone is about to stop being yours.',
      settingAction: () => _launchUrl(
        Uri.parse('https://keepandroidopen.org/'),
      ),
      settingHeader: 'Keep Android Open',
      settingIcon: Icons.android,
      iconColor: Color.fromARGB(255, 58, 221, 133),
      borderColor: theme.colorScheme.primary,
    );
  }

  Widget _discordLink(ThemeData theme) {
    return SettingTile(
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

  Widget _kofiLink(ThemeData theme) {
    return SettingTile(
      aboutSettingHeader: 'Support Cardabase development using Ko-fi.com',
      settingAction: () => _launchUrl(
        Uri.parse('https://ko-fi.com/georgeyt9769'),
      ),
      settingHeader: 'Ko-fi',
      settingIcon: Icons.monetization_on,
      iconColor: Color(0xff579fbf),
      borderColor: Color(0xff579fbf),
    );
  }

  Widget _buymeacoffeeLink(ThemeData theme) {
    return SettingTile(
      aboutSettingHeader: 'Support Cardabase development using buymeacoffee.com',
      settingAction: () => _launchUrl(
        Uri.parse('https://www.buymeacoffee.com/georgeyt9769'),
      ),
      settingHeader: 'Buy Me a Coffee',
      settingIcon: Icons.monetization_on,
      iconColor: Color(0xffe8ca04),
      borderColor: Color(0xffe8ca04),
    );
  }

  Widget _githubLink(ThemeData theme) {
    return SettingTile(
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
    return SettingTile(
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
    return SettingTile(
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
