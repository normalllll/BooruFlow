import 'dart:convert';
import 'dart:ui' as ui;

import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/features/downloads/download_presentation.dart';
import 'package:booruflow/features/downloads/downloads_page.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/features/downloads/widgets/download_artwork.dart';
import 'package:booruflow/features/downloads/widgets/download_task_details.dart';
import 'package:booruflow/features/downloads/widgets/download_task_widgets.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/ui/custom/download_flight.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../support/browse_support.dart' show browseTestApp;
import 'support.dart';

BooruDownloadItem task(
  String id,
  DownloadStatus status, {
  SaveState save = SaveState.none,
  String? batch,
}) => BooruDownloadItem(
  snapshot: DownloadTaskSnapshot(
    id: id,
    resourceId: 123,
    variantIndex: 0,
    title: id,
    filename: '$id.png',
    status: status,
    saveState: save,
    receivedBytes: 50,
    totalBytes: 100,
    progress: .5,
    localPath: null,
    error: null,
    log: null,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    batchId: batch,
  ),
);

class _FixedRates extends DownloadTransferRates {
  @override
  Map<String, double> build() => {'job': 1000.0};
}

void main() {
  setUpAll(initializeDateFormatting);
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));
  for (final width in [390.0, 720.0, 1024.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'settled download rows keep complete keyline ink and action hits',
        (tester) async {
          tester.view.physicalSize = const Size(1440, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                downloadItemsProvider.overrideWith(
                  () => TestDownloadItems([
                    task('running', DownloadStatus.running),
                  ]),
                ),
                downloadManagerProvider.overrideWithValue(
                  TestDownloadManager(),
                ),
              ],
              child: browseTestApp(const DownloadsPage()),
            ),
          );
          await tester.pumpAndSettle();
          final tile = find.byType(DownloadTaskTile);
          final clips = tester.widgetList<ClipRect>(
            find.ancestor(of: tile, matching: find.byType(ClipRect)),
          );
          expect(
            clips.where((clip) => clip.clipBehavior != Clip.none),
            isEmpty,
          );
          final mouse = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          await mouse.addPointer(location: Offset.zero);
          addTearDown(mouse.removePointer);
          await mouse.moveTo(tester.getCenter(tile));
          await tester.pumpAndSettle();
          final more = find
              .descendant(
                of: tile,
                matching: find.byWidgetPredicate(
                  (w) => w is FrostTooltip && w.message == t.frost.more,
                ),
              )
              .hitTestable();
          final target = tester.getRect(more);
          await tester.tapAt(Offset(target.right - 1, target.center.dy));
          await tester.pumpAndSettle();
          expect(find.text(t.downloads.cancel), findsOneWidget);
          expect(tester.widget<DownloadTaskTile>(tile).expanded, isFalse);
          expect(tester.takeException(), isNull);
        },
      );
      testWidgets('download page and details first frame $width/$scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              downloadItemsProvider.overrideWith(
                () => TestDownloadItems([
                  task('running', DownloadStatus.running),
                ]),
              ),
              downloadManagerProvider.overrideWithValue(TestDownloadManager()),
            ],
            child: browseTestApp(const DownloadsPage(), scale: scale),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.byType(FrostPageHeader), findsOneWidget);
        // The batch action is a priority-aware toolbar control. Measurement
        // variants are not interactive; inspect the actual live form.
        expect(
          find
              .byWidgetPredicate(
                (w) =>
                    w is FrostButton && w.label == t.downloads.pauseAll ||
                    w is FrostTooltip && w.message == t.frost.more,
              )
              .hitTestable(),
          findsWidgets,
        );
        expect(find.byType(FrostTaskRow), findsOneWidget);
        await tester.tap(find.text('running.png'));
        await tester.pumpAndSettle();
        expect(find.byType(DownloadTaskDetails), findsOneWidget);
        expect(
          tester
              .widget<DownloadTaskTile>(find.byType(DownloadTaskTile))
              .expanded,
          isTrue,
        );
        final selectedFill = FrostThemeTokens.of(
          tester.element(find.byType(DownloadTaskTile)),
        ).selectionFill;
        expect(
          find.descendant(
            of: find.byType(DownloadTaskTile),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is DecoratedBox &&
                  w.decoration is ShapeDecoration &&
                  (w.decoration as ShapeDecoration).color == selectedFill,
            ),
          ),
          findsWidgets,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      });
    }
  }
  testWidgets(
    'same-day separators exist before a row expands and retain geometry',
    (tester) async {
      tester.view.physicalSize = const Size(2160, 1800);
      tester.view.devicePixelRatio = 1.5;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            downloadItemsProvider.overrideWith(
              () => TestDownloadItems([
                task('running', DownloadStatus.running),
                task(
                  'saved-a',
                  DownloadStatus.downloaded,
                  save: SaveState.saved,
                ),
                task(
                  'saved-b',
                  DownloadStatus.downloaded,
                  save: SaveState.saved,
                ),
              ]),
            ),
            downloadManagerProvider.overrideWithValue(TestDownloadManager()),
          ],
          child: browseTestApp(const DownloadsPage()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(FrostTabBar),
          matching: find.textContaining(t.downloads.completed),
        ),
      );
      await tester.pumpAndSettle();
      Finder tile(String title) => find.ancestor(
        of: find.text(title),
        matching: find.byType(DownloadTaskTile),
      );
      Finder entry(String title) =>
          find.ancestor(of: tile(title), matching: find.byType(Column)).first;
      void expectSameDaySeparator() {
        expect(
          find.descendant(
            of: entry('saved-a.png'),
            matching: find.byType(FrostDivider),
          ),
          findsNothing,
        );
        final divider = find.descendant(
          of: entry('saved-b.png'),
          matching: find.byType(FrostDivider),
        );
        expect(divider, findsOneWidget);
        final line = tester.getRect(divider);
        expect(line.height, closeTo(1 / 1.5, .001));
        expect(
          line.top,
          closeTo(tester.getBottomLeft(tile('saved-a.png')).dy, .001),
        );
        expect(
          line.right,
          closeTo(tester.getBottomRight(tile('saved-b.png')).dx, .001),
        );
      }

      expectSameDaySeparator();
      await tester.tap(find.text('saved-a.png'));
      await tester.pumpAndSettle();
      expect(find.byType(DownloadTaskDetails), findsOneWidget);
      expectSameDaySeparator();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'expanded batch does not clip a pixel-snapped same-day separator',
    (tester) async {
      tester.view.physicalSize = const Size(2160, 1800);
      tester.view.devicePixelRatio = 1.5;
      addTearDown(tester.view.reset);
      final boundaryKey = GlobalKey();
      var offset = 0.0;
      late StateSetter move;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            downloadItemsProvider.overrideWith(
              () => TestDownloadItems([
                task('batch-running', DownloadStatus.running, batch: 'batch'),
                task('batch-queued', DownloadStatus.queued, batch: 'batch'),
                task('running', DownloadStatus.running),
                task('failed', DownloadStatus.failed),
                task(
                  'saved-a',
                  DownloadStatus.downloaded,
                  save: SaveState.saved,
                ),
                task(
                  'saved-b',
                  DownloadStatus.downloaded,
                  save: SaveState.saved,
                ),
              ]),
            ),
            downloadManagerProvider.overrideWithValue(TestDownloadManager()),
          ],
          child: browseTestApp(
            RepaintBoundary(
              key: boundaryKey,
              child: ColoredBox(
                color: Color(0xffffffff),
                child: StatefulBuilder(
                  builder: (context, update) {
                    move = update;
                    return Transform.translate(
                      offset: Offset(0, offset),
                      child: const DownloadsPage(),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('batch-queued.png'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(FrostTabBar),
          matching: find.textContaining(t.downloads.completed),
        ),
      );
      await tester.pumpAndSettle();
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(
        location: tester.getCenter(find.text('saved-a.png')),
      );
      addTearDown(mouse.removePointer);
      await tester.pumpAndSettle();
      final tile = find.ancestor(
        of: find.text('saved-b.png'),
        matching: find.byType(DownloadTaskTile),
      );
      final entry = find
          .ancestor(of: tile, matching: find.byType(Column))
          .first;
      final divider = find.descendant(
        of: entry,
        matching: find.byType(FrostDivider),
      );
      expect(divider, findsOneWidget);
      for (final next in [0.0, .1, .2, 1 / 3, .4, .5, .6]) {
        move(() => offset = next);
        await tester.pump();
        final line = tester.getRect(divider);
        final color = Color.alphaBlend(
          FrostThemeTokens.of(tester.element(divider)).separator,
          const Color(0xffffffff),
        );
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final pixel = await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1.5);
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          final origin = boundary.localToGlobal(Offset.zero);
          final x = ((line.center.dx - origin.dx) * 1.5).round();
          // The hairline is snapped to one physical row; which one depends on
          // the fraction of the line's top, so read the row it can land on.
          final top = ((line.top - origin.dy) * 1.5).floor();
          return [
            for (final y in [top, top + 1])
              () {
                final index = (y * image.width + x) * 4;
                return Color.fromARGB(
                  bytes.getUint8(index + 3),
                  bytes.getUint8(index),
                  bytes.getUint8(index + 1),
                  bytes.getUint8(index + 2),
                );
              }(),
          ];
        });
        expect(
          pixel!.any(
            (sample) =>
                (sample.r - color.r).abs() <= 1 / 255 &&
                (sample.g - color.g).abs() <= 1 / 255 &&
                (sample.b - color.b).abs() <= 1 / 255,
          ),
          isTrue,
          reason: 'offset=$offset line=$line samples=$pixel',
        );
      }
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'retained inactive downloads keep their expanded row across a resize',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var active = true;
      late StateSetter update;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            downloadItemsProvider.overrideWith(
              () => TestDownloadItems([task('job', DownloadStatus.running)]),
            ),
            downloadManagerProvider.overrideWithValue(TestDownloadManager()),
          ],
          child: browseTestApp(
            StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return IndexedStack(
                  index: active ? 0 : 1,
                  children: [
                    TickerMode(enabled: active, child: const DownloadsPage()),
                    const Center(child: Text('Other page')),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('job.png'));
      await tester.pumpAndSettle();
      final retained = tester.state(find.byType(DownloadsPage));
      update(() => active = false);
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(390, 900);
      await tester.pumpAndSettle();
      expect(find.text('Other page').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      update(() => active = true);
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(DownloadsPage)), same(retained));
      expect(find.byType(DownloadTaskDetails), findsOneWidget);
      expect(
        tester.widget<DownloadTaskTile>(find.byType(DownloadTaskTile)).expanded,
        isTrue,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'paused, retry download and retry save call their distinct manager operations',
    (tester) async {
      final manager = TestDownloadManager();
      var current = task('job', DownloadStatus.running);
      late StateSetter update;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [downloadManagerProvider.overrideWithValue(manager)],
          child: browseTestApp(
            Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 700,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    update = setState;
                    return DownloadTaskTile(task: current);
                  },
                ),
              ),
            ),
          ),
        ),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(750, 550));
      for (final entry in [
        (DownloadStatus.running, SaveState.none, t.downloads.pause, 'pause'),
        (DownloadStatus.paused, SaveState.none, t.downloads.resume, 'resume'),
        (DownloadStatus.failed, SaveState.none, t.generic.retry, 'retry'),
        (
          DownloadStatus.downloaded,
          SaveState.failed,
          t.downloads.retrySave,
          'retrySave',
        ),
      ]) {
        update(() => current = task('job', entry.$1, save: entry.$2));
        await tester.pump();
        await mouse.moveTo(tester.getCenter(find.byType(DownloadTaskTile)));
        await tester.pump(const Duration(milliseconds: 200));
        final button = find
            .byWidgetPredicate(
              (widget) => widget is FrostButton && widget.label == entry.$3,
            )
            .hitTestable();
        await mouse.moveTo(tester.getCenter(button));
        await tester.pumpAndSettle();
        await mouse.down(tester.getCenter(button));
        await mouse.up();
        await tester.pumpAndSettle();
        expect(manager.calls.last, (entry.$4, 'job'));
      }
      await mouse.removePointer();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'large batch remains lazy and completion stays visible for 600 ms before removal',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final items = TestDownloadItems([
        for (var i = 0; i < 1000; i++)
          task('job$i', DownloadStatus.running, batch: 'batch'),
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
      expect(find.byType(FrostTaskRow).evaluate().length, lessThan(30));
      items.replace([
        task(
          'job0',
          DownloadStatus.downloaded,
          save: SaveState.saved,
          batch: 'batch',
        ),
        ...items.initial.skip(1),
      ]);
      await tester.pump();
      expect(find.text('job0.png'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('job0.png'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('job0.png'), findsNothing);
      await tester.tap(find.textContaining(t.downloads.batch).first);
      await tester.pumpAndSettle();
      expect(find.byType(FrostTaskRow), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'download flight lands on measured target and reduced motion omits it',
    (tester) async {
      final key = GlobalKey<DownloadFlightHostState>();
      var reduced = false;
      late StateSetter update;
      final image = MemoryImage(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+j3i0AAAAASUVORK5CYII=',
        ),
      );
      await tester.pumpWidget(
        browseTestApp(
          StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(disableAnimations: reduced),
                child: DownloadFlightHost(
                  key: key,
                  child: const Align(
                    alignment: Alignment.bottomRight,
                    child: DownloadFlightTarget(
                      child: SizedBox(width: 60, height: 50),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      key.currentState!.fly(
        source: const Rect.fromLTWH(50, 50, 80, 100),
        image: image,
      );
      await tester.pump();
      expect(find.byType(Image), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      final flying = tester.getRect(find.byType(Image));
      expect(flying.center.dx, greaterThan(90));
      await tester.pumpAndSettle();
      expect(key.currentState!.landed.value, 1);
      expect(find.byType(Image), findsNothing);
      update(() => reduced = true);
      await tester.pump();
      key.currentState!.fly(
        source: const Rect.fromLTWH(50, 50, 80, 100),
        image: image,
      );
      await tester.pump();
      expect(find.byType(Image), findsNothing);
      expect(key.currentState!.landed.value, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'new tasks retain mounted task State and artwork while inserting at the front',
    (tester) async {
      final items = TestDownloadItems([
        task('stable', DownloadStatus.running),
        task('next', DownloadStatus.paused),
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
      final row = find.byKey(const ValueKey('task:stable'));
      final before = tester.state(row);
      final artwork = find.descendant(
        of: row,
        matching: find.byType(DownloadArtwork),
      );
      final beforeArtwork = tester.state(artwork);
      items.replace([task('new', DownloadStatus.queued), ...items.initial]);
      await tester.pumpAndSettle();
      expect(identical(tester.state(row), before), true);
      expect(identical(tester.state(artwork), beforeArtwork), true);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'expanded row keeps pointer actions hidden until hover or row keyboard focus without moving text',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            downloadManagerProvider.overrideWithValue(TestDownloadManager()),
            downloadItemsProvider.overrideWith(() => TestDownloadItems([])),
          ],
          child: browseTestApp(
            Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 700,
                child: DownloadTaskTile(
                  task: task('job', DownloadStatus.running),
                  expanded: true,
                  onTaskTap: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      final title = find.text('job.png');
      final before = tester.getRect(title);
      // The row's pointer action; the details below it have their own Pause.
      final pause = find
          .descendant(
            of: find.byType(FrostSwipeActions),
            matching: find.byWidgetPredicate(
              (w) => w is FrostButton && w.label == t.downloads.pause,
            ),
          )
          .hitTestable();
      expect(pause, findsNothing);
      expect(
        tester
            .widget<FrostSwipeActions>(find.byType(FrostSwipeActions))
            .showsPointerActions,
        isFalse,
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(750, 550));
      await mouse.moveTo(tester.getCenter(title));
      await tester.pumpAndSettle();
      expect(pause, findsOneWidget);
      expect(tester.getRect(title), before);
      await mouse.moveTo(const Offset(750, 550));
      await tester.pumpAndSettle();
      expect(pause, findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(pause, findsOneWidget);
      expect(tester.getRect(title), before);
      await mouse.removePointer();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'running and saved rows share 48 thumbnails and title keylines, one row expands at a time',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            downloadItemsProvider.overrideWith(
              () => TestDownloadItems([
                task('running', DownloadStatus.running),
                task('paused', DownloadStatus.paused),
                task('saved', DownloadStatus.downloaded, save: SaveState.saved),
              ]),
            ),
            downloadManagerProvider.overrideWithValue(TestDownloadManager()),
          ],
          child: browseTestApp(const DownloadsPage()),
        ),
      );
      await tester.pumpAndSettle();
      Finder title(String value) => find.descendant(
        of: find.byType(DownloadTaskTile),
        matching: find.text('$value.png'),
      );
      void expectThumbnails(int count) {
        final thumbnails = find.descendant(
          of: find.byType(DownloadTaskTile),
          matching: find.byType(DownloadArtwork),
        );
        expect(thumbnails, findsNWidgets(count));
        for (final thumb in thumbnails.evaluate()) {
          expect(
            tester.getSize(find.byElementPredicate((e) => identical(e, thumb))),
            const Size(48, 48),
          );
        }
      }

      final keyline = tester.getRect(title('running')).left;
      expect(tester.getRect(title('paused')).left, keyline);
      // All lists the saved row below the two in flight, on the same keyline.
      expect(tester.getRect(title('saved')).left, keyline);
      expectThumbnails(3);
      expect(find.byType(FrostTaskRow), findsNWidgets(2));
      await tester.tap(title('running'));
      await tester.pumpAndSettle();
      await tester.tap(title('paused'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<DownloadTaskTile>(find.byType(DownloadTaskTile))
            .where((w) => w.expanded)
            .map((w) => w.task.snapshot.id),
        ['paused'],
      );
      expect(
        tester
            .widget<DownloadTaskDetails>(find.byType(DownloadTaskDetails))
            .task
            .snapshot
            .id,
        'paused',
      );
      await tester.tap(
        find.descendant(
          of: find.byType(FrostTabBar),
          matching: find.textContaining(t.downloads.completed),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(title('saved')).left, keyline);
      expectThumbnails(1);
      expect(
        find.descendant(
          of: find.byType(DownloadTaskTile),
          matching: find.byWidgetPredicate(
            (w) => w is FrostListRow && w.title == 'saved.png',
          ),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  Future<TestDownloadManager> pumpDetails(
    WidgetTester tester,
    BooruDownloadItem item,
  ) async {
    final manager = TestDownloadManager();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          downloadManagerProvider.overrideWithValue(manager),
          downloadItemsProvider.overrideWith(() => TestDownloadItems([item])),
        ],
        child: browseTestApp(
          SingleChildScrollView(child: DownloadTaskDetails(task: item)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return manager;
  }

  Finder button(String label) =>
      find.byWidgetPredicate((w) => w is FrostButton && w.label == label);

  testWidgets('details pause a running task', (tester) async {
    final manager = await pumpDetails(
      tester,
      task('job', DownloadStatus.running),
    );
    expect(button(t.downloads.resume), findsNothing);
    await tester.tap(button(t.downloads.pause));
    await tester.pumpAndSettle();
    expect(manager.calls, [('pause', 'job')]);
  });

  testWidgets('details resume a paused task', (tester) async {
    final manager = await pumpDetails(
      tester,
      task('job', DownloadStatus.paused),
    );
    expect(button(t.downloads.pause), findsNothing);
    await tester.tap(button(t.downloads.resume));
    await tester.pumpAndSettle();
    expect(manager.calls, [('resume', 'job')]);
  });

  testWidgets('details offer neither pause nor resume to a finished task', (
    tester,
  ) async {
    await pumpDetails(tester, task('job', DownloadStatus.downloaded));
    expect(button(t.downloads.pause), findsNothing);
    expect(button(t.downloads.resume), findsNothing);
  });

  testWidgets('details show status, percent and only known values', (
    tester,
  ) async {
    await pumpDetails(tester, task('job', DownloadStatus.paused));
    expect(find.text(t.downloads.paused), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    // No transfer rate is known, and a paused task has no remaining time.
    expect(find.textContaining('/s'), findsNothing);
  });

  for (final (status, shown) in [
    (DownloadStatus.running, true),
    (DownloadStatus.paused, false),
  ]) {
    testWidgets('details show the rate only while running: $status', (
      tester,
    ) async {
      final item = task('job', status);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            downloadManagerProvider.overrideWithValue(TestDownloadManager()),
            downloadItemsProvider.overrideWith(() => TestDownloadItems([item])),
            downloadTransferRatesProvider.overrideWith(_FixedRates.new),
          ],
          child: browseTestApp(DownloadTaskDetails(task: item)),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining(downloadRate(1000)),
        shown ? findsOneWidget : findsNothing,
      );
    });
  }

  testWidgets('details of a failed task show its status and no percent', (
    tester,
  ) async {
    await pumpDetails(tester, task('job', DownloadStatus.failed));
    expect(find.text(t.downloads.failed), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('cancelled tasks leave Completed and follow failed ones', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          downloadManagerProvider.overrideWithValue(TestDownloadManager()),
          downloadItemsProvider.overrideWith(
            () => TestDownloadItems([
              task('cancelled', DownloadStatus.cancelled),
              task('done', DownloadStatus.downloaded),
              task('running', DownloadStatus.running),
              task('broken', DownloadStatus.failed),
            ]),
          ),
        ],
        child: browseTestApp(const DownloadsPage()),
      ),
    );
    await tester.pumpAndSettle();
    Finder tab(String label) => find
        .descendant(of: find.byType(FrostTabBar), matching: find.text(label))
        .first;
    // The Active tab counts failed, running and cancelled tasks.
    expect(find.text('3'), findsWidgets);
    // All lists them in that order, and the completed task after them.
    final order = [
      for (final name in ['broken', 'running', 'cancelled', 'done'])
        tester.getTopLeft(find.text('$name.png')).dy,
    ];
    expect(order, orderedEquals([...order]..sort()));
    // Completed holds only the finished task.
    await tester.tap(tab(t.downloads.completed));
    await tester.pumpAndSettle();
    expect(find.text('done.png').hitTestable(), findsOneWidget);
    expect(find.text('cancelled.png').hitTestable(), findsNothing);
    await tester.tap(tab(t.downloads.all));
    await tester.pumpAndSettle();
    // Failures lead under a caption with their count, tasks in flight follow
    // under the Active caption, and cancelled ones close under their own.
    expect(
      find.text(t.downloads.failedTasks(n: 1, count: '1')),
      findsOneWidget,
    );
    expect(find.text(t.downloads.active), findsWidgets);
    final cancelledCaption = find.text(
      t.downloads.cancelledTasks(n: 1, count: '1'),
    );
    expect(cancelledCaption, findsOneWidget);
    expect(
      tester.getTopLeft(cancelledCaption).dy,
      greaterThan(tester.getTopLeft(find.text('running.png')).dy),
    );
    expect(
      tester.getTopLeft(cancelledCaption).dy,
      lessThan(tester.getTopLeft(find.text('cancelled.png')).dy),
    );
    // A cancelled task keeps Retry and Delete.
    await tester.tap(find.text('cancelled.png'));
    await tester.pumpAndSettle();
    expect(button(t.generic.retry), findsWidgets);
  });

  testWidgets('cancelled tasks are not captioned as active', (tester) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          downloadManagerProvider.overrideWithValue(TestDownloadManager()),
          downloadItemsProvider.overrideWith(
            () => TestDownloadItems([
              task('broken', DownloadStatus.failed),
              task('cancelled', DownloadStatus.cancelled),
              task('done', DownloadStatus.downloaded),
            ]),
          ),
        ],
        child: browseTestApp(const DownloadsPage()),
      ),
    );
    await tester.pumpAndSettle();
    // Active names only the tab, no caption in the list.
    final inTabs = find.descendant(
      of: find.byType(FrostTabBar),
      matching: find.text(t.downloads.active),
    );
    expect(
      find.text(t.downloads.active).evaluate().length,
      inTabs.evaluate().length,
    );
    expect(
      find.text(t.downloads.failedTasks(n: 1, count: '1')),
      findsOneWidget,
    );
    expect(
      find.text(t.downloads.cancelledTasks(n: 1, count: '1')),
      findsOneWidget,
    );
  });
}
