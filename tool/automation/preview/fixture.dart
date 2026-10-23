// Deterministic preview data exists only in the Windows automation entrypoint.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:booruflow/app/ambient_artwork.dart';
import 'package:booruflow/app/app_router.dart';
import 'package:booruflow/app/booru_flow_app.dart';
import 'package:booruflow/core/app_runtime.dart';
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/downloads/download_path_reveal.dart';
import 'package:booruflow/core/downloads/download_platform.dart';
import 'package:booruflow/core/settings/background.dart';
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/booru/native_web_challenge_page.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/booru/web_challenge_logic.dart';
import 'package:booruflow/features/booru/web_challenge_page.dart';
import 'package:booruflow/features/discovery/collection_logic.dart';
import 'package:booruflow/features/discovery/discovery_logic.dart';
import 'package:booruflow/features/downloads/batch/logic.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/video_playback.dart';
import 'package:booruflow/features/search/logic.dart' as search;
import 'package:booruflow/features/settings/network/network_logic.dart';
import 'package:booruflow/features/settings/network/proxy_logic.dart';
import 'package:booruflow/features/settings/network/services/proxy_connection.dart';
import 'package:booruflow/features/update/logic.dart';
import 'package:booruflow/intl/locale_preferences.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/src/rust/api/booru_download.dart';
import 'package:booruflow/src/rust/api/booru_engine.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:booruflow/src/rust/booru/error.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';

import 'backdrop.dart';
import 'corner_composition.dart';
import 'downloads.dart';
import 'feedback.dart';
import 'icon_gallery.dart';
import 'media.dart';
import 'playback.dart';
import 'search_repository.dart';
import 'settings.dart';
import 'shape_fill_audit.dart';
import 'superellipse_seams.dart';

// Production main never imports this library or reads the preview environment.
String? activePreviewBoard;

bool isPhonePreview(String board) => const {
  'B10',
  'B11',
  'B12',
  'B13',
  'Q08',
  'Q09',
  'Q10',
  'Q11',
  'D08',
  'D09',
  'D10',
  'L09',
  'L10',
  'L11',
  'P12',
  'P13',
  'P14',
  'P15',
  'F04',
}.contains(board);

class PreviewFixture extends StatefulWidget {
  const PreviewFixture({required this.board, super.key});
  final String board;
  @override
  State<PreviewFixture> createState() => _PreviewFixtureState();
}

class _PreviewFixtureState extends State<PreviewFixture> {
  ProviderContainer? _container;
  Object? _error;
  ImageProvider? _ambient;
  PreviewSearchRepository? _searchRepository;
  PreviewChallengeBrowser? _browser;
  PreviewEngine? _mediaEngine;
  final _cancellation = ValueNotifier(0);
  @override
  void initState() {
    super.initState();
    unawaited(_prepare());
  }

