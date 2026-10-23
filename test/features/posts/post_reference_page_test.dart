import 'dart:async';
import 'dart:io';

import 'package:booruflow/app/app_router.dart';
import 'package:booruflow/app/booru_flow_app.dart';
import 'package:booruflow/core/downloads/download_database.dart'
    hide DownloadJob;
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/downloads/download_store.dart';
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/discovery/collection_logic.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/features/downloads/widgets/download_task_widgets.dart';
import 'package:booruflow/features/posts/post_detail_page.dart';
import 'package:booruflow/features/posts/post_reference_page.dart';
import 'package:booruflow/features/search/logic.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:booruflow/src/rust/booru/error.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';

import '../discovery/browse_v2_test.dart' show PendingMediaEngine;
import '../discovery/search_interaction_test.dart'
    show testSource, SearchRepositoryFake;
import '../downloads/support.dart';

class _Store implements SettingsServiceStore {
  @override
  Map<String, dynamic> load() => {};
  @override
  Future<void> write(String key, dynamic value) async {}
}

class _Engine extends PendingMediaEngine {
  final calls = <(String, String)>[];
  Object? failure;
  Completer<BooruPost>? pendingPost;
  @override
  Future<BooruPost> getPost({
    required String sourceId,
    required String postId,
  }) async {
    calls.add((sourceId, postId));
    if (failure case final error?) throw error;
    if (pendingPost case final pending?) return pending.future;
    return BooruPost(
      sourceId: sourceId,
      postId: postId,
      postKey: '$sourceId:$postId',
      rating: ContentRating.general,
      tags: const [
        BooruTag(name: 'fixture_artist', category: TagCategory.artist),
      ],
      media: const [
        MediaVariant(
          kind: MediaVariantKind.sample,
          url: 'https://fixture.invalid/sample.png',
          width: 640,
          height: 480,
        ),
      ],
      flags: const PostFlags(
        hasChildren: false,
        isPending: false,
        isDeleted: false,
        isAiGenerated: false,
      ),
    );
  }
}

class _Service extends BooruService {
  @override
  final _Engine engine = _Engine();
}

