import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/features/posts/widgets/rust_extended_network_image_provider.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:booruflow/src/rust/booru/error.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import '../discovery/home_page_test.dart' show browseTestApp;

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

  const nativeFailure = BooruError(
    code: BooruErrorCode.internal,
    sourceId: 'aibooru',
    userMessageKey: 'webChallenge.windowFailed',
    diagnosticId: 'window-test',
    details: 'stage=webview-create\nHRESULT 0x8007139F',
  );

  test(
    'native window failure exposes its cause without a runtime install hint',
    () {
      expect(
        describeBooruError(nativeFailure, includeDiagnostics: false),
        t.webChallenge.windowFailed,
      );
      expect(
        booruErrorDetails(nativeFailure),
        contains(nativeFailure.details!),
      );
      expect(
        booruErrorDetails(BooruReadableException(nativeFailure)),
        contains(nativeFailure.details!),
      );
      const missing = BooruError(
        code: BooruErrorCode.unsupportedCapability,
        userMessageKey: 'webChallenge.runtimeMissing',
        diagnosticId: 'missing',
      );
      expect(
        describeBooruError(missing, includeDiagnostics: false),
        t.webChallenge.runtimeMissing,
      );
      expect(t.webChallenge.windowFailed, isNot(contains('WebView2')));
      expect(t.webChallenge.webViewUnavailable, isNot(contains('WebView2')));
    },
  );

  test('all locales reserve the install hint for a missing runtime', () {
    for (final locale in AppLocale.values) {
      final labels = locale.buildSync().webChallenge;
      expect(labels.windowFailed, isNot(contains('WebView2')));
      expect(labels.webViewUnavailable, isNot(contains('WebView2')));
      expect(labels.runtimeMissing, contains('WebView2 Runtime'));
    }
    expect(AppLocale.zhTw.buildSync().webChallenge.windowFailed, '無法開啟網頁驗證。');
  });

  testWidgets('native system cause is visible only after expanding details', (
    tester,
  ) async {
    await tester.pumpWidget(
      browseTestApp(
        FrostErrorContent.fromError(error: nativeFailure, onRetry: () {}),
      ),
    );
    expect(find.text(t.webChallenge.windowFailed), findsOneWidget);
    expect(find.textContaining('HRESULT 0x8007139F'), findsNothing);
    await tester.tap(find.text(t.frost.errorDetails));
    await tester.pumpAndSettle();
    expect(find.textContaining('stage=webview-create'), findsOneWidget);
    expect(find.textContaining('HRESULT 0x8007139F'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('rate limit delay handles wrappers, fallback and bounds', () {
    BooruError limited(int? seconds) => BooruError(
      code: BooruErrorCode.rateLimited,
      userMessageKey: 'rate',
      diagnosticId: 'delay',
      retryAfterSeconds: seconds,
    );
    expect(booruRetryDelay(error), const Duration(seconds: 12));
    expect(
      booruRetryDelay(BooruReadableException(error)),
      const Duration(seconds: 12),
    );
    expect(booruRetryDelay(limited(null)), const Duration(seconds: 60));
    expect(booruRetryDelay(limited(-1)), Duration.zero);
    expect(booruRetryDelay(limited(100000)), const Duration(days: 1));
    expect(
      booruRetryDelay(
        const BooruError(
          code: BooruErrorCode.network,
          userMessageKey: 'network',
          diagnosticId: 'delay',
          retryAfterSeconds: 12,
        ),
      ),
      Duration.zero,
    );
    expect(booruRetryDelay(StateError('other')), Duration.zero);
  });

  test(
    'details retain technical fields without repeating the localized summary',
    () {
      final details = booruErrorDetails(error)!;
      expect(details, startsWith('source=danbooru'));
      expect(details, contains('code=rateLimited'));
      expect(details, contains('HTTP=429'));
      expect(details, contains('message=booru.error.rateLimited'));
      expect(details, contains('id=booru-test-id'));
      expect(
        details,
        isNot(contains(describeBooruError(error, includeDiagnostics: false))),
      );
      expect(booruErrorDetails(BooruReadableException(error)), details);
      expect(
        describeBooruError(error),
        '${describeBooruError(error, includeDiagnostics: false)}\n$details',
      );
    },
  );
  test(
    'media details omit the summary and redact request credentials and queries',
    () {
      const request = MediaRequest(
        sourceId: 'danbooru',
        postId: '1',
        variant: MediaVariantKind.sample,
        url: 'https://user:secret@example.test/image.jpg?token=private',
        headers: [],
        routeKey: 'test',
        cacheKey: 'test',
        authRevision: 0,
        routeRevision: 'test',
        allowDiskCache: false,
      );
      const image = MediaImageException(
        request: request,
        stage: 'fetch',
        cause: error,
        byteCount: 512,
      );
      final details = booruErrorDetails(image)!;
      expect(details, contains('source=danbooru · post=1 · variant=sample'));
      expect(details, contains('stage=fetch · cache=false · bytes=512'));
      expect(details, contains('https://example.test/image.jpg'));
      expect(details, contains('code=rateLimited'));
      expect(details, isNot(contains('secret')));
      expect(details, isNot(contains('token=private')));
      expect(
        details,
        isNot(contains(describeBooruError(error, includeDiagnostics: false))),
      );
    },
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

  testWidgets(
    'the full-screen collection error exposes diagnostics on demand',
    (tester) async {
      await tester.pumpWidget(
        browseTestApp(
          FrostErrorContent.fromError(error: error, onRetry: () {}),
        ),
      );
      await tester.tap(find.text(t.frost.errorDetails));
      await tester.pumpAndSettle();
      expect(find.textContaining('source=danbooru'), findsOneWidget);
      expect(find.textContaining('HTTP=429'), findsOneWidget);
      expect(find.textContaining('id=booru-test-id'), findsOneWidget);
      expect(find.textContaining("Instance of 'BooruError'"), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'rate limit disables retry until its absolute deadline and survives rebuild',
    (tester) async {
      var retries = 0;
      final deadline = DateTime.now().add(const Duration(seconds: 12));
      final source = _RetrySource(
        BooruReadableException(error, retryDeadline: deadline),
        () => retries++,
      );
      await source.refresh();
      Widget page() => browseTestApp(
        FrostLoadingScrollView(
          slivers: [
            FrostSliverDataList<int>(
              source: source,
              firstLoadSkeleton: const SizedBox(height: 120),
              itemBuilder: (_, value, index) => const SizedBox(height: 40),
            ),
          ],
        ),
      );
      await tester.pumpWidget(page());
      final button = find.byWidgetPredicate(
        (w) => w is FrostButton && w.label.startsWith(t.generic.retry),
      );
      expect(tester.widget<FrostButton>(button).onPressed, isNull);
      // The real collection owns an absolute deadline, not a timer-tick count.
      // Keep that production contract and advance wall time as well as fake timers.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 5)),
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(page());
      expect(find.text(t.discovery.retryIn(seconds: 7)), findsOneWidget);
      expect(tester.widget<FrostButton>(button).onPressed, isNull);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 7)),
      );
      await tester.pump(const Duration(seconds: 7));
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pump();
      expect(retries, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      source.dispose();
    },
  );
}

class _RetrySource extends FrostListSource<int> {
  _RetrySource(this.failure, this.onRetry);
  final Object failure;
  final VoidCallback onRetry;
  var attempts = 0;
  @override
  Future<List<int>> initList() async {
    if (attempts++ == 0) throw failure;
    onRetry();
    return [];
  }

  @override
  Future<List<int>> nextList() async => [];
}