  Future<void> _prepare() async {
    try {
      final board = widget.board;
      activePreviewBoard = board;
      if (!RegExp(
        r'^(R17|R19|R19AA|R19SE|R19SC|R20MC|Main|B(0[1-9]|1[0-3])|Q(0[1-9]|1[01])|D(0[1-9]|10)|L(0[1-9]|1[0-5])|P(0[1-9]|1[0-5])|F0[1-5]|W0[12]|M0[1-9])$',
      ).hasMatch(board)) {
        throw ArgumentError('Preview fixture not implemented: $board');
      }
      final sources = BooruService.instance.sources.toList()
        ..sort(
          (a, b) => a.sourceId == 'danbooru'
              ? -1
              : b.sourceId == 'danbooru'
              ? 1
              : a.displayName.compareTo(b.displayName),
        );
      if (board.startsWith('P')) {
        const order = [
          'danbooru',
          'gelbooru',
          'yande',
          'konachan_net',
          'konachan_com',
          'aibooru',
          'wallhaven',
          'anime_pictures',
        ];
        sources.sort(
          (a, b) =>
              order.indexOf(a.sourceId).compareTo(order.indexOf(b.sourceId)),
        );
      }
      _ambient = await previewBackdrop();
      await SettingsService.saveBackground(const BackgroundSettings());
      if (board.startsWith('Q') ||
          board.startsWith('D') ||
          board.startsWith('M') ||
          {'L05', 'L06', 'L07', 'L08'}.contains(board)) {
        _searchRepository = PreviewSearchRepository(
          board.startsWith('Q') ? board : 'Q01',
        );
      }
      final data = PreviewData(board);
      final service = board.startsWith('P') || {'F04', 'F05'}.contains(board)
          ? PreviewSettingsService(data, sources)
          : PreviewService(data, sources);
      if (service.engine case final PreviewEngine engine) _mediaEngine = engine;
      if (board.startsWith('P')) {
        AppInfo.version = '0.11.0';
        AppInfo.buildNumber = '38';
        SettingsService.defaultSourceId = 'danbooru';
        SettingsService.downloadPath = 'D:/Pictures/BooruFlow';
        SettingsService.maxConcurrentDownloads = 3;
        SettingsService.maxSegmentsPerTask = 4;
        SettingsService.proxyUrl = null;
      }
      if (board == 'B07' || board == 'Q03' || board == 'D03') {
        service.selectSource('yande');
      }
      if (board == 'R17' ||
          board == 'B05' ||
          board == 'B13' ||
          {'F02', 'F03', 'W01', 'W02'}.contains(board)) {
        service.selectSource('gelbooru');
      }
      final locale =
          Platform.environment['BOORUFLOW_PREVIEW_LOCALE'] ??
          const String.fromEnvironment('BOORUFLOW_PREVIEW_LOCALE');
      final language = switch (locale) {
        'en' => 0,
        'ja' => 1,
        'zh-TW' => 2,
        _ => 3,
      };
      SettingsService.language = language;
      applyLanguagePreference(language);
      SettingsService.sidebarExpanded = board != 'B09' && board != 'D07';
      SettingsService.ratings = switch (board) {
        'B01' ||
        'B03' ||
        'B08' ||
        'B09' ||
        'B10' => const [ContentRating.general, ContentRating.sensitive],
        'B07' => const [ContentRating.explicit],
        'P02' => const [ContentRating.general, ContentRating.sensitive],
        _ => const [],
      };
      await SettingsService.saveAppearance(
        SettingsService.appearance.copyWith(mode: ThemeMode.system),
      );
      final container = ProviderContainer(
        overrides: [
          ambientArtworkProvider.overrideWith(() => _PreviewArtwork(_ambient!)),
          booruServiceProvider.overrideWithValue(service),
          if (board.startsWith('M'))
            postPlaybackFactoryProvider.overrideWithValue(
              () => createPreviewPlayback(service.engine),
            ),
          if (_searchRepository case final repository?)
            search.tagSuggestionRepositoryProvider.overrideWithValue(
              repository,
            ),
          collectionLoaderProvider.overrideWithValue(data.load),
          if (board == 'R17')
            webChallengeServiceProvider.overrideWithValue(
              previewRecoveryChallenge(() => data.recovered = true),
            ),
          if (Platform.environment['BOORUFLOW_R8_REVEAL_FIXTURE']
              case final mode?
              when const {'missing', 'fileMissing'}.contains(mode))
            downloadPathRevealerProvider.overrideWith(
              (_) => DownloadPathRevealer(
                probe: (path) async =>
                    mode == 'fileMissing' && !path.endsWith('.png')
                    ? FileSystemEntityType.directory
                    : FileSystemEntityType.notFound,
                launch: (command, args, {required waitForExit}) async {
                  // Record intent only. Native verification never opens Explorer
                  // or probes the user's drive from a synthetic preview record.
                  stdout.writeln(
                    jsonEncode({'r8FileManager': command, 'arguments': args}),
                  );
                  return 0;
                },
              ),
            ),
          if (board.startsWith('L')) ...[
            downloadItemsProvider.overrideWith(
              () => PreviewDownloadItems(board),
            ),
            downloadManagerProvider.overrideWith(
              (ref) => PreviewDownloadManager(
                () =>
                    ref.read(downloadItemsProvider.notifier)
                        as PreviewDownloadItems,
              ),
            ),
            booruDownloadsProvider.overrideWithValue(
              PreviewBatchDownloads(
                board == 'L08'
                    ? data.posts.take(3).map((p) => p.postId).toSet()
                    : {},
              ),
            ),
            batchSaveLocationProvider('danbooru').overrideWith(
              (ref) async => const BatchSaveLocation(
                root: 'D:/Pictures/BooruFlow/danbooru',
                target: SaveTarget.downloadsFolder(
                  directory: 'D:/Pictures/BooruFlow',
                  subdirectory: 'danbooru',
                ),
              ),
            ),
          ] else
            downloadItemsProvider.overrideWith(() => _PreviewDownloads(data)),
          if (board.startsWith('P')) ...[
            networkProbeBackendProvider.overrideWithValue(
              previewNetworkBackend(sources.take(6).toList()),
            ),
            networkStatusProvider.overrideWith(PreviewNetworkStatus.new),
            proxySettingsProvider.overrideWith(PreviewProxySettings.new),
            proxyConnectivityProbeProvider.overrideWithValue(
              (_) async => const ProxyConnectivityResult(
                reachable: true,
                latency: Duration(milliseconds: 128),
              ),
            ),
            updateCheckProvider.overrideWith(PreviewUpdateCheck.new),
          ],
          if (isPhonePreview(board) && !Platform.isAndroid)
            downloadPlatformProvider.overrideWithValue(
              DownloadPlatform.android,
            ),
          updateLookupProvider.overrideWithValue(() async => null),
        ],
      );
      if (const {
        'B01',
        'B03',
        'B04',
        'B08',
        'B09',
        'B10',
        'B12',
      }.contains(board)) {
        container
            .read(feedSelectionProvider.notifier)
            .select(
              service.selectedSourceId,
              const FeedCollectionRequest(
                kind: FeedKind.recentPopular,
                range: PopularRange.week,
              ),
            );
      }
      if (!mounted) {
        container.dispose();
        return;
      }
      AppRouter.router.go(
        board.startsWith('Q') || {'L05', 'L06', 'L07', 'L08'}.contains(board)
            ? '/search'
            : {'F04', 'F05'}.contains(board)
            ? '/settings'
            : board.startsWith('P')
            ? (isPhonePreview(board)
                  ? '/settings'
                  : settingsPreviewRoute(board))
            : board.startsWith('L')
            ? '/downloads'
            : '/',
      );
      setState(() => _container = container);
      if (board.startsWith('P') && isPhonePreview(board) && board != 'P12') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            unawaited(AppRouter.router.push<void>(settingsPreviewRoute(board)));
          }
        });
      }
      if (board.startsWith('F') || board.startsWith('W')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (board == 'F04' || board == 'F05') {
            unawaited(
              AppRouter.router.push<void>('/settings/sources?source=danbooru'),
            );
          } else if (board == 'F02' || board == 'F03') {
            _browser = PreviewChallengeBrowser(board == 'F03');
            unawaited(
              AppRouter.pushContent<Object?>(
                context,
                WebChallengePage(
                  operation: previewChallengeOperation,
                  cancellation: _cancellation,
                  browser: _browser,
                ),
              ),
            );
          } else if (board.startsWith('W')) {
            unawaited(
              AppRouter.pushContent<bool>(
                context,
                NativeWebChallengePage(
                  service: previewNativeChallenge(board),
                  sourceId: 'gelbooru',
                  sourceName: 'Gelbooru',
                ),
              ),
            );
          }
        });
      }
      if (board.startsWith('D') ||
          {
            'M02',
            'M03',
            'M04',
            'M05',
            'M06',
            'M07',
            'M08',
            'M09',
          }.contains(board)) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final index = board.startsWith('M') ? 0 : 11;
          final image = board.startsWith('M')
              ? null
              : MemoryImage(await service.engine._image(index));
          if (!mounted) return;
          if (image != null) await precacheImage(image, context);
          if (!mounted) return;
          final collection = data.posts.map(Post.new).toList();
          unawaited(
            AppRouter.router.pushNamed<void>(
              AppRoute.postDetail.name,
              pathParameters: {'id': collection[index].id},
              extra: PostDetailRouteArgs(
                post: collection[index],
                collection: collection,
                initialIndex: index,
                preview: image,
              ),
            ),
          );
        });
      }
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'preview fixtures',
        ),
      );
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  void dispose() {
    _container?.dispose();
    _browser?.dispose();
    _mediaEngine?.disposeFixtures();
    _cancellation.dispose();
    unawaited(_searchRepository?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error case final error?) return ErrorWidget(error);
    final container = _container;
    if (container == null) return const SizedBox.shrink();
    const safe = EdgeInsets.only(top: 47, bottom: 34);
    return TranslationProvider(
      child: UncontrolledProviderScope(
        container: container,
        child: BooruFlowApp(
          checkUpdates: false,
          builder: (context, child) => MediaQuery(
            data: isPhonePreview(widget.board) && !Platform.isAndroid
                ? MediaQuery.of(
                    context,
                  ).copyWith(padding: safe, viewPadding: safe)
                : MediaQuery.of(context),
            child: switch (widget.board) {
              'R19' => const IconGallery(),
              'R19AA' => const CornerComposition(),
              'R19SE' => const SuperellipseSeams(),
              'R19SC' => const ShapeFillAudit(),
              _ => child!,
            },
          ),
        ),
      ),
    );
  }
}

