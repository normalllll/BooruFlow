import 'dart:io';

import 'package:booruflow/core/hive_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late Directory documents;
  late Directory support;
  Future<void> initialize() => initializeHiveStorage(
    documentsDirectory: documents,
    supportDirectory: support,
  );
  setUp(() async {
    root = await Directory.systemTemp.createTemp('booruflow-hive-');
    documents = await Directory(p.join(root.path, 'Documents')).create();
    support = await Directory(p.join(root.path, 'Support')).create();
  });
  tearDown(() async {
    await Hive.close();
    await root.delete(recursive: true);
  });

  test(
    'boxes move out of Documents, keeping their data and leaving downloaded files',
    () async {
      const names = [
        'settings',
        'booru_credentials',
        'discovery_tags',
        'discovery_capabilities_v1',
      ];
      Hive.init(documents.path);
      for (final name in names) {
        final box = await Hive.openBox<dynamic>(name);
        await box.put('value', {'preserved': name});
      }
      await Hive.close();
      final download = File(p.join(documents.path, 'saved.webp'));
      await download.writeAsBytes([1, 2, 3]);
      final unrelated = File(p.join(documents.path, 'unrelated.hive'));
      await unrelated.writeAsBytes([4, 5]);
      await initialize();
      for (final name in names) {
        final box = await Hive.openBox<dynamic>(name);
        expect(box.path, startsWith(support.path));
        expect(box.get('value'), {'preserved': name});
        expect(File(p.join(documents.path, '$name.hive')).existsSync(), false);
        expect(File(p.join(documents.path, '$name.lock')).existsSync(), false);
      }
      await initialize();
      expect((await Hive.openBox<dynamic>('settings')).get('value'), {
        'preserved': 'settings',
      });
      expect(await download.readAsBytes(), [1, 2, 3]);
      expect(await unrelated.readAsBytes(), [4, 5]);
    },
  );

  test('an interrupted compacted box is recovered after migration', () async {
    Hive.init(documents.path);
    final box = await Hive.openBox<dynamic>('settings');
    await box.put('value', 'recoverable');
    await Hive.close();
    await File(
      p.join(documents.path, 'settings.hive'),
    ).rename(p.join(documents.path, 'settings.hivec'));
    await initialize();
    expect(
      (await Hive.openBox<dynamic>('settings')).get('value'),
      'recoverable',
    );
    expect(File(p.join(documents.path, 'settings.hivec')).existsSync(), false);
  });

  test(
    'existing private data wins while duplicate legacy bytes stay recoverable',
    () async {
      Hive.init(documents.path);
      var box = await Hive.openBox<dynamic>('booru_credentials');
      await box.put('value', 'legacy');
      await Hive.close();
      final oldBytes = await File(
        p.join(documents.path, 'booru_credentials.hive'),
      ).readAsBytes();
      final private = Directory(p.join(support.path, 'hive'));
      Hive.init(private.path);
      box = await Hive.openBox<dynamic>('booru_credentials');
      await box.put('value', 'current');
      await Hive.close();
      await initialize();
      expect(
        (await Hive.openBox<dynamic>('booru_credentials')).get('value'),
        'current',
      );
      expect(
        File(p.join(documents.path, 'booru_credentials.hive')).existsSync(),
        false,
      );
      expect(
        await File(
          p.join(private.path, 'legacy-documents', 'booru_credentials.hive'),
        ).readAsBytes(),
        oldBytes,
      );
    },
  );

  test(
    'data nested in an app-named folder moves up, an earlier private Hive folder included',
    () async {
      final nested = Directory(p.join(support.path, 'BooruFlow'));
      final oldPrivate = Directory(p.join(nested.path, 'hive'));
      Hive.init(oldPrivate.path);
      final box = await Hive.openBox<dynamic>('settings');
      await box.put('value', 'private');
      await Hive.close();
      await File(
        p.join(oldPrivate.path, 'legacy-upgrade-version'),
      ).writeAsString('1');
      await File(p.join(nested.path, 'downloads.db')).writeAsBytes([7, 8]);
      Hive.init(documents.path);
      await (await Hive.openBox<dynamic>('settings')).put('value', 'stale');
      await Hive.close();
      await initialize();
      expect(nested.existsSync(), false);
      expect(await File(p.join(support.path, 'downloads.db')).readAsBytes(), [
        7,
        8,
      ]);
      final settings = await Hive.openBox<dynamic>('settings');
      expect(settings.path, startsWith(p.join(support.path, 'hive')));
      expect(settings.get('value'), 'private');
    },
  );
}
