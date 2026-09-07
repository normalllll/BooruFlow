import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/features/booru/booru_service.dart';
import 'package:booruflow/features/search/post_search_page.dart';
import 'package:booruflow/features/search/tag_suggestion_repository.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:booruflow/features/discovery/widgets/source_picker.dart';
import 'package:booruflow/shared/widgets/interaction_controls.dart';

BooruSourceDto testSource(String id) => BooruSourceDto(
  sourceId: id,
  displayName: id,
  protocol: BooruProtocol.moebooru,
  enabledByDefault: true,
  isAiSource: false,
  capabilities: const SourceCapabilitiesDto(
    discovery: DiscoveryCapabilitiesDto(
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
  @override
  Future<void> remember(String source, List<String> tags) async {}
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
      MaterialApp(
        home: PostSearchPage(
          sourceId: 'first',
          repository: repository,
          onSubmit: (_, tags) => submissions.add(tags),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final width in [320.0, 600.0, 1440.0]) {
    testWidgets(
      'tag manager sits beside common tags below the search row at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await mount(tester);
        final source = find.byType(SourcePicker);
        final manage = find.widgetWithText(AppButton, t.discovery.manageTags);
        expect(
          tester.getRect(manage).top,
          greaterThan(tester.getRect(find.byType(TextField)).bottom),
        );
        final heading = tester.getRect(find.text(t.discovery.commonTags));
        if (width >= 600) {
          expect(tester.getCenter(manage).dy, closeTo(heading.center.dy, 1));
        } else {
          // Long localized labels can wrap beneath the section heading.
          expect(
            tester.getRect(manage).top - heading.bottom,
            lessThanOrEqualTo(8),
          );
        }
        expect(tester.getRect(source).top, 12);
        expect(tester.getSize(source).height, 36);
        expect(tester.getSize(find.byType(TextField)).height, 36);
        if (width >= 720) {
          expect(
            tester.getCenter(source).dy,
            closeTo(tester.getCenter(find.byType(TextField)).dy, 1),
          );
          expect(
            tester.getRect(source).right,
            lessThan(tester.getRect(find.byType(TextField)).left),
          );
          expect(tester.getRect(source).left, 12);
          expect(tester.getRect(find.byType(TextField)).right, width - 12);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'suggestions float without shifting tags and stay anchored while tags scroll',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      repository.commonCount = 40;
      await mount(tester);
      final common = find.byKey(const ValueKey('common-tags'));
      final before = tester.getTopLeft(common);
      await tester.enterText(find.byType(TextField), 'mi');
      await tester.pump(const Duration(milliseconds: 300));
      repository.pending['first:mi']!.complete([
        const TagSuggestion(value: 'miku', origin: SuggestionOrigin.sourceApi),
        const TagSuggestion(value: 'mio', origin: SuggestionOrigin.sourceApi),
      ]);
      await tester.pump();
      final panel = find.byKey(const ValueKey('search-suggestions'));
      final anchor = tester.getRect(panel);
      expect(tester.getTopLeft(common), before);
      expect(anchor.left, tester.getRect(find.byType(TextField)).left);
      expect(anchor.top, tester.getRect(find.byType(TextField)).bottom + 4);
      final first = tester.widget<Material>(
        find.byKey(const ValueKey('suggestion-row-0')),
      );
      final second = tester.widget<Material>(
        find.byKey(const ValueKey('suggestion-row-1')),
      );
      expect(first.color, isNot(second.color));
      expect(first.borderRadius, isNull);
      final scroll = tester.state<ScrollableState>(
        find.descendant(
          of: find.byKey(const ValueKey('search-tags-scroll')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(scroll.position.maxScrollExtent, greaterThan(0));
      scroll.position.jumpTo(scroll.position.maxScrollExtent);
      await tester.pump();
      expect(tester.getRect(panel), anchor);
      await tester.tap(find.text('#miku', findRichText: true));
      await tester.pump();
      expect(find.byType(InputChip), findsOneWidget);
      expect(submissions, isEmpty);
      expect(panel, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'common tags wrap and selected chip starts at the shared left edge',
    (tester) async {
      tester.view.physicalSize = const Size(360, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      repository.commonCount = 20;
      await mount(tester);
      final buttons = find.descendant(
        of: find.byKey(const ValueKey('common-tags')),
        matching: find.byType(AppButton),
      );
      expect(buttons, findsNWidgets(20));
      expect(
        tester.getTopLeft(buttons.last).dy,
        greaterThan(tester.getTopLeft(buttons.first).dy),
      );
      await tester.tap(find.text('#sky', findRichText: true));
      await tester.pump();
      final paintedChip = find
          .descendant(
            of: find.byType(InputChip),
            matching: find.byType(Material),
          )
          .first;
      expect(
        tester.getRect(paintedChip).left,
        tester.getRect(find.byType(SourcePicker)).left,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'suggestions fit above the mobile keyboard and dismiss on outside tap',
    (tester) async {
      tester.view.physicalSize = const Size(360, 700);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await mount(tester);
      await tester.enterText(find.byType(TextField), 'mi');
      await tester.pump(const Duration(milliseconds: 300));
      repository.complete('first:mi', 'miku');
      await tester.pump();
      final panel = find.byKey(const ValueKey('search-suggestions'));
      expect(tester.getRect(panel).bottom, lessThanOrEqualTo(380));
      await tester.tapAt(const Offset(350, 370));
      await tester.pump();
      expect(panel, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('tag modal content uses one shared left inset', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PostSearchPage(
          sourceId: 'first',
          repository: repository,
          initialTags: List.generate(30, (i) => 'selected_tag_$i'),
          onSubmit: (_, _) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ActionChip));
    await tester.pumpAndSettle();
    final sheet = find.byType(BottomSheet);
    final tag = find.descendant(
      of: sheet,
      matching: find.text('#selected_tag_0', findRichText: true),
    );
    final chip = find
        .descendant(of: sheet, matching: find.byType(InputChip))
        .first;
    final paintedChip = find
        .descendant(of: chip, matching: find.byType(Material))
        .first;
    expect(
      tester.getRect(paintedChip).left -
          tester
              .getRect(
                find.descendant(of: sheet, matching: find.byType(ListView)),
              )
              .left,
      12,
    );
    Navigator.of(tester.element(tag)).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.discovery.moreTags));
    await tester.pumpAndSettle();
    final heading = find.descendant(
      of: sheet,
      matching: find.text(t.discovery.commonTags),
    );
    final firstTag = find
        .descendant(of: sheet, matching: find.text('#sky', findRichText: true))
        .first;
    expect(tester.getRect(firstTag).left, tester.getRect(heading).left);
    expect(
      tester.getRect(firstTag).left -
          tester
              .getRect(
                find.descendant(of: sheet, matching: find.byType(ListView)),
              )
              .left,
      12,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty submit and candidate clicks never search automatically', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(find.byType(TextField));
    await tester.testTextInput.receiveAction(TextInputAction.search);
    expect(submissions, isEmpty);
    expect(repository.calls, isEmpty);
    await tester.tap(find.text('#sky', findRichText: true));
    await tester.pump();
    expect(submissions, isEmpty);
    expect(repository.calls, isEmpty);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    expect(submissions, [
      ['sky'],
    ]);
  });
  testWidgets('debounce and generation discard slow old responses', (
    tester,
  ) async {
    await mount(tester);
    await tester.enterText(find.byType(TextField), 's');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), 'sk');
    await tester.pump(const Duration(milliseconds: 251));
    expect(repository.calls, ['first:sk']);
    await tester.enterText(find.byType(TextField), 'sky');
    await tester.pump(const Duration(milliseconds: 251));
    repository.complete('first:sky', 'new_result');
    await tester.pump();
    repository.complete('first:sk', 'stale_result');
    await tester.pump();
    expect(find.text('#new_result', findRichText: true), findsOneWidget);
    expect(find.text('#stale_result', findRichText: true), findsNothing);
  });
  testWidgets('IME composition blocks autocomplete and submission', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(find.byType(TextField));
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '初音',
        composing: TextRange(start: 0, end: 2),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.testTextInput.receiveAction(TextInputAction.search);
    expect(repository.calls, isEmpty);
    expect(submissions, isEmpty);
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(text: '初音', composing: TextRange.empty),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(repository.calls, ['first:初音']);
    repository.complete('first:初音', 'hatsune_miku');
    await tester.pump();
  });
  testWidgets('keyboard accepts a suggestion without submitting', (
    tester,
  ) async {
    await mount(tester);
    await tester.enterText(find.byType(TextField), 'mi');
    await tester.pump(const Duration(milliseconds: 300));
    repository.complete('first:mi', 'hatsune_miku');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(submissions, isEmpty);
    expect(find.byType(InputChip), findsOneWidget);
  });
  testWidgets('changing source invalidates old suggestions', (tester) async {
    await mount(tester);
    await tester.enterText(find.byType(TextField), 'mi');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('first'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('second'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    repository.complete('first:mi', 'stale_source');
    await tester.pump();
    expect(find.text('#stale_source', findRichText: true), findsNothing);
    repository.complete('second:mi', 'new_source');
    await tester.pump();
    expect(find.text('#new_source', findRichText: true), findsOneWidget);
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
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            locale: locale.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 1000),
                textScaler: const TextScaler.linear(2),
              ),
              child: PostSearchPage(
                sourceId: 'first',
                repository: repository,
                initialTags: List.generate(20, (i) => '長い作品名_超长角色标签_$i'),
                onSubmit: (_, _) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'long');
        await tester.pump(const Duration(milliseconds: 300));
        repository.pending['first:long']!.complete([
          const TagSuggestion(
            value: 'extremely_long_character_name_(series_title)',
            displayName: 'とても長い名前・非常长的角色名称',
            count: '123456789012345',
            origin: SuggestionOrigin.sourceApi,
          ),
        ]);
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
