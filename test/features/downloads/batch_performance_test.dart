import 'dart:ui' as ui;

import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/features/downloads/download_presentation.dart';
import 'package:booruflow/features/downloads/downloads_page.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/features/downloads/widgets/download_task_widgets.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';

import '../../../tool/automation/preview/downloads.dart';
import '../discovery/home_page_test.dart' show browseTestApp;
import 'downloads_v2_test.dart' show task;
import 'support.dart';

void main() {
  test(
    'L15 exposes repeated-name groups without replacing existing download fixtures',
    () {
      final items = downloadPreviewItems('L15');
      expect(items.length, 6);
      expect(items.map((i) => i.snapshot.batchName).toSet(), {'muryo'});
      expect(
        items
            .map((i) => (i.snapshot.updatedAt.day, i.snapshot.batchId))
            .toSet(),
        hasLength(3),
      );
      expect(
        downloadPreviewItems('L13').map((i) => i.snapshot.ugoiraExport).toSet(),
        hasLength(2),
      );
    },
  );
  for (final sameBatchId in [false, true]) {
    testWidgets(
      'same-named groups toggle independently across dates sameBatchId=$sameBatchId',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final items = [
          for (var i = 0; i < 2; i++)
            BooruDownloadItem(
              snapshot: DownloadTaskSnapshot(
                id: 'group-item-$i',
                resourceId: i,
                variantIndex: 0,
                title: 'item $i',
                filename: '$i.png',
                status: DownloadStatus.downloaded,
                saveState: SaveState.saved,
                receivedBytes: 100,
                totalBytes: 100,
                progress: 1,
                localPath: null,
                error: null,
                log: null,
                createdAt: DateTime(2026, 9, 12),
                updatedAt: DateTime(2026, 9, 13 - i),
                batchId: sameBatchId ? 'shared-batch' : 'batch-$i',
                batchName: 'muryo',
              ),
            ),
        ];
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              downloadItemsProvider.overrideWith(
                () => TestDownloadItems(items),
              ),
              downloadManagerProvider.overrideWithValue(TestDownloadManager()),
            ],
            child: browseTestApp(const DownloadsPage()),
          ),
        );
        await tester.pumpAndSettle();
        Finder header(int i) => find.byKey(
          ValueKey(
            'batch:${DateTime(2026, 9, 13 - i).toIso8601String()}:${sameBatchId ? 'shared-batch' : 'batch-$i'}',
          ),
        );
        List<bool> expanded() => tester
            .widgetList<FrostSliverExpand>(
              find.byType(FrostSliverExpand, skipOffstage: false),
            )
            .map((w) => w.expanded)
            .toList();
        expect(expanded(), [true, true]);
        await tester.tap(
          find.descendant(of: header(1), matching: find.text('muryo')),
        );
        await tester.pumpAndSettle();
        expect(expanded(), [true, false]);
        await tester.tap(
          find.descendant(of: header(0), matching: find.text('muryo')),
        );
        await tester.pumpAndSettle();
        expect(expanded(), [false, false]);
        await tester.tap(
          find.descendant(of: header(1), matching: find.text('muryo')),
        );
        await tester.pumpAndSettle();
        expect(expanded(), [false, true]);
        expect(tester.takeException(), isNull);
      },
    );
  }

  test(
    'batch outcome reports persisted statuses without inventing a skipped item',
    () {
      final base = largeDownloadPreviewItems().first.snapshot;
      final cancelled = BooruDownloadItem(
        snapshot: DownloadTaskSnapshot(
          id: 'cancelled',
          resourceId: 1,
          variantIndex: 0,
          title: 'x',
          filename: 'x',
          status: DownloadStatus.cancelled,
          saveState: SaveState.none,
          receivedBytes: 0,
          totalBytes: 1024,
          progress: 1,
          localPath: null,
          error: null,
          log: null,
          createdAt: base.createdAt,
          updatedAt: base.updatedAt,
        ),
      );
      final result = downloadBatchResult([
        ...largeDownloadPreviewItems().take(207),
        cancelled,
      ]);
      expect(result, contains('${t.downloads.saved} 207'));
      expect(result, contains('${t.downloads.cancelled} 1'));
      expect(result, isNot(contains('100%')));
    },
  );

  testWidgets('active batch paints byte-weighted progress and a percentage', (
    tester,
  ) async {
    final batch = [
      for (final (received, total, status) in [
        (60, 100, DownloadStatus.running),
        (0, 300, DownloadStatus.queued),
      ])
        BooruDownloadItem(
          snapshot: DownloadTaskSnapshot(
            id: '$total',
            resourceId: total,
            variantIndex: 0,
            title: '$total',
            filename: '$total.png',
            status: status,
            saveState: SaveState.none,
            receivedBytes: received,
            totalBytes: total,
            progress: received / total,
            localPath: null,
            error: null,
            log: null,
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
            batchId: 'september',
            batchName: '九月收藏',
          ),
        ),
    ];
    final expected =
        batch.fold<int>(0, (sum, item) => sum + item.snapshot.receivedBytes) /
        batch.fold<int>(0, (sum, item) => sum + item.snapshot.totalBytes!);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          downloadItemsProvider.overrideWith(() => TestDownloadItems(batch)),
          downloadManagerProvider.overrideWithValue(TestDownloadManager()),
        ],
        child: browseTestApp(const DownloadsPage()),
      ),
    );
    await tester.pumpAndSettle();
    final header = find.byWidgetPredicate(
      (widget) => widget is FrostListRow && widget.title == '九月收藏',
    );
    final ring = find.descendant(
      of: header,
      matching: find.byType(FrostProgressRing),
    );
    expect(
      tester.widget<FrostProgressRing>(ring).value,
      closeTo(expected, .000001),
    );
    expect(
      find.descendant(
        of: header,
        matching: find.text('${(expected * 100).round()}%'),
      ),
      findsOneWidget,
    );
    final paint = tester.widget<CustomPaint>(
      find.descendant(of: ring, matching: find.byType(CustomPaint)),
    );
    final ink = FrostThemeTokens.of(tester.element(ring)).actionFill.toARGB32();
    final recorder = ui.PictureRecorder();
    paint.painter!.paint(ui.Canvas(recorder), const Size(16, 16));
    final picture = recorder.endRecording();
    final image = picture.toImageSync(16, 16);
    final pixels = await tester.runAsync(() => image.toByteData());
    var filledPixels = 0;
    for (var i = 0; i < pixels!.lengthInBytes; i += 4) {
      if (pixels.getUint8(i) == (ink >> 16 & 255) &&
          pixels.getUint8(i + 1) == (ink >> 8 & 255) &&
          pixels.getUint8(i + 2) == (ink & 255) &&
          pixels.getUint8(i + 3) == 255) {
        filledPixels++;
      }
    }
    image.dispose();
    picture.dispose();
    expect(filledPixels, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'cached group labels update locale without waiting for download events',
    (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            downloadItemsProvider.overrideWith(
              () => TestDownloadItems(largeDownloadPreviewItems()),
            ),
            downloadManagerProvider.overrideWithValue(TestDownloadManager()),
          ],
          child: browseTestApp(const DownloadsPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('${t.downloads.saved} 208'), findsWidgets);
      LocaleSettings.setLocaleSync(AppLocale.zhCn);
      await tester.pumpAndSettle();
      expect(find.text('${t.downloads.saved} 208'), findsWidgets);
      expect(find.text(t.downloads.today), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      LocaleSettings.setLocaleSync(AppLocale.en);
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'completion moves one task between live groups without duplicate keys',
    (tester) async {
      final other = task('other', DownloadStatus.running, batch: 'same');
      final saved = task(
        'saved',
        DownloadStatus.downloaded,
        save: SaveState.saved,
        batch: 'same',
      );
      final items = TestDownloadItems([
        task('moving', DownloadStatus.running, batch: 'same'),
        other,
        saved,
      ]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            downloadItemsProvider.overrideWith(() => items),
            downloadManagerProvider.overrideWithValue(TestDownloadManager()),
          ],
          child: browseTestApp(const DownloadsPage()),
        ),
      );
      await tester.pumpAndSettle();
      items.replace([
        task(
          'moving',
          DownloadStatus.downloaded,
          save: SaveState.saved,
          batch: 'same',
        ),
        other,
        saved,
      ]);
      await tester.pump();
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets(
    'saved-only page has one section gap; offscreen collapse does not pre-scroll',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            downloadItemsProvider.overrideWith(
              () => TestDownloadItems(largeDownloadPreviewItems()),
            ),
            downloadManagerProvider.overrideWithValue(TestDownloadManager()),
          ],
          child: browseTestApp(const DownloadsPage()),
        ),
      );
      await tester.pumpAndSettle();
      final headerBottom = tester
          .getBottomLeft(find.byType(FrostPageHeader))
          .dy;
      expect(
        tester.getTopLeft(find.text(t.downloads.today)).dy,
        closeTo(headerBottom + FrostGap.section, .001),
      );
      final scroll = tester
          .widget<CustomScrollView>(find.byType(CustomScrollView))
          .controller!;
      scroll.jumpTo(500);
      await tester.pump();
      final batch = find.byWidgetPredicate(
        (widget) => widget is FrostListRow && widget.title == 'muryo 1',
        skipOffstage: false,
      );
      expect(tester.getTopLeft(batch).dy, lessThan(headerBottom));
      tester.widget<FrostListRow>(batch).onPressed!();
      expect(scroll.offset, 500);
      await tester.pump();
      expect(scroll.offset, 500);
      await tester.pumpAndSettle();
      // Programmatic collapse does not force an offscreen header into view.
      expect(scroll.offset, lessThanOrEqualTo(scroll.position.maxScrollExtent));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'clicking a partially visible batch header never jumps before collapse',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            downloadItemsProvider.overrideWith(
              () => TestDownloadItems(largeDownloadPreviewItems()),
            ),
            downloadManagerProvider.overrideWithValue(TestDownloadManager()),
          ],
          child: browseTestApp(const DownloadsPage()),
        ),
      );
      await tester.pumpAndSettle();
      final batch = find.byWidgetPredicate(
        (widget) => widget is FrostListRow && widget.title == 'muryo 2',
        skipOffstage: false,
      );
      final scroll = tester
          .widget<CustomScrollView>(find.byType(CustomScrollView))
          .controller!;
      // Set up the observed edge position via framework scrolling, independent of
      // the page's toggle callback. A second layout resolves lazy extent estimates.
      for (var attempt = 0; attempt < 2; attempt++) {
        await Scrollable.ensureVisible(tester.element(batch), alignment: 1);
        await tester.pump();
      }
      scroll.jumpTo(scroll.offset - 20);
      await tester.pump();
      final viewport = tester.getRect(find.byType(CustomScrollView));
      final header = tester.getRect(batch), offset = scroll.offset;
      expect(header.top, lessThan(viewport.bottom));
      expect(header.bottom, greaterThan(viewport.bottom));
      await tester.tapAt(Offset(header.center.dx, header.top + 8));
      expect(scroll.offset, closeTo(offset, .001));
      await tester.pump();
      for (var frame = 0; frame < 50; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(scroll.offset, closeTo(offset, .001));
        expect(tester.getTopLeft(batch).dy, closeTo(header.top, .001));
        expect(tester.takeException(), isNull);
      }
      final firstReveal = tester
          .widgetList<FrostSliverExpand>(
            find.byType(FrostSliverExpand, skipOffstage: false),
          )
          .toList()[1];
      expect(firstReveal.expanded, isFalse);
      final picker = tester.widget<FrostPicker<DownloadFilter>>(
        find
            .byWidgetPredicate((w) => w is FrostPicker<DownloadFilter>)
            .hitTestable(),
      );
      picker.onChanged!(DownloadFilter.failed);
      await tester.pumpAndSettle();
      picker.onChanged!(DownloadFilter.all);
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<FrostSliverExpand>(
              find.byType(FrostSliverExpand, skipOffstage: false),
            )
            .toList()[1]
            .expanded,
        isFalse,
      );
    },
  );

  testWidgets('3x208 batch reveal constructs only a viewport of task rows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final items = TestDownloadItems(largeDownloadPreviewItems());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          downloadItemsProvider.overrideWith(() => items),
          downloadManagerProvider.overrideWithValue(TestDownloadManager()),
        ],
        child: browseTestApp(const DownloadsPage()),
      ),
    );
    await tester.pumpAndSettle();
    // Other groups are already mounted while all three are collapsed.
    await tester.tap(find.text('muryo 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('muryo 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('muryo 3'));
    await tester.pumpAndSettle();
    var unrelatedRebuilds = 0;
    final previous = debugOnRebuildDirtyWidget;
    debugOnRebuildDirtyWidget = (element, builtOnce) {
      previous?.call(element, builtOnce);
      if (element.widget case FrostListRow(title: 'muryo 2' || 'muryo 3')) {
        unrelatedRebuilds++;
      }
    };
    addTearDown(() => debugOnRebuildDirtyWidget = previous);
    final counts = <int>[];
    for (var repeat = 0; repeat < 2; repeat++) {
      await tester.tap(find.text('muryo 1'));
      await tester.pump();
      for (var frame = 0; frame < 30; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        counts.add(
          find.byType(DownloadTaskTile, skipOffstage: false).evaluate().length,
        );
      }
    }
    // ignore: avoid_print
    print(
      'R4 mounted task rows: max=${counts.reduce((a, b) => a > b ? a : b)} frames=$counts',
    );
    expect(counts.every((count) => count < 35), isTrue);
    expect(unrelatedRebuilds, 0);
    expect(tester.takeException(), isNull);
  });
}
