import 'dart:async';

import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/search/inline_search.dart';
import 'package:booruflow/features/search/logic.dart';
import 'package:booruflow/features/search/services/tag_suggestion_repository.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/shared/app_page.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

BooruSource testSource(String id) => BooruSource(
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

class SearchRepositoryFake extends TagSuggestionRepository {
  int commonCount = 1;
  bool failInitialize = false, failHistory = false, failCommon = false;
  int initializations = 0, historyLoads = 0, commonLoads = 0;
  final calls = <String>[];
  final pending = <String, Completer<List<TagSuggestion>>>{};
  @override
  Future<void> initialize() async {
    initializations++;
    if (failInitialize) throw StateError('initialize failed');
  }

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
  final history = <String, List<String>>{};
  @override
  Future<List<String>> recentSearches(String source) async {
    historyLoads++;
    if (failHistory) throw StateError('history failed');
    return List.of(history[source] ?? []);
  }

  @override
  Future<void> removeSearch(String source, String query) async =>
      history[source]?.remove(query);
  @override
  Future<void> clearSearches(String source) async => history[source] = [];
  @override
  Future<void> remember(String source, List<String> tags) async {
    history[source] = {tags.join(' '), ...?history[source]}.toList();
  }

  @override
  Future<List<TagSuggestion>> common(
    String source,
    String locale, {
    bool refresh = false,
    int page = 1,
  }) async {
    commonLoads++;
    if (failCommon) throw StateError('common failed');
    return commonTags();
  }

  List<TagSuggestion> commonTags() => List.generate(
    commonCount,
    (index) => TagSuggestion(
      value: index == 0 ? 'sky' : 'common_long_tag_$index',
      origin: SuggestionOrigin.sourceApi,
      verified: true,
    ),
  );
  @override
  Future<List<TagSuggestion>> remote(
    String source,
    String locale,
    String text,
  ) {
    calls.add('$source:$text');
    return (pending['$source:$text'] = Completer<List<TagSuggestion>>()).future;
  }

  void complete(String query, String tag) => pending[query]!.complete([
    TagSuggestion(
      value: tag,
      origin: SuggestionOrigin.sourceApi,
      verified: true,
    ),
  ]);
}

Widget searchTestApp(
  Widget child, {
  double scale = 1,
  AppLocale locale = AppLocale.en,
  TagSuggestionRepository? repository,
}) => TranslationProvider(
  child: ProviderScope(
    overrides: [
      if (repository != null)
        tagSuggestionRepositoryProvider.overrideWithValue(repository),
    ],
    child: FrostScope(
      config: appFrostConfig,
      child: MaterialApp(
        locale: locale.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: FrostTheme.build(
          config: appFrostConfig,
          brightness: Brightness.light,
          platform: TargetPlatform.windows,
          locale: locale.flutterLocale,
        ),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: FrostLayoutScope(child: child),
          ),
        ),
      ),
    ),
  ),
);
Finder suggestion(String label) =>
    find.byWidgetPredicate((w) => w is FrostListRow && w.title == label);
TextEditingController input(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText)).controller;

/// A page whose header carries an [InlineSearch], inside a router that records
/// the tags of every results page opened.
class SearchHarness {
  final submissions = <List<String>>[];

