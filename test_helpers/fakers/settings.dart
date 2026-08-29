import 'package:cardabase/feature/cards/card_list_view_options.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:faker/faker.dart';

import 'random.dart';

extension SettingsFakerExtensions on Faker {
  SettingsFaker get settings => SettingsFaker(this);
}

class SettingsFaker {
  const SettingsFaker(this.faker);

  final Faker faker;

  /// Settings, with everything which is not passed left at its default.
  ///
  /// The defaults rather than fake values: a test which starts the app cares
  /// about the one setting it is about, and a random theme or a random number
  /// of columns would change what is on screen underneath it.
  Settings settings({
    String? lastSeenAppVersion = '1.0.0',
    AutoBackupSettings autoBackups = const AutoBackupSettings.defaultValue(),
    ThemeSettings theme = const ThemeSettings.defaultValue(),
    DeveloperOptions developerOptions = const DeveloperOptions.defaultValue(),
    bool useAutoBrightness = true,
    bool vibrateOnDifferentActions = true,
    List<String> tags = const [],
    CardListViewOptions cardListViewOptions =
        const CardListViewOptions.defaultValue(),
    String customExportPath = Settings.defaultCardExportDirectoryPath,
  }) {
    return Settings(
      lastSeenAppVersion: lastSeenAppVersion,
      autoBackups: autoBackups,
      theme: theme,
      developerOptions: developerOptions,
      useAutoBrightness: useAutoBrightness,
      vibrateOnDifferentActions: vibrateOnDifferentActions,
      tags: tags,
      cardListViewOptions: cardListViewOptions,
      customExportPath: customExportPath,
    );
  }

  /// Settings with every field filled in with fake values, for the tests which
  /// check that nothing is dropped on the way to storage and back.
  Settings fullSettings() {
    return Settings(
      lastSeenAppVersion: '1.0.0',
      autoBackups: autoBackupSettings(),
      theme: themeSettings(),
      developerOptions: const DeveloperOptions(isEnabled: true),
      useAutoBrightness: faker.randomGenerator.boolean(),
      vibrateOnDifferentActions: faker.randomGenerator.boolean(),
      tags: tags(),
      cardListViewOptions: cardListViewOptions(),
      customExportPath: 'Download/${faker.lorem.word()}',
    );
  }

  List<String> tags({int max = 5}) {
    return faker.randomGenerator
        .amount((_) => faker.lorem.word(), max, min: 1)
        .toSet()
        .toList(growable: false);
  }

  CardListViewOptions cardListViewOptions({
    int numberOfColumns = 1,
    SortingStyle sortingStyle = SortingStyle.latest,
    bool sortNameCaseInsensitive = false,
    bool sortNameIgnoreAccents = false,
    List<String> customOrder = const [],
  }) {
    return CardListViewOptions(
      numberOfColumns: numberOfColumns,
      sortingStyle: sortingStyle,
      sortNameCaseInsensitive: sortNameCaseInsensitive,
      sortNameIgnoreAccents: sortNameIgnoreAccents,
      customOrder: customOrder,
    );
  }

  ThemeSettings themeSettings() {
    return ThemeSettings(
      useDarkMode: faker.randomGenerator.boolean(),
      useExtraDark: faker.randomGenerator.boolean(),
      useSystemFont: faker.randomGenerator.boolean(),
      loyaltyCardEffect: LoyaltyCardEffectSettings(
        isEnabled: faker.randomGenerator.boolean(),
        effect: faker.randomGenerator.element(LoyaltyCardEffect.values),
      ),
      rightBackButton: faker.randomGenerator.boolean(),
    );
  }

  AutoBackupSettings autoBackupSettings() {
    return AutoBackupSettings(
      isEnabled: faker.randomGenerator.boolean(),
      lastUpdate: faker.nullOr(() => faker.date.dateTime().toUtc()),
      interval: Duration(days: faker.randomGenerator.integer(30, min: 1)),
      format: BackupFormat.json,
    );
  }
}
