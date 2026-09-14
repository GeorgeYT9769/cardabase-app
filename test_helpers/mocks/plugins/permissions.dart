import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockPermissionsPlatform extends Mock implements _PermissionsPlatform {}

abstract class _PermissionsPlatform {
  Future<int> checkPermissionStatus(Object? permission);
  Future<int> checkServiceStatus(Object? permission);
  Future<Map<Object?, Object?>> requestPermissions(Object? permissions);
  Future<bool> shouldShowRequestPermissionRationale(Object? permission);
  Future<bool> openAppSettings();
}

MockPermissionsPlatform createMockPermissionsPlatform(
  TestDefaultBinaryMessenger messenger,
) {
  final mock = MockPermissionsPlatform();
  messenger.setMockMethodCallHandler(
    MethodChannel('flutter.baseflow.com/permissions/methods'),
    (call) {
      return switch (call.method) {
        'checkPermissionStatus' => mock.checkPermissionStatus(call.arguments),
        'checkServiceStatus' => mock.checkServiceStatus(call.arguments),
        'requestPermissions' => mock.requestPermissions(call.arguments),
        'shouldShowRequestPermissionRationale' =>
          mock.shouldShowRequestPermissionRationale(call.arguments),
        'openAppSettings' => mock.openAppSettings(),
        _ => throw Exception('unknown permissions method: ${call.method}'),
      };
    },
  );

  when(() => mock.checkPermissionStatus(any()))
      .thenAnswer((i) => Future.value(1));
  when(() => mock.checkServiceStatus(any())).thenAnswer((i) => Future.value(1));
  when(() => mock.requestPermissions(any())).thenAnswer((i) {
    final requested = i.positionalArguments.first;
    final permissions = requested is List ? requested : [requested];
    return Future.value({for (final permission in permissions) permission: 1});
  });
  when(() => mock.shouldShowRequestPermissionRationale(any()))
      .thenAnswer((i) => Future.value(false));
  when(() => mock.openAppSettings()).thenAnswer((i) => Future.value(true));
  return mock;
}

extension PermissionsGetItExtensions on GetIt {
  void registerMockPermissions() {
    GetIt.I.registerLazySingleton(() {
      return createMockPermissionsPlatform(
        GetIt.I<TestDefaultBinaryMessenger>(),
      );
    });
  }
}
