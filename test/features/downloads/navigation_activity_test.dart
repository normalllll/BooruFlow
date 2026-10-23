import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Items extends DownloadItems {
  _Items(this.items);
  final List<BooruDownloadItem> items;
  @override
  List<BooruDownloadItem> build() => items;
}

BooruDownloadItem item(
  String id,
  DownloadStatus status,
  int received,
  int? total, {
  SaveState save = SaveState.none,
}) => BooruDownloadItem(
  snapshot: DownloadTaskSnapshot(
    id: id,
    resourceId: 1,
    variantIndex: 0,
    title: id,
    filename: id,
    status: status,
    saveState: save,
    receivedBytes: received,
    totalBytes: total,
    progress: 0,
    localPath: null,
    error: null,
    log: null,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  ),
);

void main() {
  ({int count, double? progress}) activity(List<BooruDownloadItem> items) {
    final container = ProviderContainer.test(
      overrides: [downloadItemsProvider.overrideWith(() => _Items(items))],
    );
    return container.read(downloadActivityProvider);
  }

  test(
    'navigation includes queued running paused and saving, and weights bytes',
    () {
      expect(
        activity([
          item('a', DownloadStatus.queued, 0, 100),
          item('b', DownloadStatus.running, 300, 600),
          item('c', DownloadStatus.paused, 100, 200),
          item(
            'd',
            DownloadStatus.downloaded,
            100,
            100,
            save: SaveState.saving,
          ),
          item('e', DownloadStatus.downloaded, 200, 200, save: SaveState.saved),
          item('f', DownloadStatus.failed, 0, 10),
        ]),
        (count: 4, progress: .5),
      );
    },
  );
  test(
    'unknown size retains count without misleading determinate progress',
    () {
      expect(activity([item('a', DownloadStatus.running, 50, null)]), (
        count: 1,
        progress: null,
      ));
      expect(activity([item('a', DownloadStatus.queued, 0, 0)]), (
        count: 1,
        progress: null,
      ));
    },
  );
  test(
    'received bytes are clamped per task and empty activity hides status',
    () {
      expect(
        activity([
          item('a', DownloadStatus.running, 500, 100),
          item('b', DownloadStatus.running, -100, 100),
        ]),
        (count: 2, progress: .5),
      );
      expect(activity([]), (count: 0, progress: null));
    },
  );
}