void main() {
  const ids = [
    'yande',
    'konachan_net',
    'konachan_com',
    'danbooru',
    'aibooru',
    'gelbooru',
    'wallhaven',
    'anime_pictures',
  ];
  late _Service service;
  late Directory temporary;
  final records = <String, List<BooruDownloadItem>>{};

  setUpAll(() async {
    temporary = await Directory.systemTemp.createTemp(
      'booruflow-r8-reference-',
    );
    for (final origin in ['single', 'batch', 'legacy']) {
      final file = File('${temporary.path}/$origin.db');
      var database = DownloadDatabase(executor: NativeDatabase(file));
      var store = DriftDownloadStore(database);
      for (final (index, source) in ids.indexed) {
        final id = source == 'wallhaven' ? 'abc123' : '363100';
        await store.upsertJob(
          DownloadJob.create(
            sourceId: source,
            postId: id,
            resourceId: index + 1,
            variantIndex: 0,
            batchId: origin == 'batch' ? 'persisted-batch' : null,
            url: Uri.parse('https://fixture.invalid/$source/$id.png'),
            filename: '$id (1).png',
            saveTarget: SaveTarget.downloadsFolder(
              directory: r'C:\Users\fixture\Downloads\BooruFlow',
              subdirectory: '$source/muryo',
            ),
          ),
        );
      }
      if (origin == 'legacy') {
        // Reopen a real version-1 schema; migration adds optional metadata only.
        await database.customStatement(
          'ALTER TABLE download_jobs DROP COLUMN ugoira_export',
        );
        await database.customStatement(
          'ALTER TABLE download_jobs DROP COLUMN batch_id',
        );
        await database.customStatement('PRAGMA user_version = 1');
      }
      await store.close();
      database = DownloadDatabase(executor: NativeDatabase(file));
      store = DriftDownloadStore(database);
      records[origin] = (await store.listTasks())
          .map((s) => BooruDownloadItem(snapshot: s))
          .toList();
      await store.close();
      expect(records[origin], hasLength(ids.length));
    }
  });
  tearDownAll(() {
    expect(temporary.absolute.parent.path, Directory.systemTemp.absolute.path);
    return temporary.delete(recursive: true);
  });

  setUp(() async {
    await SettingsService.initialize(store: _Store());
    LocaleSettings.setLocaleSync(AppLocale.en);
    service = _Service()..useSourcesForTesting(ids.map(testSource).toList());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('frost_window'),
          (call) async => call.method == 'getState'
              ? {'revision': 0, 'active': true}
              : null,
        );
    AppRouter.router.go('/downloads');
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('frost_window'), null),
  );

  Future<void> frames(WidgetTester tester) async {
    for (var i = 0; i < 35; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  Future<void> mount(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(() => tester.pumpWidget(const SizedBox()));
    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            booruServiceProvider.overrideWithValue(service),
            collectionLoaderProvider.overrideWithValue(
              (_, _) async => const PostPage(items: [], exhausted: true),
            ),
            downloadItemsProvider.overrideWith(
              () => TestDownloadItems(const []),
            ),
            downloadManagerProvider.overrideWithValue(TestDownloadManager()),
            tagSuggestionRepositoryProvider.overrideWithValue(
              SearchRepositoryFake(),
            ),
          ],
          child: BooruFlowApp(checkUpdates: false),
        ),
      ),
    );
    await frames(tester);
  }

  for (final origin in ['single', 'batch', 'legacy']) {
    testWidgets(
      'restored $origin records open exact references for every source without a feed snapshot',
      (tester) async {
        await mount(tester);
        for (final item in records[origin]!) {
          final context = tester.element(find.byType(FrostPageHeader).first);
          unawaited(openDownloadPost(context, item));
          await frames(tester);
          final detail = tester.widget<PostDetailPage>(
            find.byType(PostDetailPage),
          );
          expect(detail.args.post.sourceId, item.sourceId);
          expect(detail.args.post.id, item.postId);
          expect(detail.args.collection, hasLength(1));
          expect(AppRouter.currentUri.queryParameters['source'], item.sourceId);
          expect(
            service.engine.calls.where(
              (c) => c == (item.sourceId, item.postId),
            ),
            hasLength(1),
          );
          expect(
            tester.widget<FrostShell>(find.byType(FrostShell)).canGoBack,
            isTrue,
          );
          AppRouter.popRightNavigator();
          await frames(tester);
          expect(find.byType(PostReferencePage), findsNothing);
          expect(AppRouter.currentUri.path, '/downloads');
        }
      },
      variant: TargetPlatformVariant.only(TargetPlatform.windows),
    );
  }

  testWidgets(
    'missing post retains shell back without a body back button or invented browser URL',
    (tester) async {
      service.engine.failure = const BooruError(
        code: BooruErrorCode.invalidResponse,
        httpStatus: 404,
        userMessageKey: 'fixture.missing',
        diagnosticId: 'r8',
      );
      await mount(tester);
      unawaited(
        openDownloadPost(
          tester.element(find.byType(FrostPageHeader).first),
          records['single']!.first,
        ),
      );
      await frames(tester);
      expect(find.byType(PostDetailPage), findsNothing);
      final empty = tester.widget<FrostEmptyState>(
        find.byType(FrostEmptyState).last,
      );
      expect(empty.title, t.postDetail.notFound);
      expect(empty.actionLabel, isNull);
      expect(
        find.descendant(
          of: find.byType(FrostEmptyState).last,
          matching: find.byType(FrostButton),
        ),
        findsNothing,
      );
      expect(
        tester.widget<FrostShell>(find.byType(FrostShell)).canGoBack,
        isTrue,
      );
      final back = find
          .byWidgetPredicate(
            (w) => w is FrostTooltip && w.message == t.frost.back,
          )
          .hitTestable();
      expect(back, findsOneWidget);
      await tester.tap(back);
      await frames(tester);
      expect(AppRouter.currentUri.path, '/downloads');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets(
    'reference retry preserves the failure until the new request resolves',
    (tester) async {
      service.engine.failure = StateError('fixture unavailable');
      await mount(tester);
      unawaited(
        openDownloadPost(
          tester.element(find.byType(FrostPageHeader).first),
          records['single']!.first,
        ),
      );
      await frames(tester);
      expect(find.byType(FrostErrorContent), findsOneWidget);
      service.engine.failure = null;
      service.engine.pendingPost = Completer<BooruPost>();
      await tester.tap(find.text(t.frost.retry).hitTestable());
      await frames(tester);
      expect(find.byType(PostDetailPage), findsNothing);
      expect(find.byType(FrostErrorContent), findsOneWidget);
      final pending = service.engine.pendingPost!;
      service.engine.pendingPost = null;
      pending.complete(
        await service.engine.getPost(sourceId: 'yande', postId: '363100'),
      );
      await frames(tester);
      expect(find.byType(PostDetailPage), findsOneWidget);
    },
  );
}