class _PreviewDownloads extends DownloadItems {
  _PreviewDownloads(this.data);
  final PreviewData data;
  @override
  List<BooruDownloadItem> build() => data.downloads;
}

class PreviewData {
  PreviewData(this.board);
  final String board;
  bool recovered = false;
  final _held = Completer<PostPage>();
  int _calls = 0;
  late final posts = List.generate(
    {'L06', 'L07', 'L08'}.contains(board)
        ? 1240
        : board == 'B03'
        ? 15
        : 48,
    (index) => post(index),
  );
  late final downloads = List.generate(
    switch (board) {
      'B03' || 'F01' => 1,
      'B09' || 'B10' || 'B12' => 2,
      _ => 0,
    },
    (i) => BooruDownloadItem(
      post: Post(posts[i]),
      snapshot: DownloadTaskSnapshot(
        id: 'preview-download-$i',
        resourceId: i,
        variantIndex: 0,
        title: '#${posts[i].postId}',
        filename: '${posts[i].postId}.png',
        status: DownloadStatus.running,
        saveState: SaveState.none,
        receivedBytes: 4823450,
        totalBytes: 10485760,
        progress: .46,
        localPath: null,
        error: null,
        log: null,
        createdAt: DateTime(2026, 9, 15, 10, 24),
        updatedAt: DateTime(2026, 9, 15, 10, 24),
        sourceId: posts[i].sourceId,
        postId: posts[i].postId,
      ),
    ),
  );

