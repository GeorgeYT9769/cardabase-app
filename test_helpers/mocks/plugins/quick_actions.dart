import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockQuickActionsPlatform extends Mock implements _QuickActionsPlatform {}

abstract class _QuickActionsPlatform {
  Future<String?> getLaunchAction();
  Future<void> setShortcutItems(Object? items);
  Future<void> clearShortcutItems();
}

MockQuickActionsPlatform createMockQuickActionsPlatform(
  TestDefaultBinaryMessenger messenger,
) {
  final mock = MockQuickActionsPlatform();
  messenger.setMockMethodCallHandler(
    MethodChannel('plugins.flutter.io/quick_actions'),
    (call) {
      return switch (call.method) {
        'getLaunchAction' => mock.getLaunchAction(),
        'setShortcutItems' => mock.setShortcutItems(call.arguments),
        'clearShortcutItems' => mock.clearShortcutItems(),
        _ => throw Exception('unknown quick actions method: ${call.method}'),
      };
    },
  );

  when(() => mock.getLaunchAction()).thenAnswer((i) => Future.value());
  when(() => mock.setShortcutItems(any())).thenAnswer((i) => Future.value());
  when(() => mock.clearShortcutItems()).thenAnswer((i) => Future.value());
  return mock;
}

extension QuickActionsGetItExtensions on GetIt {
  void registerMockQuickActions() {
    GetIt.I.registerLazySingleton(() {
      return createMockQuickActionsPlatform(
        GetIt.I<TestDefaultBinaryMessenger>(),
      );
    });
  }
}
