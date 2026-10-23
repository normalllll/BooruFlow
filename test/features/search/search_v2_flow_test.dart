import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/discovery/discovery_page.dart';
import 'package:booruflow/features/search/post_search_page.dart';
import 'package:booruflow/features/search/services/tag_suggestion_repository.dart';
import 'package:booruflow/features/search/user_tags_page.dart';
import 'package:booruflow/features/search/widgets/common_tags_sheet.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:frost_ui/src/overlays/_popover_surface.dart';

import '../discovery/search_interaction_test.dart'
    show searchTestApp, testSource, SearchRepositoryFake, input, suggestion;

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

void main() {
  late Repository repository;
  setUp(() async {
    await SettingsService.initialize(store: _Store());
    LocaleSettings.setLocaleSync(AppLocale.en);
    BooruService.instance.useSourcesForTesting([
      testSource('first'),
      testSource('second'),
    ]);
    repository = Repository();
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

  for (final width in [390.0, 1000.0]) {
    testWidgets(
      'tag insertion and search submit at $width do not open the keyboard',
      (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        repository.commonItems = [
          const TagSuggestion(value: 'sky', origin: SuggestionOrigin.sourceApi),
          const TagSuggestion(
            value: 'blue',
            origin: SuggestionOrigin.sourceApi,
          ),
        ];
        final submitted = <List<String>>[];
        await mount(
          tester,
          PostSearchPage(
            sourceId: 'first',
            repository: repository,
            onSubmit: (_, tags) => submitted.add(tags),
          ),
        );
        final editable = tester.widget<EditableText>(find.byType(EditableText));
        for (final tag in ['sky', 'blue']) {
          await tester.tap(
            find.byWidgetPredicate((w) => w is FrostTag && w.label == tag),
          );
          await tester.pumpAndSettle();
          expect(editable.focusNode.hasFocus, isFalse);
          expect(tester.testTextInput.isVisible, isFalse);
          expect(
            input(tester).selection,
            TextSelection.collapsed(offset: input(tester).text.length),
          );
        }
        await tester.tap(
          find
              .byWidgetPredicate(
                (w) => w is FrostButton && w.label == t.frost.search,
              )
              .hitTestable()
              .first,
        );
        await tester.pumpAndSettle();
        expect(submitted, [
          ['sky', 'blue'],
        ]);
        expect(tester.testTextInput.isVisible, isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'pointer insertion retains existing editing focus without select-all',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      addTearDown(tester.view.reset);
      repository.commonItems = [
        const TagSuggestion(value: 'blue', origin: SuggestionOrigin.sourceApi),
      ];
      await mount(
        tester,
        PostSearchPage(
          sourceId: 'first',
          repository: repository,
          onSubmit: (_, _) {},
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pump();
      await tester.tap(
        find.byWidgetPredicate((w) => w is FrostTag && w.label == 'blue'),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasPrimaryFocus,
        isTrue,
      );
      expect(input(tester).text, 'blue ');
      expect(input(tester).selection, const TextSelection.collapsed(offset: 5));
      expect(tester.takeException(), isNull);
    },
  );
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
      await mount(
        tester,
        PostSearchPage(
          sourceId: 'first',
          repository: repository,
          onSubmit: (_, _) {},
        ),
      );
      final tag = find.byWidgetPredicate(
        (w) => w is FrostTag && w.label == 'bikini',
      );
      expect(tag, findsOneWidget);
      expect(tester.widget<FrostTag>(tag).detail, isNull);
      await tester.tap(tag);
      await tester.pumpAndSettle();
      expect(input(tester).text.trim(), 'bikini');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'breakpoint changes retain editable State, caret, composing and focus',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await mount(
        tester,
        PostSearchPage(
          sourceId: 'first',
          repository: repository,
          onSubmit: (_, _) {},
        ),
      );
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
      expect(find.byType(FrostPopoverSurface), findsNothing);
      expect(find.byWidgetPredicate((w) => w is FrostList), findsOneWidget);
      tester.view.physicalSize = const Size(1000, 800);
      await tester.pumpAndSettle();
      expect(find.byType(FrostPopoverSurface), findsOneWidget);
      expect(
        tester.state<EditableTextState>(find.byType(EditableText)),
        same(editable),
      );
      expect(controller.selection, composing.selection);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('first use hides empty history and uses one custom-tags card', (
    tester,
  ) async {
    await mount(
      tester,
      PostSearchPage(
        sourceId: 'first',
        repository: repository,
        onSubmit: (_, _) {},
      ),
    );
    expect(find.text(t.discovery.recentSearches), findsNothing);
    final empty = find.descendant(
      of: find.byType(FrostGroupedSection),
      matching: suggestion(t.discovery.noCustomTags),
    );
    expect(empty, findsOneWidget);
    expect(
      tester.widget<FrostListRow>(empty).subtitle,
      t.discovery.customTagsHint,
    );
    expect(
      find.descendant(of: empty, matching: find.text(t.discovery.addTag)),
      findsOneWidget,
    );
  });
  testWidgets(
    'common tag categories share data dots, counts and an explicit add action',
    (tester) async {
      const artist = TagSuggestion(
        value: 'wlop',
        category: TagCategory.artist,
        count: '1204',
        origin: SuggestionOrigin.sourceApi,
      );
      const character = TagSuggestion(
        value: 'miku',
        category: TagCategory.character,
        count: '160204',
        origin: SuggestionOrigin.sourceApi,
      );
      await mount(
        tester,
        PostSearchPage(
          sourceId: 'first',
          repository: repository,
          onSubmit: (_, _) {},
        ),
      );
      final context = tester.element(find.byType(PostSearchPage));
      final future = showFrostDialog<TagSuggestion>(
        context: context,
        builder: (_) => FrostDialog(
          title: t.discovery.commonTags,
          scrollable: false,
          content: SizedBox(
            height: 400,
            child: CommonTagsSheet(
              repository: repository,
              source: 'first',
              locale: 'en',
              initialTags: const [artist, character],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(CommonTagsSheet),
          matching: find.byType(FrostDataDot),
        ),
        findsNWidgets(2),
      );
      expect(find.text('1,204'), findsOneWidget);
      expect(find.text('160,204'), findsOneWidget);
      await tester.tap(find.text(t.discovery.artist).hitTestable().last);
      await tester.pumpAndSettle();
      expect(suggestion('miku'), findsNothing);
      final row = suggestion('wlop');
      final add = find.descendant(
        of: row,
        matching: find.byWidgetPredicate(
          (w) => w is FrostButton && w.label == t.discovery.addTag,
        ),
      );
      await tester.tap(add);
      await tester.pumpAndSettle();
      expect(await future, same(artist));
      expect(find.byType(CommonTagsSheet), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'recent queries restore full text, submit once, persist and clear',
    (tester) async {
      repository.history['first'] = ['sky -cloud', 'blue'];
      final calls = <List<String>>[];
      await mount(
        tester,
        PostSearchPage(
          sourceId: 'first',
          repository: repository,
          onSubmit: (_, tags) => calls.add(tags),
        ),
      );
      await tester.tap(suggestion('sky -cloud'));
      await tester.pumpAndSettle();
      expect(input(tester).text, 'sky -cloud ');
      expect(calls, isEmpty);
      expect(repository.calls, isEmpty);
      await tester.tap(
        find
            .byWidgetPredicate(
              (w) => w is FrostButton && w.label == t.frost.search,
            )
            .hitTestable()
            .first,
      );
      await tester.pumpAndSettle();
      expect(calls, [
        ['sky', '-cloud'],
      ]);
      expect(repository.history['first']!.first, 'sky -cloud');
      await tester.tap(
        find.descendant(
          of: find.byWidgetPredicate(
            (w) =>
                w is FrostSectionHeader &&
                w.title == t.discovery.recentSearches,
          ),
          matching: find.text(t.generic.clear),
        ),
      );
      await tester.pumpAndSettle();
      expect(repository.history['first'], isEmpty);
      expect(find.text(t.discovery.recentSearches), findsNothing);
      expect(find.text(t.discovery.noRecentSearches), findsNothing);
    },
  );
  for (final touch in [false, true]) {
    testWidgets(
      'recent query deletes via ${touch ? 'swipe' : 'hover'} without searching',
      (tester) async {
        repository.history['first'] = ['sky', 'blue'];
        await mount(
          tester,
          PostSearchPage(
            sourceId: 'first',
            repository: repository,
            onSubmit: (_, _) => fail('deleting must not submit'),
          ),
        );
        final history = find.byKey(const ValueKey('history-sky'));
        if (touch) {
          await tester.drag(history, const Offset(-500, 0));
          await tester.pumpAndSettle();
        } else {
          final mouse = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          await mouse.addPointer(location: Offset.zero);
          await mouse.moveTo(tester.getCenter(history));
          await tester.pumpAndSettle();
          await tester.tap(
            find
                .descendant(
                  of: history,
                  matching: find.byWidgetPredicate(
                    (w) => w is FrostButton && w.label == t.frost.remove,
                  ),
                )
                .hitTestable()
                .first,
          );
          await tester.pumpAndSettle();
          await mouse.removePointer();
        }
        expect(repository.history['first'], ['blue']);
        expect(tester.takeException(), isNull);
      },
    );
  }
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
      await mount(
        tester,
        PostSearchPage(
          sourceId: 'first',
          repository: repository,
          onSubmit: (_, _) {},
        ),
      );
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
      await tester.ensureVisible(find.text('Miku'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Miku'));
      await tester.pumpAndSettle();
      expect(input(tester).text, 'hatsune_miku ');
    },
  );
  testWidgets(
    'suggestion replaces the term at caret, preserves operators and trailing query',
    (tester) async {
      await mount(
        tester,
        PostSearchPage(
          sourceId: 'first',
          repository: repository,
          onSubmit: (_, _) {},
        ),
      );
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
      await mount(
        tester,
        PostSearchPage(
          sourceId: 'first',
          repository: repository,
          onSubmit: (_, _) {},
        ),
      );
      await tester.enterText(find.byType(EditableText), 'loc');
      await tester.pump(const Duration(milliseconds: 300));
      expect(suggestion('local'), findsOneWidget);
      repository.pending['first:loc']!.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      final row = tester.widget<FrostListRow>(suggestion('local'));
      expect(row.subtitle, 'Translation');
      expect(row.inlineSubtitle, true);
      expect(row.value, '12,345');
      expect(find.text(t.generic.loadFailed), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'dialog validates, saves chosen scope and edits or deletes an alias',
    (tester) async {
      await mount(tester, const UserTagsPage(sourceId: 'first'));
      await tester.tap(button(t.discovery.addTagAction));
      await tester.pumpAndSettle();
      expect(find.byType(FrostForm), findsOneWidget);
      await tester.enterText(field(t.discovery.canonicalTag), 'two tags');
      await tester.tap(button(t.settings.account.save));
      await tester.pumpAndSettle();
      expect(find.text(t.discovery.invalidTag), findsOneWidget);
      expect(repository.stored, isEmpty);
      await tester.enterText(field(t.discovery.canonicalTag), 'sky');
      await tester.enterText(field(t.discovery.displayName), 'My sky');
      await tester.tap(find.text('first').hitTestable().last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('second').hitTestable().last);
      await tester.pumpAndSettle();
      await tester.tap(button(t.settings.account.save));
      await tester.pumpAndSettle();
      expect(find.byType(FrostDialog), findsNothing);
      expect(repository.stored.single.sourceId, 'second');
      expect(repository.stored.single.displayName, 'My sky');
      await tester.tap(suggestion('My sky'));
      await tester.pumpAndSettle();
      await tester.enterText(field(t.discovery.displayName), 'Renamed');
      await tester.tap(button(t.settings.account.save));
      await tester.pumpAndSettle();
      expect(repository.stored.single.displayName, 'Renamed');
      await tester.tap(suggestion('Renamed'));
      await tester.pumpAndSettle();
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
    repository.failSave = true;
    await mount(tester, const UserTagsPage(sourceId: 'first'));
    await tester.tap(button(t.discovery.addTagAction));
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
    'compact editor with back retains an editable query at 2x and pending response is disposal-safe',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await mount(
        tester,
        Builder(
          builder: (context) => FrostButton(
            label: 'Open',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PostSearchPage(
                  sourceId: 'first',
                  repository: repository,
                  isQueryEditor: true,
                  onSubmit: (_, _) {},
                ),
              ),
            ),
          ),
        ),
        scale: 2,
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(FrostTokenField), findsOneWidget);
      expect(tester.getSize(find.byType(EditableText)).width, greaterThan(0));
      expect(
        find.byWidgetPredicate(
          (w) => w is FrostTooltip && w.message == t.frost.back,
        ),
        findsOneWidget,
      );
      await tester.enterText(find.byType(EditableText), 'pending');
      await tester.pump(const Duration(milliseconds: 300));
      Navigator.of(tester.element(find.byType(PostSearchPage))).pop();
      await tester.pumpAndSettle();
      repository.complete('first:pending', 'late');
      await tester.pumpAndSettle();
      expect(find.byType(PostSearchPage), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('result More saves one canonical term as a scoped alias', (
    tester,
  ) async {
    await mount(
      tester,
      DiscoveryPage(
        tags: const ['sky', '-cloud'],
        sourceId: 'first',
        loader: (_, _) async => const PostPage(items: [], exhausted: true),
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
