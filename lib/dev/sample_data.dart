// Sample data for development: the sample entrypoint (tool/sample_main.dart),
// the UI automation entrypoint and widget tests. Nothing in the app's own
// entrypoint imports this file, so release builds leave it out.
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:booruflow/dev/sample_downloads.dart';
import 'package:booruflow/dev/sample_tags.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/browse/collection_logic.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/search/logic.dart' as search;
import 'package:booruflow/features/settings/network/network_logic.dart';
import 'package:booruflow/features/settings/network/proxy_logic.dart';
import 'package:booruflow/features/settings/network/services/proxy_connection.dart';
import 'package:booruflow/features/update/logic.dart';
import 'package:booruflow/src/rust/api/booru_auth.dart';
import 'package:booruflow/src/rust/api/booru_download.dart'
    show MediaFetchEvent;
import 'package:booruflow/src/rust/api/booru_engine.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:booruflow/src/rust/api/web_challenge.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

/// 48 posts by one artist, with tags, a source link and a parent/child pair,
/// so browse, detail and related posts all have content.
class SampleData {
  late final posts = List.generate(48, post);

  BooruPost post(int index) {
    const heights = [300, 240, 280, 350, 230, 300, 330, 220, 260, 210];
    final id = 1270690 - index;
    return BooruPost(
      sourceId: 'danbooru',
      postId: '$id',
      postKey: 'danbooru:$id',
      rating: ContentRating.general,
      score: 128,
      createdAtIso8601: '2026-09-15T10:24:00Z',
      webUrl: 'https://danbooru.donmai.us/posts/$id',
      sourceUrl: 'https://www.pixiv.net/artworks/123456789',
      tags: const [
        BooruTag(name: 'Mika_Pikazo', category: TagCategory.artist),
        BooruTag(name: 'hatsune_miku', category: TagCategory.character),
        BooruTag(name: 'vocaloid', category: TagCategory.copyright),
        BooruTag(name: '1girl', category: TagCategory.general),
        BooruTag(name: 'long_hair', category: TagCategory.general),
        BooruTag(name: 'twintails', category: TagCategory.general),
        BooruTag(name: 'sky', category: TagCategory.general),
        BooruTag(name: 'sunset', category: TagCategory.general),
      ],
      media: [
        for (final kind in [MediaVariantKind.sample, MediaVariantKind.original])
          MediaVariant(
            kind: kind,
            url: 'https://sample.invalid/$index.png',
            width: 2248,
            height: heights[index % heights.length] * 10,
            mediaType: index == 1 ? MediaType.gif : MediaType.png,
            extension_: 'png',
            byteLengthDecimal: '2726297',
            checksum: const Checksum(
              algorithm: ChecksumAlgorithm.md5,
              value: '3f9a0123456789abcdef0123456789c21e',
            ),
          ),
      ],
      flags: PostFlags(
        hasChildren: index == 4,
        parentId: switch (index) {
          11 => '1270679',
          12 || 13 => '1270678',
          _ => null,
        },
        isPending: false,
        isDeleted: false,
        isAiGenerated: false,
      ),
    );
  }

  Future<PostPage> load(CollectionKey key, String? cursor) async =>
      PostPage(items: posts, exhausted: true);
}

/// The booru service on sample data: sources come from the real service,
/// everything else is local.
class SampleService extends BooruService {
  SampleService(this.data) : engine = SampleEngine(data);
  final SampleData data;
  String _selected = 'danbooru';

  @override
  List<BooruSource> get sources => BooruService.instance.sources.toList()
    ..sort(
      (a, b) => a.sourceId == 'danbooru'
          ? -1
          : b.sourceId == 'danbooru'
          ? 1
          : a.displayName.compareTo(b.displayName),
    );
  @override
  String get selectedSourceId => _selected;
  @override
  BooruSource sourceById(String sourceId) =>
      sources.firstWhere((source) => source.sourceId == sourceId);
  @override
  void selectSource(String sourceId) {
    if (_selected == sourceId) return;
    sourceById(sourceId);
    _selected = sourceId;
    notifyChanged();
  }

  @override
  final SampleEngine engine;
  @override
  String cacheRevision(String sourceId) => 'sample';
  @override
  String get networkCacheRevision => 'sample';

  @override
  Map<String, String> savedAuth(String sourceId) => sourceId == 'danbooru'
      ? {'username': 'mika', 'apiKey': 'sample-not-a-real-secret'}
      : {};
  @override
  AuthSchema authSchema(String sourceId) => AuthSchema(
    sourceId: sourceId,
    usesWebSession: false,
    fields: sourceById(sourceId).capabilities.authKind == AuthKind.none
        ? []
        : const [
            AuthField(
              kind: AuthFieldKind.username,
              labelKey: 'username',
              required_: true,
              secret: false,
            ),
            AuthField(
              kind: AuthFieldKind.apiKey,
              labelKey: 'apiKey',
              required_: true,
              secret: true,
            ),
          ],
  );
  @override
  AuthState authState(String sourceId) => AuthState(
    sourceId: sourceId,
    status: sourceId == 'danbooru'
        ? AuthStatus.verified
        : AuthStatus.notConfigured,
    username: sourceId == 'danbooru' ? 'mika' : null,
    authRevision: 1,
  );
}

