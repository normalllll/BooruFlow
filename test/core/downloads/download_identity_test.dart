import 'package:booruflow/core/downloads/download_models.dart';
import 'package:flutter_test/flutter_test.dart';

DownloadTaskSnapshot _task(
  DownloadStatus status, {
  SaveState save = SaveState.none,
  String? source = 'yande',
  String? post = '7',
  int variant = 0,
}) => DownloadTaskSnapshot(
  id: 'any',
  sourceId: source,
  postId: post,
  resourceId: 1,
  variantIndex: variant,
  title: 't',
  filename: 'f',
  status: status,
  saveState: save,
  receivedBytes: 0,
  totalBytes: null,
  progress: 0,
  localPath: null,
  error: null,
  log: null,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  const identity = DownloadIdentity(
    sourceId: 'yande',
    postId: '7',
    variantIndex: 0,
  );

  test('queued, running, paused, downloaded and saving tasks block', () {
    for (final status in [
      DownloadStatus.queued,
      DownloadStatus.running,
      DownloadStatus.paused,
      DownloadStatus.downloaded,
    ]) {
      expect(
        downloadBlockFor(identity, [_task(status)]),
        DownloadBlock.inProgress,
        reason: '$status',
      );
    }
    expect(
      downloadBlockFor(identity, [
        _task(DownloadStatus.downloaded, save: SaveState.saving),
      ]),
      DownloadBlock.inProgress,
    );
  });

  test('a saved task blocks as saved, whatever else is listed', () {
    expect(
      downloadBlockFor(identity, [
        _task(DownloadStatus.running),
        _task(DownloadStatus.downloaded, save: SaveState.saved),
      ]),
      DownloadBlock.saved,
    );
  });

  test('failed and cancelled tasks never block, so retry stays possible', () {
    expect(downloadBlockFor(identity, [_task(DownloadStatus.failed)]), isNull);
    expect(
      downloadBlockFor(identity, [_task(DownloadStatus.cancelled)]),
      isNull,
    );
    expect(
      downloadBlockFor(identity, [
        _task(DownloadStatus.downloaded, save: SaveState.failed),
      ]),
      isNull,
    );
  });

  test('only the same source, post and variant counts', () {
    for (final other in [
      _task(DownloadStatus.running, source: 'konachan'),
      _task(DownloadStatus.running, post: '8'),
      _task(DownloadStatus.running, variant: 1),
      _task(DownloadStatus.running, source: null, post: null),
    ]) {
      expect(downloadBlockFor(identity, [other]), isNull);
    }
  });
}
