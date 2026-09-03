import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loading_more_list/loading_more_list.dart';
import 'package:yande_gui/features/booru/booru_error_presentation.dart';
import 'package:yande_gui/shared/widgets/loading_more_indicator.dart';
import 'package:yande_gui/src/rust/booru/error.dart';

void main() {
  const error = BooruErrorDto(
    code: BooruErrorCode.rateLimited,
    sourceId: 'danbooru',
    userMessageKey: 'booru.error.rateLimited',
    diagnosticId: 'booru-test-id',
    httpStatus: 429,
    retryAfterSeconds: 12,
    action: RecoveryAction.retry,
  );

  test('Booru errors expose actionable diagnostics instead of an instance', () {
    final message = describeBooruError(error);

    expect(message, contains('source=danbooru'));
    expect(message, contains('code=rateLimited'));
    expect(message, contains('HTTP=429'));
    expect(message, contains('retryAfter=12s'));
    expect(message, contains('action=retry'));
    expect(message, contains('message=booru.error.rateLimited'));
    expect(message, contains('id=booru-test-id'));
    expect(message, isNot(contains("Instance of 'BooruErrorDto'")));
  });

  test('wrapped bridge errors remain readable when Flutter prints them', () {
    final wrapped = makeBooruErrorReadable(error);

    expect(wrapped, isA<BooruReadableException>());
    expect(wrapped.toString(), describeBooruError(error));
  });

  testWidgets('the full-screen list error renders diagnostics', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoadingMoreIndicator(
          status: IndicatorStatus.fullScreenError,
          errorRefresh: () {},
          error: error,
        ),
      ),
    );

    expect(find.textContaining('source=danbooru'), findsOneWidget);
    expect(find.textContaining('HTTP=429'), findsOneWidget);
    expect(find.textContaining('id=booru-test-id'), findsOneWidget);
    expect(find.textContaining("Instance of 'BooruErrorDto'"), findsNothing);
  });
}
