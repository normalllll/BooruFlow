import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/browse/collection_logic.dart';
import 'package:booruflow/features/browse/results_page.dart';
import 'package:booruflow/features/browse/widgets/browse_card.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';

import '../../support/browse_support.dart';
import '../discovery/search_interaction_test.dart' show testSource;
import '../downloads/support.dart' show TestDownloadItems;
import 'post_waterfall_test.dart' show collectionApp;

class _Store implements SettingsServiceStore {
  @override
  Map<String, dynamic> load() => {};
  @override
  Future<void> write(String key, dynamic value) async {}
}

BooruDownloadItem _download(String postId, DownloadStatus status) =>
    BooruDownloadItem(
      snapshot: DownloadTaskSnapshot(
        id: 'task-$postId',
        sourceId: 'yande',
        postId: postId,
        resourceId: 1,
        variantIndex: MediaVariantKind.original.index,
        title: '#$postId',
        filename: '$postId.png',
        status: status,
        saveState: status == DownloadStatus.downloaded
            ? SaveState.saved
            : SaveState.none,
        receivedBytes: 1,
        totalBytes: 1,
        progress: 1,
        localPath: null,
        error: null,
        log: null,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );

void main() {
  late PendingMediaService service;
  setUp(() async {
    await SettingsService.initialize(store: _Store());
    LocaleSettings.setLocaleSync(AppLocale.en);
    service = PendingMediaService()
      ..useSourcesForTesting([testSource('yande')]);
  });

  group('thumbnail size columns', () {
    // A 360-wide phone leaves 328 for the grid.
    int columns(ThumbnailSize size) => frostWaterfallColumnCount(
      width: 328,
      preferredTileWidth: size.preferredTileWidth,
      gap: FrostGap.grid,
      textScale: 1,
    );

    test('small gives three columns on a phone', () {
      expect(columns(ThumbnailSize.small), 3);
    });
    test('medium and large give two columns on a phone', () {
      expect(columns(ThumbnailSize.medium), 2);
      expect(columns(ThumbnailSize.large), 2);
    });
  });

  group('download mark on the card', () {
    Future<void> mountCard(
      WidgetTester tester, {
      required TargetPlatform platform,
      required List<BooruDownloadItem> downloads,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            booruServiceProvider.overrideWithValue(service),
            downloadItemsProvider.overrideWith(
              () => TestDownloadItems(downloads),
            ),
          ],
          child: browseTestApp(
            Center(
              child: SizedBox(
                width: 240,
                child: BrowseCard(post: Post(browsePost(1)), onTap: (_, _) {}),
              ),
            ),
            platform: platform,
          ),
        ),
      );
      await tester.pump();
      addTearDown(() => tester.pumpWidget(const SizedBox()));
    }

    Finder labelled(String label) =>
        find.byWidgetPredicate((w) => w is FrostButton && w.label == label);
    // The saved mark is a status, not a button.
    Finder savedMark() => find.byWidgetPredicate(
      (w) => w is FrostBadge && w.label == t.downloads.downloaded,
    );

    for (final (name, platform) in [
      ('pointer', TargetPlatform.windows),
      ('touch', TargetPlatform.android),
    ]) {
      testWidgets(
        '$name: a downloaded post shows a check mark that is not a button',
        (tester) async {
          await mountCard(
            tester,
            platform: platform,
            downloads: [_download('1', DownloadStatus.downloaded)],
          );
          await tester.pump(const Duration(milliseconds: 300));
          expect(savedMark(), findsOneWidget);
          expect(labelled(t.downloads.downloaded), findsNothing);
          expect(labelled(t.postDetail.download), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets('$name: another post\'s download does not mark the card', (
        tester,
      ) async {
        await mountCard(
          tester,
          platform: platform,
          downloads: [_download('2', DownloadStatus.downloaded)],
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(savedMark(), findsNothing);
      });
    }

    testWidgets(
      'touch: an undownloaded card always shows the download button',
      (tester) async {
        await mountCard(
          tester,
          platform: TargetPlatform.android,
          downloads: [],
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(labelled(t.postDetail.download), findsOneWidget);
        expect(savedMark(), findsNothing);
      },
    );

    testWidgets('pointer: an undownloaded card shows download only on hover', (
      tester,
    ) async {
      await mountCard(tester, platform: TargetPlatform.windows, downloads: []);
      expect(labelled(t.postDetail.download), findsNothing);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byType(BrowseCard)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(labelled(t.postDetail.download), findsOneWidget);
      expect(savedMark(), findsNothing);
    });

    testWidgets('a download in progress offers no action and no mark', (
      tester,
    ) async {
      await mountCard(
        tester,
        platform: TargetPlatform.android,
        downloads: [_download('1', DownloadStatus.running)],
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(savedMark(), findsNothing);
      expect(labelled(t.postDetail.download), findsNothing);
    });

    testWidgets('a failed download leaves the action available', (
      tester,
    ) async {
      await mountCard(
        tester,
        platform: TargetPlatform.android,
        downloads: [_download('1', DownloadStatus.failed)],
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(labelled(t.postDetail.download), findsOneWidget);
    });
  });

  group('refresh', () {
    var loads = 0;
    Future<PostPage> loader(CollectionKey _, String? _) async {
      loads++;
      return PostPage(items: [browsePost(1)], exhausted: true);
    }

    setUp(() => loads = 0);

    Future<void> mountWaterfall(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        collectionApp(
          collection: collectionKey(0),
          loader: loader,
          service: service,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(loads, 1);
      addTearDown(() => tester.pumpWidget(const SizedBox()));
    }

    Future<void> chord(
      WidgetTester tester,
      LogicalKeyboardKey? modifier,
      LogicalKeyboardKey key,
    ) async {
      if (modifier != null) await tester.sendKeyDownEvent(modifier);
      await tester.sendKeyDownEvent(key);
      await tester.sendKeyUpEvent(key);
      if (modifier != null) await tester.sendKeyUpEvent(modifier);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    for (final (name, modifier, key) in [
      ('Ctrl+R', LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyR),
      ('Cmd+R', LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.keyR),
      ('F5', null, LogicalKeyboardKey.f5),
    ]) {
      testWidgets('$name refreshes the waterfall', (tester) async {
        await mountWaterfall(tester);
        await chord(tester, modifier, key);
        expect(loads, 2);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('the card context menu offers Refresh and it refreshes', (
      tester,
    ) async {
      await mountWaterfall(tester);
      final pointer = await tester.startGesture(
        tester.getCenter(find.byType(BrowseCard)),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await pointer.up();
      await tester.pumpAndSettle();
      expect(find.text(t.generic.refresh), findsOneWidget);
      await tester.tap(find.text(t.generic.refresh));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(loads, 2);
    });

    testWidgets('the page More menu offers Refresh and it refreshes', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            booruServiceProvider.overrideWithValue(service),
            collectionLoaderProvider.overrideWithValue(loader),
          ],
          child: browseTestApp(
            const ResultsPage(tags: ['sky'], sourceId: 'yande'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      addTearDown(() => tester.pumpWidget(const SizedBox()));
      expect(loads, 1);
      final moreAnchor = find.byWidgetPredicate(
        (widget) =>
            widget is FrostMenuAnchor &&
            widget.entries.any(
              (entry) =>
                  entry is FrostMenuAction &&
                  entry.label == t.discovery.copyQueryLink,
            ),
      );
      await tester.tap(moreAnchor.hitTestable().last);
      await tester.pumpAndSettle();
      expect(find.text(t.generic.refresh), findsOneWidget);
      await tester.tap(find.text(t.generic.refresh));
      await tester.pumpAndSettle();
      expect(loads, 2);
    });
  });
}
