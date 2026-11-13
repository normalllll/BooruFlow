import 'dart:async';
import 'dart:convert';

import 'package:booruflow/app/app_router.dart';
import 'package:booruflow/core/downloads/download_manager_contract.dart';
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/downloads/download_entry.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/features/downloads/services/booru_downloads.dart';
import 'package:booruflow/features/image_viewer/viewer_controls.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/post_actions.dart';
import 'package:booruflow/features/posts/stage_image_presentation.dart';
import 'package:booruflow/features/posts/widgets/post_detail_panel.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_download.dart';
import 'package:booruflow/src/rust/api/booru_engine.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:booruflow/ui/custom/download_flight.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';

import '../../support/browse_support.dart' show browseTestApp;
import '../discovery/search_interaction_test.dart' show testSource;
import '../posts/media_type_presentation_test.dart' show variant;
import 'support.dart' show TestDownloadItems;

class _Store implements SettingsServiceStore {
  @override
  Map<String, dynamic> load() => {};
  @override
  Future<void> write(String key, dynamic value) async {}
}

/// Prepares from the post it is given and fails on any request of its own.
class _Engine implements BooruEngine {
  final prepared = <BooruPost>[];
  @override
  Future<PreparedDownload> preparePostDownload({
    required BooruPost post,
    required MediaVariantKind variant,
  }) async {
    prepared.add(post);
    return PreparedDownload(
      sourceId: post.sourceId,
      postId: post.postId,
      variant: variant,
      url: 'https://cdn.example/original.png',
      headers: const [],
      allowedMediaKinds: const [],
      filename: '${post.postId}.png',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('No request of its own: ${invocation.memberName}');
}

class _Service extends BooruService {
  _Service(this.value) {
    useSourcesForTesting([testSource('danbooru')]);
  }
  final BooruEngine value;
  @override
  BooruEngine get engine => value;
}

class _Manager implements DownloadManager {
  final jobs = <DownloadJob>[];
  final tasks = <DownloadTaskSnapshot>[];
  final stream = StreamController<List<DownloadTaskSnapshot>>.broadcast();

  @override
  Future<void> initialize() async {}
  /// Holds an enqueue until it completes, then fails it with [failure].
  Completer<void>? gate;
  Object? failure;

  @override
  Future<int> enqueue(List<DownloadJob> value) async {
    await gate?.future;
    if (failure case final error?) throw error;
    jobs.addAll(value);
    tasks.addAll([
      for (final job in value)
        DownloadTaskSnapshot(
          id: job.id,
          sourceId: job.sourceId,
          postId: job.postId,
          resourceId: job.resourceId,
          variantIndex: job.variantIndex,
          title: job.filename,
          filename: job.filename,
          status: DownloadStatus.queued,
          saveState: SaveState.none,
          receivedBytes: 0,
          totalBytes: null,
          progress: 0,
          localPath: null,
          error: null,
          log: null,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
    ]);
    stream.add(List.of(tasks));
    return value.length;
  }

  @override
  Future<List<DownloadTaskSnapshot>> listTasks({
    int? resourceId,
    DownloadStatus? status,
    SaveState? saveState,
  }) async => List.of(tasks);
  @override
  Stream<List<DownloadTaskSnapshot>> watchTasks({int? resourceId}) =>
      stream.stream;
  @override
  Future<void> dispose() => stream.close();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

BooruDownloadItem _item(
  Post post,
  DownloadStatus status, {
  SaveState save = SaveState.none,
}) => BooruDownloadItem(
  snapshot: DownloadTaskSnapshot(
    id: 'task-${post.id}',
    sourceId: post.sourceId,
    postId: post.id,
    resourceId: post.resourceId,
    variantIndex: MediaVariantKind.original.index,
    title: '#${post.id}',
    filename: '${post.id}.png',
    status: status,
    saveState: save,
    receivedBytes: 1,
    totalBytes: 10,
    progress: .1,
    localPath: null,
    error: null,
    log: null,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  ),
);

Post _post(String id) => Post(
  BooruPost(
    sourceId: 'danbooru',
    postId: id,
    postKey: 'danbooru:$id',
    rating: ContentRating.general,
    tags: const [],
    media: [variant(MediaVariantKind.original, 'png')],
    flags: const PostFlags(
      hasChildren: false,
      isPending: false,
      isDeleted: false,
      isAiGenerated: false,
    ),
  ),
);

final _image = MemoryImage(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+j3i0AAAAASUVORK5CYII=',
  ),
);

// Fitting rows build more than one candidate; any of them will do.
Finder _button(String label) => find
    .byWidgetPredicate((w) => w is FrostButton && w.label == label)
    .first;

void main() {
  late Post post;
  setUp(() async {
    await SettingsService.initialize(store: _Store());
    LocaleSettings.setLocaleSync(AppLocale.en);
    post = _post('1');
  });

  group('adding a download', () {
    late _Engine engine;
    late _Manager manager;
    late BooruDownloads downloads;
    setUp(() {
      engine = _Engine();
      manager = _Manager();
      downloads = BooruDownloads(service: _Service(engine), manager: manager);
    });

    testWidgets('prepares from the post in hand and queues it once', (
      tester,
    ) async {
      await tester.pumpWidget(browseTestApp(const SizedBox()));
      final first = downloads.add(post);
      // The post is claimed at once: a second tap changes nothing.
      expect(downloads.blockFor(BooruDownloads.identityOf(post)), isNotNull);
      expect(await downloads.add(post), isFalse);
      expect(await first, isTrue);
      expect(engine.prepared.single, same(post.data));
      expect(manager.jobs, hasLength(1));
      // The queued task blocks it, without waiting for the sampled stream.
      expect(
        downloads.blockFor(BooruDownloads.identityOf(post)),
        DownloadBlock.inProgress,
      );
      expect(await downloads.add(post), isFalse);
      expect(manager.jobs, hasLength(1));
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('shows the added toast unless a flight announced it', (
      tester,
    ) async {
      await tester.pumpWidget(browseTestApp(const SizedBox()));
      await downloads.add(post, announce: false);
      await tester.pump();
      expect(find.text(t.verificationPage.downloadAdded), findsNothing);
      await downloads.add(_post('2'));
      await tester.pump();
      expect(find.text(t.verificationPage.downloadAdded), findsOneWidget);
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('shows the added toast at claim time; a failure follows it', (
      tester,
    ) async {
      await tester.pumpWidget(
        browseTestApp(
          const SizedBox(),
          navigatorKey: AppRouter.rootNavigatorKey,
        ),
      );
      manager
        ..gate = Completer<void>()
        ..failure = StateError('no space');
      final added = downloads.add(post);
      await tester.pump();
      // Nothing has been prepared or queued yet, and the toast is there.
      expect(manager.jobs, isEmpty);
      expect(find.text(t.verificationPage.downloadAdded), findsOneWidget);
      manager.gate!.complete();
      expect(await added, isFalse);
      await tester.pump();
      expect(find.text(t.verificationPage.downloadFailed), findsOneWidget);
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('a retry from the failure toast shows the added toast', (
      tester,
    ) async {
      await tester.pumpWidget(
        browseTestApp(
          const SizedBox(),
          navigatorKey: AppRouter.rootNavigatorKey,
        ),
      );
      manager.failure = StateError('no space');
      expect(await downloads.add(post, announce: false), isFalse);
      await tester.pump();
      expect(find.text(t.verificationPage.downloadFailed), findsOneWidget);
      expect(find.text(t.verificationPage.downloadAdded), findsNothing);
      manager.failure = null;
      await tester.tap(find.text(t.generic.retry));
      await tester.pump();
      await tester.pump();
      expect(manager.jobs, hasLength(1));
      expect(find.text(t.verificationPage.downloadAdded), findsOneWidget);
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('only a claimed post flies', (tester) async {
      await tester.pumpWidget(browseTestApp(const SizedBox()));
      var flights = 0;
      bool fly() {
        flights++;
        return true;
      }

      final first = downloads.add(post, flight: fly);
      // A second tap, and a post a batch holds, get neither flight nor toast.
      expect(await downloads.add(post, flight: fly), isFalse);
      final held = _post('2');
      expect(downloads.claim(BooruDownloads.identityOf(held)), isTrue);
      expect(await downloads.add(held, flight: fly), isFalse);
      expect(flights, 1);
      expect(await first, isTrue);
      await tester.pump();
      expect(find.text(t.verificationPage.downloadAdded), findsNothing);
      expect(find.text(t.downloads.messages.downloadTaskExists), findsNothing);
      expect(manager.jobs, hasLength(1));
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('a saved task from a batch also blocks a single download', (
      tester,
    ) async {
      await tester.pumpWidget(browseTestApp(const SizedBox()));
      manager.tasks.add(
        _item(post, DownloadStatus.downloaded, save: SaveState.saved).snapshot,
      );
      await downloads.initialize();
      expect(
        downloads.blockFor(BooruDownloads.identityOf(post)),
        DownloadBlock.saved,
      );
      expect(await downloads.add(post), isFalse);
      expect(manager.jobs, isEmpty);
    });
  });

  group('the detail download button', () {
    Future<void> mount(WidgetTester tester, List<BooruDownloadItem> items) =>
        tester.pumpWidget(
          ProviderScope(
            overrides: [
              downloadItemsProvider.overrideWith(
                () => TestDownloadItems(items),
              ),
            ],
            child: browseTestApp(
              Center(
                child: PostDetailActions(
                  post: post,
                  onOpen: () {},
                  moreEntries: const [],
                ),
              ),
            ),
          ),
        );

    testWidgets('is available for a post nothing has taken', (tester) async {
      await mount(tester, []);
      expect(
        tester.widget<FrostButton>(_button(t.postDetail.download)).onPressed,
        isNotNull,
      );
    });

    testWidgets('is disabled and says Downloaded for a saved post', (
      tester,
    ) async {
      await mount(tester, [
        _item(post, DownloadStatus.downloaded, save: SaveState.saved),
      ]);
      expect(
        find.byWidgetPredicate(
          (w) => w is FrostButton && w.label == t.postDetail.download,
        ),
        findsNothing,
      );
      final button = tester.widget<FrostButton>(
        _button(t.downloads.downloaded),
      );
      expect(button.onPressed, isNull);
      expect(button.state, FrostActionState.idle);
    });

    testWidgets('is disabled and says Downloading while in progress', (
      tester,
    ) async {
      await mount(tester, [_item(post, DownloadStatus.running)]);
      final button = tester.widget<FrostButton>(
        _button(t.downloads.downloading),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('is available again after a failure', (tester) async {
      await mount(tester, [_item(post, DownloadStatus.failed)]);
      expect(
        tester.widget<FrostButton>(_button(t.postDetail.download)).onPressed,
        isNotNull,
      );
    });

    testWidgets('does not fly without a flight source, and says so', (
      tester,
    ) async {
      final manager = _Manager();
      final downloads = BooruDownloads(
        service: _Service(_Engine()),
        manager: manager,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [booruDownloadsProvider.overrideWithValue(downloads)],
          child: browseTestApp(
            DownloadFlightHost(
              child: Center(
                child: PostDetailActions(
                  post: post,
                  onOpen: () {},
                  moreEntries: const [],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(_button(t.postDetail.download));
      await tester.pump();
      await tester.pump();
      expect(find.byType(Image), findsNothing);
      expect(manager.jobs, hasLength(1));
      expect(find.text(t.verificationPage.downloadAdded), findsOneWidget);
      await tester.pump(const Duration(seconds: 10));
    });
  });

  testWidgets('a viewer download shows the added toast and never flies', (
    tester,
  ) async {
    final manager = _Manager();
    final downloads = BooruDownloads(
      service: _Service(_Engine()),
      manager: manager,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [booruDownloadsProvider.overrideWithValue(downloads)],
        child: browseTestApp(
          DownloadFlightHost(
            child: Align(
              alignment: Alignment.bottomRight,
              child: DownloadFlightTarget(
                child: ViewerBottomBar(
                  post: post,
                  presentation: StageImagePresentation(post: post),
                  scale: 1,
                  maxScale: 4,
                  onZoom: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(_button(t.postDetail.download));
    await tester.pump();
    await tester.pump();
    expect(find.byType(Image), findsNothing);
    expect(manager.jobs, hasLength(1));
    expect(find.text(t.verificationPage.downloadAdded), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('the menu entry is disabled for a post that is taken', (
    tester,
  ) async {
    late List<FrostMenuEntry> open, taken;
    await tester.pumpWidget(
      browseTestApp(
        Builder(
          builder: (context) {
            open = postMenuEntries(
              context: context,
              post: post,
              download: () {},
            );
            taken = postMenuEntries(
              context: context,
              post: post,
              download: () {},
              downloadEnabled: false,
            );
            return const SizedBox();
          },
        ),
      ),
    );
    expect((open.first as FrostMenuAction).enabled, isTrue);
    expect((taken.first as FrostMenuAction).enabled, isFalse);
  });

  group('the downloads entry', () {
    late _Manager manager;
    late BooruDownloads downloads;
    late GlobalKey<DownloadFlightHostState> host;
    late Post other;
    final claim = BooruDownloads.identityOf(_post('1'));

    // One other download is active, as the badge says.
    Future<void> mount(WidgetTester tester) async {
      other = _post('9');
      manager = _Manager()
        ..tasks.add(_item(other, DownloadStatus.running).snapshot);
      downloads = BooruDownloads(
        service: _Service(_Engine()),
        manager: manager,
      );
      await downloads.initialize();
      host = GlobalKey<DownloadFlightHostState>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [booruDownloadsProvider.overrideWithValue(downloads)],
          child: browseTestApp(
            DownloadFlightHost(
              key: host,
              child: const Align(
                alignment: Alignment.bottomRight,
                child: DownloadEntryButton(alwaysShown: true),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    int badge(WidgetTester tester) => tester
        .widget<FrostShellTaskButton>(find.byType(FrostShellTaskButton))
        .badge;

    Future<bool> addWithFlight() => downloads.add(
      post,
      flight: () => host.currentState!.fly(
        source: const Rect.fromLTWH(20, 20, 80, 100),
        image: _image,
        claim: claim,
      ),
    );

    testWidgets('does not count a download whose flight is in the air', (
      tester,
    ) async {
      await mount(tester);
      expect(badge(tester), 1);
      final added = addWithFlight();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(host.currentState!.inAir.value, [claim]);
      expect(await added, isTrue);
      await tester.pump();
      expect(badge(tester), 1);
      await tester.pumpAndSettle();
      expect(host.currentState!.inAir.value, isEmpty);
      expect(badge(tester), 2);
    });

    testWidgets('a failed enqueue mid-flight never dips below the others', (
      tester,
    ) async {
      await mount(tester);
      manager
        ..gate = Completer<void>()
        ..failure = StateError('no space');
      final added = addWithFlight();
      await tester.pump();
      expect(badge(tester), 1);
      manager.gate!.complete();
      expect(await added, isFalse);
      // The claim is released while the flight is still in the air.
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 30));
        expect(badge(tester), 1, reason: 'frame $i');
      }
      expect(host.currentState!.inAir.value, isNotEmpty);
      await tester.pumpAndSettle();
      expect(badge(tester), 1);
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('a task that finishes mid-flight takes nothing off', (
      tester,
    ) async {
      await mount(tester);
      expect(await addWithFlight(), isTrue);
      await tester.pump();
      expect(badge(tester), 1);
      // The download completes before its flight lands.
      manager.tasks[1] = _item(
        post,
        DownloadStatus.downloaded,
        save: SaveState.saved,
      ).snapshot;
      manager.stream.add(List.of(manager.tasks));
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 20));
        expect(badge(tester), 1, reason: 'frame $i');
      }
      expect(host.currentState!.inAir.value, isNotEmpty);
      await tester.pumpAndSettle();
      expect(badge(tester), 1);
    });

    testWidgets('a flight without a claim takes nothing off', (tester) async {
      await mount(tester);
      host.currentState!.fly(
        source: const Rect.fromLTWH(20, 20, 80, 100),
        image: _image,
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(badge(tester), 1);
      await tester.pumpAndSettle();
    });
  });

  group('the flight', () {
    late GlobalKey<DownloadFlightHostState> host;
    Future<void> mount(WidgetTester tester, {bool reduced = false}) async {
      host = GlobalKey<DownloadFlightHostState>();
      await tester.pumpWidget(
        browseTestApp(
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
              child: DownloadFlightHost(
                key: host,
                child: const Align(
                  alignment: Alignment.bottomRight,
                  child: DownloadFlightTarget(
                    child: SizedBox(width: 60, height: 50),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Future<int> flightMilliseconds(WidgetTester tester, Rect source) async {
      expect(host.currentState!.fly(source: source, image: _image), isTrue);
      var elapsed = 0;
      do {
        await tester.pump(const Duration(milliseconds: 10));
        elapsed += 10;
      } while (find.byType(Image).evaluate().isNotEmpty && elapsed < 2000);
      await tester.pumpAndSettle();
      return elapsed;
    }

    testWidgets('lasts 400 to 600 ms, longer for a longer way', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await mount(tester);
      final near = await flightMilliseconds(
        tester,
        const Rect.fromLTWH(1000, 760, 60, 60),
      );
      final far = await flightMilliseconds(
        tester,
        const Rect.fromLTWH(20, 20, 60, 60),
      );
      expect(near, inInclusiveRange(400, 440));
      expect(far, inInclusiveRange(560, 630));
      expect(far, greaterThan(near));
    });

    testWidgets('leaves slowly, shrinks early and fades only at the end', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await mount(tester);
      const source = Rect.fromLTWH(100, 100, 200, 300);
      final end = tester.getCenter(find.byType(DownloadFlightTarget));
      final length = (end - source.center).distance;
      host.currentState!.fly(source: source, image: _image);
      await tester.pump();
      final image = find.byType(Image);
      final opacity = find.ancestor(of: image, matching: find.byType(Opacity));
      // A quarter of the time covers well under a quarter of the way.
      await tester.pump(const Duration(milliseconds: 150));
      final early = tester.getRect(image);
      expect((early.center - source.center).distance / length, lessThan(.12));
      expect(early.width, lessThan(source.width));
      expect(tester.widget<Opacity>(opacity).opacity, 1);
      // The card has shrunk to about a small thumbnail by 30 percent.
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getRect(image).shortestSide, closeTo(48, 8));
      expect(tester.widget<Opacity>(opacity).opacity, 1);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.widget<Opacity>(opacity).opacity, lessThan(1));
      await tester.pumpAndSettle();
    });

    testWidgets('reports that none started without animations', (tester) async {
      await mount(tester, reduced: true);
      expect(
        host.currentState!.fly(
          source: const Rect.fromLTWH(20, 20, 60, 60),
          image: _image,
        ),
        isFalse,
      );
      expect(host.currentState!.inAir.value, isEmpty);
    });
  });
}
