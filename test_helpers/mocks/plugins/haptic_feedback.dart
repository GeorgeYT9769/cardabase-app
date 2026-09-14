import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockHapticFeedbackPlatform extends Mock
    implements _HapticFeedbackPlatform {}

abstract class _HapticFeedbackPlatform {
  Future<bool> canVibrate();
  Future<void> success();
  Future<void> warning();
  Future<void> error();
  Future<void> light();
  Future<void> medium();
  Future<void> heavy();
  Future<void> rigid();
  Future<void> soft();
  Future<void> selection();
}

MockHapticFeedbackPlatform createMockHapticFeedbackPlatform(
  TestDefaultBinaryMessenger messenger,
) {
  final mock = MockHapticFeedbackPlatform();
  messenger.setMockMethodCallHandler(
    MethodChannel('haptic_feedback'),
    (call) {
      return switch (call.method) {
        'canVibrate' => mock.canVibrate(),
        'success' => mock.success(),
        'warning' => mock.warning(),
        'error' => mock.error(),
        'light' => mock.light(),
        'medium' => mock.medium(),
        'heavy' => mock.heavy(),
        'rigid' => mock.rigid(),
        'soft' => mock.soft(),
        'selection' => mock.selection(),
        _ => throw Exception('unknown haptic feedback method: ${call.method}'),
      };
    },
  );

  when(() => mock.canVibrate()).thenAnswer((i) => Future.value(true));
  when(() => mock.success()).thenAnswer((i) => Future.value());
  when(() => mock.warning()).thenAnswer((i) => Future.value());
  when(() => mock.error()).thenAnswer((i) => Future.value());
  when(() => mock.light()).thenAnswer((i) => Future.value());
  when(() => mock.medium()).thenAnswer((i) => Future.value());
  when(() => mock.heavy()).thenAnswer((i) => Future.value());
  when(() => mock.rigid()).thenAnswer((i) => Future.value());
  when(() => mock.soft()).thenAnswer((i) => Future.value());
  when(() => mock.selection()).thenAnswer((i) => Future.value());
  return mock;
}

extension HapticFeedbackGetItExtensions on GetIt {
  void registerMockHapticFeedback() {
    GetIt.I.registerLazySingleton(() {
      return createMockHapticFeedbackPlatform(
        GetIt.I<TestDefaultBinaryMessenger>(),
      );
    });
  }
}
