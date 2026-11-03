// Downloads page: task list, filters, details and actions. Asserts through
// Frost widget types, i18n keys, routes and fake service state.
// ignore_for_file: library_private_types_in_public_api

import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/core/downloads/download_manager_contract.dart';
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/browse/collection_logic.dart';
import 'package:booruflow/features/downloads/batch/batch_download_dialog.dart';
import 'package:booruflow/features/downloads/batch/logic.dart';
import 'package:booruflow/features/downloads/downloads_page.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/features/downloads/services/booru_downloads.dart';
import 'package:booruflow/features/downloads/widgets/download_transfer_summary.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/intl/number_format.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/shared/app_page.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../../support/frost_app_layers.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _Items extends DownloadItems {
  _Items(this.initial);
  final List<BooruDownloadItem> initial;
  @override
  List<BooruDownloadItem> build() => initial;
  void replace(List<BooruDownloadItem> value) => state = value;
}

class _Manager implements DownloadManager {
  final calls = <(String, String)>[];
  final jobs = <DownloadJob>[];
  @override
  Future<void> pause(String id) async => calls.add(('pause', id));
  @override
  Future<void> resume(String id) async => calls.add(('resume', id));
  @override
  Future<void> retry(String id) async => calls.add(('retry', id));
  @override
  Future<void> retrySave(String id) async => calls.add(('retrySave', id));
  @override
  Future<void> cancel(String id) async => calls.add(('cancel', id));
  @override
  Future<void> deleteTask(String id) async => calls.add(('deleteTask', id));
  @override
  Future<void> sync() async => calls.add(('sync', ''));
  @override
  Future<int> enqueue(List<DownloadJob> value) async {
    jobs.addAll(value);
    return value.length;
  }

  @override
  Future<List<DownloadTaskSnapshot>> listTasks({
    int? resourceId,
    DownloadStatus? status,
    SaveState? saveState,
  }) async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Session extends BooruSession {
  @override
  BooruSessionState build() =>
      const BooruSessionState(sourceId: 'yande', revision: 0);
}

class _BatchDownloads extends BooruDownloads {
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
  }) async => DownloadJob.create(
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

BooruSource _source(String id) => BooruSource(
  sourceId: id,
  displayName: id,
  protocol: BooruProtocol.moebooru,
  enabledByDefault: true,
  isAiSource: false,
  capabilities: const SourceCapabilities(
    discovery: DiscoveryCapabilities(
      popular: CapabilityAvailability.unsupported,
      commonTags: CapabilityAvailability.available,
      popularRanges: [],
      historicalRanges: [],
      timeBasis: PopularTimeBasis.indexTimeWindow,
      additionalFeeds: [],
      autocompleteMinChars: 1,
    ),
    ratings: [ContentRating.general],
    authKind: AuthKind.none,
    supportsSearch: true,
    supportsPostDetail: true,
    supportsAutocomplete: true,
    supportsRelatedPosts: false,
    supportsOriginal: true,
    supportsAuthenticatedMedia: false,
    supportsBackgroundDownload: true,
  ),
);

BooruPost _post(String id) => BooruPost(
  sourceId: 'yande',
  postId: id,
  postKey: 'yande:$id',
  rating: ContentRating.general,
  tags: const [],
  media: const [
    MediaVariant(
      kind: MediaVariantKind.original,
      url: 'https://example.invalid/original.png',
      width: 600,
      height: 800,
    ),
  ],
  webUrl: 'https://yande.re/post/show/$id',
  flags: const PostFlags(
    hasChildren: false,
    isPending: false,
    isDeleted: false,
    isAiGenerated: false,
  ),
);

// ---------------------------------------------------------------------------
// Task fixtures
// ---------------------------------------------------------------------------

/// A task whose title (no post id) is its [file] name.
BooruDownloadItem task(
  String id,
  DownloadStatus status, {
  SaveState save = SaveState.none,
  String? batch,
  String? batchName,
  String? error,
  String? path,
  String? file,
  DateTime? when,
  bool sized = true,
}) {
  final done = status == DownloadStatus.downloaded;
  return BooruDownloadItem(
    snapshot: DownloadTaskSnapshot(
      id: id,
      resourceId: 123,
      variantIndex: 0,
      title: id,
      filename: file ?? '$id.png',
      status: status,
      saveState: save,
      receivedBytes: done ? 100 : 50,
      totalBytes: sized ? 100 : null,
      progress: done ? 1 : .5,
      localPath: path,
      error: error,
      log: null,
      sourceId: 'yande',
      createdAt: when ?? DateTime(2026),
      updatedAt: when ?? DateTime(2026),
      batchId: batch,
      batchName: batchName,
    ),
  );
}

BooruDownloadItem saved(
  String id, {
  DateTime? when,
  String? path,
  String? file,
}) => task(
  id,
  DownloadStatus.downloaded,
  save: SaveState.saved,
  when: when ?? DateTime.now(),
  path: path,
  file: file,
);

String pathOf(String id) =>
    r'C:\Users\fixture\Downloads\BooruFlow\'
    '$id.png';
String normalizedPath(BooruDownloadItem item) => item.snapshot.localPath!;

DateTime noon(int daysAgo) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day - daysAgo, 12);
}

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

