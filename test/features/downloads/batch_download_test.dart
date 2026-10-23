import 'dart:async';

import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/discovery/collection_logic.dart';
import 'package:booruflow/features/downloads/batch/batch_download_dialog.dart';
import 'package:booruflow/features/downloads/batch/logic.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/services/booru_downloads.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';

import '../discovery/home_page_test.dart' show browseTestApp;
import '../posts/detail_viewer_v2_test.dart' show data;
import 'support.dart';

class _Session extends BooruSession {
  @override
  BooruSessionState build() =>
      const BooruSessionState(sourceId: 'yande', revision: 0);
}

class _Downloads extends BooruDownloads {
  Completer<void>? gate;
  String? fail;
  final prepared = <String>[];
  @override
  Future<void> initialize() async {}
  @override
  void beginBatch(String batchId) {}
  @override
  void endBatch(String batchId) {}
  @override
  Future<DownloadJob> prepare(
    Post post, {
    String? batchId,
    SaveTarget? saveTarget,
  }) async {
    prepared.add(post.id);
    await gate?.future;
    if (post.id == fail) {
      fail = null;
      throw StateError('preparation failed');
    }
    return DownloadJob.create(
      resourceId: post.resourceId,
      sourceId: post.sourceId,
      postId: post.id,
      variantIndex: MediaVariantKind.original.index,
      url: Uri.parse('https://example.invalid/${post.id}.png'),
      filename: '${post.id}.png',
      saveTarget: saveTarget!,
      batchId: batchId,
    );
  }
}