  Future<PostPage> load(CollectionKey key, String? cursor) async {
    _calls++;
    if (board == 'R17') {
      if (recovered) return const PostPage(items: [], exhausted: true);
      throw BooruError(
        code: BooruErrorCode.challengeRequired,
        sourceId: key.sourceId,
        userMessageKey: 'booru.error.challengeRequired',
        diagnosticId: 'r17-verification',
      );
    }
    if (board == 'L06' && cursor != null) return _held.future;
    if (board == 'B04' && _calls > 1) return _held.future;
    if (board == 'B02' ||
        board == 'B11' ||
        (board == 'B03' && cursor != null)) {
      return _held.future;
    }
    if (board == 'B05' || board == 'B13') {
      throw BooruError(
        code: BooruErrorCode.network,
        sourceId: key.sourceId,
        userMessageKey: 'network',
        diagnosticId: 'preview-network',
      );
    }
    if (board == 'B06') {
      throw BooruError(
        code: BooruErrorCode.rateLimited,
        sourceId: key.sourceId,
        userMessageKey: 'rate_limited',
        diagnosticId: 'preview-rate-limit',
        httpStatus: 429,
        retryAfterSeconds: 38,
      );
    }
    if (board == 'B07' && key.ratings.isNotEmpty) throw NoSupportedRatings();
    return PostPage(
      items: posts,
      nextCursor: board == 'B03' || board == 'L06' ? 'page-2' : null,
      exhausted: board != 'B03' && board != 'L06',
    );
  }

