import 'package:cardabase/feature/cards/barcode_type_type_adapter.dart';
import 'package:cardabase/hive_registrar.g.dart';
import 'package:cardabase/util/vibration_provider.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:package_info_plus/package_info_plus.dart';

extension GetItExtensions on GetIt {
  void registerHive() {
    registerLazySingletonAsync<HiveInterface>(() async {
      await Hive.initFlutter();
      Hive.registerAdapter(const BarcodeTypeAdapter());
      Hive.registerAdapters();
      return Hive;
    });

    registerLazySingletonAsync(
      () => getAsync<HiveInterface>().then((hive) => hive.openBox('password')),
      instanceName: 'passwordBox',
      dispose: (box) => box.close(),
    );
  }

  void registerPackageInfo() {
    registerLazySingletonAsync(() => PackageInfo.fromPlatform());
  }

  void registerHaptics() {
    registerLazySingleton(
      () => VibrationProvider(
        settingsBox: get(),
      ),
    );
  }
}
