import 'package:cardabase/feature/settings/model.dart';
import 'package:cardabase/util/list_notifier.dart';
import 'package:flutter/foundation.dart';

class EditableSettings {
  const EditableSettings({
    required this.lastSeenAppVersion,
    required this.autoBackups,
    required this.theme,
    required this.developerOptions,
    required this.useAutoBrightness,
    required this.vibrateOnDifferentActions,
    required this.tags,
    required this.cardListViewOptions,
  });

  factory EditableSettings.fromValue(Settings value) {
    return EditableSettings(
      lastSeenAppVersion: ValueNotifier(value.lastSeenAppVersion),
      autoBackups: EditableAutoBackupSettings.fromValue(value.autoBackups),
      theme: EditableThemeSettings.fromValue(value.theme),
      developerOptions: EditableDeveloperOptions.fromValue(
        value.developerOptions,
      ),
      useAutoBrightness: ValueNotifier(value.useAutoBrightness),
      vibrateOnDifferentActions: ValueNotifier(value.vibrateOnDifferentActions),
      tags: ListNotifier(value.tags),
      cardListViewOptions: EditableCardListViewOptions.fromValue(
        value.cardListViewOptions,
      ),
    );
  }

  final ValueNotifier<String?> lastSeenAppVersion;
  final EditableAutoBackupSettings autoBackups;
  final EditableThemeSettings theme;
  final EditableDeveloperOptions developerOptions;
  final ValueNotifier<bool> useAutoBrightness;
  final ValueNotifier<bool> vibrateOnDifferentActions;
  final ListNotifier<String> tags;
  final EditableCardListViewOptions cardListViewOptions;

  void loadValue(Settings value) {
    lastSeenAppVersion.value = value.lastSeenAppVersion;
    autoBackups.loadValue(value.autoBackups);
    theme.loadValue(value.theme);
    developerOptions.loadValue(value.developerOptions);
    useAutoBrightness.value = value.useAutoBrightness;
    vibrateOnDifferentActions.value = value.vibrateOnDifferentActions;
    tags.value = value.tags;
    cardListViewOptions.loadValue(value.cardListViewOptions);
  }

  Settings seal() {
    return Settings(
      lastSeenAppVersion: lastSeenAppVersion.value,
      autoBackups: autoBackups.seal(),
      theme: theme.seal(),
      developerOptions: developerOptions.seal(),
      useAutoBrightness: useAutoBrightness.value,
      vibrateOnDifferentActions: vibrateOnDifferentActions.value,
      tags: tags.value,
      cardListViewOptions: cardListViewOptions.seal(),
    );
  }

  void dispose() {
    lastSeenAppVersion.dispose();
    autoBackups.dispose();
    theme.dispose();
    developerOptions.dispose();
    useAutoBrightness.dispose();
    vibrateOnDifferentActions.dispose();
    tags.dispose();
    cardListViewOptions.dispose();
  }
}

class EditableAutoBackupSettings {
  const EditableAutoBackupSettings({
    required this.isEnabled,
    required this.lastUpdate,
    required this.interval,
  });

  factory EditableAutoBackupSettings.fromValue(AutoBackupSettings value) {
    return EditableAutoBackupSettings(
      isEnabled: ValueNotifier(value.isEnabled),
      lastUpdate: ValueNotifier(value.lastUpdate),
      interval: ValueNotifier(value.interval),
    );
  }

  final ValueNotifier<bool> isEnabled;
  final ValueNotifier<DateTime?> lastUpdate;
  final ValueNotifier<Duration> interval;

  void loadValue(AutoBackupSettings value) {
    isEnabled.value = value.isEnabled;
    lastUpdate.value = value.lastUpdate;
    interval.value = value.interval;
  }

  AutoBackupSettings seal() {
    return AutoBackupSettings(
      isEnabled: isEnabled.value,
      lastUpdate: lastUpdate.value,
      interval: interval.value,
    );
  }

  void dispose() {
    isEnabled.dispose();
    lastUpdate.dispose();
    interval.dispose();
  }
}

