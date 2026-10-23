import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/features/downloads/download_presentation.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support.dart';

BooruDownloadItem sample(
  int received,
  int seconds, {
  DownloadStatus status = DownloadStatus.running,
  int? total = 10000,
}) => BooruDownloadItem(
  snapshot: DownloadTaskSnapshot(
    id: 'job',
    resourceId: 1,
    variantIndex: 0,
    title: 'job',
    filename: 'job.png',
    status: status,
    saveState: SaveState.none,
    receivedBytes: received,
    totalBytes: total,
    progress: .5,
    localPath: null,
    error: null,
    log: null,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026).add(Duration(seconds: seconds)),
  ),
);

void main() {
  test(
    'rates require two engine samples and discard reset, pause and removed jobs',
    () {
      final items = TestDownloadItems([sample(1000, 0)]);
      final container = ProviderContainer.test(
        overrides: [downloadItemsProvider.overrideWith(() => items)],
      );
      container.listen(downloadTransferRatesProvider, (_, _) {});
      expect(container.read(downloadTransferRatesProvider), isEmpty);
      items.replace([sample(3000, 2)]);
      expect(container.read(downloadTransferRatesProvider), {'job': 1000.0});
      items.replace([sample(3000, 2)]);
      expect(container.read(downloadTransferRatesProvider), {'job': 1000.0});
      items.replace([sample(3500, 3)]);
      expect(container.read(downloadTransferRatesProvider), {'job': 500.0});
      items.replace([sample(50, 4)]);
      expect(container.read(downloadTransferRatesProvider), isEmpty);
      items.replace([sample(550, 5)]);
      expect(container.read(downloadTransferRatesProvider), {'job': 500.0});
      items.replace([sample(550, 5, status: DownloadStatus.paused)]);
      expect(container.read(downloadTransferRatesProvider), isEmpty);
      items.replace([sample(550, 5)]);
      expect(container.read(downloadTransferRatesProvider), isEmpty);
      items.replace([sample(750, 4)]);
      expect(container.read(downloadTransferRatesProvider), isEmpty);
      items.replace([]);
      expect(container.read(downloadTransferRatesProvider), isEmpty);
    },
  );
  test(
    'summary weights actual bytes and omits unknown speeds and remaining sizes',
    () {
      final known = sample(3000, 2);
      expect(downloadTransferSummary([known], const {}).rate, isNull);
      expect(downloadTransferSummary([known], const {}).remaining, isNull);
      final summary = downloadTransferSummary([known], const {'job': 1000});
      expect(summary.count, 1);
      expect(summary.progress, .3);
      expect(summary.rate, 1000);
      expect(summary.remaining, downloadRemainingTime(7));
      expect(
        downloadTransferSummary(
          [sample(3000, 2, total: null)],
          const {'job': 1000},
        ).progress,
        isNull,
      );
      expect(
        downloadTransferSummary(
          [sample(3000, 2, total: null)],
          const {'job': 1000},
        ).remaining,
        isNull,
      );
      expect(downloadRemaining(known.snapshot, 0), isNull);
    },
  );
}
