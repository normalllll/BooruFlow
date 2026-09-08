import 'dart:io';

import 'package:booruflow/core/downloads/download_database.dart'
    hide DownloadJob;
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/downloads/download_store.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
        postId: 'abc123',
        variantIndex: 3,
        url: Uri.parse('https://example.com/image.jpg'),
        filename: 'abc123.jpg',
        networkOptions: const DownloadNetworkOptions(
          headers: {'Referer': 'https://example.com/'},
        ),
        validation: const DownloadValidationOptions(expectedBytes: 1234),
        saveTarget: const SaveTarget.downloadsFolder(subdirectory: 'wallhaven'),
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
        expect(version.read<int>('user_version'), 1);
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
        expect(
          (await store.listTasks()).single.status,
          DownloadStatus.downloaded,
        );
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
}
