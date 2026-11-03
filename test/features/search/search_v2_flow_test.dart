import 'dart:async';

import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/browse/collection_logic.dart';
import 'package:booruflow/features/browse/results_page.dart';
import 'package:booruflow/features/search/services/tag_suggestion_repository.dart';
import 'package:booruflow/features/tags/common_tags_page.dart';
import 'package:booruflow/features/tags/my_tags_page.dart';
import 'package:booruflow/features/tags/tags_page.dart';
import 'package:booruflow/intl/number_format.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';

import '../discovery/search_interaction_test.dart'
    show
        SearchHarness,
        SearchRepositoryFake,
        input,
        searchTestApp,
        suggestion,
        testSource;

class _Store implements SettingsServiceStore {
  @override
  Map<String, dynamic> load() => {};
  @override
  Future<void> write(String key, dynamic value) async {}
}

class Repository extends SearchRepositoryFake {
  final events = StreamController<void>.broadcast(sync: true);
  final stored = <UserTagAlias>[];
  bool failSave = false;
  List<TagSuggestion> localItems = [];
  List<TagSuggestion>? commonItems;
  @override
  Stream<void> get changes => events.stream;
  @override
  List<UserTagAlias> get aliases => List.of(stored);
  @override
  Future<void> saveAlias(UserTagAlias alias) async {
    if (failSave) throw StateError('save failed');
    stored.removeWhere((value) => value.id == alias.id);
    stored.add(alias);
    events.add(null);
  }

  @override
  Future<void> deleteAlias(String id) async {
    stored.removeWhere((value) => value.id == id);
    events.add(null);
  }

  @override
  List<TagSuggestion> local(String source, String locale, String text) =>
      localItems;
  @override
  Future<List<TagSuggestion>> common(
    String source,
    String locale, {
    bool refresh = false,
    int page = 1,
  }) async =>
      commonItems ??
      [
        for (final category in TagCategory.values)
          TagSuggestion(
            value: category.name,
            category: category,
            origin: SuggestionOrigin.sourceApi,
            verified: true,
          ),
      ];
}

Finder field(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is FrostTextField && w.label == label),
  matching: find.byType(EditableText),
);
Finder button(String label) => find.text(label).hitTestable().first;
Finder tooltip(String message) => find
    .byWidgetPredicate((w) => w is FrostTooltip && w.message == message)
    .hitTestable()
    .first;