BatchDownloadRequest request(CollectionLoader loader) => BatchDownloadRequest(
  sourceName: 'Yande.re',
  key: CollectionKey(
    sourceId: 'yande',
    request: const FeedCollectionRequest(),
    ratings: [],
    revision: 0,
  ),
  loader: loader,
);
const location = BatchSaveLocation(
  root: 'test/downloads',
  target: SaveTarget.downloadsFolder(directory: 'test/downloads'),
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'closing and reopening during enqueue keeps the same operation; repeated submit does not duplicate',
    () async {
      final manager = TestDownloadManager(), downloads = _Downloads();
      final container = ProviderContainer.test(
        overrides: [
          booruSessionProvider.overrideWith(_Session.new),
          downloadManagerProvider.overrideWithValue(manager),
          booruDownloadsProvider.overrideWithValue(downloads),
        ],
      );
      final input = request(
        (_, _) async =>
            PostPage(items: [data('1'), data('2')], exhausted: true),
      );
      var subscription = container.listen(
        batchDownloadProvider(input),
        (_, _) {},
      );
      final logic = container.read(batchDownloadProvider(input).notifier);
      await logic.fetch(2);
      logic.setFolder('October');
      downloads.gate = Completer<void>();
      final operation = logic.enqueue(location);
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(batchDownloadProvider(input)).phase,
        BatchPhase.enqueueing,
      );
      subscription.close();
      await container.pump();
      // This is the same retained family when the dialog reopens.
      subscription = container.listen(batchDownloadProvider(input), (_, _) {});
      expect(
        identical(container.read(batchDownloadProvider(input).notifier), logic),
        true,
      );
      await logic.enqueue(location);
      downloads.gate!.complete();
      await operation;
      final result = container.read(batchDownloadProvider(input));
      expect(result.phase, BatchPhase.finished);
      expect(result.enqueued, 2);
      expect(result.failed, isEmpty);
      expect(manager.jobs.map((job) => job.postId), ['1', '2']);
      expect(manager.jobs.map((job) => job.saveTarget.subdirectory).toSet(), {
        'October',
      });
      subscription.close();
    },
  );
  test(
    'partial preparation failure retains successes and retries only failed posts',
    () async {
      final manager = TestDownloadManager(),
          downloads = _Downloads()..fail = '2';
      final container = ProviderContainer.test(
        overrides: [
          booruSessionProvider.overrideWith(_Session.new),
          downloadManagerProvider.overrideWithValue(manager),
          booruDownloadsProvider.overrideWithValue(downloads),
        ],
      );
      final input = request(
        (_, _) async =>
            PostPage(items: [data('1'), data('2')], exhausted: true),
      );
      final subscription = container.listen(
        batchDownloadProvider(input),
        (_, _) {},
      );
      final logic = container.read(batchDownloadProvider(input).notifier);
      await logic.fetch(2);
      logic.setFolder('October');
      await logic.enqueue(location);
      expect(
        container
            .read(batchDownloadProvider(input))
            .failed
            .map((post) => post.id),
        ['2'],
      );
      await logic.retryEnqueue();
      expect(container.read(batchDownloadProvider(input)).enqueued, 2);
      expect(manager.jobs.map((job) => job.postId), ['1', '2']);
      expect(downloads.prepared, ['1', '2', '2']);
      subscription.close();
    },
  );
  test(
    'stopping collection ignores late pages and preserves already found posts',
    () async {
      final later = Completer<PostPage>();
      var page = 0;
      final input = request(
        (_, _) async => page++ == 0
            ? PostPage(items: [data('1')], nextCursor: 'next', exhausted: false)
            : later.future,
      );
      final container = ProviderContainer.test(
        overrides: [booruSessionProvider.overrideWith(_Session.new)],
      );
      final subscription = container.listen(
        batchDownloadProvider(input),
        (_, _) {},
      );
      final logic = container.read(batchDownloadProvider(input).notifier);
      final fetch = logic.fetch(10);
      await Future<void>.delayed(Duration.zero);
      logic.stopFetching();
      later.complete(PostPage(items: [data('2')], exhausted: true));
      await fetch;
      final result = container.read(batchDownloadProvider(input));
      expect(result.phase, BatchPhase.ready);
      expect(result.fetchEnd, BatchFetchEnd.stopped);
      expect(result.items.map((post) => post.id), ['1']);
      subscription.close();
    },
  );
  for (final width in [390.0, 1024.0]) {
    testWidgets('batch setup cancels and reopens without fetching at $width', (
      tester,
    ) async {
      LocaleSettings.setLocaleSync(AppLocale.en);
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var loads = 0;
      final input = request((_, _) async {
        loads++;
        return PostPage(items: [], exhausted: true);
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            batchSaveLocationProvider(
              'yande',
            ).overrideWith((ref) async => location),
          ],
          child: browseTestApp(
            Builder(
              builder: (context) => Center(
                child: FrostButton(
                  label: 'Open batch',
                  onPressed: () => showBatchDownloadDialog(context, input),
                ),
              ),
            ),
          ),
        ),
      );
      for (var attempt = 0; attempt < 2; attempt++) {
        await tester.tap(find.text('Open batch'));
        await tester.pumpAndSettle();
        expect(find.byType(BatchDownloadDialog), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is FrostTextField &&
                widget.label == t.batchDownload.folderLabel,
          ),
          findsNothing,
        );
        final cancel = find.text(t.generic.cancel).hitTestable().last;
        await tester.ensureVisible(cancel);
        await tester.tap(cancel);
        await tester.pumpAndSettle();
        expect(find.byType(BatchDownloadDialog), findsNothing);
        expect(tester.takeException(), isNull);
      }
      expect(loads, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    });
    testWidgets(
      'batch fetching closes safely before a page returns at $width',
      (tester) async {
        LocaleSettings.setLocaleSync(AppLocale.en);
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final page = Completer<PostPage>();
        final input = request((_, _) => page.future);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              booruSessionProvider.overrideWith(_Session.new),
              batchSaveLocationProvider(
                'yande',
              ).overrideWith((ref) async => location),
            ],
            child: browseTestApp(
              Builder(
                builder: (context) => Center(
                  child: FrostButton(
                    label: 'Open batch',
                    onPressed: () => showBatchDownloadDialog(context, input),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open batch'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.batchDownload.start));
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.text(t.batchDownload.stop), findsOneWidget);
        Navigator.of(
          tester.element(find.byType(BatchDownloadDialog)),
        ).pop(false);
        await tester.pumpAndSettle();
        expect(find.byType(BatchDownloadDialog), findsNothing);
        expect(tester.takeException(), isNull);
        page.complete(PostPage(items: [data('1')], exhausted: true));
        await tester.pump();
        await tester.pump();
        expect(find.byType(BatchDownloadDialog), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
    testWidgets('batch modal submits and continues after closing at $width', (
      tester,
    ) async {
      LocaleSettings.setLocaleSync(AppLocale.en);
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final manager = TestDownloadManager(),
          downloads = _Downloads()..gate = Completer<void>();
      final input = request(
        (_, _) async =>
            PostPage(items: [data('1'), data('2')], exhausted: true),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            booruSessionProvider.overrideWith(_Session.new),
            downloadManagerProvider.overrideWithValue(manager),
            booruDownloadsProvider.overrideWithValue(downloads),
            batchSaveLocationProvider(
              'yande',
            ).overrideWith((ref) async => location),
          ],
          child: browseTestApp(
            Builder(
              builder: (context) => Center(
                child: FrostButton(
                  label: 'Open batch',
                  onPressed: () => showBatchDownloadDialog(context, input),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open batch'));
      await tester.pumpAndSettle();
      expect(find.byType(FrostDialog), findsOneWidget);
      await tester.tap(find.text(t.batchDownload.start));
      await tester.pumpAndSettle();
      final folder = find.byWidgetPredicate(
        (widget) =>
            widget is FrostTextField &&
            widget.label == t.batchDownload.folderLabel,
      );
      await tester.ensureVisible(folder);
      await tester.enterText(folder, 'October');
      await tester.pumpAndSettle();
      final submit = find.text(t.batchDownload.enqueue(count: '2'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pump(const Duration(milliseconds: 350));
      final cancel = find.text(t.batchDownload.close).hitTestable();
      await tester.ensureVisible(cancel.last);
      await tester.tap(cancel.last);
      await tester.pumpAndSettle();
      expect(find.byType(BatchDownloadDialog), findsNothing);
      downloads.gate!.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(manager.jobs.length, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