const _wide = Size(1147, 717);
const _compact = Size(360, 780);
const _browseMarker = 'browse destination marker';

Future<void> settle(WidgetTester tester, {int frames = 30}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

class Mounted {
  Mounted(this.tester, this.router, this.manager, this.items);
  final WidgetTester tester;
  final GoRouter router;
  final _Manager manager;
  final _Items items;
}

Future<Mounted> mount(
  WidgetTester tester,
  List<BooruDownloadItem> list, {
  Size size = _wide,
  TargetPlatform? platform,
  double scale = 1,
  AppLocale locale = AppLocale.en,
  String location = '/downloads',
  Widget Function(BuildContext)? home,
  _Manager? manager,
  Widget Function(Widget child)? scope,
  bool settleAfter = true,
}) async {
  LocaleSettings.setLocaleSync(locale);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final fake = manager ?? _Manager();
  final items = _Items(list);
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: AppRoute.posts.path,
        name: AppRoute.posts.name,
        builder: (context, _) => home != null
            ? home(context)
            : const Center(child: Text(_browseMarker)),
      ),
      GoRoute(
        path: AppRoute.downloads.path,
        name: AppRoute.downloads.name,
        builder: (_, state) => DownloadsPage(
          taskId: state.uri.queryParameters['task'],
          revealRequest: state.uri.queryParameters['reveal'],
        ),
      ),
    ],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    router.dispose();
  });
  final isWide = size.width > 600;
  final app = TranslationProvider(
    child: FrostScope(
      config: appFrostConfig,
      child: MaterialApp.router(
        routerConfig: router,
        theme: FrostTheme.build(
          config: appFrostConfig,
          brightness: Brightness.light,
          platform:
              platform ??
              (isWide ? TargetPlatform.windows : TargetPlatform.android),
          locale: Locale(locale.languageCode),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: FrostLayoutScope(child: frostAppLayers(child!)),
        ),
      ),
    ),
  );
  Widget wrap(Widget child) => scope != null
      ? scope(child)
      : ProviderScope(
          overrides: [
            downloadItemsProvider.overrideWith(() => items),
            downloadManagerProvider.overrideWithValue(fake),
            booruSourcesProvider.overrideWithValue([_source('yande')]),
          ],
          child: child,
        );
  await tester.pumpWidget(wrap(app));
  if (settleAfter) await settle(tester);
  return Mounted(tester, router, fake, items);
}

/// The text of every rendered paragraph, zero-width break hints removed.
String _plain(InlineSpan span) => span
    .toPlainText(includePlaceholders: false)
    .replaceAll(RegExp('[\u200b\u2060\u00ad]'), '');

/// Content containing [needle] that is mounted (a collapsed detail is not),
/// however it is drawn: a paragraph, an editable (selectable) text, a path
/// text or a key-value list entry. Selectable path text paints through
/// placeholders, so the structured widgets are matched by their own data.
Finder showing(String needle) => find.byWidgetPredicate(
  (w) =>
      w is RichText && _plain(w.text).contains(needle) ||
      w is EditableText && w.controller.text.contains(needle) ||
      w is FrostPathText && w.path.contains(needle) ||
      w is FrostKeyValueList && w.entries.any((e) => e.value.contains(needle)),
  description: 'content containing "$needle"',
);

Finder title(String file) => find.text(file).hitTestable();

Finder get tabBar => find.byType(FrostTabBar);

Finder tabNamed(String name) =>
    find.descendant(of: tabBar, matching: find.textContaining(name));

Future<void> openSection(WidgetTester tester, String name) async {
  final tab = tabNamed(name).first;
  await tester.ensureVisible(tab);
  await tester.tap(tab);
  await settle(tester);
}

/// Scrolls the page's lists until [target] (a plain finder, not hit-testable
/// only) is built, then centres it so no pinned chrome covers it.
Future<void> bring(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      240,
      maxScrolls: 80,
      scrollable: find
          .byWidgetPredicate((w) => w is Scrollable && w.axis == Axis.vertical)
          .first,
    );
  }
  await Scrollable.ensureVisible(target.first.evaluate().first, alignment: .5);
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> tapRow(WidgetTester tester, String file) async {
  await bring(tester, find.text(file));
  await tester.tap(title(file).first);
  await settle(tester);
}

int selectedTab(WidgetTester tester) {
  final bar = tester.widget<FrostTabBar>(tabBar);
  final controller =
      bar.controller ?? DefaultTabController.of(tester.element(tabBar));
  return controller.index;
}

