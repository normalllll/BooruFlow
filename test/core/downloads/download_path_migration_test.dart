import 'dart:convert';
import 'dart:io';

import 'package:booruflow/core/downloads/download_database.dart'
    hide DownloadJob;
import 'package:booruflow/core/downloads/download_engine.dart';
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/downloads/download_store.dart';
import 'package:booruflow/core/file_paths.dart';
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

class _SettingsStore implements SettingsServiceStore {
  final values = <String, dynamic>{};
  final writes = <(String, Object?)>[];
  @override
  Map<String, dynamic> load() => Map.of(values);
  @override
  Future<void> write(String key, dynamic value) async {
    values[key] = value;
    writes.add((key, value));
  }
}

void main() {
  test(
    'version 3 migration normalizes stored target and path once, preserving references and opaque metadata',
    () async {
      final temp = await Directory.systemTemp.createTemp(
        'booruflow-r8-path-migration-',
      );
      addTearDown(() async {
        expect(temp.absolute.parent.path, Directory.systemTemp.absolute.path);
        await temp.delete(recursive: true);
      });
      final file = File(p.join(temp.path, 'history.db'));
      var database = DownloadDatabase(executor: NativeDatabase(file));
      var store = DriftDownloadStore(database);
      final job = DownloadJob.create(
        sourceId: 'yande',
        postId: '363100',
        resourceId: 363100,
        variantIndex: 0,
        batchId: 'muryo-batch',
        filename: '363100 (1).png',
        url: Uri.parse('https://fixture.invalid/363100.png'),
        saveTarget: const SaveTarget.downloadsFolder(),
      );
      await store.upsertJob(job);
      final mixedRoot = '${temp.path}/Downloads\\BooruFlow';
      const mixedChild = r'yande/muryo';
      final mixedFile = '$mixedRoot/$mixedChild\\363100 (1).png';
      await database.customStatement(
        'UPDATE download_jobs SET save_target_json = ? WHERE id = ?',
        [
          jsonEncode({
            'type': 'downloadsFolder',
            'directory': mixedRoot,
            'subdirectory': mixedChild,
            'futureMetadata': 'keep',
          }),
          job.id,
        ],
      );
      await database.customStatement(
        'UPDATE download_states SET local_path = ? WHERE job_id = ?',
        [mixedFile, job.id],
      );
      await database.customStatement('PRAGMA user_version = 3');
      await store.close();
      database = DownloadDatabase(executor: NativeDatabase(file));
      store = DriftDownloadStore(database);
      final restored = (await store.getTask(job.id))!;
      expect(restored.sourceId, 'yande');
      expect(restored.postId, '363100');
      expect(restored.batchId, 'muryo-batch');
      expect(restored.localPath, normalizeLocalPath(mixedFile));
      final raw =
          (await database
                  .customSelect('SELECT save_target_json FROM download_jobs')
                  .getSingle())
              .read<String>('save_target_json');
      final json = jsonDecode(raw) as Map;
      expect(json['directory'], normalizeLocalPath(mixedRoot));
      expect(json['subdirectory'], normalizeLocalPath(mixedChild));
      expect(json['futureMetadata'], 'keep');
      final stored =
          (await database
                  .customSelect('SELECT local_path FROM download_states')
                  .getSingle())
              .read<String>('local_path');
      expect(stored, normalizeLocalPath(mixedFile));
      expect(
        (await database.customSelect('PRAGMA user_version').getSingle())
            .read<int>('user_version'),
        4,
      );
      await store.close();
      database = DownloadDatabase(executor: NativeDatabase(file));
      store = DriftDownloadStore(database);
      expect((await store.getTask(job.id))!.localPath, stored);
      await store.close();
    },
  );
  test(
    'new saves and native engine snapshots persist normalized filesystem paths and preserve gallery URI identifiers',
    () async {
      final database = DownloadDatabase(executor: NativeDatabase.memory());
      final store = DriftDownloadStore(database);
      addTearDown(store.close);
      final job = DownloadJob.create(
        resourceId: 1,
        sourceId: 'yande',
        postId: '1',
        variantIndex: 0,
        url: Uri.parse('https://fixture.invalid/1.png'),
        filename: '1.png',
        saveTarget: const SaveTarget.photos(subdirectory: r'yande\batch'),
      );
      await store.upsertJob(job);
      for (final value in [
        r'C:/Downloads/BooruFlow\yande/muryo\1.png',
        'content://media/1',
        'ph://asset/1',
      ]) {
        await store.updateSaveState(job.id, SaveState.saved, localPath: value);
        await store.applyEngineSnapshot(
          DownloadEngineSnapshot(
            jobId: job.id,
            status: DownloadStatus.downloaded,
            saveState: SaveState.saved,
            receivedBytes: 100,
            totalBytes: 100,
            progress: 1,
            localPath: value,
          ),
        );
        expect(
          (await store.getTask(job.id))!.localPath,
          normalizeLocalPath(value),
        );
        expect(
          (await database
                  .customSelect('SELECT local_path FROM download_states')
                  .getSingle())
              .read<String>('local_path'),
          normalizeLocalPath(value),
        );
      }
      expect(
        (await store.getJob(job.id))!.saveTarget.subdirectory,
        'yande/batch',
      );
    },
  );
  test(
    'settings normalize on load and write, with a one-time persisted migration',
    () async {
      final store = _SettingsStore()
        ..values['downloadPath'] = r'C:/Users/fixture\Downloads';
      await SettingsService.initialize(store: store);
      final expected = normalizeLocalPath(r'C:/Users/fixture\Downloads');
      expect(SettingsService.downloadPath, expected);
      expect(store.values['downloadPath'], expected);
      expect(store.writes.where((w) => w.$1 == 'downloadPath'), hasLength(1));
      await SettingsService.initialize(store: store);
      expect(store.writes.where((w) => w.$1 == 'downloadPath'), hasLength(1));
      SettingsService.downloadPath = r'D:/Pictures\Downloads';
      expect(
        SettingsService.downloadPath,
        normalizeLocalPath(r'D:/Pictures\Downloads'),
      );
      expect(store.values['downloadPath'], SettingsService.downloadPath);
    },
  );
}
