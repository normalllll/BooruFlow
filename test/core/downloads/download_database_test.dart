import 'dart:io';
import 'package:booruflow/core/downloads/download_database.dart'
    hide DownloadJob;
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/downloads/download_store.dart';
import 'package:booruflow/src/rust/api/booru_download.dart' show UgoiraExport;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'ugoira formats persist independently and retry keeps the original choice',
    () async {
      final db = DownloadDatabase(executor: NativeDatabase.memory());
      final store = DriftDownloadStore(db);
      addTearDown(store.close);
      for (final format in UgoiraExport.values) {
        final job = DownloadJob.create(
          resourceId: 9,
          sourceId: 'danbooru',
          postId: '9',
          variantIndex: 0,
          url: Uri.parse('https://cdn.example/9.zip'),
          filename: format == UgoiraExport.losslessWebp ? '9.webp' : '9.zip',
          saveTarget: const SaveTarget.downloadsFolder(),
          ugoiraExport: format,
        );
        expect(job.copyWith().ugoiraExport, format);
        await store.upsertJob(job);
        expect((await store.getJob(job.id))!.ugoiraExport, format);
      }
      final tasks = await store.listTasks();
      expect(tasks.length, 2);
      expect(
        tasks.map((t) => t.ugoiraExport).toSet(),
        UgoiraExport.values.toSet(),
      );
      expect(tasks.map((t) => t.filename).toSet(), {'9.webp', '9.zip'});
    },
  );

  test(
    'fresh database creates the complete schema and persists current jobs across reopen',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'booruflow-schema-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/downloads.db');
      var database = DownloadDatabase(executor: NativeDatabase(file));
      var store = DriftDownloadStore(database);
      final job = DownloadJob.create(
        resourceId: 12,
        sourceId: 'wallhaven',
        batchId: 'batch-september',
        postId: 'abc123',
        variantIndex: 3,
        url: Uri.parse('https://example.com/image.jpg'),
        filename: 'abc123.jpg',
        networkOptions: const DownloadNetworkOptions(
          headers: {'Referer': 'https://example.com/'},
        ),
        validation: const DownloadValidationOptions(expectedBytes: 1234),
        saveTarget: const SaveTarget.downloadsFolder(
          subdirectory: 'wallhaven/September collection',
        ),
      );
      try {
        expect(await store.listTasks(), isEmpty);
        final columns = await database
            .customSelect('PRAGMA table_info(download_jobs)')
            .get();
        final names = columns.map((row) => row.read<String>('name')).toSet();
        expect(
          names,
          containsAll([
            'source_id',
            'post_id',
            'network_options_json',
            'validation_json',
          ]),
        );
        expect(names, isNot(contains('headers_json')));
        final version = await database
            .customSelect('PRAGMA user_version')
            .getSingle();
        expect(version.read<int>('user_version'), 4);
        await store.upsertJob(job);
        await store.updateStatus(job.id, DownloadStatus.downloaded);
        await store.close();
        database = DownloadDatabase(executor: NativeDatabase(file));
        store = DriftDownloadStore(database);
        final restored = (await store.getJob(job.id))!;
        expect(restored.sourceId, 'wallhaven');
        expect(restored.postId, 'abc123');
        expect(restored.networkOptions.toJson(), job.networkOptions.toJson());
        expect(restored.validation.expectedBytes, 1234);
        final restoredSnapshot = (await store.listTasks()).single;
        expect(restoredSnapshot.status, DownloadStatus.downloaded);
        expect(restoredSnapshot.sourceId, 'wallhaven');
        expect(restoredSnapshot.postId, 'abc123');
        expect(restoredSnapshot.batchName, 'September collection');
        await database.customStatement(
          "UPDATE download_jobs SET network_options_json = '{}' WHERE id = ?",
          [job.id],
        );
        expect(await store.getJob(job.id), isNull);
        expect(await store.listTasks(), isEmpty);
      } finally {
        await store.close();
      }
    },
  );
  test(
    'missing optional batch folder metadata keeps history visible without an invented name',
    () async {
      final database = DownloadDatabase(executor: NativeDatabase.memory());
      final store = DriftDownloadStore(database);
      addTearDown(store.close);
      final job = DownloadJob.create(
        resourceId: 1,
        sourceId: 'yande',
        postId: '1',
        variantIndex: 0,
        batchId: 'batch',
        url: Uri.parse('https://example.invalid/1.png'),
        filename: '1.png',
        saveTarget: const SaveTarget.downloadsFolder(
          subdirectory: 'yande/October',
        ),
      );
      await store.upsertJob(job);
      expect((await store.listTasks()).single.batchName, 'October');
      for (final metadata in ['{}', '{']) {
        await database.customStatement(
          'UPDATE download_jobs SET save_target_json = ? WHERE id = ?',
          [metadata, job.id],
        );
        final task = (await store.listTasks()).single;
        expect(task.id, job.id);
        expect(task.batchName, isNull);
        expect(task.status, DownloadStatus.queued);
      }
    },
  );
}
