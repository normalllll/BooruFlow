import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'legacy_upgrade.dart';

Future<Directory>? _supportDirectory;

/// The application's own data directory, after older layouts were moved into
/// it. On Windows this is `%APPDATA%\io.github.normalllll\BooruFlow`.
Future<Directory> appSupportDirectory() => _supportDirectory ??= () async {
  final support = await getApplicationSupportDirectory();
  await flattenLegacySupportFolder(support);
  return support;
}();

/// Opens Hive in `<support>/hive`, never in the user's Documents folder.
/// Boxes an older version left in Documents move before any box opens.
Future<void> initializeHiveStorage({
  @visibleForTesting Directory? documentsDirectory,
  @visibleForTesting Directory? supportDirectory,
}) async {
  final Directory support;
  if (supportDirectory == null) {
    support = await appSupportDirectory();
  } else {
    support = supportDirectory;
    await flattenLegacySupportFolder(support);
  }
  final documents =
      documentsDirectory ?? await getApplicationDocumentsDirectory();
  final private = Directory(p.join(support.path, 'hive'));
  await private.create(recursive: true);
  await upgradeDocumentsStorage(documents, private);
  Hive.init(private.path);
}
