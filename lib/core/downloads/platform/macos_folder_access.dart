import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The sandbox grants a folder the user picked for one run. A security-scoped
/// bookmark carries that grant to later runs. The folder path itself stays in
/// the settings; only the grant is kept here.
abstract final class MacosFolderAccess {
  static const _channel = MethodChannel('booruflow/folder_access');

  static Future<File> _bookmark() async => File(
    p.join(
      (await getApplicationSupportDirectory()).path,
      'download_folder.bookmark',
    ),
  );

  /// Keeps the grant for [path], which the user has just picked.
  static Future<void> remember(String path) async {
    if (!Platform.isMacOS) return;
    try {
      await _write(path);
    } on Exception {
      // The folder still works for this run.
    }
  }

  /// Regains the folder picked in an earlier run, if there was one.
  static Future<void> restore() async {
    if (!Platform.isMacOS) return;
    try {
      final file = await _bookmark();
      if (!await file.exists()) return;
      final path = await _channel.invokeMethod<String>(
        'open',
        await file.readAsBytes(),
      );
      // Bookmarks age; a fresh one is cheap and keeps the grant valid.
      if (path != null) await _write(path);
    } on Exception {
      // Without the grant the save reports the folder as not writable.
    }
  }

  static Future<void> _write(String path) async {
    final bytes = await _channel.invokeMethod<Uint8List>('bookmark', path);
    if (bytes == null) return;
    await (await _bookmark()).writeAsBytes(bytes, flush: true);
  }
}
