import 'package:flutter/material.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loading_more_list/loading_more_list.dart';
import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/shared/widgets/loading_more_indicator.dart';
import 'package:booruflow/src/rust/booru/error.dart';
import 'package:booruflow/shared/widgets/interaction_controls.dart';

void main() {
  const error = BooruError(
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
    expect(message, isNot(contains("Instance of 'BooruError'")));
  });

  test(
    'missing routes explain local routing instead of source availability',
    () {
      const routeError = BooruError(
        code: BooruErrorCode.network,
        sourceId: 'gelbooru',
        userMessageKey: 'booru.error.routeUnavailable',
        diagnosticId: 'route-test',
        action: RecoveryAction.refreshRoute,
      );
      final message = describeBooruError(routeError);
      expect(message, startsWith(t.booruError.routeUnavailable));
      expect(message, isNot(contains(t.booruError.sourceUnavailable)));
      expect(message, contains('action=refreshRoute'));
      expect(message, isNot(contains('HTTP=')));
    },
  );

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
    expect(find.textContaining("Instance of 'BooruError'"), findsNothing);
  });

  testWidgets(
    'rate limit disables retry until cooldown expires and survives rebuild',
    (tester) async {
      var retries = 0;
      Widget page() => MaterialApp(
        home: Scaffold(
          body: LoadingMoreIndicator(
            status: IndicatorStatus.fullScreenError,
            errorRefresh: () => retries++,
            error: error,
          ),
        ),
      );
      await tester.pumpWidget(page());
      expect(
        tester.widget<AppButton>(find.byType(AppButton)).onPressed,
        isNull,
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(page());
      expect(find.textContaining('(7s)'), findsOneWidget);
      await tester.pump(const Duration(seconds: 7));
      await tester.ensureVisible(find.byType(AppButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(AppButton));
      expect(retries, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
