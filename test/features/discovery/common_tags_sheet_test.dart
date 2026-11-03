import 'package:booruflow/features/search/services/tag_suggestion_repository.dart';
import 'package:booruflow/features/tags/common_tags_page.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'search_interaction_test.dart' show searchTestApp;

TagSuggestion tag(String value) => TagSuggestion(
  value: value,
  origin: SuggestionOrigin.sourceApi,
  verified: true,
);

class _Repository extends TagSuggestionRepository {
  final pages = <int>[];
  @override
  Future<void> initialize() async {}
  @override
  String? displayName(String source, String locale, String value) => null;
  @override
  Future<List<TagSuggestion>> common(
    String source,
    String locale, {
    bool refresh = false,
    int page = 1,
  }) async {
    pages.add(page);
    if (page == 1) return List.generate(50, (i) => tag('tag$i'));
    if (pages.where((value) => value == 2).length == 1) {
      throw StateError('temporary failure');
    }
    return [tag('tag49'), tag('last_tag')];
  }
}

void main() {
  testWidgets('common tags retry preserves page and deduplicates overlap', (
    tester,
  ) async {
    final repository = _Repository();
    await tester.pumpWidget(
      searchTestApp(
        const AllCommonTagsPage(sourceId: 'yande'),
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();
    // The actual scroll path starts page two. Its failure leaves page one
    // visible; explicit retry repeats page two, never page three.
    await tester.scrollUntilVisible(
      find.text(t.generic.retry),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(repository.pages, [1, 2]);
    await tester.tap(find.text(t.generic.retry));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('last_tag'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(repository.pages, [1, 2, 2]);
    expect(find.text(t.discovery.loadMore), findsNothing);
    expect(find.text(t.generic.retry), findsNothing);
    // Each tag has a single label, including its canonical value.
    expect(find.text('tag49'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
