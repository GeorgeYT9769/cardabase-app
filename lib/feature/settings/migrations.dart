import 'package:cardabase/feature/settings/model.dart';
import 'package:hive_ce/hive.dart';

Future<void> migrateSettingsTo202603(Box oldBox, Box<Settings> newBox) {
  if (newBox.isNotEmpty) {
    return Future.value();
  }

  final lastAutoUpdate = oldBox.get('lastAutoUpdate') as String?;
  final loyaltyCardEffect = switch (oldBox.get('effectChosen') as String?) {
    'none' => null,
    'glitter' => LoyaltyCardEffect.glitter,
    'snowy' => LoyaltyCardEffect.snowy,
    _ => LoyaltyCardEffect.grain,
  };

  final sortingStyle = switch (oldBox.get('sort')) {
    'nameaz' => SortingStyle.nameAz,
    'nameza' => SortingStyle.nameZa,
    'latest' => SortingStyle.latest,
    _ => SortingStyle.oldest,
  };

  final tags = (oldBox.get('tags') as List?)
          ?.whereType<String>()
          .toList(growable: false) ??
      [];

  return newBox.add(
    Settings(
      lastSeenAppVersion: oldBox.get('lastSeenAppVersion') as String?,
      autoBackups: AutoBackupSettings(
        isEnabled: oldBox.get('autoBackups') as bool? ?? false,
        lastUpdate: lastAutoUpdate == null
            ? null
            : DateTime.tryParse(lastAutoUpdate)?.toUtc(),
        interval: Duration(days: oldBox.get('autoBackupInterval') as int? ?? 7),
      ),
      theme: ThemeSettings(
        useDarkMode: oldBox.get('useDarkMode') as bool? ?? false,
        useExtraDark: oldBox.get('useExtraDark') as bool? ?? false,
        useSystemFont: oldBox.get('useSystemFont') as bool? ?? false,
        loyaltyCardEffect: loyaltyCardEffect == null
            ? const LoyaltyCardEffectSettings.defaultValue()
            : LoyaltyCardEffectSettings(
                isEnabled: oldBox.get('effect') as bool? ?? false,
                effect: loyaltyCardEffect,
              ),
      ),
      developerOptions: DeveloperOptions(
        isEnabled: oldBox.get('developerOptions') as bool? ?? false,
      ),
      useAutoBrightness: oldBox.get('setBrightness') as bool? ?? true,
      vibrateOnDifferentActions: oldBox.get('setVibration') as bool? ?? true,
      tags: tags,
      cardListViewOptions: CardListViewOptions(
        numberOfColumns: oldBox.get('columnAmount') as int? ?? 1,
        sortingStyle: sortingStyle,
        sortNameCaseInsensitive: false,
        sortNameIgnoreAccents: false,
      ),
    ),
  );
}
