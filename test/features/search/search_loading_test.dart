import 'dart:async';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/search/services/tag_suggestion_repository.dart';
import 'package:booruflow/features/tags/tags_page.dart';
import 'package:booruflow/shared/loading_content.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import '../discovery/search_interaction_test.dart'
    show searchTestApp, testSource, SearchRepositoryFake;

class _PendingRepository extends SearchRepositoryFake {
  final tags = Completer<List<TagSuggestion>>();
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
    testWidgets('tags first load uses the tag shape at scale $scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      BooruService.instance.useSourcesForTesting([testSource('first')]);
      final repository = _PendingRepository();
      await tester.pumpWidget(
        searchTestApp(const TagsPage(), repository: repository, scale: scale),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(AppLoadingContent), findsOneWidget);
      final bones = find.descendant(
        of: find.byType(AppLoadingContent),
        matching: find.byType(FrostTag),
      );
      expect(bones, findsNWidgets(3));
      final tagSize = tester.getSize(bones.first);
      expect(tagSize.height, greaterThan(0));
      expect(tester.takeException(), isNull);
      repository.tags.complete(const [
        TagSuggestion(value: 'landscape', origin: SuggestionOrigin.sourceApi),
      ]);
      await tester.pumpAndSettle();
      expect(find.byType(AppLoadingContent), findsNothing);
      expect(
        tester.getSize(
          find.byWidgetPredicate(
            (w) => w is FrostTag && w.label == 'landscape',
          ),
        ),
        tagSize,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