  BooruPost post(int index) {
    if (board.startsWith('M')) return mediaPreviewPost(board, index);
    if (board.startsWith('D')) return detail(index);
    final heights = isPhonePreview(board)
        ? [240, 200, 260, 180, 220, 240]
        : [300, 240, 280, 350, 230, 300, 330, 220, 260, 210];
    final height = heights[index % heights.length];
    final id = (board == 'B12' ? 1270269 : 1270690) - index;
    return BooruPost(
      sourceId: 'danbooru',
      postId: '$id',
      postKey: 'danbooru:$id',
      rating: ContentRating.general,
      score: 128,
      createdAtIso8601: '2026-09-15T10:24:00Z',
      webUrl: 'https://danbooru.donmai.us/posts/$id',
      tags: const [BooruTag(name: 'Mika_Pikazo', category: TagCategory.artist)],
      media: [
        for (final kind in [MediaVariantKind.sample, MediaVariantKind.original])
          MediaVariant(
            kind: kind,
            url: 'https://preview.invalid/$index.png',
            width: isPhonePreview(board) ? 1790 : 2248,
            height: height * 10,
            mediaType: index == 1 ? MediaType.gif : MediaType.png,
            extension_: 'png',
            byteLengthDecimal: '2726297',
          ),
      ],
      flags: PostFlags(
        hasChildren: index == 4,
        isPending: false,
        isDeleted: false,
        isAiGenerated: false,
      ),
    );
  }

  BooruPost detail(int index) {
    final wide = board == 'D03';
    final source = wide ? 'yande' : 'danbooru';
    final id = (wide ? 1102945 : 1270280) - index;
    return BooruPost(
      sourceId: source,
      postId: '$id',
      postKey: '$source:$id',
      rating: ContentRating.general,
      score: wide ? 54 : 128,
      createdAtIso8601: '2026-10-12T13:04:00Z',
      webUrl: wide
          ? 'https://yande.re/post/show/$id'
          : 'https://danbooru.donmai.us/posts/$id',
      sourceUrl: 'https://www.pixiv.net/artworks/123456789',
      tags: board == 'D02'
          ? []
          : [
              if (!wide)
                const BooruTag(
                  name: 'Mika_Pikazo',
                  category: TagCategory.artist,
                ),
              const BooruTag(
                name: 'hatsune_miku',
                category: TagCategory.character,
              ),
              const BooruTag(name: 'vocaloid', category: TagCategory.copyright),
              for (final tag
                  in wide
                      ? ['twintails', 'cityscape', 'night', 'horns']
                      : ['1girl', 'long_hair', 'twintails', 'sky', 'sunset'])
                BooruTag(name: tag, category: TagCategory.general),
            ],
      media: [
        for (final kind in [MediaVariantKind.sample, MediaVariantKind.original])
          MediaVariant(
            kind: kind,
            url: 'https://preview.invalid/${kind.name}/$index.png',
            width: wide ? 4096 : 1200,
            height: wide ? 2731 : 1600,
            mediaType: MediaType.png,
            extension_: 'png',
            byteLengthDecimal: wide ? '7759462' : '2726297',
            checksum: const Checksum(
              algorithm: ChecksumAlgorithm.md5,
              value: '3f9a0123456789abcdef0123456789c21e',
            ),
          ),
      ],
      flags: PostFlags(
        hasChildren: !wide && index == 11,
        parentId: wide
            ? null
            : switch (index) {
                11 => '1270270',
                12 || 13 => '1270269',
                _ => null,
              },
        isPending: false,
        isDeleted: false,
        isAiGenerated: false,
      ),
    );
  }
}

