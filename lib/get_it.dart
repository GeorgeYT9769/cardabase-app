import 'package:cardabase/feature/cards/barcode_type_type_adapter.dart';
import 'package:cardabase/hive_registrar.g.dart';
import 'package:cardabase/util/vibration_provider.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:package_info_plus/package_info_plus.dart';

extension GetItExtensions on GetIt {
  void registerHive() {
    registerLazySingletonAsync<HiveInterface>(() async {
      // ignore: avoid_print
      print('registerHive: initializing Hive');
      await Hive.initFlutter();
      Hive.registerAdapter(const BarcodeTypeAdapter());
      Hive.registerAdapters();
      // ignore: avoid_print
      print('registerHive: Hive initialized');
      return Hive;
    });

    registerLazySingletonAsync(
      () => getAsync<HiveInterface>().then((hive) async {
        // ignore: avoid_print
        print('registerHive: opening password box');
        late Box box;
        try {
          box = await hive.openBox('password');
        } catch (e, s) {
          // Do not delete here. Deleting can silently drop lock/password data.
          // Surface the error so startup fallback can report it.
          // ignore: avoid_print
          print('registerHive: failed opening password box: $e\n$s');
          rethrow;
        }
        // ignore: avoid_print
        print('registerHive: opened password box');
        return box;
      }),
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
