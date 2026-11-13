// Settings and the remaining pages. Pages are found by widget types, i18n keys,
// routes and fake state; NotFoundPage is detected by its `t.generic.notFound`
// title and its empty-state action.
import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:booruflow/app/app_router.dart';
import 'package:booruflow/app/booru_flow_app.dart';
import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/core/downloads/download_manager_contract.dart';
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/booru/native_web_challenge_page.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/booru/services/web_challenge_service.dart';
import 'package:booruflow/features/booru/web_challenge_browser.dart';
import 'package:booruflow/features/booru/web_challenge_page.dart';
import 'package:booruflow/features/browse/collection_logic.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/features/posts/post_detail_page.dart';
import 'package:booruflow/features/search/logic.dart';
import 'package:booruflow/features/search/services/tag_suggestion_repository.dart';
import 'package:booruflow/features/settings/settings_page.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_engine.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:booruflow/src/rust/api/web_challenge.dart';
import 'package:booruflow/src/rust/booru/error.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:frost_ui/media.dart';
import 'package:material_ui/material_ui.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _Store implements SettingsServiceStore {
  final values = <String, dynamic>{};
  @override
  Map<String, dynamic> load() => Map.of(values);
  @override
  Future<void> write(String key, dynamic value) async => values[key] = value;
}

class _NoDownloads extends DownloadItems {
  @override
  List<BooruDownloadItem> build() => [];
}

class _Manager implements DownloadManager {
  @override
  Future<void> sync() async {}
  @override
  Future<List<DownloadTaskSnapshot>> listTasks({
    int? resourceId,
    DownloadStatus? status,
    SaveState? saveState,
  }) async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Tags extends TagSuggestionRepository {
  @override
  Future<void> initialize() async {}
  @override
  List<TagSuggestion> local(String source, String locale, String text) => [];
  @override
  List<TagSuggestion> merge(
    String source,
    String locale,
    String text,
    Iterable<TagSuggestion> values,
  ) => values.toList();
  @override
  String? displayName(String source, String locale, String value) => null;
  @override
  Future<List<String>> recentSearches(String source) async => [];
  @override
  Future<List<TagSuggestion>> common(
    String source,
    String locale, {
    bool refresh = false,
    int page = 1,
  }) async => [];
}

/// Every fixture source needs no account, so its detail is the "no account
/// needed" status plus the supported ratings, and nothing here touches Rust.
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

class _Engine implements BooruEngine {
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
    return _post(sourceId, postId);
  }