class PreviewService extends BooruService {
  PreviewService(PreviewData data, this.sources, {PreviewEngine? engine})
    : engine = engine ?? PreviewEngine(data);
  @override
  final List<BooruSource> sources;
  String _selected = 'danbooru';
  @override
  String get selectedSourceId => _selected;
  @override
  BooruSource sourceById(String id) =>
      sources.firstWhere((source) => source.sourceId == id);
  @override
  void selectSource(String id) {
    if (_selected == id) return;
    sourceById(id);
    _selected = id;
    notifyChanged();
  }

  @override
  final PreviewEngine engine;
  @override
  String cacheRevision(String sourceId) => 'preview';
  @override
  String get networkCacheRevision => 'preview';
}

class PreviewEngine implements BooruEngine {
  PreviewEngine(this.data);
  final PreviewData data;
  final _images = <int, Future<Uint8List>>{};
  final _detailPending = Completer<BooruPost>();
  final _mediaPending = Completer<void>();
  final _videoSources = <PreviewVideoSource>[];
  bool _disposed = false;
  void disposeFixtures() {
    _disposed = true;
    for (final source in _videoSources) {
      source.close();
    }
    _videoSources.clear();
  }

  @override
  Future<MediaRequest> prepareMediaUrl({
    required String sourceId,
    required String postId,
    required MediaVariantKind variant,
    required String url,
    required bool allowDiskCache,
  }) async => MediaRequest(
    sourceId: sourceId,
    postId: postId,
    variant: variant,
    url: url,
    headers: const [],
    routeKey: 'preview',
    cacheKey: '${data.board}/$sourceId/$postId/${variant.name}/$url',
    authRevision: 0,
    routeRevision: 'preview',
    allowDiskCache: false,
  );
  @override
  Stream<MediaFetchEvent> streamMedia({required MediaRequest request}) async* {
    if (data.board == 'R20MC') {
      throw BooruError(
        code: BooruErrorCode.challengeRequired,
        sourceId: request.sourceId,
        userMessageKey: 'booru.error.challengeRequired',
        diagnosticId: 'media-feedback-fixture',
        httpStatus: 403,
      );
    }
    if (data.board == 'D02' && request.variant == MediaVariantKind.original) {
      await _mediaPending.future;
    }
    if (data.board == 'D04' && request.variant == MediaVariantKind.original) {
      throw BooruError(
        code: BooruErrorCode.network,
        sourceId: request.sourceId,
        userMessageKey: 'network',
        diagnosticId: 'preview-original',
      );
    }
    final index = int.parse(
      Uri.parse(request.url).pathSegments.last.split('.').first,
    );
    final bytes =
        (data.board.startsWith('M')
            ? await mediaPreviewBytes(request)
            : null) ??
        await _images.putIfAbsent(index, () => _image(index));
    yield MediaFetchEvent.chunk(
      bytes: bytes,
      receivedBytesDecimal: '${bytes.length}',
      totalBytesDecimal: '${bytes.length}',
    );
  }

  @override
  Future<MediaRequest> prepareVideoRequest({
    required MediaRequest request,
  }) async {
    final source = await PreviewVideoSource.open(
      request,
      corrupt: data.board == 'M06',
      initialDelay: data.board == 'M09'
          ? const Duration(seconds: 3)
          : Duration.zero,
    );
    if (_disposed) {
      source.close();
      throw StateError('Closed preview');
    }
    _videoSources.add(source);
    return MediaRequest(
      sourceId: request.sourceId,
      postId: request.postId,
      variant: request.variant,
      url: source.url,
      headers: request.headers,
      routeKey: request.routeKey,
      cacheKey: request.cacheKey,
      authRevision: request.authRevision,
      routeRevision: request.routeRevision,
      allowDiskCache: false,
    );
  }

