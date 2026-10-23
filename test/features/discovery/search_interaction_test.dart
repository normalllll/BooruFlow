import 'dart:async';

import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/search/logic.dart';
import 'package:booruflow/features/search/post_search_page.dart';
import 'package:booruflow/features/search/services/tag_suggestion_repository.dart';
import 'package:booruflow/features/search/widgets/common_tags_sheet.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:frost_ui/src/overlays/_popover_surface.dart';

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
  final calls = <String>[];
  final pending = <String, Completer<List<TagSuggestion>>>{};
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
  final history = <String, List<String>>{};
  @override
  Future<List<String>> recentSearches(String source) async =>
      List.of(history[source] ?? []);
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
  }) async => List.generate(
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

void main() {
  late SearchRepositoryFake repository;
  late List<List<String>> submissions;
  setUp(() {
    BooruService.instance.useSourcesForTesting([
      testSource('first'),
      testSource('second'),
    ]);
    repository = SearchRepositoryFake();
    submissions = [];
  });
  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      searchTestApp(
        PostSearchPage(
          sourceId: 'first',
          repository: repository,
          onSubmit: (_, tags) => submissions.add(tags),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final width in [320.0, 600.0, 1440.0]) {
    testWidgets('source, token input and actions share one header at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await mount(tester);
      final header = tester.getRect(find.byType(FrostPageHeader)),
          field = tester.getRect(find.byType(FrostTokenField));
      expect(header.height, width < 600 ? 48 : 52);
      expect(field.center.dy, closeTo(header.center.dy, 1));
      expect(field.width, greaterThan(0));
      if (width >= 600) {
        expect(find.byType(FrostTitleMenu), findsOneWidget);
        expect(field.width, lessThanOrEqualTo(640));
        final manager = find.byWidgetPredicate(
          (w) => w is FrostTooltip && w.message == t.discovery.manageTags,
        );
        expect(
          tester.getCenter(manager.hitTestable().first).dy,
          closeTo(header.center.dy, 1),
        );
      } else {
        expect(find.byType(FrostTitleMenu), findsOneWidget);
        final source = find.byType(FrostTitleMenu);
        expect(tester.getRect(source).right, lessThan(field.left));
      }
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'suggestions float without shifting content and stay pinned during body scrolling',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      repository.commonCount = 40;
      await mount(tester);
      final common = find.byType(FrostTag).first,
          before = tester.getTopLeft(find.byType(FrostTag).first);
      await tester.enterText(find.byType(EditableText), 'mi');
      await tester.pump(const Duration(milliseconds: 300));
      repository.pending['first:mi']!.complete([
        const TagSuggestion(value: 'miku', origin: SuggestionOrigin.sourceApi),
        const TagSuggestion(value: 'mio', origin: SuggestionOrigin.sourceApi),
      ]);
      await tester.pumpAndSettle();
      final panel = find.byType(FrostPopoverSurface),
          anchor = tester.getRect(find.byType(FrostPopoverSurface));
      expect(tester.getTopLeft(common), before);
      expect(anchor.left, tester.getRect(find.byType(FrostTokenField)).left);
      expect(anchor.top, tester.getRect(find.byType(FrostTokenField)).bottom);
      final scroll = tester.state<ScrollableState>(
        find.descendant(
          of: find.byKey(const PageStorageKey('search-content')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(scroll.position.maxScrollExtent, greaterThan(0));
      scroll.position.jumpTo(scroll.position.maxScrollExtent);
      await tester.pump();
      expect(tester.getRect(panel), anchor);
      await tester.tap(find.text('miku'));
      await tester.pumpAndSettle();
      expect(input(tester).text, 'miku ');
      expect(submissions, isEmpty);
      expect(panel, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'common tags wrap and append completed tokens without submitting',
    (tester) async {
      tester.view.physicalSize = const Size(360, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      repository.commonCount = 20;
      await mount(tester);
      final tags = find.byType(FrostTag);
      expect(tags, findsNWidgets(20));
      expect(
        tester.getTopLeft(tags.last).dy,
        greaterThan(tester.getTopLeft(tags.first).dy),
      );
      await tester.tap(find.text('sky'));
      await tester.pumpAndSettle();
      expect(input(tester).text, 'sky ');
      expect(submissions, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'compact body suggestions fit above keyboard and dismiss on outside tap',
    (tester) async {
      tester.view.physicalSize = const Size(360, 700);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      addTearDown(tester.view.reset);
      await mount(tester);
      await tester.enterText(find.byType(EditableText), 'mi');
      await tester.pump(const Duration(milliseconds: 300));
      repository.complete('first:mi', 'miku');
      await tester.pumpAndSettle();
      final list = find.byWidgetPredicate((widget) => widget is FrostList);
      expect(find.byType(FrostPopoverSurface), findsNothing);
      expect(list, findsOneWidget);
      expect(tester.getRect(list).bottom, lessThanOrEqualTo(380));
      expect(tester.getSize(find.byType(FrostPageHeader)).height, 48);
      await tester.tapAt(const Offset(350, 400));
      await tester.pumpAndSettle();
      expect(find.byType(FrostPopoverSurface), findsNothing);
      expect(list, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'more common tags opens a shared lazy panel and selection returns to query',
    (tester) async {
      await mount(tester);
      await tester.tap(find.text(t.discovery.moreTags));
      await tester.pumpAndSettle();
      expect(find.byType(CommonTagsSheet), findsOneWidget);
      final row = find.descendant(
        of: find.byType(CommonTagsSheet),
        matching: suggestion('sky'),
      );
      expect(row, findsOneWidget);
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(input(tester).text, 'sky ');
      expect(submissions, isEmpty);
      expect(find.byType(CommonTagsSheet), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'empty submit and candidate clicks never search automatically; next Enter submits',
    (tester) async {
      await mount(tester);
      await tester.tap(find.byType(EditableText));
      await tester.testTextInput.receiveAction(TextInputAction.search);
      expect(submissions, isEmpty);
      expect(repository.calls, isEmpty);
      await tester.tap(find.text('sky'));
      await tester.pumpAndSettle();
      expect(submissions, isEmpty);
      expect(repository.calls, isEmpty);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      expect(submissions, [
        ['sky'],
      ]);
    },
  );
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
    expect(submissions, isEmpty);
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
      expect(submissions, isEmpty);
      expect(input(tester).text, 'hatsune_miku ');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(submissions, [
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
    await tester.tap(find.text('first'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('second'));
    await tester.pump(const Duration(milliseconds: 300));
    repository.complete('first:mi', 'stale_source');
    await tester.pump();
    expect(suggestion('stale_source'), findsNothing);
    repository.complete('second:mi', 'new_source');
    await tester.pump();
    // Changing a source leaves focus on its trigger; focusing the input reveals its new results.
    await tester.tap(find.byType(EditableText));
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
        await tester.pumpWidget(
          searchTestApp(
            PostSearchPage(
              sourceId: 'first',
              repository: repository,
              initialTags: List.generate(20, (i) => '長い作品名_超长角色标签_$i'),
              onSubmit: (_, _) {},
            ),
            scale: 2,
            locale: locale,
          ),
        );
        await tester.pumpAndSettle();
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
