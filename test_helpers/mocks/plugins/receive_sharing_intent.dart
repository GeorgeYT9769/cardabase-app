import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockSharingIntentPlatform extends Mock implements _SharingIntentPlatform {
  final Map<Object, StreamSubscription> _subscriptions = {};

  Future<void> dispose() {
    return Future.wait(
      _subscriptions.values
          .map((subscription) => subscription.cancel())
          .toList(growable: false),
    );
  }
}

abstract class _SharingIntentPlatform {
  Future<String?> getInitialMedia();
  Future<void> reset();
  Stream<String?> mediaStream();
}

MockSharingIntentPlatform createMockSharingIntentPlatform(
  TestDefaultBinaryMessenger messenger,
) {
  final mock = MockSharingIntentPlatform();
  messenger.setMockMethodCallHandler(
    MethodChannel('receive_sharing_intent/messages'),
    (call) {
      return switch (call.method) {
        'getInitialMedia' => mock.getInitialMedia(),
        'reset' => mock.reset(),
        _ => throw Exception('unknown sharing intent method: ${call.method}'),
      };
    },
  );

  messenger.setMockStreamHandler(
    EventChannel('receive_sharing_intent/events-media'),
    MockStreamHandler.inline(
      onListen: (arguments, events) {
        mock._subscriptions[arguments.hashCode] =
            mock.mediaStream().listen(events.success);
      },
      onCancel: (arguments) =>
          mock._subscriptions[arguments.hashCode]?.cancel(),
    ),
  );

  when(() => mock.getInitialMedia()).thenAnswer((i) => Future.value());
  when(() => mock.reset()).thenAnswer((i) => Future.value());
  when(() => mock.mediaStream()).thenAnswer((i) => const Stream.empty());
  return mock;
}

extension SharingIntentGetItExtensions on GetIt {
  void registerMockSharingIntent() {
    GetIt.I.registerLazySingleton(() {
      return createMockSharingIntentPlatform(
        GetIt.I<TestDefaultBinaryMessenger>(),
      );
    });
  }
}