class EditableThemeSettings {
  const EditableThemeSettings({
    required this.useDarkMode,
    required this.useExtraDark,
    required this.useSystemFont,
    required this.loyaltyCardEffect,
  });

  factory EditableThemeSettings.fromValue(ThemeSettings value) {
    return EditableThemeSettings(
      useDarkMode: ValueNotifier(value.useDarkMode),
      useExtraDark: ValueNotifier(value.useExtraDark),
      useSystemFont: ValueNotifier(value.useSystemFont),
      loyaltyCardEffect: EditableLoyaltyCardEffectSettings.fromValue(
        value.loyaltyCardEffect,
      ),
    );
  }

  final ValueNotifier<bool> useDarkMode;
  final ValueNotifier<bool> useExtraDark;
  final ValueNotifier<bool> useSystemFont;
  final EditableLoyaltyCardEffectSettings loyaltyCardEffect;

  void loadValue(ThemeSettings value) {
    useDarkMode.value = value.useDarkMode;
    useExtraDark.value = value.useExtraDark;
    useSystemFont.value = value.useSystemFont;
    loyaltyCardEffect.loadValue(value.loyaltyCardEffect);
  }

  ThemeSettings seal() {
    return ThemeSettings(
      useDarkMode: useDarkMode.value,
      useExtraDark: useExtraDark.value,
      useSystemFont: useSystemFont.value,
      loyaltyCardEffect: loyaltyCardEffect.seal(),
    );
  }

  void dispose() {
    useDarkMode.dispose();
    useExtraDark.dispose();
    useSystemFont.dispose();
  }
}

class EditableLoyaltyCardEffectSettings {
  const EditableLoyaltyCardEffectSettings({
    required this.isEnabled,
    required this.effect,
  });

  factory EditableLoyaltyCardEffectSettings.fromValue(
    LoyaltyCardEffectSettings value,
  ) {
    return EditableLoyaltyCardEffectSettings(
      isEnabled: ValueNotifier(value.isEnabled),
      effect: ValueNotifier(value.effect),
    );
  }

  final ValueNotifier<bool> isEnabled;
  final ValueNotifier<LoyaltyCardEffect> effect;

  void loadValue(LoyaltyCardEffectSettings value) {
    isEnabled.value = value.isEnabled;
    effect.value = value.effect;
  }

  LoyaltyCardEffectSettings seal() {
    return LoyaltyCardEffectSettings(
      isEnabled: isEnabled.value,
      effect: effect.value,
    );
  }
}

class EditableDeveloperOptions {
  const EditableDeveloperOptions({required this.isEnabled});

  factory EditableDeveloperOptions.fromValue(DeveloperOptions value) {
    return EditableDeveloperOptions(isEnabled: ValueNotifier(value.isEnabled));
  }

  final ValueNotifier<bool> isEnabled;

  void loadValue(DeveloperOptions value) {
    isEnabled.value = value.isEnabled;
  }

  DeveloperOptions seal() {
    return DeveloperOptions(isEnabled: isEnabled.value);
  }

  void dispose() {
    isEnabled.dispose();
  }
}

class EditableCardListViewOptions {
  const EditableCardListViewOptions({
    required this.numberOfColumns,
    required this.sortingStyle,
  });

  factory EditableCardListViewOptions.fromValue(CardListViewOptions value) {
    return EditableCardListViewOptions(
      numberOfColumns: ValueNotifier(value.numberOfColumns),
      sortingStyle: ValueNotifier(value.sortingStyle),
    );
  }

  final ValueNotifier<int> numberOfColumns;
  final ValueNotifier<SortingStyle> sortingStyle;

  void loadValue(CardListViewOptions value) {
    numberOfColumns.value = value.numberOfColumns;
    sortingStyle.value = value.sortingStyle;
  }

  CardListViewOptions seal() {
    return CardListViewOptions(
      numberOfColumns: numberOfColumns.value,
      sortingStyle: sortingStyle.value,
    );
  }

  void dispose() {
    numberOfColumns.dispose();
    sortingStyle.dispose();
  }
}
