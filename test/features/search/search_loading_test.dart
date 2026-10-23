import 'dart:async';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/search/post_search_page.dart';
import 'package:booruflow/features/search/services/tag_suggestion_repository.dart';
import 'package:booruflow/shared/loading_content.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:frost_ui/src/controls/_button_control.dart';
import '../discovery/search_interaction_test.dart'
    show searchTestApp, testSource, SearchRepositoryFake;

class _PendingRepository extends SearchRepositoryFake {
  final tags = Completer<List<TagSuggestion>>();
  final queries = Completer<List<String>>();
  @override
  Future<List<String>> recentSearches(String source) => queries.future;
  @override
  Future<List<TagSuggestion>> common(
    String source,
    String locale, {
    bool refresh = false,
    int page = 1,
  }) => tags.future;
}

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'search first load uses tag and history shapes at scale $scale',
      (tester) async {
        tester.view.physicalSize = const Size(390, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        BooruService.instance.useSourcesForTesting([testSource('first')]);
        final repository = _PendingRepository();
        await tester.pumpWidget(
          searchTestApp(
            PostSearchPage(
              sourceId: 'first',
              repository: repository,
              onSubmit: (_, _) {},
            ),
            repository: repository,
            scale: scale,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          find
              .byType(FrostActivityIndicator)
              .evaluate()
              .where(
                (element) =>
                    element
                        .findAncestorWidgetOfExactType<FrostButtonControl>() ==
                    null,
              ),
          isEmpty,
        );
        expect(find.byType(AppLoadingContent), findsNWidgets(2));
        expect(find.byType(FrostTag), findsNWidgets(3));
        final tagSize = tester.getSize(find.byType(FrostTag).first);
        expect(tagSize.height, greaterThan(0));
        expect(tester.takeException(), isNull);
        repository.tags.complete(const [
          TagSuggestion(value: 'landscape', origin: SuggestionOrigin.sourceApi),
        ]);
        repository.queries.complete([]);
        await tester.pumpAndSettle();
        expect(find.byType(AppLoadingContent), findsNothing);
        expect(tester.getSize(find.byType(FrostTag).first), tagSize);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