  Future<Uint8List> _image(int index) async {
    // Recognizable cover art makes successful video-cover decoding visible.
    if (data.board.startsWith('D') || {'M01', 'M02'}.contains(data.board)) {
      return _detailImage();
    }
    const colors = [
      0xff7a909a,
      0xffb390ad,
      0xff8b96ca,
      0xff6caaa0,
      0xff88bfd9,
      0xffd8ab80,
      0xff9cac7b,
    ];
    final color = Color(colors[index % colors.length]);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const bounds = Rect.fromLTWH(0, 0, 320, 520);
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, bounds.bottomRight, [
          Color.lerp(color, const Color(0xffffffff), .5)!,
          Color.lerp(color, const Color(0xff000000), .22)!,
        ]),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(320, 520);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      return bytes!.buffer.asUint8List();
    } finally {
      image.dispose();
      picture.dispose();
    }
  }

  Future<Uint8List> _detailImage() async {
    final wide = data.board == 'D03';
    final recorder = ui.PictureRecorder();
    // A deterministic test photograph substitute, decoded by the real media path.
    final paintCanvas = Canvas(recorder);
    // R3 phone fixtures deliberately disagree with 1200 x 1600 metadata.
    // The actual 1080 x 1915 decoded pixels must define the natural stage.
    final tall = {'D08', 'D09'}.contains(data.board);
    final width = wide
        ? 640.0
        : tall
        ? 1080.0
        : 480.0;
    final height = wide
        ? 427.0
        : tall
        ? 1915.0
        : 640.0;
    paintCanvas.drawRect(
      Rect.fromLTWH(0, 0, width, height),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(width, height),
          wide
              ? [const Color(0xffb9e1f3), const Color(0xff688fc3)]
              : [const Color(0xfff7ddb8), const Color(0xffd98a60)],
        ),
    );
    paintCanvas.drawCircle(
      Offset(width * .5, height * .4),
      width * .22,
      Paint()..color = wide ? const Color(0xffdbeff7) : const Color(0xfffcebd0),
    );
    for (final (top, color) in [(.55, 0xffb9694a), (.72, 0xff8f4e3a)]) {
      final path = Path()
        ..moveTo(0, height)
        ..lineTo(0, height * .8)
        ..lineTo(width * .3, height * top)
        ..lineTo(width * .5, height * (top + .2))
        ..lineTo(width * .72, height * (top - .1))
        ..lineTo(width, height)
        ..close();
      paintCanvas.drawPath(
        path,
        Paint()..color = wide ? const Color(0xff507c9e) : Color(color),
      );
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    try {
      return (await image.toByteData(
        format: ui.ImageByteFormat.png,
      ))!.buffer.asUint8List();
    } finally {
      image.dispose();
      picture.dispose();
    }
  }

  @override
  Future<BooruPost> getPost({
    required String sourceId,
    required String postId,
  }) async => data.board == 'D02'
      ? _detailPending.future
      : data.posts.firstWhere(
          (p) => p.sourceId == sourceId && p.postId == postId,
        );
  @override
  Future<List<BooruPost>> relatedPosts({
    required String sourceId,
    required String postId,
  }) async => data.posts.take(4).toList();
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError(
    'Preview backend does not implement ${invocation.memberName}',
  );
}

// Fixed test art enters through the same provider as decoded detail artwork.
class _PreviewArtwork extends AmbientArtwork {
  _PreviewArtwork(this.image);
  final ImageProvider image;
  @override
  ImageProvider? build() => image;
  @override
  void show(ImageProvider image) {} // Keep the test floor fixed in every board.
}
