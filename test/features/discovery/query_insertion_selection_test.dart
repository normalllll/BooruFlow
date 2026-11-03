import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/search/services/tag_suggestion_repository.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'search_interaction_test.dart'
    show SearchHarness, SearchRepositoryFake, input, suggestion, testSource;

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
  Future<void> mount(WidgetTester tester, {double width = 390}) async {
    tester.view.physicalSize = Size(width, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await SearchHarness().mount(tester, repository: repository);
    addTearDown(() => tester.pumpWidget(const SizedBox()));
  }

  void atEnd(WidgetTester tester, String text) {
    expect(input(tester).text, text);
    expect(
      input(tester).selection,
      TextSelection.collapsed(offset: text.length),
    );
  }

  for (final entry in ['common', 'alias', 'history', 'suggestion']) {
    testWidgets(
      '$entry inserts through one path with no all-selection and caret at complete query end',
      (tester) async {
        await mount(tester);
        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();
        final initial = tester.state(find.byType(EditableText));
        input(tester).value = const TextEditingValue(
          text: 'base ',
          selection: TextSelection.collapsed(offset: 5),
        );
        await tester.pumpAndSettle();
        if (entry == 'suggestion') {
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
        } else {
          final label = switch (entry) {
            'common' => 'sky',
            'alias' => 'My favorite',
            _ => 'saved query',
          };
          await tester.tap(suggestion(label).hitTestable());
        }
        await tester.pumpAndSettle();
        atEnd(tester, switch (entry) {
          'common' => 'base sky ',
          'alias' => 'base my_tag ',
          'history' => 'saved query ',
          _ => 'pre character suffix ',
        });
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText))
              .focusNode
              .hasFocus,
          isTrue,
        );
        expect(tester.state(find.byType(EditableText)), same(initial));
        // The list stays open for the next pick, whichever list this query
        // now shows; Enter submits rather than selecting from it.
        if (entry != 'suggestion') {
          expect(suggestion('My favorite').hitTestable(), findsOneWidget);
        }
      },
      variant: TargetPlatformVariant.only(TargetPlatform.windows),
    );
  }
}