  /// Media never arrives: the stage shows its placeholder.
  @override
  Future<MediaRequest> prepareMediaUrl({
    required String sourceId,
    required String postId,
    required MediaVariantKind variant,
    required String url,
    required bool allowDiskCache,
  }) => Completer<MediaRequest>().future;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Service extends BooruService {
  @override
  final _Engine engine = _Engine();
}

BooruPost _post(String sourceId, String id) => BooruPost(
  sourceId: sourceId,
  postId: id,
  postKey: '$sourceId:$id',
  rating: ContentRating.general,
  tags: const [BooruTag(name: 'fixture_artist', category: TagCategory.artist)],
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

// Embedded web challenge ----------------------------------------------------

const _operation = WebChallengeOperation(
  operationId: 'settings-operation',
  spec: WebChallengeSpec(
    sourceId: 'gelbooru',
    displayName: 'Gelbooru',
    entryUrl: 'https://gelbooru.com/',
    navigationHosts: ['gelbooru.com'],
    captureTargets: [],
    timeoutSeconds: 600,
  ),
);

const _challengeState = WebChallengeState(
  sourceId: 'gelbooru',
  hasSavedData: true,
  verified: true,
  revision: 1,
);

class _Browser extends WebChallengeBrowser {
  @override
  Uri get url => Uri.parse('https://gelbooru.com/');
  @override
  bool loading = false;
  @override
  bool available = true;
  @override
  bool failed = false;
  @override
  Future<void> open(WebChallengeSpec spec) async {}
  @override
  Future<void> reload() async {}
  @override
  Future<WebChallengeCandidate> capture(WebChallengeSpec spec) async =>
      const WebChallengeCandidate(cookies: [], snapshots: [], userAgent: 'x');
  @override
  Future<void> clear() async {}
  @override
  Widget content(BuildContext context) =>
      const SizedBox(key: ValueKey('injected-web-content'));
}

/// The external (wry) window: each `runWindow` call is one open window that the
/// test closes, fails or lets finish.
class _NativeBackend implements WebChallengeBackend {
  final cancelled = <String>[];
  final windows = <Completer<WebChallengeState>>[];
  @override
  Future<WebChallengeOperation> begin(String sourceId) async => _operation;
  @override
  Future<WebChallengeState> runWindow(WebChallengeOperation operation) {
    final window = Completer<WebChallengeState>();
    windows.add(window);
    return window.future;
  }

  @override
  Future<WebChallengeState> complete(
    String id,
    WebChallengeCandidate candidate,
  ) async => _challengeState;
  @override
  Future<void> cancel(String id) async {
    cancelled.add(id);
    for (final window in windows) {
      if (!window.isCompleted) window.complete(_challengeState);
    }
  }

  @override
  Future<void> clear(String sourceId) async {}
}

// ---------------------------------------------------------------------------
// Finders and helpers
// ---------------------------------------------------------------------------

const _wide = Size(1147, 717);
const _phone = Size(390, 844);
const _compact = Size(360, 780);

Finder _listRow(String title) => find.byWidgetPredicate(
  (w) => w is FrostListRow && w.title == title,
  description: 'FrostListRow "$title"',
);

/// The visible settings layout. A retained destination root may also exist, so
/// the topmost (last) one is the page the user sees.
FrostSettingsSections _sections(WidgetTester tester) => tester
    .widgetList<FrostSettingsSections>(find.byType(FrostSettingsSections))
    .last;

/// The shell's one Back control on a pointer window (the title bar's).
Finder _shellBack() => find
    .byWidgetPredicate((w) => w is FrostTooltip && w.message == t.frost.back)
    .hitTestable();

/// A control by its visible label: a button, or a tooltip target (icon-only).
Finder _control(Iterable<String> labels) => find.byWidgetPredicate(
  (w) =>
      w is FrostButton && labels.contains(w.label) ||
      w is FrostTooltip && labels.contains(w.message),
  description: 'control ${labels.join(' / ')}',
);

Finder _inHeader(Finder finder) =>
    find.descendant(of: find.byType(FrostPageHeader), matching: finder);

String _plain(Widget widget) => switch (widget) {
  Text(:final data?) => data,
  Text(:final textSpan?) => textSpan.toPlainText(),
  _ => '',
};

/// Frames instead of pumpAndSettle: loading pages animate forever.
Future<void> _settle(WidgetTester tester, [int frames = 24]) async {
  for (var frame = 0; frame < frames; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// 5.11: one header row. Its title carries the source name, and everything in
/// the header sits on one line (a second title row would offset the centres).
void _expectOneRowHeader(WidgetTester tester, String sourceName) {
  expect(find.byType(FrostPageHeader), findsOneWidget);
  final named = _inHeader(find.textContaining(sourceName));
  expect(named, findsOneWidget, reason: 'the title names the source');
  expect(
    _plain(tester.widget(named)),
    isNot(sourceName),
    reason: 'the title is "<source> verification", not a bare source name',
  );
  final centres = [
    for (final element in _inHeader(find.byType(Text)).evaluate())
      tester
          .getCenter(find.byElementPredicate((e) => identical(e, element)))
          .dy,
  ];
  expect(centres, isNotEmpty);
  expect(
    centres.reduce((a, b) => a > b ? a : b) -
        centres.reduce((a, b) => a < b ? a : b),
    lessThan(4),
    reason: 'no second header row under the title',
  );
}

// ---------------------------------------------------------------------------

final _mediaSkeleton = find.byWidgetPredicate(
  (widget) =>
      widget is FrostMediaFrame &&
      widget.image == null &&
      widget.child is SizedBox,
);

void main() {
  const channel = MethodChannel('frost_window');
  late _Store store;
  late _Service service;

  setUp(() async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    store = _Store();
    await SettingsService.initialize(store: store);
    service = _Service()
      ..useSourcesForTesting(
        ['yande', 'danbooru', 'wallhaven'].map(_source).toList(),
      );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (call) async => call.method == 'getState'
              ? {'revision': 0, 'active': true}
              : null,
        );
    AppRouter.router.go('/');
  });
  tearDown(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  // The real application on the real router, as app_shell_test mounts it.
  Future<void> mountApp(
    WidgetTester tester, {
    Size size = _wide,
    double scale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(() => tester.pumpWidget(const SizedBox()));
    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            booruServiceProvider.overrideWithValue(service),
            downloadItemsProvider.overrideWith(_NoDownloads.new),
            downloadManagerProvider.overrideWithValue(_Manager()),
            tagSuggestionRepositoryProvider.overrideWithValue(_Tags()),
            collectionLoaderProvider.overrideWithValue(
              (_, _) async => const PostPage(items: [], exhausted: true),
            ),
          ],
          child: BooruFlowApp(
            windowController: FrostWindowController(
              minimumSize: const Size(320, 480),
            ),
            checkUpdates: false,
            builder: scale == 1
                ? null
                : (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
          ),
        ),
      ),
    );
    await _settle(tester);
  }

  // One page in a plain Frost app, without the shell.
  Future<void> mountPage(
    WidgetTester tester,
    Widget page, {
    Size size = _wide,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(() => tester.pumpWidget(const SizedBox()));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [booruServiceProvider.overrideWithValue(service)],
        child: TranslationProvider(
          child: FrostScope(
            config: appFrostConfig,
            child: MaterialApp(
              theme: FrostTheme.build(
                config: appFrostConfig,
                brightness: Brightness.light,
                platform: TargetPlatform.windows,
                locale: const Locale('en'),
              ),
              home: FrostLayoutScope(child: page),
            ),
          ),
        ),
      ),
    );
    await _settle(tester);
  }

