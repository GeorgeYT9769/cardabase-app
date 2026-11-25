import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class NoPermissionToExternalStorageException implements Exception {
  const NoPermissionToExternalStorageException();
}

/// Implemented by MainActivity.kt on Android. Returns the public external
/// storage root of the *current* user/profile, e.g. `/storage/emulated/10`,
/// instead of assuming the default user (`/storage/emulated/0`).
const MethodChannel storageChannel = MethodChannel('cardabase_storage');

/// A storage-access failure, so the existing export error handlers cover it.
class ExternalStorageUnavailableException
    extends NoPermissionToExternalStorageException {
  const ExternalStorageUnavailableException([this.message]);

  final String? message;

  @override
  String toString() =>
      'ExternalStorageUnavailableException${message != null ? ': $message' : ''}';
}

/// Resolves the configured export path against the active user's public
/// external storage root. Non-Android builds use the documents directory.
Future<Directory> resolveExportDirectory(
  String directoryPath, {
  bool? isAndroid,
}) async {
  final bool android = isAndroid ?? Platform.isAndroid;
  final String root;

  if (android) {
    final String? path;
    try {
      path = await storageChannel.invokeMethod<String>(
        'getExternalStorageDirectory',
      );
    } on PlatformException catch (e) {
      throw ExternalStorageUnavailableException(e.message);
    } on MissingPluginException catch (e) {
      throw ExternalStorageUnavailableException(e.message);
    }
    if (path == null || path.isEmpty) {
      throw const ExternalStorageUnavailableException(
        'Android returned no external storage directory',
      );
    }
    root = path;
  } else {
    root = (await getApplicationDocumentsDirectory()).path;
  }

  return Directory(exportDirectoryPath(root, directoryPath));
}

/// Joins a configured path to [root]. A leading separator is ignored so a
/// configured absolute path cannot silently escape the resolved root.
String exportDirectoryPath(String root, String directoryPath) {
  final String relative = directoryPath.trim().replaceFirst(RegExp(r'^[/\\]+'), '');
  if (relative.isEmpty) return root;

  // Android roots are POSIX paths even when the tests run on Windows.
  final p.Context context = RegExp(r'^[A-Za-z]:[\\/]').hasMatch(root)
      ? p.context
      : p.Context(style: p.Style.posix);
  return relative
      .split(RegExp(r'[/\\]'))
      .where((segment) => segment.isNotEmpty)
      .fold(root, (path, segment) => context.join(path, segment));
}