/// Serves posts and generated pictures; calls it does not cover throw.
class SampleEngine implements BooruEngine {
  SampleEngine(this.data);
  final SampleData data;
  final _images = <int, Future<Uint8List>>{};

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
    routeKey: 'sample',
    cacheKey: 'sample/$sourceId/$postId/${variant.name}/$url',
    authRevision: 0,
    routeRevision: 'sample',
    allowDiskCache: false,
  );

  @override
  Stream<MediaFetchEvent> streamMedia({required MediaRequest request}) async* {
    final index = int.parse(
      Uri.parse(request.url).pathSegments.last.split('.').first,
    );
    final bytes = await _images.putIfAbsent(index, () => _image(index));
    yield MediaFetchEvent.chunk(
      bytes: bytes,
      receivedBytesDecimal: '${bytes.length}',
      totalBytesDecimal: '${bytes.length}',
    );
  }

  // A gradient scene in a per-post colour, drawn once and encoded as PNG.
  Future<Uint8List> _image(int index) async {
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
    const width = 480.0;
    const height = 640.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, width, height),
      Paint()
        ..shader =
            ui.Gradient.linear(Offset.zero, const Offset(width, height), [
              Color.lerp(color, const Color(0xffffffff), .5)!,
              Color.lerp(color, const Color(0xff000000), .22)!,
            ]),
    );
    canvas.drawCircle(
      const Offset(width * .5, height * .4),
      width * .22,
      Paint()..color = Color.lerp(color, const Color(0xffffffff), .8)!,
    );
    for (final (top, shade) in [(.55, .3), (.72, .5)]) {
      canvas.drawPath(
        Path()
          ..moveTo(0, height)
          ..lineTo(0, height * .8)
          ..lineTo(width * .3, height * top)
          ..lineTo(width * .5, height * (top + .2))
          ..lineTo(width * .72, height * (top - .1))
          ..lineTo(width, height)
          ..close(),
        Paint()..color = Color.lerp(color, const Color(0xff000000), shade)!,
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
  }) async => data.posts.firstWhere(
    (p) => p.sourceId == sourceId && p.postId == postId,
  );
  @override
  Future<List<BooruPost>> relatedPosts({
    required String sourceId,
    required String postId,
  }) async => data.posts.take(4).toList();
  @override
  Future<AuthState> verifyAuth({required String sourceId}) async => AuthState(
    sourceId: sourceId,
    status: AuthStatus.verified,
    authRevision: 1,
    username: 'mika',
  );
  @override
  Future<WebChallengeState> webChallengeState({
    required String sourceId,
  }) async => WebChallengeState(
    sourceId: sourceId,
    hasSavedData: sourceId == 'danbooru',
    verified: sourceId == 'danbooru',
    revision: 1,
  );
  /// Popular feeds answer with the sample posts, so their availability probe
  /// reports them as available.
  @override
  Future<PostPage> feed({required FeedRequest request}) async =>
      PostPage(items: data.posts, exhausted: true);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError(
    'Sample backend does not implement ${invocation.memberName}',
  );
}

RouteCacheState _routes() => RouteCacheState(
  initialized: true,
  refreshing: false,
  routeRevision: 'sample',
  fetchedAtIso8601: '2026-10-19T21:04:00+08:00',
  provider: RouteProvider.uncensoredDns,
  routes: List.generate(
    36,
    (i) => PersistedHostRoute(
      logicalHost: 'host$i.example.invalid',
      httpsPort: 443,
      candidates: const ['192.0.2.1'],
    ),
  ),
  diagnostics: const [],
);

class _SampleNetworkStatus extends NetworkStatus {
  @override
  NetworkStatusState build() => NetworkStatusState(
    routes: _routes(),
    checks: const {
      'danbooru': SourceCheckStatus.available,
      'gelbooru': SourceCheckStatus.available,
      'yande': SourceCheckStatus.available,
    },
  );
}

class _SampleProxySettings extends ProxySettings {
  @override
  ProxySettingsState build() => ProxySettingsState.fromUrl(
    'http://127.0.0.1:7890',
  ).copyWith(reachable: true);
}

final _data = SampleData();
final _tags = SampleTagRepository();

/// Provider overrides that put the app on sample data: browse, search, tags,
/// detail, downloads and settings need no network.
final List<Override> sampleOverrides = [
  booruServiceProvider.overrideWith((ref) => SampleService(_data)),
  search.tagSuggestionRepositoryProvider.overrideWithValue(_tags),
  collectionLoaderProvider.overrideWithValue(_data.load),
  downloadItemsProvider.overrideWith(SampleDownloadItems.new),
  downloadManagerProvider.overrideWith(
    (ref) => SampleDownloadManager(
      () => ref.read(downloadItemsProvider.notifier) as SampleDownloadItems,
    ),
  ),
  booruDownloadsProvider.overrideWithValue(SampleBooruDownloads()),
  networkProbeBackendProvider.overrideWith(
    (ref) => NetworkProbeBackend(
      sources: ref.watch(booruServiceProvider).sources,
      read: () async => _routes(),
      refresh: () async => _routes(),
      probe: (id) async => SourceConnectionCheck(
        sourceId: id,
        apiAvailable: true,
        mediaAvailable: true,
      ),
      load: () => null,
      save: (_) async {},
    ),
  ),
  networkStatusProvider.overrideWith(_SampleNetworkStatus.new),
  proxySettingsProvider.overrideWith(_SampleProxySettings.new),
  proxyConnectivityProbeProvider.overrideWithValue(
    (_) async => const ProxyConnectivityResult(
      reachable: true,
      latency: Duration(milliseconds: 128),
    ),
  ),
  updateLookupProvider.overrideWithValue(() async => null),
];