  /// Opens the wide settings destination with the sources section selected.
  Future<void> openSourcesSection(WidgetTester tester) async {
    await mountApp(tester);
    AppRouter.router.go('/settings');
    await _settle(tester);
    await tester.tap(find.text(SettingsSection.sources.title).first);
    await _settle(tester);
  }

  group('wide split with a source detail pane', () {
    testWidgets(
      'navigation column and pane sit side by side; a source opens as the FrostSectionsDetail while the column stays',
      (tester) async {
        await openSourcesSection(tester);
        expect(_sections(tester).detail, isNull);
        final navigation = find.text(SettingsSection.appearance.title).first;
        final navigationRect = tester.getRect(navigation);
        final row = _listRow('yande');
        expect(row, findsOneWidget);
        expect(
          navigationRect.right,
          lessThan(tester.getRect(row).left),
          reason: 'the navigation column is left of the settings pane',
        );

        await tester.tap(row);
        await _settle(tester);
        expect(_sections(tester).detail, isNotNull);
        expect(find.text(t.settings.source.supportedRatings), findsOneWidget);
        expect(
          tester.getRect(navigation),
          navigationRect,
          reason: 'only the pane changes; the column does not move',
        );
        expect(navigation.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.windows),
    );

    testWidgets('Back closes the detail first and keeps the sources list', (
      tester,
    ) async {
      await openSourcesSection(tester);
      await tester.tap(_listRow('yande'));
      await _settle(tester);
      expect(_sections(tester).detail, isNotNull);

      expect(_shellBack(), findsOneWidget);
      await tester.tap(_shellBack());
      await _settle(tester);
      expect(_sections(tester).detail, isNull);
      expect(find.text(t.settings.source.supportedRatings), findsNothing);
      expect(_listRow('yande').hitTestable(), findsOneWidget);
      expect(_sections(tester).selectedIndex, SettingsSection.sources.index);
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

    testWidgets(
      'choosing another section closes the detail and shows that section',
      (tester) async {
        await openSourcesSection(tester);
        await tester.tap(_listRow('danbooru'));
        await _settle(tester);
        expect(_sections(tester).detail, isNotNull);

        await tester.tap(find.text(SettingsSection.appearance.title).first);
        await _settle(tester);
        expect(_sections(tester).detail, isNull);
        expect(find.text(t.settings.source.supportedRatings), findsNothing);
        expect(
          _sections(tester).selectedIndex,
          SettingsSection.appearance.index,
        );
        expect(find.byType(FrostPicker<FrostThemeMode>), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.windows),
    );
  });

  group('narrow settings home and routes', () {
    testWidgets('home lists every section with the current value on its row', (
      tester,
    ) async {
      await mountApp(tester, size: _phone);
      AppRouter.router.go('/settings');
      await _settle(tester);
      for (final section in SettingsSection.values) {
        final titles = {
          section.title,
          if (section == SettingsSection.general) t.settings.language,
        };
        expect(
          find.byWidgetPredicate(
            (w) => w is FrostListRow && titles.contains(w.title),
          ),
          findsOneWidget,
          reason: 'a row for ${section.name}',
        );
      }
      expect(
        find.descendant(
          of: _listRow(SettingsSection.appearance.title),
          matching: find.text(t.settings.system),
        ),
        findsOneWidget,
      );
      expect(find.byType(FrostPicker<FrostThemeMode>), findsNothing);
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    for (final section in [
      SettingsSection.appearance,
      SettingsSection.browsing,
      SettingsSection.downloads,
    ]) {
      testWidgets(
        'tapping ${section.name} navigates to /settings/${section.pathSegment}',
        (tester) async {
          await mountApp(tester, size: _phone);
          AppRouter.router.go('/settings');
          await _settle(tester);
          await tester.tap(_listRow(section.title));
          await _settle(tester);
          expect(AppRouter.currentUri.path, '/settings/${section.pathSegment}');
          expect(AppRouter.currentUri.queryParameters, isEmpty);
          expect(tester.takeException(), isNull);
        },
        variant: TargetPlatformVariant.only(TargetPlatform.android),
      );
    }

    testWidgets(
      'tapping a source row navigates to /settings/sources/<source> and Back returns to the list',
      (tester) async {
        await mountApp(tester, size: _phone);
        AppRouter.router.go('/settings/sources');
        await _settle(tester);
        await tester.tap(_listRow('danbooru'));
        await _settle(tester);
        expect(AppRouter.currentUri.path, '/settings/sources/danbooru');
        expect(AppRouter.currentUri.queryParameters, isEmpty);
        expect(
          _inHeader(find.text('danbooru')),
          findsOneWidget,
          reason: 'the page title is the source name',
        );
        expect(find.text(t.settings.source.supportedRatings), findsOneWidget);

        final back = find.byType(FrostCompactBackButton).hitTestable();
        expect(back, findsOneWidget);
        await tester.tap(back);
        await _settle(tester);
        expect(AppRouter.currentUri.path, '/settings/sources');
        expect(_listRow('danbooru'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );
  });

  group('source deep link', () {
    testWidgets(
      'a wide window opens /settings/sources/<source> as the sources section with that detail',
      (tester) async {
        await mountApp(tester);
        AppRouter.router.go('/settings/sources/wallhaven');
        await _settle(tester);
        expect(find.byType(FrostSettingsSections), findsWidgets);
        expect(_sections(tester).selectedIndex, SettingsSection.sources.index);
        expect(_sections(tester).detail, isNotNull);
        expect(find.text(t.settings.source.supportedRatings), findsOneWidget);
        expect(
          find.text('wallhaven'),
          findsWidgets,
          reason: 'the detail names its source',
        );
        expect(
          find.text(SettingsSection.appearance.title).first.hitTestable(),
          findsOneWidget,
          reason: 'the navigation column is still there',
        );

        await tester.tap(_shellBack());
        await _settle(tester);
        expect(_sections(tester).detail, isNull);
        expect(_listRow('wallhaven').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.windows),
    );
  });

  group('appearance and browsing controls', () {
    for (final size in [_wide, _phone]) {
      testWidgets(
        'tone is a segmented choice, disabled while the mode follows the system (${size.width.round()} wide)',
        (tester) async {
          await SettingsService.saveAppearance(
            SettingsService.appearance.copyWith(
              mode: FrostThemeMode.system,
              lightTone: FrostTone.cool,
            ),
          );
          await mountPage(
            tester,
            const SettingsPage(section: SettingsSection.appearance),
            size: size,
          );
          Finder tone() => find.byType(FrostPicker<FrostTone>);
          expect(tone(), findsOneWidget);
          FrostPicker<FrostTone> picker() =>
              tester.widget<FrostPicker<FrostTone>>(tone());
          expect(picker().style.name, 'segmented');
          expect(picker().options.map((o) => o.value), [
            FrostTone.neutral,
            FrostTone.cool,
            FrostTone.warm,
          ]);
          expect(picker().options.map((o) => o.label), [
            t.settingsV2.neutral,
            t.settingsV2.cool,
            t.settingsV2.warm,
          ]);
          expect(picker().onChanged, isNull, reason: 'system mode');
          expect(
            find.byType(FrostThumbnail),
            findsNothing,
            reason: 'the drawn palette previews are gone',
          );

          await tester.tap(find.text(t.settings.light));
          await _settle(tester);
          expect(picker().onChanged, isNotNull);
          await tester.tap(find.text(t.settingsV2.warm));
          await _settle(tester);
          expect(SettingsService.appearance.lightTone, FrostTone.warm);
          expect(picker().value, FrostTone.warm);

          await tester.tap(find.text(t.settings.system));
          await _settle(tester);
          expect(picker().onChanged, isNull);
          expect(
            SettingsService.appearance.lightTone,
            FrostTone.warm,
            reason: 'the manual choice is kept',
          );
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'browsing has a small/medium/large thumbnail size and no columns-per-row setting',
      (tester) async {
        await mountPage(
          tester,
          const SettingsPage(section: SettingsSection.browsing),
        );
        expect(find.text(t.settings.thumbnailSize), findsOneWidget);
        await tester.tap(find.text(t.settings.thumbnailSize));
        await _settle(tester);
        for (final label in [
          t.settings.thumbnailSmall,
          t.settings.thumbnailMedium,
          t.settings.thumbnailLarge,
        ]) {
          expect(find.text(label), findsWidgets, reason: label);
        }
        await tester.tap(find.text(t.settings.thumbnailLarge).last);
        await _settle(tester);
        expect(SettingsService.thumbnailSize, ThumbnailSize.large);

        final words = RegExp('column|per row', caseSensitive: false);
        expect(
          [
            for (final text in tester.widgetList<Text>(find.byType(Text)))
              _plain(text),
          ].where(words.hasMatch),
          isEmpty,
        );
        expect(find.byType(FrostStepper), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('appearance has no columns-per-row setting either', (
      tester,
    ) async {
      await mountPage(
        tester,
        const SettingsPage(section: SettingsSection.appearance),
      );
      final words = RegExp('column|per row', caseSensitive: false);
      expect(
        [
          for (final text in tester.widgetList<Text>(find.byType(Text)))
            _plain(text),
        ].where(words.hasMatch),
        isEmpty,
      );
      expect(find.byType(FrostStepper), findsNothing);
    });
  });

  group('no back-to-sources button in the pane', () {
    testWidgets('with a detail open the only way back is the shell Back', (
      tester,
    ) async {
      await openSourcesSection(tester);
      await tester.tap(_listRow('yande'));
      await _settle(tester);
      final detail = _sections(tester).detail;
      expect(detail, isNotNull);

      expect(
        find.byWidgetPredicate(
          (w) => w is FrostButton && w.label == SettingsSection.sources.title,
        ),
        findsNothing,
        reason: 'no "<- Sources & accounts" button',
      );
      final sectionTitles = SettingsSection.values.map((s) => s.title);
      expect(
        find.descendant(
          of: find.byWidget(detail!.child),
          matching: find.byWidgetPredicate(
            (w) =>
                w is FrostButton &&
                (sectionTitles.contains(w.label) || w.label == t.frost.back),
          ),
        ),
        findsNothing,
        reason: 'the pane carries no back button of its own',
      );
      expect(find.byType(FrostCompactBackButton), findsNothing);
      expect(_shellBack(), findsOneWidget);

      await tester.tap(_shellBack());
      await _settle(tester);
      expect(_sections(tester).detail, isNull);
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
  });

  group('web challenge', () {
    for (final size in [_wide, _phone]) {
      testWidgets(
        'embedded page has one header row with refresh, done and more, and the host in the more menu (${size.width.round()} wide)',
        (tester) async {
          final browser = _Browser();
          final cancellation = ValueNotifier(0);
          addTearDown(() {
            browser.dispose();
            cancellation.dispose();
          });
          await mountPage(
            tester,
            WebChallengePage(
              operation: _operation,
              cancellation: cancellation,
              browser: browser,
            ),
            size: size,
          );
          _expectOneRowHeader(tester, 'Gelbooru');
          expect(
            find.byKey(const ValueKey('injected-web-content')),
            findsOneWidget,
          );

          final refresh = _control({t.settingsDetails.refresh});
          final done = _control({t.webChallenge.finish, t.frost.done});
          final more = _control({t.frost.more});
          for (final (name, control) in [
            ('refresh', refresh),
            ('done', done),
            ('more', more),
          ]) {
            expect(control, findsWidgets, reason: name);
            expect(
              _inHeader(control).evaluate().length,
              control.evaluate().length,
              reason: '$name lives in the header, not in a toolbar below it',
            );
          }

          const host = 'gelbooru.com';
          expect(
            find.text(host),
            findsNothing,
            reason: 'the host takes no row until the more menu opens',
          );
          await tester.tap(more.hitTestable().first);
          await _settle(tester);
          expect(
            find.text(host),
            findsOneWidget,
            reason: 'the host is the more menu group title',
          );
          expect(tester.takeException(), isNull);
        },
      );
    }

    /// Opens [NativeWebChallengePage] as a pushed route, the way the service
    /// resolves a challenge on Windows, and waits for its waiting state.
    Future<WebChallengeService> openNative(
      WidgetTester tester,
      _NativeBackend backend,
      Size size,
    ) async {
      final service = WebChallengeService.forTesting(
        backendFactory: () => backend,
        collector: (_, _, _) =>
            throw StateError('Native must not use the embedded collector'),
        changed: (_) async {},
        nativeWindow: true,
      );
      await mountPage(
        tester,
        Builder(
          builder: (context) => FrostButton(
            label: 'Open',
            onPressed: () {
              Navigator.of(context).push<bool>(
                FrostDetailPage<bool>(
                  child: NativeWebChallengePage(
                    service: service,
                    sourceId: 'gelbooru',
                    sourceName: 'Gelbooru',
                  ),
                ).createRoute(context),
              );
            },
          ),
        ),
        size: size,
      );
      await tester.tap(find.text('Open'));
      await _settle(tester);
      return service;
    }

    for (final size in [_wide, _phone]) {
      testWidgets(
        'native page waits for the window with one header row and a cancel action (${size.width.round()} wide)',
        (tester) async {
          final backend = _NativeBackend();
          final service = await openNative(tester, backend, size);
          expect(service.activity?.phase, WebChallengePhase.waiting);
          expect(find.text(t.webChallenge.waiting), findsWidgets);
          _expectOneRowHeader(tester, 'Gelbooru');

          final cancel = _control({t.generic.cancel, t.frost.cancel});
          expect(cancel.hitTestable(), findsWidgets);
          await tester.tap(cancel.hitTestable().first);
          await _settle(tester);
          expect(backend.cancelled, isNotEmpty);
          expect(service.activity, isNull);
          expect(find.text('Open'), findsOneWidget, reason: 'the page closed');
          expect(tester.takeException(), isNull);
        },
      );
    }

    for (final (name, error) in [
      (
        'closed',
        const BooruError(
          code: BooruErrorCode.cancelled,
          userMessageKey: 'fixture.closed',
          diagnosticId: 'settings',
        ),
      ),
      ('failed', StateError('window failed')),
    ]) {
      testWidgets(
        'native page shows a failure state with reopen when the window is $name, and reopening waits again',
        (tester) async {
          final backend = _NativeBackend();
          await openNative(tester, backend, _wide);
          backend.windows.single.completeError(error);
          await _settle(tester);
          expect(find.text(t.webChallenge.waiting), findsNothing);
          expect(find.byType(FrostEmptyState), findsOneWidget);
          _expectOneRowHeader(tester, 'Gelbooru');

          final reopen = find.byWidgetPredicate(
            (w) => w is FrostButton && w.label == t.verificationPage.reopen,
          );
          expect(reopen.hitTestable(), findsOneWidget);
          await tester.tap(reopen);
          await _settle(tester);
          expect(backend.windows, hasLength(2));
          expect(find.text(t.webChallenge.waiting), findsWidgets);
          expect(find.byType(FrostEmptyState), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  group('not found page', () {
    for (final (route, size, platform) in [
      ('/image-viewer', _wide, TargetPlatform.windows),
      ('/image-viewer', _phone, TargetPlatform.android),
      ('/settings/not-a-section', _wide, TargetPlatform.windows),
      ('/settings/not-a-section', _phone, TargetPlatform.android),
      ('/content', _wide, TargetPlatform.windows),
    ]) {
      testWidgets(
        '$route without its data shows the not found page that returns to browsing (${size.width.round()} wide)',
        (tester) async {
          await mountApp(tester, size: size);
          AppRouter.router.go(route);
          await _settle(tester);

          expect(
            _inHeader(find.text(t.generic.notFound)),
            findsOneWidget,
            reason: 'the page is titled "${t.generic.notFound}"',
          );
          final empty = find.byType(FrostEmptyState);
          expect(empty, findsOneWidget);
          expect(
            tester.widget<FrostEmptyState>(empty).onAction,
            isNotNull,
            reason: 'the empty state offers a way back',
          );

          final action = find.descendant(
            of: empty,
            matching: find.byType(FrostButton),
          );
          expect(action, findsOneWidget);
          await tester.tap(action);
          await _settle(tester);
          expect(AppRouter.currentUri.path, '/');
          // Browsing may show its own empty state for the sample source.
          expect(find.text(t.generic.notFound), findsNothing);
          expect(tester.takeException(), isNull);
        },
        variant: TargetPlatformVariant.only(platform),
      );
    }
  });

  group('deep-linked post without collection data', () {
    testWidgets(
      'shows a skeleton while loading, then the detail without usable previous/next controls',
      (tester) async {
        service.engine.pendingPost = Completer<BooruPost>();
        await mountApp(tester);
        AppRouter.router.go('/posts/363100?source=yande');
        await _settle(tester);

        expect(find.byType(PostDetailPage), findsNothing);
        expect(
          find.byKey(const ValueKey('post-detail-layout')),
          findsOneWidget,
        );
        expect(_mediaSkeleton, findsWidgets);
        expect(find.byType(FrostErrorContent), findsNothing);
        expect(service.engine.calls, [('yande', '363100')]);

        service.engine.pendingPost!.complete(_post('yande', '363100'));
        service.engine.pendingPost = null;
        await _settle(tester);
        expect(find.byType(PostDetailPage), findsOneWidget);
        final detail = tester.widget<PostDetailPage>(
          find.byType(PostDetailPage),
        );
        expect(detail.args.collection, hasLength(1));
        expect(detail.args.post.id, '363100');

        final frame = tester.getRect(find.byType(FrostMediaFrame).first);
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        addTearDown(mouse.removePointer);
        for (final x in [frame.left + 30, frame.right - 30]) {
          await mouse.moveTo(Offset(x, frame.center.dy));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(
            find.byWidgetPredicate(
              (w) =>
                  w is FrostButton &&
                      (w.label == t.frost.previous ||
                          w.label == t.frost.next) &&
                      w.onPressed != null ||
                  w is FrostMediaButton &&
                      (w.label == t.frost.previous ||
                          w.label == t.frost.next) &&
                      w.onPressed != null,
            ),
            findsNothing,
            reason: 'a single post has nothing to page to',
          );
        }
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.windows),
    );

    testWidgets('a failed load offers retry, and retry reloads the post', (
      tester,
    ) async {
      service.engine.failure = StateError('fixture unavailable');
      await mountApp(tester);
      AppRouter.router.go('/posts/363100?source=yande');
      await _settle(tester);
      expect(find.byType(PostDetailPage), findsNothing);
      expect(service.engine.calls, hasLength(1));
      final retry = find.text(t.frost.retry).hitTestable();
      expect(retry, findsOneWidget);

      service.engine.failure = null;
      await tester.tap(retry);
      await _settle(tester);
      expect(service.engine.calls, hasLength(2), reason: 'retry reloads');
      expect(find.byType(PostDetailPage), findsOneWidget);
      expect(find.text(t.frost.retry), findsNothing);
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
  });

  group('text scale 2.0', () {
    // A page to open, and something it must have drawn so a blank page or an
    // error page is no pass.
    final pages = <(String, String, Finder Function(Size))>[
      ('settings home', '/settings', (size) => find.text(t.settings.title)),
      (
        'appearance',
        '/settings/appearance',
        (_) => find.byType(FrostPicker<FrostThemeMode>),
      ),
      (
        'sources with a detail open',
        '/settings/sources/yande',
        (_) => find.text(t.settings.source.supportedRatings),
      ),
      ('not found', '/image-viewer', (_) => find.byType(FrostEmptyState)),
    ];
    for (final (name, route, expected) in pages) {
      for (final locale in [AppLocale.en, AppLocale.ja]) {
        for (final (size, platform, label) in [
          (_compact, TargetPlatform.android, '360 compact'),
          (_wide, TargetPlatform.windows, '1147x717 wide'),
        ]) {
          testWidgets('$name: ${locale.languageTag} at 2.0 text, $label', (
            tester,
          ) async {
            LocaleSettings.setLocaleSync(locale);
            store.values['language'] = locale == AppLocale.ja ? 1 : 0;
            await SettingsService.initialize(store: store);
            await mountApp(tester, size: size, scale: 2);
            AppRouter.router.go(route);
            await _settle(tester);
            expect(expected(size), findsWidgets);
            expect(tester.takeException(), isNull);
            await _settle(tester, 40);
            expect(tester.takeException(), isNull);
          }, variant: TargetPlatformVariant.only(platform));
        }
      }
    }
  });
}
