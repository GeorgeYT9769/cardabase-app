import 'package:cardabase/feature/settings/migrations.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive_ce.dart';

extension SettingsGetItExtensions on GetIt {
  void registerSettings() {
    registerLazySingletonAsync<SettingsBox>(
      () async {
        final hive = await getAsync<HiveInterface>();

        final oldSettingsBox = await hive.openBox('settingsBox');
        final newSettingsBox = await hive.openBox<Settings>('settings202603');
        final oldCardsBox = await hive.openBox('mybox');

        await migrateSettingsTo202603(
          oldSettingsBox,
          newSettingsBox,
          oldCardsBox,
        );
        await oldSettingsBox.close();
        await oldCardsBox.close();

        return newSettingsBox;
      },
      dispose: (box) => box.close(),
    );
  }
}

extension SettingsBoxExtensions on Box<Settings> {
  Settings get value => getAt(0) ?? Settings.defaultValue();

  Future<void> save(Settings settings) {
    if (isEmpty) {
      return add(settings);
    } else {
      return putAt(0, settings);
    }
  }
}