/// A header action named [label] in the live (hit-testable) form of the page
/// header: a labelled button, a tooltip-wrapped icon button or plain text.
Finder headerAction(String label) => find
    .descendant(
      of: find.byType(FrostPageHeader),
      matching: find.byWidgetPredicate(
        (w) =>
            w is FrostButton && w.label == label ||
            w is FrostTooltip && w.message == label,
        description: 'header action "$label"',
      ),
    )
    .hitTestable();

Future<void> openMore(WidgetTester tester) async {
  final more = headerAction(t.frost.more);
  expect(more, findsWidgets);
  await tester.tap(more.first);
  await settle(tester, frames: 12);
}

/// The total bar keeps its room while nothing is in flight, unseen.
double _barOpacity(WidgetTester tester) => tester
    .widget<AnimatedOpacity>(
      find.ancestor(
        of: find.byType(FrostProgressBar),
        matching: find.byType(AnimatedOpacity),
      ),
    )
    .opacity;

String _longName(String stem) =>
    '${List.filled(8, 'an_extremely_long_${stem}_name').join('_')}.png';

void main() {
  setUpAll(initializeDateFormatting);
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  group('sections', () {
    final mixed = [
      task('run1', DownloadStatus.running),
      task('run2', DownloadStatus.running),
      task('queue1', DownloadStatus.queued),
      task('pause1', DownloadStatus.paused),
      task('fail1', DownloadStatus.failed, error: 'Connection timed out'),
      saved('done1'),
      saved('done2'),
      saved('done3'),
    ];

    testWidgets(
      'the sections are three FrostTabBar tabs, all, active then completed, with their counts',
      (tester) async {
        await mount(tester, mixed);
        expect(find.byType(AppSectionPage), findsOneWidget);
        final tabs = tester.widget<FrostTabBar>(tabBar).tabs;
        expect(tabs, hasLength(3));
        String text(FrostTab tab) => '${tab.label} ${tab.secondaryLabel ?? ''}';
        // All holds every task: 8. Active holds queued, running, paused and
        // failed: 5. Completed: 3.
        expect(text(tabs[0]), contains(t.downloads.all));
        expect(text(tabs[0]), contains(formatCount(8)));
        expect(text(tabs[1]), contains(t.downloads.active));
        expect(text(tabs[1]), contains(formatCount(5)));
        expect(text(tabs[1]), isNot(contains(formatCount(3))));
        expect(text(tabs[2]), contains(t.downloads.completed));
        expect(text(tabs[2]), contains(formatCount(3)));
        expect(text(tabs[2]), isNot(contains(formatCount(5))));
        // The page opens on All.
        expect(selectedTab(tester), 0);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('the tab counts follow the task list', (tester) async {
      final fixture = await mount(tester, mixed);
      fixture.items.replace([...mixed, task('run3', DownloadStatus.running)]);
      await settle(tester);
      final tabs = tester.widget<FrostTabBar>(tabBar).tabs;
      expect(
        '${tabs[0].label} ${tabs[0].secondaryLabel ?? ''}',
        contains(formatCount(9)),
      );
      expect(
        '${tabs[1].label} ${tabs[1].secondaryLabel ?? ''}',
        contains(formatCount(6)),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping a row stays on the downloads page', (tester) async {
      final fixture = await mount(tester, mixed);
      await tapRow(tester, 'run1.png');
      expect(fixture.router.state.uri.path, AppRoute.downloads.path);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'there is no all / active / failed / saved selector besides the tabs',
      (tester) async {
        await mount(tester, mixed);
        expect(find.byWidgetPredicate((w) => w is FrostPicker), findsNothing);
        final all = find.textContaining(
          RegExp('^${RegExp.escape(t.downloads.all)}\\b'),
        );
        expect(all, findsOneWidget);
        expect(
          find.descendant(of: tabBar, matching: all),
          findsOneWidget,
          reason: 'the only All is the tab',
        );
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('failed tasks', () {
    final list = [
      task('run1', DownloadStatus.running),
      task('queue1', DownloadStatus.queued),
      task(
        'fail1',
        DownloadStatus.failed,
        error: 'Connection timed out\nSocketException: OS Error (errno = 110)',
      ),
    ];

    testWidgets('a failed task is listed before running and queued tasks', (
      tester,
    ) async {
      await mount(tester, list);
      final failed = tester.getTopLeft(title('fail1.png').first).dy;
      expect(failed, lessThan(tester.getTopLeft(title('run1.png').first).dy));
      expect(failed, lessThan(tester.getTopLeft(title('queue1.png').first).dy));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a failed task shows its failure reason', (tester) async {
      await mount(tester, list);
      expect(showing('Connection timed out'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the retry action calls retry for that task', (tester) async {
      final fixture = await mount(tester, list);
      final retry = find
          .byWidgetPredicate(
            (w) => w is FrostButton && w.label == t.generic.retry,
          )
          .hitTestable();
      expect(retry, findsWidgets);
      await tester.tap(retry.first);
      await settle(tester, frames: 6);
      expect(fixture.manager.calls, [('retry', 'fail1')]);
      expect(tester.takeException(), isNull);
    });
  });

  group('batches', () {
    final list = [
      task('solo', DownloadStatus.running),
      task(
        'b1',
        DownloadStatus.running,
        batch: 'batch-a',
        batchName: 'yande scenery',
      ),
      task(
        'b2',
        DownloadStatus.running,
        batch: 'batch-a',
        batchName: 'yande scenery',
      ),
      task(
        'b3',
        DownloadStatus.queued,
        batch: 'batch-a',
        batchName: 'yande scenery',
      ),
    ];

    testWidgets(
      'tasks of one batch sit under a batch row that shows done / total',
      (tester) async {
        await mount(tester, list);
        final batchRow = find.text('yande scenery').hitTestable();
        expect(batchRow, findsOneWidget);
        expect(
          find
              .text(
                t.downloads.batchProgress(
                  completed: formatCount(0),
                  total: formatCount(3),
                ),
              )
              .hitTestable(),
          findsOneWidget,
        );
        final head = tester.getTopLeft(batchRow).dy;
        for (final file in ['b1.png', 'b2.png', 'b3.png']) {
          expect(title(file), findsOneWidget);
          expect(tester.getTopLeft(title(file)).dy, greaterThan(head));
        }
        expect(title('solo.png'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('finished tasks still count towards the batch', (tester) async {
      await mount(tester, [
        task(
          'b1',
          DownloadStatus.downloaded,
          save: SaveState.saved,
          batch: 'batch-a',
          batchName: 'yande scenery',
        ),
        task(
          'b2',
          DownloadStatus.running,
          batch: 'batch-a',
          batchName: 'yande scenery',
        ),
        task(
          'b3',
          DownloadStatus.queued,
          batch: 'batch-a',
          batchName: 'yande scenery',
        ),
      ]);
      expect(
        find
            .text(
              t.downloads.batchProgress(
                completed: formatCount(1),
                total: formatCount(3),
              ),
            )
            .hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('collapsing the batch row hides its tasks only', (
      tester,
    ) async {
      await mount(tester, list);
      await tester.tap(find.text('yande scenery').hitTestable());
      await settle(tester);
      for (final file in ['b1.png', 'b2.png', 'b3.png']) {
        expect(title(file), findsNothing);
      }
      expect(title('solo.png'), findsOneWidget);
      expect(find.text('yande scenery').hitTestable(), findsOneWidget);
      await tester.tap(find.text('yande scenery').hitTestable());
      await settle(tester);
      for (final file in ['b1.png', 'b2.png', 'b3.png']) {
        expect(title(file), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('inline details', () {
    final one = task('one', DownloadStatus.paused, path: pathOf('one'));
    final two = task('two', DownloadStatus.paused, path: pathOf('two'));
    final list = [one, two];

    testWidgets('tapping a row expands its details inline, again collapses', (
      tester,
    ) async {
      await mount(tester, list);
      final path = normalizedPath(one);
      expect(showing(path), findsNothing);
      final secondBefore = tester.getTopLeft(title('two.png').first).dy;
      await tapRow(tester, 'one.png');
      expect(showing(path), findsWidgets);
      // Inline: the row below moves down, no side panel or sheet takes over.
      expect(
        tester.getTopLeft(title('two.png').first).dy,
        greaterThan(secondBefore),
      );
      await tapRow(tester, 'one.png');
      expect(showing(path), findsNothing);
      expect(tester.getTopLeft(title('two.png').first).dy, secondBefore);
      expect(tester.takeException(), isNull);
    });

    testWidgets('pause is instant and draws no result', (tester) async {
      final fixture = await mount(tester, [
        task('run', DownloadStatus.running),
      ]);
      await tapRow(tester, 'run.png');
      final pause = find.byWidgetPredicate(
        (w) =>
            w is FrostButton &&
            w.label == t.downloads.pause &&
            w.size == FrostControlSize.small,
      );
      await tester.tap(pause.hitTestable());
      await tester.pump();
      expect(tester.widget<FrostButton>(pause).state, FrostActionState.idle);
      await settle(tester);
      expect(tester.widget<FrostButton>(pause).state, FrostActionState.idle);
      expect(fixture.manager.calls, contains(('pause', 'run')));
      expect(tester.takeException(), isNull);
    });

    testWidgets('expanding another row collapses the first', (tester) async {
      await mount(tester, list);
      final first = normalizedPath(one), second = normalizedPath(two);
      final secondBefore = tester.getTopLeft(title('two.png').first).dy;
      await tapRow(tester, 'one.png');
      expect(showing(first), findsWidgets);
      expect(showing(second), findsNothing);
      await tapRow(tester, 'two.png');
      expect(showing(first), findsNothing);
      expect(showing(second), findsWidgets);
      // The first row's details are gone, so the second row is back in place.
      expect(tester.getTopLeft(title('two.png').first).dy, secondBefore);
      expect(tester.takeException(), isNull);
    });
  });

  group('total progress', () {
    String summary(int n) => t.downloads.activeTasks(count: formatCount(n));

    testWidgets('shows while tasks are running, in the active section', (
      tester,
    ) async {
      await mount(tester, [
        task('run1', DownloadStatus.running),
        task('run2', DownloadStatus.running),
        task('fail1', DownloadStatus.failed, error: 'boom'),
      ]);
      expect(find.text(summary(2)).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('is absent without running tasks', (tester) async {
      await mount(tester, [
        task('fail1', DownloadStatus.failed, error: 'boom'),
        saved('done1'),
      ]);
      for (var n = 1; n <= 3; n++) {
        expect(find.text(summary(n)), findsNothing);
      }
      expect(_barOpacity(tester), 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a touch row keeps no room for hover actions', (tester) async {
      await mount(
        tester,
        [task('run', DownloadStatus.running)],
        size: _compact,
        platform: TargetPlatform.android,
      );
      expect(
        tester.widget<FrostTaskRow>(find.byType(FrostTaskRow)).trailing,
        isNull,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a pointer row keeps its hover actions', (tester) async {
      await mount(tester, [task('run', DownloadStatus.running)]);
      expect(
        tester.widget<FrostTaskRow>(find.byType(FrostTaskRow)).trailing,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps one height through every state', (tester) async {
      double height() =>
          tester.getSize(find.byType(DownloadTransferSummary)).height;
      final fixture = await mount(tester, [
        task('fail1', DownloadStatus.failed, error: 'boom'),
      ]);
      final idle = height();
      for (final list in [
        [task('a', DownloadStatus.queued, sized: false)],
        [task('a', DownloadStatus.running, sized: false)],
        [task('a', DownloadStatus.running)],
        [task('a', DownloadStatus.paused)],
        [task('a', DownloadStatus.cancelled)],
      ]) {
        fixture.items.replace(list);
        await settle(tester);
        expect(height(), idle, reason: list.first.snapshot.status.name);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not move backwards when a task finishes', (tester) async {
      final fixture = await mount(tester, [
        task('a', DownloadStatus.running),
        task('b', DownloadStatus.running),
      ]);
      double bar() => tester
          .widget<FrostProgressBar>(
            find.descendant(
              of: find.byType(DownloadTransferSummary),
              matching: find.byType(FrostProgressBar),
            ),
          )
          .value;
      expect(bar(), closeTo(.5, .001));
      fixture.items.replace([saved('a'), task('b', DownloadStatus.running)]);
      await settle(tester);
      expect(bar(), closeTo(.75, .001));
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows no activity while everything is paused', (tester) async {
      final fixture = await mount(tester, [
        task('a', DownloadStatus.running, sized: false),
      ]);
      Finder dots() => find.descendant(
        of: find.byType(DownloadTransferSummary),
        matching: find.byType(FrostActivityIndicator),
      );
      expect(dots(), findsOneWidget);
      fixture.items.replace([task('a', DownloadStatus.paused, sized: false)]);
      await settle(tester);
      expect(dots(), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('is not part of the completed section', (tester) async {
      await mount(tester, [
        task('run1', DownloadStatus.running),
        task('run2', DownloadStatus.running),
        saved('done1'),
      ]);
      expect(find.text(summary(2)).hitTestable(), findsOneWidget);
      await openSection(tester, t.downloads.completed);
      expect(find.text(summary(2)).hitTestable(), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('the completed section groups tasks under date headers', (
    tester,
  ) async {
    final old = DateTime(2020, 3, 14, 12);
    await mount(tester, [
      task('run1', DownloadStatus.running),
      saved('c-old', when: old),
      saved('c-today-1', when: noon(0)),
      saved('c-yesterday', when: noon(1)),
      saved('c-today-2', when: noon(0)),
    ]);
    await openSection(tester, t.downloads.completed);
    final today = find.text(t.downloads.today).hitTestable();
    final yesterday = find.text(t.downloads.yesterday).hitTestable();
    final oldHeader = find.text(DateFormat.yMd('en').format(old)).hitTestable();
    expect(today, findsOneWidget);
    expect(yesterday, findsOneWidget);
    expect(oldHeader, findsOneWidget);
    double top(Finder finder) => tester.getTopLeft(finder.first).dy;
    // Newest group first; every task sits under its own header.
    expect(top(today), lessThan(top(title('c-today-1.png'))));
    expect(top(today), lessThan(top(title('c-today-2.png'))));
    expect(top(title('c-today-1.png')), lessThan(top(yesterday)));
    expect(top(title('c-today-2.png')), lessThan(top(yesterday)));
    expect(top(yesterday), lessThan(top(title('c-yesterday.png'))));
    expect(top(title('c-yesterday.png')), lessThan(top(oldHeader)));
    expect(top(oldHeader), lessThan(top(title('c-old.png'))));
    expect(title('run1.png'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  group('header actions', () {
    final running = [
      task('run1', DownloadStatus.running),
      task('fail1', DownloadStatus.failed, error: 'Connection timed out'),
      saved('done1'),
    ];
    final paused = [
      task('pause1', DownloadStatus.paused),
      task('fail1', DownloadStatus.failed, error: 'Connection timed out'),
      saved('done1'),
    ];

    testWidgets(
      'one header action reads pause all while a task runs and calls pause',
      (tester) async {
        final fixture = await mount(tester, running);
        expect(headerAction(t.downloads.pauseAll), findsWidgets);
        expect(headerAction(t.downloads.resumeAll), findsNothing);
        await tester.tap(headerAction(t.downloads.pauseAll).first);
        await settle(tester, frames: 6);
        expect(fixture.manager.calls, contains(('pause', 'run1')));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'the same header slot becomes resume all when nothing runs and calls resume',
      (tester) async {
        final fixture = await mount(tester, paused);
        expect(headerAction(t.downloads.resumeAll), findsWidgets);
        expect(headerAction(t.downloads.pauseAll), findsNothing);
        await tester.tap(headerAction(t.downloads.resumeAll).first);
        await settle(tester, frames: 6);
        expect(fixture.manager.calls, contains(('resume', 'pause1')));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('the action switches live with the running state', (
      tester,
    ) async {
      final fixture = await mount(tester, running);
      expect(headerAction(t.downloads.pauseAll), findsWidgets);
      fixture.items.replace(paused);
      await settle(tester);
      expect(headerAction(t.downloads.resumeAll), findsWidgets);
      expect(headerAction(t.downloads.pauseAll), findsNothing);
      fixture.items.replace(running);
      await settle(tester);
      expect(headerAction(t.downloads.pauseAll), findsWidgets);
      expect(headerAction(t.downloads.resumeAll), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'clear completed is not a header button; the more menu has retry failed, clear completed and sync',
      (tester) async {
        await mount(tester, running);
        expect(headerAction(t.downloads.clearCompleted), findsNothing);
        expect(find.text(t.downloads.retryFailed), findsNothing);
        await openMore(tester);
        expect(
          find.text(t.downloads.retryFailed).hitTestable(),
          findsOneWidget,
        );
        expect(
          find.text(t.downloads.clearCompleted).hitTestable(),
          findsOneWidget,
        );
        expect(find.text(t.downloads.sync).hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('menu actions with nothing to act on are disabled', (
      tester,
    ) async {
      await mount(tester, [task('run', DownloadStatus.running)]);
      final dynamic menu = tester
          .widget<FrostPageHeader>(find.byType(FrostPageHeader))
          .actions
          .last;
      final actions = (menu.entries as List<FrostMenuEntry>)
          .whereType<FrostMenuAction>();
      for (final label in [
        t.downloads.retryFailed,
        t.downloads.clearCompleted,
      ]) {
        expect(
          actions.firstWhere((action) => action.label == label).onSelected,
          isNull,
          reason: label,
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('retry failed in the more menu retries the failed task', (
      tester,
    ) async {
      final fixture = await mount(tester, running);
      await openMore(tester);
      await tester.tap(find.text(t.downloads.retryFailed).hitTestable());
      await settle(tester, frames: 6);
      expect(fixture.manager.calls, contains(('retry', 'fail1')));
      expect(tester.takeException(), isNull);
    });

    testWidgets('sync in the more menu syncs the manager', (tester) async {
      final fixture = await mount(tester, running);
      await openMore(tester);
      await tester.tap(find.text(t.downloads.sync).hitTestable());
      await settle(tester, frames: 6);
      expect(fixture.manager.calls, contains(('sync', '')));
      expect(tester.takeException(), isNull);
    });
  });

  group('deep link', () {
    void expectRevealed(
      WidgetTester tester,
      BooruDownloadItem target,
      String file,
    ) {
      final row = title(file);
      expect(row, findsOneWidget, reason: 'the linked row is on screen');
      final rect = tester.getRect(row);
      final view = Offset.zero & _wide;
      expect(view.contains(rect.topLeft), isTrue, reason: '$rect in $view');
      expect(view.contains(rect.bottomRight), isTrue, reason: '$rect in $view');
      expect(
        showing(normalizedPath(target)),
        findsWidgets,
        reason: 'the linked row is expanded',
      );
    }

    testWidgets('a completed task selects All, expands and shows its row', (
      tester,
    ) async {
      final done = [
        for (var i = 0; i < 60; i++)
          saved('d$i', when: noon(0), path: pathOf('d$i')),
      ];
      await mount(
        tester,
        [
          for (var i = 0; i < 3; i++) task('r$i', DownloadStatus.running),
          ...done,
        ],
        location: '${AppRoute.downloads.path}?task=d45',
        settleAfter: false,
      );
      await settle(tester, frames: 80);
      expect(selectedTab(tester), 0);
      expectRevealed(tester, done[45], 'd45.png');
      expect(tester.takeException(), isNull);
    });

    testWidgets('an active task is revealed in All, expanded', (tester) async {
      final active = [
        for (var i = 0; i < 60; i++)
          task('active$i', DownloadStatus.running, path: pathOf('active$i')),
      ];
      await mount(
        tester,
        [...active, for (var i = 0; i < 3; i++) saved('d$i', when: noon(0))],
        location: '${AppRoute.downloads.path}?task=active45',
        settleAfter: false,
      );
      await settle(tester, frames: 80);
      expect(selectedTab(tester), 0);
      expectRevealed(tester, active[45], 'active45.png');
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('no tasks shows an empty state whose action goes to /', (
    tester,
  ) async {
    final fixture = await mount(tester, []);
    expect(find.byType(FrostEmptyState), findsOneWidget);
    expect(find.text(t.downloads.noTasks).hitTestable(), findsOneWidget);
    expect(fixture.router.state.uri.path, AppRoute.downloads.path);
    await tester.tap(find.text(t.downloads.browse).hitTestable());
    await settle(tester);
    expect(fixture.router.state.uri.path, '/');
    expect(find.text(_browseMarker), findsOneWidget);
    expect(find.byType(FrostEmptyState), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a task that completes stays in the active section for 600 ms, then moves to completed',
    (tester) async {
      final fixture = await mount(tester, [
        task('job', DownloadStatus.running),
        task('other', DownloadStatus.running),
      ]);
      await openSection(tester, t.downloads.active);
      expect(title('job.png'), findsOneWidget);
      fixture.items.replace([
        saved('job'),
        task('other', DownloadStatus.running),
      ]);
      await tester.pump();
      expect(title('job.png'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 400));
      expect(title('job.png'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      expect(title('job.png'), findsOneWidget, reason: 'still held at 500 ms');
      await tester.pump(const Duration(milliseconds: 200));
      await settle(tester);
      expect(title('job.png'), findsNothing, reason: 'gone after the hold');
      expect(title('other.png'), findsOneWidget);
      await openSection(tester, t.downloads.completed);
      expect(title('job.png'), findsOneWidget);
      expect(title('other.png'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'in All a task that completes moves from the tasks in flight to the completed days after 600 ms',
    (tester) async {
      final fixture = await mount(tester, [
        task('job', DownloadStatus.running),
        task('other', DownloadStatus.running),
      ]);
      double top(String file) => tester.getTopLeft(title(file)).dy;
      expect(top('job.png'), lessThan(top('other.png')));
      fixture.items.replace([
        saved('job'),
        task('other', DownloadStatus.running),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(top('job.png'), lessThan(top('other.png')), reason: 'held');
      await tester.pump(const Duration(milliseconds: 300));
      await settle(tester);
      expect(top('job.png'), greaterThan(top('other.png')));
      expect(find.text(t.downloads.today), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  group('batch download dialog', () {
    const location = BatchSaveLocation(
      root: 'test/downloads',
      target: SaveTarget.downloadsFolder(directory: 'test/downloads'),
    );

    int primaryActions(WidgetTester tester) {
      final dialog = tester.widget<FrostDialog>(find.byType(FrostDialog));
      return [
        ?dialog.leadingAction,
        ...dialog.actions,
      ].where((action) => action.isDefault).length;
    }

    for (final width in [390.0, 1024.0]) {
      testWidgets(
        'each step of the dialog has exactly one primary action at $width',
        (tester) async {
          final request = BatchDownloadRequest(
            sourceName: 'Yande.re',
            key: CollectionKey(
              sourceId: 'yande',
              request: const FeedCollectionRequest(),
              ratings: [],
              revision: 0,
            ),
            loader: (_, _) async =>
                PostPage(items: [_post('1'), _post('2')], exhausted: true),
          );
          final manager = _Manager();
          await mount(
            tester,
            [],
            size: Size(width, 1000),
            location: AppRoute.posts.path,
            manager: manager,
            home: (context) => Center(
              child: FrostButton(
                label: 'Open batch',
                onPressed: () => showBatchDownloadDialog(context, request),
              ),
            ),
            scope: (child) => ProviderScope(
              overrides: [
                booruSessionProvider.overrideWith(_Session.new),
                downloadManagerProvider.overrideWithValue(manager),
                booruDownloadsProvider.overrideWithValue(_BatchDownloads()),
                batchSaveLocationProvider(
                  'yande',
                ).overrideWith((ref) async => location),
              ],
              child: child,
            ),
          );
          await tester.tap(find.text('Open batch'));
          await settle(tester);
          expect(find.byType(FrostDialog), findsOneWidget);
          expect(find.text(t.batchDownload.title).hitTestable(), findsWidgets);
          // Setup.
          expect(primaryActions(tester), 1);
          await tester.tap(find.text(t.batchDownload.start));
          await settle(tester);
          // Ready: choose a folder, then enqueue.
          expect(primaryActions(tester), 1);
          final folder = find.byWidgetPredicate(
            (w) =>
                w is FrostTextField && w.label == t.batchDownload.folderLabel,
          );
          await tester.ensureVisible(folder);
          await tester.enterText(folder, 'October');
          await settle(tester, frames: 6);
          final enqueue = find.text(t.batchDownload.enqueue(count: '2'));
          await tester.ensureVisible(enqueue);
          await tester.tap(enqueue);
          await settle(tester);
          // Finished.
          expect(find.text(t.batchDownload.done), findsWidgets);
          expect(primaryActions(tester), 1);
          expect(manager.jobs, hasLength(2));
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('the dialog is the batch dialog, not a page', (tester) async {
      final request = BatchDownloadRequest(
        sourceName: 'Yande.re',
        key: CollectionKey(
          sourceId: 'yande',
          request: const FeedCollectionRequest(),
          ratings: [],
          revision: 0,
        ),
        loader: (_, _) async => PostPage(items: [], exhausted: true),
      );
      await mount(
        tester,
        [],
        location: AppRoute.posts.path,
        home: (context) => Center(
          child: FrostButton(
            label: 'Open batch',
            onPressed: () => showBatchDownloadDialog(context, request),
          ),
        ),
        scope: (child) => ProviderScope(
          overrides: [
            batchSaveLocationProvider(
              'yande',
            ).overrideWith((ref) async => location),
          ],
          child: child,
        ),
      );
      await tester.tap(find.text('Open batch'));
      await settle(tester);
      expect(find.byType(BatchDownloadDialog), findsOneWidget);
      expect(find.byType(FrostDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  for (final locale in [AppLocale.en, AppLocale.ja]) {
    for (final (size, label) in [
      (_compact, 'compact 360 wide'),
      (_wide, 'wide 1147x717'),
    ]) {
      testWidgets(
        'no overflow at 2.0 text in ${locale.languageTag}, $label, with long titles and a long failure reason',
        (tester) async {
          final longReason =
              'Connection timed out while contacting '
              '${List.filled(10, 'a-very-long-host-name').join('.')}\n'
              '${List.filled(12, 'SocketException: OS Error (errno = 110)').join(' ')}';
          final longPath =
              r'C:\Users\fixture\Downloads\BooruFlow\'
              '${List.filled(6, 'an-extremely-long-folder-name').join(r'\')}'
              r'\final.png';
          final list = [
            task(
              'fail',
              DownloadStatus.failed,
              file: _longName('failed'),
              error: longReason,
              path: longPath,
            ),
            task(
              'run',
              DownloadStatus.running,
              file: _longName('running'),
              path: longPath,
            ),
            task(
              'pause',
              DownloadStatus.paused,
              file: _longName('paused'),
              path: longPath,
            ),
            for (var i = 0; i < 2; i++)
              task(
                'b$i',
                DownloadStatus.running,
                batch: 'long-batch',
                batchName: List.filled(8, 'a-very-long-batch-name').join(' '),
                file: _longName('batch$i'),
              ),
            saved('done1', file: _longName('done1'), path: longPath),
            saved('done2', when: noon(1), file: _longName('done2')),
          ];
          await mount(tester, list, size: size, scale: 2, locale: locale);
          expect(tester.takeException(), isNull);
          // Expand the failed row (long reason and path), then another.
          await tapRow(tester, list[0].snapshot.filename);
          expect(tester.takeException(), isNull);
          await tapRow(tester, list[1].snapshot.filename);
          expect(tester.takeException(), isNull);
          // Collapse and expand the long batch row.
          final batchRow = find.text(list[3].snapshot.batchName!).hitTestable();
          await bring(tester, find.text(list[3].snapshot.batchName!));
          await tester.tap(batchRow.first);
          await settle(tester);
          expect(tester.takeException(), isNull);
          await tester.tap(batchRow.first);
          await settle(tester);
          expect(tester.takeException(), isNull);
          // Completed section with date groups and an expanded row.
          await openSection(tester, t.downloads.completed);
          expect(tester.takeException(), isNull);
          await tapRow(tester, list[5].snapshot.filename);
          expect(tester.takeException(), isNull);
          // The header menu at this scale.
          await openSection(tester, t.downloads.active);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
