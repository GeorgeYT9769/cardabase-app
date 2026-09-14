import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../../get_it.dart';

class MockPathProviderPlatform extends Mock
    with
        // ignore: invalid_use_of_visible_for_testing_member
        MockPlatformInterfaceMixin
    implements
        PathProviderPlatform {}

MockPathProviderPlatform createMockPathProviderPlatform(
  TestDefaultBinaryMessenger messenger,
  Directory directory,
) {
  final mock = MockPathProviderPlatform();
  messenger.setMockMethodCallHandler(
    MethodChannel('plugins.flutter.io/path_provider'),
    (call) {
      return switch (call.method) {
        'getTemporaryDirectory' => mock.getTemporaryPath(),
        'getApplicationSupportDirectory' => mock.getApplicationSupportPath(),
        'getLibraryDirectory' => mock.getLibraryPath(),
        'getApplicationDocumentsDirectory' =>
          mock.getApplicationDocumentsPath(),
        'getApplicationCacheDirectory' => mock.getApplicationCachePath(),
        'getStorageDirectory' => mock.getExternalStoragePath(),
        'getExternalCacheDirectories' => mock.getExternalCachePaths(),
        'getExternalStorageDirectories' => mock.getExternalStoragePaths(),
        'getDownloadsDirectory' => mock.getDownloadsPath(),
        _ => throw Exception('unknown path provider method: ${call.method}'),
      };
    },
  );
  PathProviderPlatform.instance = mock;

  when(() => mock.getTemporaryPath())
      .thenAnswer((i) => Future.value(directory.path));
  when(() => mock.getApplicationSupportPath())
      .thenAnswer((i) => Future.value(directory.path));
  when(() => mock.getLibraryPath())
      .thenAnswer((i) => Future.value(directory.path));
  when(() => mock.getApplicationDocumentsPath())
      .thenAnswer((i) => Future.value(directory.path));
  when(() => mock.getApplicationCachePath())
      .thenAnswer((i) => Future.value(directory.path));
  when(() => mock.getExternalStoragePath())
      .thenAnswer((i) => Future.value(directory.path));
  when(() => mock.getDownloadsPath())
      .thenAnswer((i) => Future.value(directory.path));
  when(() => mock.getExternalCachePaths())
      .thenAnswer((i) => Future.value([directory.path]));
  when(() => mock.getExternalStoragePaths(type: any(named: 'type')))
      .thenAnswer((i) => Future.value([directory.path]));
  return mock;
}

extension PathProviderGetItExtensions on GetIt {
  void registerMockPathProvider() {
    GetIt.I.registerLazySingletonAsync(() async {
      return createMockPathProviderPlatform(
        GetIt.I<TestDefaultBinaryMessenger>(),
        await GetIt.I.getAsync<Directory>(
          instanceName: TestGetItInstanceNames.storageDirectory.value,
        ),
      );
    });
  }
}
