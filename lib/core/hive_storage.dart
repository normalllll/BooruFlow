import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'legacy_upgrade.dart';

/// Keeps private boxes outside the iOS Documents directory shared with Files.
/// Migration runs before any box opens; other platforms keep their existing path.
Future<void> initializeHiveStorage({
  @visibleForTesting TargetPlatform? platform,
  @visibleForTesting Directory? documentsDirectory,
  @visibleForTesting Directory? supportDirectory,
}) async {
  final ios = platform == null
      ? Platform.isIOS
      : platform == TargetPlatform.iOS;
  if (!ios) {
    await Hive.initFlutter();
    return;
  }
  final documents =
      documentsDirectory ?? await getApplicationDocumentsDirectory();
  final support = supportDirectory ?? await getApplicationSupportDirectory();
  final private = Directory(p.join(support.path, 'BooruFlow', 'hive'));
  await private.create(recursive: true);
  await upgradeDocumentsStorage(documents, private);
  await Hive.initFlutter(private.path);
}
