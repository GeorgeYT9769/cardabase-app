import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

const testScreenBrightness = 0.5;

class MockScreenBrightnessPlatform extends Mock
    implements _ScreenBrightnessPlatform {}

abstract class _ScreenBrightnessPlatform {
  Future<double> getSystemScreenBrightness();
  Future<void> setSystemScreenBrightness(Object? arguments);
  Future<double> getApplicationScreenBrightness();
  Future<void> setApplicationScreenBrightness(Object? arguments);
  Future<void> resetApplicationScreenBrightness();
  Future<bool> hasApplicationScreenBrightnessChanged();
  Future<bool> isAutoReset();
  Future<void> setAutoReset(Object? arguments);
  Future<bool> isAnimate();
  Future<void> setAnimate(Object? arguments);
  Future<bool> canChangeSystemBrightness();
}

MockScreenBrightnessPlatform createMockScreenBrightnessPlatform(
  TestDefaultBinaryMessenger messenger,
) {
  final mock = MockScreenBrightnessPlatform();
  messenger.setMockMethodCallHandler(
    MethodChannel('github.com/aaassseee/screen_brightness'),
    (call) {
      return switch (call.method) {
        'getSystemScreenBrightness' => mock.getSystemScreenBrightness(),
        'setSystemScreenBrightness' =>
          mock.setSystemScreenBrightness(call.arguments),
        'getApplicationScreenBrightness' =>
          mock.getApplicationScreenBrightness(),
        'setApplicationScreenBrightness' =>
          mock.setApplicationScreenBrightness(call.arguments),
        'resetApplicationScreenBrightness' =>
          mock.resetApplicationScreenBrightness(),
        'hasApplicationScreenBrightnessChanged' =>
          mock.hasApplicationScreenBrightnessChanged(),
        'isAutoReset' => mock.isAutoReset(),
        'setAutoReset' => mock.setAutoReset(call.arguments),
        'isAnimate' => mock.isAnimate(),
        'setAnimate' => mock.setAnimate(call.arguments),
        'canChangeSystemBrightness' => mock.canChangeSystemBrightness(),
        _ => throw Exception(
            'unknown screen brightness method: ${call.method}',
          ),
      };
    },
  );

  // nothing turns the brightness up or down behind the app's back.
  for (final channel in [
    EventChannel('github.com/aaassseee/screen_brightness/'
        'application_brightness_changed'),
    EventChannel(
      'github.com/aaassseee/screen_brightness/system_brightness_changed',
    ),
  ]) {
    messenger.setMockStreamHandler(
      channel,
      MockStreamHandler.inline(onListen: (arguments, events) {}),
    );
  }

  when(() => mock.getSystemScreenBrightness())
      .thenAnswer((i) => Future.value(testScreenBrightness));
  when(() => mock.getApplicationScreenBrightness())
      .thenAnswer((i) => Future.value(testScreenBrightness));
  when(() => mock.setSystemScreenBrightness(any()))
      .thenAnswer((i) => Future.value());
  when(() => mock.setApplicationScreenBrightness(any()))
      .thenAnswer((i) => Future.value());
  when(() => mock.resetApplicationScreenBrightness())
      .thenAnswer((i) => Future.value());
  when(() => mock.hasApplicationScreenBrightnessChanged())
      .thenAnswer((i) => Future.value(false));
  when(() => mock.isAutoReset()).thenAnswer((i) => Future.value(true));
  when(() => mock.setAutoReset(any())).thenAnswer((i) => Future.value());
  when(() => mock.isAnimate()).thenAnswer((i) => Future.value(true));
  when(() => mock.setAnimate(any())).thenAnswer((i) => Future.value());
  when(() => mock.canChangeSystemBrightness())
      .thenAnswer((i) => Future.value(true));
  return mock;
}

extension ScreenBrightnessGetItExtensions on GetIt {
  void registerMockScreenBrightness() {
    GetIt.I.registerLazySingleton(() {
      return createMockScreenBrightnessPlatform(
        GetIt.I<TestDefaultBinaryMessenger>(),
      );
    });
  }
}
