import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockClipboardPlatform extends Mock implements _ClipboardPlatform {
  String? clipboardText;
}

abstract class _ClipboardPlatform {
  Future<void> setData(Object? data);
  Future<Map<Object?, Object?>?> getData(Object? format);
  Future<bool> hasStrings();
}

MockClipboardPlatform createMockClipboardPlatform(
  TestDefaultBinaryMessenger messenger,
) {
  final mock = MockClipboardPlatform();
  messenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) {
      return switch (call.method) {
        'Clipboard.setData' => mock.setData(call.arguments),
        'Clipboard.getData' => mock.getData(call.arguments),
        // the framework reads the answer to this one out of a map rather than
        // taking it as it comes.
        'Clipboard.hasStrings' =>
          mock.hasStrings().then((hasStrings) => {'value': hasStrings}),
        // the platform channel carries more than the clipboard -- the
        // system chrome, the sounds, the navigator -- and none of that has
        // to happen for a test to pass.
        _ => Future<Object?>.value(),
      };
    },
  );

  when(() => mock.setData(any())).thenAnswer((i) {
    mock.clipboardText =
        (i.positionalArguments.first as Map)['text'] as String?;
    return Future.value();
  });
  when(() => mock.getData(any())).thenAnswer(
    (i) => Future.value({'text': mock.clipboardText}),
  );
  when(() => mock.hasStrings()).thenAnswer(
    (i) => Future.value(mock.clipboardText?.isNotEmpty ?? false),
  );
  return mock;
}

extension ClipboardGetItExtensions on GetIt {
  void registerMockClipboard() {
    GetIt.I.registerLazySingleton(() {
      return createMockClipboardPlatform(GetIt.I<TestDefaultBinaryMessenger>());
    });
  }
}
