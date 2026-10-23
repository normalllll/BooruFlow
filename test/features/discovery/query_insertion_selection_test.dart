import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/search/post_search_page.dart';
import 'package:booruflow/features/search/services/tag_suggestion_repository.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import 'search_interaction_test.dart'
    show SearchRepositoryFake, searchTestApp, testSource, input, suggestion;

class _Repository extends SearchRepositoryFake {
  @override
  List<UserTagAlias> get aliases => const [
    UserTagAlias(
      id: 'favorite',
      value: 'my_tag',
      sourceId: 'first',
      locale: 'en',
      displayName: 'My favorite',
    ),
  ];
}

void main() {
  late _Repository repository;
  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
    BooruService.instance.useSourcesForTesting([testSource('first')]);
    repository = _Repository()..history['first'] = ['saved query'];
  });
  Future<void> mount(
    WidgetTester tester, {
    double width = 1440,
    double keyboardInset = 0,
    bool isQueryEditor = false,
    bool autofocus = true,
  }) async {
    tester.view.physicalSize = Size(width, 1200);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = FakeViewPadding(bottom: keyboardInset);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      searchTestApp(
        PostSearchPage(
          sourceId: 'first',
          repository: repository,
          initialTags: isQueryEditor ? ['from_detail'] : null,
          isQueryEditor: isQueryEditor,
          autofocus: autofocus,
          onSubmit: (_, _) {},
        ),
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(() => tester.pumpWidget(const SizedBox()));
  }

  Finder tag(String label) =>
      find.byWidgetPredicate((w) => w is FrostTag && w.label == label);
  void atEnd(WidgetTester tester, String text) {
    expect(input(tester).text, text);
    expect(
      input(tester).selection,
      TextSelection.collapsed(offset: text.length),
    );
  }

  for (final entry in [
    'common',
    'alias',
    'history',
    'suggestion',
    'more-common',
  ]) {
    testWidgets(
      '$entry inserts through one path with no all-selection and caret at complete query end',
      (tester) async {
        await mount(tester);
        final initial = tester.state(find.byType(EditableText));
        final initiallyFocused = tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus;
        input(tester).value = const TextEditingValue(
          text: 'base ',
          selection: TextSelection.collapsed(offset: 5),
        );
        await tester.pumpAndSettle();
        if (entry == 'common' || entry == 'alias') {
          final target = tag(entry == 'common' ? 'sky' : 'My favorite');
          await tester.ensureVisible(target);
          await tester.tap(target);
        } else if (entry == 'history') {
          final target = find.byWidgetPredicate(
            (w) => w is FrostListRow && w.title == 'saved query',
          );
          await tester.tap(target);
        } else if (entry == 'more-common') {
          await tester.tap(find.text(t.discovery.moreTags));
          await tester.pumpAndSettle();
          await tester.tap(suggestion('sky').hitTestable());
        } else {
          tester
              .widget<EditableText>(find.byType(EditableText))
              .focusNode
              .requestFocus();
          await tester.pumpAndSettle();
          input(tester).value = const TextEditingValue(
            text: 'pre mi suffix',
            selection: TextSelection.collapsed(offset: 6),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          repository.pending['first:mi']!.complete([
            const TagSuggestion(
              value: 'character',
              origin: SuggestionOrigin.sourceApi,
            ),
          ]);
          await tester.pumpAndSettle();
          await tester.tap(suggestion('character').hitTestable());
        }
        await tester.pumpAndSettle();
        atEnd(tester, switch (entry) {
          'common' || 'more-common' => 'base sky ',
          'alias' => 'base my_tag ',
          'history' => 'saved query ',
          _ => 'pre character suffix ',
        });
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText))
              .focusNode
              .hasFocus,
          entry == 'suggestion' || initiallyFocused,
        );
        expect(tester.state(find.byType(EditableText)), same(initial));
      },
      variant: TargetPlatformVariant.only(TargetPlatform.windows),
    );
  }

  testWidgets('compact tag insertion leaves a closed keyboard closed', (
    tester,
  ) async {
    await mount(tester, width: 390);
    expect(tester.testTextInput.isVisible, isFalse);
    await tester.ensureVisible(tag('sky'));
    await tester.tap(tag('sky'));
    await tester.pumpAndSettle();
    atEnd(tester, 'sky ');
    expect(tester.testTextInput.isVisible, isFalse);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isFalse,
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets(
    'compact tag insertion restores editing when the keyboard was already open',
    (tester) async {
      await mount(tester, width: 390, keyboardInset: 280);
      await tester.showKeyboard(find.byType(EditableText));
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isTrue);
      await tester.ensureVisible(tag('sky'));
      await tester.tap(tag('sky'));
      await tester.pumpAndSettle();
      atEnd(tester, 'sky ');
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
      expect(tester.testTextInput.isVisible, isTrue);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  for (final autofocus in [true, false]) {
    testWidgets(
      'initial query editor preserves inserted caret, autofocus=$autofocus',
      (tester) async {
        await mount(
          tester,
          width: autofocus ? 1440 : 390,
          isQueryEditor: true,
          autofocus: autofocus,
        );
        atEnd(tester, 'from_detail ');
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText))
              .focusNode
              .hasFocus,
          autofocus,
        );
        if (!autofocus) expect(tester.testTextInput.isVisible, isFalse);
      },
    );
  }
}
