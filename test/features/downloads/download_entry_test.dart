import 'package:booruflow/app/app_router.dart';
import 'package:booruflow/app/booru_flow_app.dart';
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/browse/collection_logic.dart';
import 'package:booruflow/features/downloads/download_entry.dart';
import 'package:booruflow/features/downloads/download_notifications.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/features/downloads/widgets/download_task_widgets.dart';
import 'package:booruflow/features/search/logic.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../discovery/search_interaction_test.dart'
    show testSource, SearchRepositoryFake;
import 'download_tasks_test.dart' show task;
import 'support.dart' show TestDownloadManager;

final class _MemoryStore implements SettingsServiceStore {
  final values = <String, dynamic>{};
  @override
  Map<String, dynamic> load() => Map.of(values);
  @override
  Future<void> write(String key, dynamic value) async => values[key] = value;
}

class _Downloads extends DownloadItems {
  _Downloads(this.initial);
  final List<BooruDownloadItem> initial;
  @override
  List<BooruDownloadItem> build() => initial;
  void replace(List<BooruDownloadItem> items) => state = items;
}

void main() {
  setUpAll(initializeDateFormatting);
  const channel = MethodChannel('frost_window');
  late _MemoryStore store;
  setUp(() async {
    store = _MemoryStore();
    await SettingsService.initialize(store: store);
    LocaleSettings.setLocaleSync(AppLocale.en);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (call) async => call.method == 'getState'
              ? {
                  'revision': 0,
                  'active': true,
                  'captionMode': 'client',
                  'leftButtons': <String>[],
                  'rightButtons': ['minimize', 'maximize', 'close'],
                  'nativeControls': [0.0, 0.0, 0.0, 0.0],
                }
              : null,
        );
    AppRouter.router.go('/');
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<void> mount(
    WidgetTester tester, {
    List<BooruDownloadItem> downloads = const [],
  }) async {
    addTearDown(() => tester.pumpWidget(const SizedBox()));
    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            downloadItemsProvider.overrideWith(() => _Downloads(downloads)),
            downloadManagerProvider.overrideWithValue(TestDownloadManager()),
            tagSuggestionRepositoryProvider.overrideWithValue(
              SearchRepositoryFake(),
            ),
            booruServiceProvider.overrideWithValue(
              BooruService()..useSourcesForTesting([testSource('yande')]),
            ),
            collectionLoaderProvider.overrideWithValue(
              (_, _) async => const PostPage(items: [], exhausted: true),
            ),
          ],
          child: BooruFlowApp(
            windowController: FrostWindowController(
              minimumSize: const Size(320, 480),
            ),
            checkUpdates: false,
          ),
        ),
      ),
    );
    for (var frame = 0; frame < 12; frame++) {
      await tester.pump();
    }
  }

  void setDownloads(WidgetTester tester, List<BooruDownloadItem> items) {
    final container = ProviderScope.containerOf(
      tester.element(find.byType(FrostShell)),
    );
    (container.read(downloadItemsProvider.notifier) as _Downloads).replace(
      items,
    );
  }

  final entry = find.byType(FrostShellTaskButton);
  final panel = find.byType(DownloadEntryPanel);
  BooruDownloadItem saved(String id) =>
      task(id, DownloadStatus.downloaded, save: SaveState.saved);

  testWidgets(
    'the sidebar lists Downloads last, below the destinations, and opens the panel',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await mount(tester, downloads: [task('running', DownloadStatus.running)]);
      final shell = tester.widget<FrostShell>(find.byType(FrostShell));
      expect(shell.destinations.map((item) => item.label), [
        'Browse',
        'Tags',
        'Settings',
      ]);
      expect(entry, findsOneWidget);
      expect(
        tester.getTopLeft(entry).dy,
        greaterThan(
          tester
              .getBottomLeft(
                find.byWidgetPredicate(
                  (w) => w is FrostNavItem && w.label == 'Settings',
                ),
              )
              .dy,
        ),
      );
      expect(panel, findsNothing);
      await tester.tap(entry);
      await tester.pumpAndSettle();
      expect(panel, findsOneWidget);
      expect(
        find.descendant(of: panel, matching: find.text('running.png')),
        findsOneWidget,
      );
      expect(find.text(t.downloads.viewAll), findsOneWidget);
      expect(AppRouter.currentUri.path, '/');
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets('the sidebar entry is there with no downloads at all', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await mount(tester);
    expect(entry, findsOneWidget);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: panel, matching: find.text(t.downloads.noTasks)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets(
    'a panel item opens the downloads page on that task and Back returns',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await mount(
        tester,
        downloads: [task('running', DownloadStatus.running), saved('done')],
      );
      AppRouter.router.go('/tags');
      await tester.pumpAndSettle();
      await tester.tap(entry);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: panel, matching: find.text('done.png')),
      );
      await tester.pumpAndSettle();
      expect(panel, findsNothing, reason: 'the panel closes first');
      expect(AppRouter.currentUri.path, '/downloads');
      expect(AppRouter.currentUri.queryParameters['task'], 'done');
      expect(
        tester
            .widgetList<DownloadTaskTile>(find.byType(DownloadTaskTile))
            .where((w) => w.expanded)
            .single
            .task
            .snapshot
            .id,
        'done',
      );
      final shell = tester.widget<FrostShell>(find.byType(FrostShell));
      expect(shell.selectedIndex, 1, reason: 'Tags opened it and stays lit');
      expect(shell.canGoBack, isTrue);
      AppRouter.popRightNavigator();
      await tester.pumpAndSettle();
      expect(AppRouter.currentUri.path, '/tags');
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets('View all opens the downloads page above the current page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await mount(tester, downloads: [task('running', DownloadStatus.running)]);
    AppRouter.router.go('/settings');
    await tester.pumpAndSettle();
    await tester.tap(entry);
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.downloads.viewAll));
    await tester.pumpAndSettle();
    expect(AppRouter.currentUri.path, '/downloads');
    expect(AppRouter.currentUri.queryParameters, isEmpty);
    expect(tester.widget<FrostShell>(find.byType(FrostShell)).selectedIndex, 2);
    AppRouter.popRightNavigator();
    await tester.pumpAndSettle();
    expect(AppRouter.currentUri.path, '/settings');
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('a deep link to /downloads has Browse below it', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await mount(tester, downloads: [task('running', DownloadStatus.running)]);
    AppRouter.router.go('/downloads');
    await tester.pumpAndSettle();
    final shell = tester.widget<FrostShell>(find.byType(FrostShell));
    expect(shell.selectedIndex, 0);
    expect(shell.canGoBack, isTrue);
    AppRouter.popRightNavigator();
    await tester.pumpAndSettle();
    expect(AppRouter.currentUri.path, '/');
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets(
    'the floating entry hides without download records and shows with one',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await mount(tester);
      expect(entry, findsNothing);
      setDownloads(tester, [task('running', DownloadStatus.running)]);
      await tester.pumpAndSettle();
      expect(entry, findsOneWidget);
      setDownloads(tester, const []);
      await tester.pumpAndSettle();
      expect(entry, findsNothing);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets('the floating entry opens the panel', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await mount(tester, downloads: [saved('done')]);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(panel, findsOneWidget);
    expect(
      find.descendant(of: panel, matching: find.text('done.png')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets(
    'the floating position is saved when it moves and restored on the next run',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final downloads = [task('running', DownloadStatus.running)];
      await mount(tester, downloads: downloads);
      // At first it rests at the end of the bottom of its band.
      expect(
        SettingsService.downloadEntryPosition,
        const FrostFloatingEntryPosition(),
      );
      final start = tester.getCenter(entry);
      expect(start.dx, greaterThan(195));
      await tester.drag(entry, const Offset(-250, -300));
      await tester.pumpAndSettle();
      final moved = SettingsService.downloadEntryPosition;
      expect(moved.edge, FrostFloatingEntryEdge.start);
      expect(moved.fraction, lessThan(1));
      expect(store.values['downloadEntryPosition'], {
        'edge': 'start',
        'fraction': moved.fraction,
      });
      final rest = tester.getCenter(entry);
      expect(rest.dx, lessThan(195));
      // The next run starts there.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await mount(tester, downloads: downloads);
      await tester.pumpAndSettle();
      expect(tester.getCenter(entry).dx, closeTo(rest.dx, .5));
      expect(tester.getCenter(entry).dy, closeTo(rest.dy, .5));
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  test('an unreadable floating position is a missing one', () async {
    for (final value in <Object?>[
      {'edge': 'sideways', 'fraction': .5},
      {'edge': 'start', 'fraction': 3},
      {'edge': 'start', 'fraction': 'low'},
      {'fraction': .5},
    ]) {
      final broken = _MemoryStore()..values['downloadEntryPosition'] = value;
      await SettingsService.initialize(store: broken);
      expect(
        SettingsService.downloadEntryPosition,
        const FrostFloatingEntryPosition(),
        reason: '$value',
      );
    }
    final good = _MemoryStore()
      ..values['downloadEntryPosition'] = {'edge': 'start', 'fraction': .25};
    await SettingsService.initialize(store: good);
    expect(
      SettingsService.downloadEntryPosition,
      const FrostFloatingEntryPosition(
        edge: FrostFloatingEntryEdge.start,
        fraction: .25,
      ),
    );
  });

  testWidgets(
    'All is the default tab and lists tasks in flight and completed ones',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await mount(
        tester,
        downloads: [
          task('running', DownloadStatus.running),
          task('failed', DownloadStatus.failed),
          saved('done'),
        ],
      );
      AppRouter.router.go('/downloads');
      await tester.pumpAndSettle();
      final tabs = tester.widget<FrostTabBar>(find.byType(FrostTabBar));
      Finder inTabs(String label) => find
          .descendant(of: find.byType(FrostTabBar), matching: find.text(label))
          .first;
      expect(tabs.controller!.index, 0);
      expect(tabs.tabs.map((tab) => tab.label), [
        t.downloads.all,
        t.downloads.active,
        t.downloads.completed,
      ]);
      expect(tabs.tabs.map((tab) => tab.secondaryLabel), ['3', '2', '1']);
      expect(find.text('running.png'), findsOneWidget);
      expect(find.text('failed.png'), findsOneWidget);
      expect(find.text('done.png'), findsOneWidget);
      // Tasks in flight lead, then the completed days.
      expect(
        tester.getTopLeft(find.text('running.png')).dy,
        lessThan(tester.getTopLeft(find.text('done.png')).dy),
      );
      await tester.tap(inTabs(t.downloads.active));
      await tester.pumpAndSettle();
      // The other tabs stay built beside the one on screen.
      expect(find.text('done.png').hitTestable(), findsNothing);
      expect(find.text('running.png').hitTestable(), findsOneWidget);
      await tester.tap(inTabs(t.downloads.completed));
      await tester.pumpAndSettle();
      expect(find.text('done.png').hitTestable(), findsOneWidget);
      expect(find.text('running.png').hitTestable(), findsNothing);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets('a task link selects All and reveals a completed task there', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await mount(
      tester,
      downloads: [task('running', DownloadStatus.running), saved('done')],
    );
    openDownloadTask('done');
    await tester.pumpAndSettle();
    final tabs = tester.widget<FrostTabBar>(find.byType(FrostTabBar));
    expect(tabs.controller!.index, 0);
    final expanded = tester
        .widgetList<DownloadTaskTile>(find.byType(DownloadTaskTile))
        .where((w) => w.expanded);
    expect(expanded.single.task.snapshot.id, 'done');
    expect(find.text('running.png'), findsOneWidget);
    expect(find.text('done.png'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
}
