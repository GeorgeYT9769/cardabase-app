import 'package:cardabase/data/hive_type_ids.dart';
import 'package:cardabase/feature/settings/editable_model.dart';
import 'package:hive_ce/hive.dart';

part 'model.g.dart';

typedef SettingsBox = Box<Settings>;

@HiveType(typeId: HiveTypeIds.settings)
class Settings {
  const Settings({
    required this.lastSeenAppVersion,
    required this.autoBackups,
    required this.theme,
    required this.developerOptions,
    required this.useAutoBrightness,
    required this.vibrateOnDifferentActions,
    required this.tags,
    required this.cardListViewOptions,
    this.customExportPath,
  });

  const Settings.defaultValue()
      : this(
          lastSeenAppVersion: null,
          autoBackups: const AutoBackupSettings.defaultValue(),
          theme: const ThemeSettings.defaultValue(),
          developerOptions: const DeveloperOptions.defaultValue(),
          useAutoBrightness: true,
          vibrateOnDifferentActions: true,
          tags: const [],
          cardListViewOptions: const CardListViewOptions.defaultValue(),
          customExportPath: '/storage/emulated/0/Download/Cardabase',
        );

  @HiveField(0)
  final String? lastSeenAppVersion;
  @HiveField(1)
  final AutoBackupSettings autoBackups;
  @HiveField(2)
  final ThemeSettings theme;
  @HiveField(3)
  final DeveloperOptions developerOptions;
  @HiveField(4)
  final bool useAutoBrightness;
  @HiveField(5)
  final bool vibrateOnDifferentActions;
  @HiveField(6)
  final List<String> tags;
  @HiveField(7)
  final CardListViewOptions cardListViewOptions;
  @HiveField(8)
  final String? customExportPath;

  EditableSettings editable() => EditableSettings.fromValue(this);
}

@HiveType(typeId: HiveTypeIds.autoBackupSettings)
class AutoBackupSettings {
  const AutoBackupSettings({
    required this.isEnabled,
    required this.lastUpdate,
    required this.interval,
  });

  const AutoBackupSettings.defaultValue()
      : this(
          isEnabled: false,
          lastUpdate: null,
          interval: const Duration(days: 7),
        );

  @HiveField(0)
  final bool isEnabled;
  @HiveField(1)
  final DateTime? lastUpdate;
  @HiveField(2)
  final Duration interval;

  EditableAutoBackupSettings editable() {
    return EditableAutoBackupSettings.fromValue(this);
  }
}

@HiveType(typeId: HiveTypeIds.themeSettings)
class ThemeSettings {
  const ThemeSettings({
    required this.useDarkMode,
    required this.useExtraDark,
    required this.useSystemFont,
    required this.loyaltyCardEffect,
  });

  const ThemeSettings.defaultValue()
      : this(
          useDarkMode: false,
          useExtraDark: false,
          useSystemFont: false,
          loyaltyCardEffect: const LoyaltyCardEffectSettings.defaultValue(),
        );

  @HiveField(0)
  final bool useDarkMode;
  @HiveField(1)
  final bool useExtraDark;
  @HiveField(2)
  final bool useSystemFont;
  @HiveField(3)
  final LoyaltyCardEffectSettings loyaltyCardEffect;

  EditableThemeSettings editable() => EditableThemeSettings.fromValue(this);
}

@HiveType(typeId: HiveTypeIds.loyaltyCardEffectSettings)
class LoyaltyCardEffectSettings {
  const LoyaltyCardEffectSettings({
    required this.isEnabled,
    required this.effect,
  });

  const LoyaltyCardEffectSettings.defaultValue()
      : this(isEnabled: false, effect: LoyaltyCardEffect.grain);

  @HiveField(0)
  final bool isEnabled;
  @HiveField(1)
  final LoyaltyCardEffect effect;

  EditableLoyaltyCardEffectSettings editable() {
    return EditableLoyaltyCardEffectSettings.fromValue(this);
  }
}

@HiveType(typeId: HiveTypeIds.loyaltyCardEffect)
enum LoyaltyCardEffect {
  @HiveField(0)
  snowy,
  @HiveField(1)
  grain,
  @HiveField(2)
  glitter
}

@HiveType(typeId: HiveTypeIds.developerOptions)
class DeveloperOptions {
  const DeveloperOptions({required this.isEnabled});

  const DeveloperOptions.defaultValue() : this(isEnabled: false);

  @HiveField(0)
  final bool isEnabled;

  EditableDeveloperOptions editable() {
    return EditableDeveloperOptions.fromValue(this);
  }
}

@HiveType(typeId: HiveTypeIds.sortingStyle)
enum SortingStyle {
  @HiveField(0)
  nameAz,
  @HiveField(1)
  nameZa,
  @HiveField(2)
  latest,
  @HiveField(3)
  oldest
}

@HiveType(typeId: HiveTypeIds.cardListViewOptions)
class CardListViewOptions {
  const CardListViewOptions({
    required this.numberOfColumns,
    required this.sortingStyle,
    required this.sortNameCaseInsensitive,
    required this.sortNameIgnoreAccents,
  });

  const CardListViewOptions.defaultValue()
      : this(
          numberOfColumns: 1,
          sortingStyle: SortingStyle.latest,
          sortNameCaseInsensitive: false,
          sortNameIgnoreAccents: false,
        );

  @HiveField(0)
  final int numberOfColumns;
  @HiveField(1)
  final SortingStyle sortingStyle;
  @HiveField(2, defaultValue: false)
  final bool sortNameCaseInsensitive;
  @HiveField(3, defaultValue: false)
  final bool sortNameIgnoreAccents;

  EditableCardListViewOptions editable() {
    return EditableCardListViewOptions.fromValue(this);
  }
}
