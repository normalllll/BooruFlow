import 'dart:async';
import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/features/booru/services/web_challenge_service.dart';
import 'package:booruflow/features/booru/web_challenge_logic.dart';
import 'package:booruflow/features/discovery/collection_logic.dart';
import 'package:booruflow/features/discovery/widgets/post_collection_view.dart';
import 'package:booruflow/features/posts/media_presentation.dart';
import 'package:booruflow/features/posts/widgets/post_media_recovery.dart';
import 'package:booruflow/features/posts/widgets/rust_extended_network_image_provider.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:booruflow/src/rust/booru/error.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import '../discovery/home_page_test.dart' show browseTestApp;
import '../posts/media_type_presentation_test.dart' show mediaPost, variant;
import 'web_challenge_service_test.dart' show Backend, candidate;

const challenge = BooruError(
  code: BooruErrorCode.challengeRequired,
  sourceId: 'danbooru',
  userMessageKey: 'booru.error.challengeRequired',
  diagnosticId: 'recovery-test',
);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));
  for (final image in [false, true]) {
    testWidgets(
      'verification uses the same mapping and retries once image=$image',
      (tester) async {
        var retries = 0;
        final backend = Backend();
        final capture = Completer<Object?>();
        final service = WebChallengeService.forTesting(
          backendFactory: () => backend,
          collector: (_, _, _) => capture.future,
          changed: (_) async {},
        );
        final error = BooruReadableException(challenge);
        await tester.pumpWidget(
          browseTestApp(
            ProviderScope(
              overrides: [
                webChallengeServiceProvider.overrideWithValue(service),
              ],
              child: image
                  ? SizedBox(
                      height: 280,
                      child: PostMediaRecovery(
                        post: mediaPost([
                          variant(MediaVariantKind.sample, 'jpg'),
                        ]),
                        purpose: PostMediaPurpose.stage,
                        style: PostMediaRecoveryStyle.failure,
                        error: MediaImageException(
                          request: const MediaRequest(
                            sourceId: 'danbooru',
                            postId: '1',
                            variant: MediaVariantKind.sample,
                            url: 'https://example.invalid/1.jpg',
                            headers: [],
                            routeKey: 'test',
                            cacheKey: 'test',
                            authRevision: 0,
                            routeRevision: 'test',
                            allowDiskCache: false,
                          ),
                          stage: 'fetch',
                          cause: error,
                        ),
                        onRetry: () async {
                          retries++;
                        },
                      ),
                    )
                  : FrostErrorContent.fromError(
                      error: error,
                      onRetry: () => retries++,
                    ),
            ),
          ),
        );
        final action = find.byWidgetPredicate(
          (w) => w is FrostButton && w.label == t.webChallenge.open,
        );
        expect(action, findsOneWidget);
        await tester.tap(action);
        await tester.pump();
        await tester.tap(action);
        capture.complete(candidate);
        await tester.pumpAndSettle();
        expect(backend.completions, 1);
        expect(retries, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets(
    'verification cancellation leaves retry available without reloading',
    (tester) async {
      var retries = 0;
      final service = WebChallengeService.forTesting(
        backendFactory: Backend.new,
        collector: (_, _, _) async => null,
        changed: (_) async {},
      );
      await tester.pumpWidget(
        browseTestApp(
          ProviderScope(
            overrides: [webChallengeServiceProvider.overrideWithValue(service)],
            child: FrostErrorContent.fromError(
              error: challenge,
              onRetry: () => retries++,
            ),
          ),
        ),
      );
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is FrostButton && w.label == t.webChallenge.open,
        ),
      );
      await tester.pumpAndSettle();
      expect(retries, 0);
      expect(find.text(t.frost.retry), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('rate limited presentation retains its request title and clock', (
    tester,
  ) async {
    const error = BooruError(
      code: BooruErrorCode.rateLimited,
      userMessageKey: 'rate',
      diagnosticId: 'limited',
    );
    await tester.pumpWidget(
      browseTestApp(
        FrostErrorContent.fromError(
          error: BooruReadableException(error),
          onRetry: () {},
        ),
      ),
    );
    expect(find.text(t.discovery.tooManyRequests), findsOneWidget);
    expect(
      tester.widget<FrostIcon>(find.byType(FrostIcon).first).icon,
      appIcons.clock,
    );
    expect(find.byType(FrostErrorActionButton), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  for (final kind in ['feed', 'search', 'filtered']) {
    testWidgets('$kind empty collection supplies the original App title', (
      tester,
    ) async {
      await tester.pumpWidget(
        browseTestApp(
          PostCollectionView(
            collection: (
              key: CollectionKey(
                sourceId: 'danbooru',
                revision: 0,
                request: kind == 'search'
                    ? TagSearchCollectionRequest(['sky'])
                    : const FeedCollectionRequest(),
                ratings: kind == 'filtered' ? [ContentRating.general] : [],
              ),
              loader: (_, _) async =>
                  const PostPage(items: [], exhausted: true),
            ),
            headerBuilder: (_, source) =>
                const FrostPageHeader(title: FrostText('Browse')),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(
        find.text(switch (kind) {
          'search' => t.discovery.noSearchResults,
          'filtered' => t.discovery.noFilteredPosts,
          _ => t.discovery.noFeedPosts,
        }),
        findsOneWidget,
      );
      expect(find.text(t.frost.noMoreItems), findsNothing);
      expect(find.text(t.discovery.resetFilters), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