  Future<void> mount(
    WidgetTester tester, {
    required TagSuggestionRepository repository,
    List<String> query = const [],
    double scale = 1,
    AppLocale locale = AppLocale.en,
  }) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => FrostLayoutScope(
            child: AppPage(
              header: FrostPageHeader(
                title: const FrostText('Host'),
                middle: InlineSearch(sourceId: 'first', query: query),
              ),
              slivers: const [SliverToBoxAdapter(child: SizedBox(height: 600))],
            ),
          ),
          routes: [
            GoRoute(
              name: AppRoute.results.name,
              path: 'results',
              builder: (_, state) {
                final tags = ResultsQuery.parse(state.uri).tags;
                if (submissions.isEmpty || submissions.last != tags) {
                  submissions.add(tags);
                }
                return const SizedBox();
              },
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            tagSuggestionRepositoryProvider.overrideWithValue(repository),
          ],
          child: FrostApp.router(
            title: 'Search test',
            config: appFrostConfig,
            routerConfig: router,
            locale: locale.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}

void main() {
  late SearchRepositoryFake repository;
  late SearchHarness harness;
  setUp(() {
    BooruService.instance.useSourcesForTesting([
      testSource('first'),
      testSource('second'),
    ]);
    repository = SearchRepositoryFake();
    harness = SearchHarness();
  });
  Future<void> mount(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await harness.mount(tester, repository: repository);
  }

  testWidgets(
    'empty submit and landing selections never search automatically; next Enter submits',
    (tester) async {
      await mount(tester);
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.search);
      expect(harness.submissions, isEmpty);
      expect(repository.calls, isEmpty);
      await tester.tap(suggestion('sky').hitTestable());
      await tester.pumpAndSettle();
      expect(input(tester).text, 'sky ');
      expect(harness.submissions, isEmpty);
      expect(repository.calls, isEmpty);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(harness.submissions, [
        ['sky'],
      ]);
    },
  );
  testWidgets('a common tag pick records the tag as verified', (tester) async {
    await mount(tester);
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    final rules =
        (tester.widget<EditableText>(find.byType(EditableText)).controller
                as FrostTokenEditingController)
            .rules;
    expect(rules.any((r) => r.tone == FrostTokenTone.positive), isFalse);
    await tester.tap(suggestion('sky').hitTestable());
    await tester.pumpAndSettle();
    final picked =
        (tester.widget<EditableText>(find.byType(EditableText)).controller
                as FrostTokenEditingController)
            .rules;
    expect(
      picked.any(
        (r) => r.tone == FrostTokenTone.positive && r.pattern.hasMatch('sky'),
      ),
      isTrue,
    );
  });
  testWidgets('a history failure is shown with a retry, not as an empty list', (
    tester,
  ) async {
    repository.failHistory = true;
    await mount(tester);
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(find.textContaining('history failed'), findsNothing);
    expect(find.text(t.discovery.recentSearches), findsOneWidget);
    final loads = repository.historyLoads;
    repository.failHistory = false;
    repository.history['first'] = ['blue_sky'];
    await tester.tap(find.text(t.generic.retry));
    await tester.pumpAndSettle();
    expect(repository.historyLoads, greaterThan(loads));
    expect(suggestion('blue_sky'), findsOneWidget);
  });
  testWidgets('a common tag failure is shown with a retry', (tester) async {
    repository.failCommon = true;
    await mount(tester);
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(suggestion('sky'), findsNothing);
    expect(find.text(t.discovery.commonTags), findsOneWidget);
    repository.failCommon = false;
    await tester.tap(find.text(t.generic.retry));
    await tester.pumpAndSettle();
    expect(suggestion('sky'), findsOneWidget);
  });
  testWidgets('an initialization failure offers a retry', (tester) async {
    repository.failInitialize = true;
    await mount(tester);
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(find.text(t.generic.retry), findsOneWidget);
    final loads = repository.initializations;
    repository.failInitialize = false;
    await tester.tap(find.text(t.generic.retry));
    await tester.pumpAndSettle();
    expect(repository.initializations, greaterThan(loads));
    expect(find.text(t.generic.retry), findsNothing);
    expect(suggestion('sky'), findsOneWidget);
  });
  testWidgets('debounce and generation discard slow old responses', (
    tester,
  ) async {
    await mount(tester);
    await tester.enterText(find.byType(EditableText), 's');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(EditableText), 'sk');
    await tester.pump(const Duration(milliseconds: 251));
    expect(repository.calls, ['first:sk']);
    await tester.enterText(find.byType(EditableText), 'sky');
    await tester.pump(const Duration(milliseconds: 251));
    repository.complete('first:sky', 'new_result');
    await tester.pump();
    repository.complete('first:sk', 'stale_result');
    await tester.pumpAndSettle();
    expect(suggestion('new_result'), findsOneWidget);
    expect(suggestion('stale_result'), findsNothing);
  });
  testWidgets('IME blocks autocomplete and submission until composing ends', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(find.byType(EditableText));
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '初音',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 0, end: 2),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.testTextInput.receiveAction(TextInputAction.search);
    expect(repository.calls, isEmpty);
    expect(harness.submissions, isEmpty);
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '初音',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange.empty,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(repository.calls, ['first:初音']);
    repository.complete('first:初音', 'hatsune_miku');
    await tester.pumpAndSettle();
  });
  testWidgets(
    'keyboard accepts one suggestion and second Enter submits complete query',
    (tester) async {
      await mount(tester);
      await tester.enterText(find.byType(EditableText), 'mi');
      await tester.pump(const Duration(milliseconds: 300));
      repository.complete('first:mi', 'hatsune_miku');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(harness.submissions, isEmpty);
      expect(input(tester).text, 'hatsune_miku ');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(harness.submissions, [
        ['hatsune_miku'],
      ]);
    },
  );
  testWidgets('source changes invalidate pending old source suggestions', (
    tester,
  ) async {
    await mount(tester);
    await tester.enterText(find.byType(EditableText), 'mi');
    await tester.pump(const Duration(milliseconds: 300));
    BooruService.instance.selectSource('second');
    await tester.pump(const Duration(milliseconds: 300));
    repository.complete('first:mi', 'stale_source');
    await tester.pump();
    expect(suggestion('stale_source'), findsNothing);
    await tester.pump(const Duration(milliseconds: 300));
    repository.complete('second:mi', 'new_source');
    await tester.pumpAndSettle();
    expect(suggestion('new_source'), findsOneWidget);
  });
  for (final locale in AppLocale.values) {
    for (final width in [320.0, 600.0, 1440.0]) {
      testWidgets('full editor $locale at $width and large text', (
        tester,
      ) async {
        LocaleSettings.setLocaleSync(locale);
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await harness.mount(
          tester,
          repository: repository,
          query: List.generate(20, (i) => '長い作品名_超长角色标签_$i'),
          scale: 2,
          locale: locale,
        );
        await tester.tap(find.byType(EditableText));
        await tester.enterText(find.byType(EditableText), 'long');
        await tester.pump(const Duration(milliseconds: 300));
        repository.pending['first:long']!.complete([
          const TagSuggestion(
            value: 'extremely_long_character_name_(series_title)',
            displayName: 'とても長い名前・非常长的角色名称',
            count: '123456789012345',
            origin: SuggestionOrigin.sourceApi,
          ),
        ]);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
