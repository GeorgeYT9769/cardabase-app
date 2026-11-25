import 'package:cardabase/feature/cards/import_export/export_directory.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(storageChannel, null);
  });

  group('exportDirectoryPath', () {
    test('resolves the default relative path against the root', () {
      expect(
        exportDirectoryPath('/storage/emulated/10', 'Download/Cardabase'),
        '/storage/emulated/10/Download/Cardabase',
      );
    });

    test('ignores a leading slash instead of escaping the root', () {
      expect(
        exportDirectoryPath('/storage/emulated/10', '/Download/Cardabase'),
        '/storage/emulated/10/Download/Cardabase',
      );
    });

    test('resolves nested paths and trailing separators', () {
      expect(
        exportDirectoryPath('/storage/emulated/10', 'Backup//cards/'),
        '/storage/emulated/10/Backup/cards',
      );
    });

    test('an empty path resolves to the root itself', () {
      expect(exportDirectoryPath('/storage/emulated/10', ''), '/storage/emulated/10');
    });
  });

  group('resolveExportDirectory', () {
    test('uses the storage root reported by Android for the current profile',
        () async {
      messenger.setMockMethodCallHandler(storageChannel, (call) async {
        expect(call.method, 'getExternalStorageDirectory');
        return '/storage/emulated/10';
      });

      final directory = await resolveExportDirectory(
        'Download/Cardabase',
        isAndroid: true,
      );

      expect(directory.path, '/storage/emulated/10/Download/Cardabase');
    });

    test('turns platform errors into a clear exception', () async {
      messenger.setMockMethodCallHandler(storageChannel, (call) async {
        throw PlatformException(
          code: 'UNAVAILABLE',
          message: 'no external storage',
        );
      });

      await expectLater(
        resolveExportDirectory('Download/Cardabase', isAndroid: true),
        throwsA(
          isA<ExternalStorageUnavailableException>().having(
            (e) => e.message,
            'message',
            'no external storage',
          ),
        ),
      );
    });

    test('fails when no root is returned', () async {
      messenger.setMockMethodCallHandler(storageChannel, (call) async => null);

      await expectLater(
        resolveExportDirectory('Download/Cardabase', isAndroid: true),
        throwsA(isA<ExternalStorageUnavailableException>()),
      );
    });
  });
}
