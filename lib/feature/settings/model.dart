import 'package:cardabase/data/hive.dart';
import 'package:cardabase/feature/cards/card_list_view_options.dart';
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
    required this.customExportPath,
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
          customExportPath: defaultCardExportDirectoryPath,
        );

  static const defaultCardExportDirectoryPath = 'Download/Cardabase';

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
  @HiveField(8, defaultValue: defaultCardExportDirectoryPath)
  final String customExportPath;

  Map<String, dynamic> toJsonMap() {
    return {
      if (lastSeenAppVersion != null) 'lastSeenAppVersion': lastSeenAppVersion,
      'autoBackups': autoBackups.toJsonMap(),
      'theme': theme.toJsonMap(),
      'developerOptions': developerOptions.toJsonMap(),
      'useAutoBrightness': useAutoBrightness,
      'vibrateOnDifferentActions': vibrateOnDifferentActions,
      'tags': tags,
      'cardListViewOptions': cardListViewOptions.toJsonMap(),
      'customExportPath': customExportPath,
    };
  }

  EditableSettings editable() => EditableSettings.fromValue(this);

  factory Settings.fromJsonMap(Map<String, dynamic> map) {
    return Settings(
      lastSeenAppVersion: map['lastSeenAppVersion'] as String?,
      autoBackups: map['autoBackups'] != null
          ? AutoBackupSettings.fromJsonMap(map['autoBackups'] as Map<String, dynamic>)
          : const AutoBackupSettings.defaultValue(),
      theme: map['theme'] != null
          ? ThemeSettings.fromJsonMap(map['theme'] as Map<String, dynamic>)
          : const ThemeSettings.defaultValue(),
      developerOptions: map['developerOptions'] != null
          ? DeveloperOptions.fromJsonMap(map['developerOptions'] as Map<String, dynamic>)
          : const DeveloperOptions.defaultValue(),
      useAutoBrightness: map['useAutoBrightness'] as bool? ?? true,
      vibrateOnDifferentActions: map['vibrateOnDifferentActions'] as bool? ?? true,
      tags: (map['tags'] as List?)?.cast<String>() ?? const [],
      cardListViewOptions: map['cardListViewOptions'] != null
          ? CardListViewOptions.fromJsonMap(map['cardListViewOptions'] as Map<String, dynamic>)
          : const CardListViewOptions.defaultValue(),
      customExportPath: map['customExportPath'] as String? ?? defaultCardExportDirectoryPath,
    );
  }
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

  Map<String, dynamic> toJsonMap() {
    return {
      'isEnabled': isEnabled,
      if (lastUpdate != null) 'lastUpdate': lastUpdate?.toIso8601String(),
      'interval': interval.inMilliseconds,
    };
  }

  factory AutoBackupSettings.fromJsonMap(Map<String, dynamic> map) {
    return AutoBackupSettings(
      isEnabled: map['isEnabled'] as bool? ?? false,
      lastUpdate: map['lastUpdate'] != null ? DateTime.parse(map['lastUpdate'] as String) : null,
      interval: Duration(milliseconds: map['interval'] as int? ?? const Duration(days: 7).inMilliseconds),
    );
  }

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

  Map<String, dynamic> toJsonMap() {
    return {
      'useDarkMode': useDarkMode,
      'useExtraDark': useExtraDark,
      'useSystemFont': useSystemFont,
      'loyaltyCardEffect': loyaltyCardEffect.toJsonMap(),
    };
  }

  factory ThemeSettings.fromJsonMap(Map<String, dynamic> map) {
    return ThemeSettings(
      useDarkMode: map['useDarkMode'] as bool? ?? false,
      useExtraDark: map['useExtraDark'] as bool? ?? false,
      useSystemFont: map['useSystemFont'] as bool? ?? false,
      loyaltyCardEffect: map['loyaltyCardEffect'] != null
          ? LoyaltyCardEffectSettings.fromJsonMap(map['loyaltyCardEffect'] as Map<String, dynamic>)
          : const LoyaltyCardEffectSettings.defaultValue(),
    );
  }

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

  Map<String, dynamic> toJsonMap() {
    return {
      'isEnabled': isEnabled,
      'effect': effect.name,
    };
  }

  factory LoyaltyCardEffectSettings.fromJsonMap(Map<String, dynamic> map) {
    return LoyaltyCardEffectSettings(
      isEnabled: map['isEnabled'] as bool? ?? false,
      effect: LoyaltyCardEffect.values.firstWhere(
        (e) => e.name == map['effect'],
        orElse: () => LoyaltyCardEffect.grain,
      ),
    );
  }

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

  Map<String, dynamic> toJsonMap() {
    return {
      'isEnabled': isEnabled,
    };
  }

  factory DeveloperOptions.fromJsonMap(Map<String, dynamic> map) {
    return DeveloperOptions(
      isEnabled: map['isEnabled'] as bool? ?? false,
    );
  }

  EditableDeveloperOptions editable() {
    return EditableDeveloperOptions.fromValue(this);
  }
}