void main() {
  late Repository repository;
  late SearchHarness harness;
  setUp(() async {
    await SettingsService.initialize(store: _Store());
    LocaleSettings.setLocaleSync(AppLocale.en);
    BooruService.instance.useSourcesForTesting([
      testSource('first'),
      testSource('second'),
    ]);
    repository = Repository();
    harness = SearchHarness();
  });
  Future<void> mount(
    WidgetTester tester,
    Widget child, {
    double scale = 1,
  }) async {
    await tester.pumpWidget(
      searchTestApp(child, repository: repository, scale: scale),
    );
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await repository.events.close();
    });
  }

  Future<void> mountSearch(WidgetTester tester, {double width = 390}) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await harness.mount(tester, repository: repository);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await repository.events.close();
    });
  }

  testWidgets(
    'common tags suppress formatting-only translations while keeping canonical values',
    (tester) async {
      repository.commonItems = [
        const TagSuggestion(
          value: 'bikini',
          displayName: 'Bikini',
          origin: SuggestionOrigin.sourceApi,
        ),
      ];
      await mount(tester, const TagsPage());
      final tag = find.byWidgetPredicate(
        (w) => w is FrostTag && w.label == 'bikini',
      );
      expect(tag, findsOneWidget);
      expect(tester.widget<FrostTag>(tag).detail, isNull);
    },
  );
  testWidgets(
    'breakpoint changes retain editable State, caret, composing and focus',
    (tester) async {
      await mountSearch(tester, width: 1000);
      await tester.tap(find.byType(EditableText));
      const composing = TextEditingValue(
        text: 'sky 初音',
        selection: TextSelection.collapsed(offset: 6),
        composing: TextRange(start: 4, end: 6),
      );
      tester.testTextInput.updateEditingValue(composing);
      await tester.pump();
      final editable = tester.state<EditableTextState>(
        find.byType(EditableText),
      );
      final controller = input(tester);
      for (final width in [390.0, 1000.0, 390.0]) {
        tester.view.physicalSize = Size(width, 800);
        await tester.pump();
        expect(
          tester.state<EditableTextState>(find.byType(EditableText)),
          same(editable),
        );
        expect(input(tester), same(controller));
        expect(controller.value, composing);
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText))
              .focusNode
              .hasFocus,
          isTrue,
        );
        expect(find.byType(FrostPageHeader), findsOneWidget);
        expect(repository.calls, isEmpty);
        expect(tester.takeException(), isNull);
      }
      tester.testTextInput.updateEditingValue(
        composing.copyWith(composing: TextRange.empty),
      );
      await tester.pump(const Duration(milliseconds: 300));
      repository.complete('first:初音', 'hatsune_miku');
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(1000, 800);
      await tester.pumpAndSettle();
      expect(find.text('hatsune_miku').hitTestable(), findsOneWidget);
      expect(
        tester.state<EditableTextState>(find.byType(EditableText)),
        same(editable),
      );
      expect(controller.selection, composing.selection);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('first use shows no recent searches and one add-tag line', (
    tester,
  ) async {
    await mount(tester, const TagsPage());
    expect(find.text(t.discovery.recentSearches), findsNothing);
    expect(find.text(t.discovery.noCustomTags), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is FrostTag && w.label == t.discovery.addTag,
      ),
      findsOneWidget,
    );
  });
  testWidgets('a common tag shows its translation and a short post count', (
    tester,
  ) async {
    repository.commonItems = [
      const TagSuggestion(
        value: 'scenery',
        displayName: '风景',
        category: TagCategory.general,
        count: '1204000',
        origin: SuggestionOrigin.sourceApi,
      ),
    ];
    await mount(tester, const TagsPage());
    final tag = tester.widget<FrostTag>(
      find.byWidgetPredicate((w) => w is FrostTag && w.label == 'scenery'),
    );
    expect(tag.detail, '风景 · ${formatCompactCount(1204000)}');
    expect(tester.takeException(), isNull);
  });
  testWidgets('common tag rows share data dots and counts', (tester) async {
    await mount(tester, const AllCommonTagsPage(sourceId: 'first'));
    repository.commonItems = [
      const TagSuggestion(
        value: 'wlop',
        category: TagCategory.artist,
        count: '1204',
        origin: SuggestionOrigin.sourceApi,
      ),
      const TagSuggestion(
        value: 'miku',
        category: TagCategory.character,
        count: '160204',
        origin: SuggestionOrigin.sourceApi,
      ),
    ];
    await tester.pumpWidget(const SizedBox());
    await mount(tester, const AllCommonTagsPage(sourceId: 'first'));
    expect(
      find.descendant(
        of: find.byType(AllCommonTagsPage),
        matching: find.byType(FrostDataDot),
      ),
      findsNWidgets(2),
    );
    expect(find.text('1,204'), findsOneWidget);
    expect(find.text('160,204'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'recent queries restore full text, submit once, persist and clear',
    (tester) async {
      repository.history['first'] = ['sky -cloud', 'blue'];
      await mountSearch(tester);
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      await tester.tap(suggestion('sky -cloud'));
      await tester.pumpAndSettle();
      expect(input(tester).text, 'sky -cloud ');
      expect(harness.submissions, isEmpty);
      expect(repository.calls, isEmpty);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(harness.submissions, [
        ['sky', '-cloud'],
      ]);
      expect(repository.history['first']!.first, 'sky -cloud');
    },
  );
  testWidgets('recent query clear empties the history', (tester) async {
    repository.history['first'] = ['sky -cloud', 'blue'];
    await mountSearch(tester);
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.discovery.clearHistory).hitTestable().first);
    await tester.pumpAndSettle();
    expect(repository.history['first'], isEmpty);
    expect(find.text(t.discovery.recentSearches), findsNothing);
    expect(find.text(t.discovery.noRecentSearches), findsNothing);
  });
  testWidgets('recent query deletes with its remove button without searching', (
    tester,
  ) async {
    repository.history['first'] = ['sky', 'blue'];
    await mountSearch(tester);
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .descendant(
            of: suggestion('sky'),
            matching: find.byWidgetPredicate(
              (w) => w is FrostButton && w.label == t.frost.remove,
            ),
          )
          .hitTestable()
          .first,
    );
    await tester.pumpAndSettle();
    expect(repository.history['first'], ['blue']);
    expect(harness.submissions, isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'categories and scoped aliases use canonical query values and metadata',
    (tester) async {
      repository.stored.addAll([
        const UserTagAlias(
          id: 'one',
          value: 'hatsune_miku',
          sourceId: 'first',
          locale: 'en',
          displayName: 'Miku',
        ),
        const UserTagAlias(
          id: 'two',
          value: 'hidden',
          sourceId: 'second',
          locale: 'en',
          displayName: 'Other source',
        ),
      ]);
      await mount(tester, const TagsPage());
      final tags = tester.widgetList<FrostTag>(find.byType(FrostTag)).toList();
      expect(
        tags
            .where((tag) => tag.dataColor != null)
            .map((tag) => tag.dataColor)
            .toSet(),
        TagCategory.values.map((c) => c.index).toSet(),
      );
      expect(
        tags.singleWhere((tag) => tag.label == 'Miku').detail,
        'hatsune_miku',
      );
      expect(find.text('Other source'), findsNothing);
    },
  );
  testWidgets(
    'suggestion replaces the term at caret, preserves operators and trailing query',
    (tester) async {
      await mountSearch(tester);
      await tester.tap(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'sky -mi rating:s ');
      input(tester).selection = const TextSelection.collapsed(offset: 7);
      await tester.pump(const Duration(milliseconds: 300));
      expect(repository.calls, ['first:mi']);
      repository.complete('first:mi', 'hatsune_miku');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(input(tester).text, 'sky -hatsune_miku rating:s ');
      expect(
        input(tester).selection,
        TextSelection.collapsed(offset: 'sky -hatsune_miku rating:s '.length),
      );
    },
  );
  testWidgets(
    'loading, local failure and counts render in real suggestion rows',
    (tester) async {
      repository.localItems = [
        const TagSuggestion(
          value: 'local',
          displayName: 'Translation',
          category: TagCategory.artist,
          count: '12345',
          origin: SuggestionOrigin.lexicon,
        ),
      ];
      await mountSearch(tester);
      await tester.tap(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'loc');
      await tester.pump(const Duration(milliseconds: 300));
      expect(suggestion('local'), findsOneWidget);
      repository.pending['first:loc']!.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: suggestion('local'),
          matching: find.text('Translation'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: suggestion('local'), matching: find.text('12,345')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'dialog validates, saves chosen scope and edits or deletes an alias',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await mount(tester, const MyTagsPage());
      await tester.tap(tooltip(t.discovery.addTagAction));
      await tester.pumpAndSettle();
      expect(find.byType(FrostForm), findsOneWidget);
      await tester.enterText(field(t.discovery.canonicalTag), 'two tags');
      await tester.tap(button(t.settings.account.save));
      await tester.pumpAndSettle();
      expect(find.text(t.discovery.invalidTag), findsOneWidget);
      expect(repository.stored, isEmpty);
      await tester.enterText(field(t.discovery.canonicalTag), 'sky');
      await tester.enterText(field(t.discovery.displayName), 'My sky');
      await tester.tap(find.text(t.discovery.allTagSources).hitTestable().last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('second').hitTestable().last);
      await tester.pumpAndSettle();
      await tester.tap(button(t.settings.account.save));
      await tester.pumpAndSettle();
      expect(find.byType(FrostDialog), findsNothing);
      expect(repository.stored.single.sourceId, 'second');
      expect(repository.stored.single.displayName, 'My sky');
      Future<void> edit(String title) async {
        await tester.tap(
          suggestion(title),
          buttons: kSecondaryButton,
          kind: PointerDeviceKind.mouse,
        );
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.discovery.editTag).hitTestable().last);
        await tester.pumpAndSettle();
      }

      await edit('My sky');
      await tester.enterText(field(t.discovery.displayName), 'Renamed');
      await tester.tap(button(t.settings.account.save));
      await tester.pumpAndSettle();
      expect(repository.stored.single.displayName, 'Renamed');
      await edit('Renamed');
      final dialog = tester.widget<FrostDialog>(find.byType(FrostDialog));
      expect(dialog.leadingAction!.role, FrostButtonRole.destructive);
      await tester.tap(find.text(t.discovery.deleteTag).hitTestable().last);
      await tester.pumpAndSettle();
      expect(repository.stored, isEmpty);
      expect(find.text(t.discovery.noCustomTags), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('save error retains dialog and input and can retry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    repository.failSave = true;
    await mount(tester, const MyTagsPage(sourceId: 'first'));
    await tester.tap(tooltip(t.discovery.addTagAction));
    await tester.pumpAndSettle();
    await tester.enterText(field(t.discovery.canonicalTag), 'sky');
    await tester.tap(button(t.settings.account.save));
    await tester.pumpAndSettle();
    expect(find.byType(FrostDialog), findsOneWidget);
    expect(
      tester
          .widget<EditableText>(field(t.discovery.canonicalTag))
          .controller
          .text,
      'sky',
    );
    repository.failSave = false;
    await tester.enterText(field(t.discovery.canonicalTag), 'sky2');
    await tester.tap(button(t.settings.account.save));
    await tester.pumpAndSettle();
    expect(repository.stored.single.value, 'sky2');
    expect(find.byType(FrostDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'compact inline search stays editable at 2x and a pending response is disposal-safe',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await harness.mount(tester, repository: repository, scale: 2);
      expect(find.byType(FrostTokenField), findsOneWidget);
      expect(tester.getSize(find.byType(EditableText)).width, greaterThan(0));
      await tester.enterText(find.byType(EditableText), 'pending');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpWidget(const SizedBox());
      repository.complete('first:pending', 'late');
      await tester.pumpAndSettle();
      await repository.events.close();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('result More saves one canonical term as a scoped alias', (
    tester,
  ) async {
    await mount(
      tester,
      ProviderScope(
        overrides: [
          collectionLoaderProvider.overrideWithValue(
            (_, _) async => const PostPage(items: [], exhausted: true),
          ),
        ],
        child: const ResultsPage(tags: ['sky', '-cloud'], sourceId: 'first'),
      ),
    );
    await tester.tap(
      find
          .byWidgetPredicate(
            (w) => w is FrostTooltip && w.message == t.frost.more,
          )
          .hitTestable()
          .last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.discovery.addCustomTag).hitTestable().last);
    await tester.pumpAndSettle();
    await tester.tap(suggestion('-cloud'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<EditableText>(field(t.discovery.canonicalTag))
          .controller
          .text,
      'cloud',
    );
    await tester.tap(button(t.settings.account.save));
    await tester.pumpAndSettle();
    expect(repository.stored.single.value, 'cloud');
    expect(repository.stored.single.sourceId, 'first');
    expect(tester.takeException(), isNull);
  });
}
