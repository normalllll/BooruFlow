// Text scale and long-language overflow for the browse, results, detail and viewer pages: browse with
// several feeds, results for a long query, the post detail with long values
// and the viewer, at 1.3 and 2.0 times text, in English and Japanese, on a wide
// pointer window and a narrow touch one.
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/browse/browse_page.dart';
import 'package:booruflow/features/browse/collection_logic.dart';
import 'package:booruflow/features/browse/results_page.dart';
import 'package:booruflow/features/browse/widgets/browse_card.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/features/image_viewer/image_zoom_page.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/post_detail_page.dart';
import 'package:booruflow/features/search/logic.dart';
import 'package:booruflow/features/search/services/tag_suggestion_repository.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';

import '../../support/browse_support.dart';
import '../discovery/search_interaction_test.dart' show testSource;

class _Store implements SettingsServiceStore {
  @override
  Map<String, dynamic> load() => {};
  @override
  Future<void> write(String key, dynamic value) async {}
}

class _Downloads extends DownloadItems {
  @override
  List<BooruDownloadItem> build() => [];
}

class _Tags extends TagSuggestionRepository {
  @override
  Future<void> initialize() async {}
  @override
  String? displayName(String source, String locale, String value) => null;
}

/// Media never arrives, so pages show their placeholders and chrome.
class _Engine extends PendingMediaEngine {
  @override
  Future<BooruPost> getPost({
    required String sourceId,
    required String postId,
  }) async => _post(postId);
}

class _Service extends BooruService {
  @override
  final _Engine engine = _Engine();
}

BooruSource _popularSource() {
  final base = testSource('yande');
  return BooruSource(
    sourceId: base.sourceId,
    displayName: base.displayName,
    protocol: base.protocol,
    enabledByDefault: true,
    isAiSource: false,
    capabilities: SourceCapabilities(
      ratings: base.capabilities.ratings,
      authKind: base.capabilities.authKind,
      supportsSearch: true,
      supportsPostDetail: true,
      supportsAutocomplete: true,
      supportsRelatedPosts: false,
      supportsOriginal: true,
      supportsAuthenticatedMedia: false,
      supportsBackgroundDownload: true,
      discovery: const DiscoveryCapabilities(
        popular: CapabilityAvailability.available,
        commonTags: CapabilityAvailability.available,
        popularRanges: [PopularRange.day, PopularRange.week],
        historicalRanges: [PopularRange.day],
        timeBasis: PopularTimeBasis.calendarUploadPeriod,
        additionalFeeds: [],
        autocompleteMinChars: 1,
      ),
    ),
  );
}

final _longSource =
    'https://example.invalid/${List.filled(8, 'a-very-long-path-segment').join('/')}';
final _longTag = List.filled(6, 'extremely_long_tag_name').join('_');

BooruPost _post(String id) => BooruPost(
  sourceId: 'yande',
  postId: id,
  postKey: 'yande:$id',
  author: 'uploader_with_a_rather_long_name',
  webUrl: 'https://yande.re/post/show/$id',
  sourceUrl: _longSource,
  rating: ContentRating.general,
  score: 1234567,
  createdAtIso8601: '2026-10-12T01:02:03Z',
  tags: [
    BooruTag(name: _longTag, category: TagCategory.artist),
    BooruTag(name: '${_longTag}_character', category: TagCategory.character),
    BooruTag(name: '${_longTag}_series', category: TagCategory.copyright),
    for (var i = 0; i < 12; i++)
      BooruTag(name: '${_longTag}_$i', category: TagCategory.general),
    BooruTag(name: 'meta_$_longTag', category: TagCategory.meta),
  ],
  media: [
    for (final kind in [MediaVariantKind.sample, MediaVariantKind.original])
      MediaVariant(
        kind: kind,
        url: 'https://example.invalid/$id/${kind.name}.png',
        width: 4096,
        height: 2894,
        byteLengthDecimal: '3145728',
        extension_: 'png',
      ),
  ],
  flags: const PostFlags(
    hasChildren: false,
    isPending: false,
    isDeleted: false,
    isAiGenerated: false,
  ),
);

void main() {
  late _Service service;

  setUp(() async {
    await SettingsService.initialize(store: _Store());
    service = _Service()..useSourcesForTesting([_popularSource()]);
    BooruService.instance.useSourcesForTesting([_popularSource()]);
  });
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  Widget scope(Widget child) => ProviderScope(
    overrides: [
      booruServiceProvider.overrideWithValue(service),
      tagSuggestionRepositoryProvider.overrideWithValue(_Tags()),
      downloadItemsProvider.overrideWith(_Downloads.new),
      collectionLoaderProvider.overrideWithValue(
        (_, _) async => PostPage(
          items: [for (var i = 1; i <= 40; i++) _post('$i')],
          exhausted: true,
        ),
      ),
    ],
    child: child,
  );

  // Each page names something it must have drawn, so a blank page is no pass.
  final pages = <(String, Widget Function(), Finder)>[
    (
      'browse with several feeds',
      () => const BrowsePage(),
      find.byType(BrowseCard),
    ),
    (
      'results for a long query',
      () => ResultsPage(
        tags: [for (var i = 0; i < 8; i++) '${_longTag}_$i', '-excluded_tag'],
        sourceId: 'yande',
      ),
      find.byType(BrowseCard),
    ),
    (
      'post detail with long values',
      () => PostDetailPage(args: PostDetailRouteArgs(post: Post(_post('101')))),
      find.byType(FrostTag),
    ),
    (
      'viewer',
      () => ImageZoomPage(
        args: ImageViewerRouteArgs(
          collection: [for (var i = 1; i <= 5; i++) Post(_post('$i'))],
          initialIndex: 1,
        ),
      ),
      find.text('2 / 5'),
    ),
  ];

  for (final (name, build, content) in pages) {
    for (final locale in [AppLocale.en, AppLocale.ja]) {
      for (final scale in [1.3, 2.0]) {
        for (final (size, platform, label) in [
          (const Size(1147, 717), TargetPlatform.windows, 'wide'),
          (const Size(360, 780), TargetPlatform.android, 'narrow touch'),
        ]) {
          testWidgets('$name: ${locale.languageTag} at $scale text, $label', (
            tester,
          ) async {
            LocaleSettings.setLocaleSync(locale);
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              scope(browseTestApp(build(), scale: scale, platform: platform)),
            );
            for (var frame = 0; frame < 16; frame++) {
              await tester.pump(const Duration(milliseconds: 50));
            }
            expect(content, findsWidgets);
            expect(tester.takeException(), isNull);
            // Settle input-driven chrome too, then leave cleanly.
            await tester.pump(const Duration(seconds: 3));
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox());
          });
        }
      }
    }
  }
}
