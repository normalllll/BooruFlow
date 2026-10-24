import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/features/downloads/widgets/download_artwork.dart';
import 'package:booruflow/features/posts/displayed_media_frame.dart';
import 'package:booruflow/features/posts/media_presentation.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/widgets/post_media.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_download.dart';
import 'package:booruflow/src/rust/api/booru_engine.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:booruflow/src/rust/booru/error.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';

import '../discovery/home_page_test.dart' show browseTestApp;
import '../discovery/search_interaction_test.dart' show testSource;

MediaVariant variant(MediaVariantKind kind, String ext, {MediaType? type}) =>
    MediaVariant(
      kind: kind,
      url: 'https://example.invalid/${kind.name}.$ext',
      extension_: ext,
      mediaType: type ?? mediaTypeForExtension(ext),
      width: 320,
      height: 240,
    );
Post mediaPost(List<MediaVariant> media) => Post(
  BooruPost(
    sourceId: 'danbooru',
    postId: '12408475',
    postKey: 'danbooru:12408475',
    rating: ContentRating.general,
    tags: const [],
    media: media,
    webUrl: 'https://danbooru.donmai.us/posts/12408475',
    flags: const PostFlags(
      hasChildren: false,
      isPending: false,
      isDeleted: false,
      isAiGenerated: false,
    ),
  ),
);

class _Store implements SettingsServiceStore {
  @override
  Map<String, dynamic> load() => {};
  @override
  Future<void> write(String key, dynamic value) async {}
}

class _Engine implements BooruEngine {
  final requested = <String>[];
  bool networkFailure = false;
  BooruPost? recovered;
  int metadataRequests = 0;
  @override
  Future<BooruPost> getPost({
    required String sourceId,
    required String postId,
  }) async {
    metadataRequests++;
    return recovered!;
  }

  @override
  Future<MediaRequest> prepareMediaUrl({
    required String sourceId,
    required String postId,
    required MediaVariantKind variant,
    required String url,
    required bool allowDiskCache,
  }) async {
    requested.add(url);
    if (networkFailure) {
      throw const BooruError(
        code: BooruErrorCode.network,
        userMessageKey: 'booru.error.network',
        diagnosticId: 'test',
      );
    }
    return MediaRequest(
      sourceId: sourceId,
      postId: postId,
      variant: variant,
      url: url,
      headers: const [],
      routeKey: 'test',
      cacheKey: url,
      authRevision: 0,
      routeRevision: 'test',
      allowDiskCache: false,
    );
  }

  @override
  Stream<MediaFetchEvent> streamMedia({required MediaRequest request}) async* {
    final bytes = request.url.endsWith('.avif')
        ? Uint8List.fromList([0, 1, 2])
        : base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
          );
    yield MediaFetchEvent.chunk(
      bytes: bytes,
      receivedBytesDecimal: '${bytes.length}',
      totalBytesDecimal: '${bytes.length}',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Service extends BooruService {
  @override
  final _Engine engine = _Engine();
}

void main() {
  for (final ext in ['jpg', 'png', 'webp', 'avif']) {
    test('$ext selects image variants and preserves the original download', () {
      final original = variant(MediaVariantKind.original, ext);
      final sample = variant(MediaVariantKind.sample, 'jpg');
      final post = mediaPost([
        variant(MediaVariantKind.thumbnail, 'jpg'),
        sample,
        original,
      ]);
      expect(postStageMedia(post), sample);
      expect(
        postImageVariants(
          post,
        ).every((media) => postMediaKind(media) == MediaKind.image),
        isTrue,
      );
      expect(post.originalMedia.extension_, ext);
    });
  }
  test(
    'GIF uses a static cover in grids and the original in stage/viewer/copy',
    () {
      final cover = variant(MediaVariantKind.thumbnail, 'jpg');
      final original = variant(MediaVariantKind.original, 'gif');
      final post = mediaPost([cover, original]);
      expect(postImageVariants(post).first, cover);
      for (final purpose in [
        PostMediaPurpose.stage,
        PostMediaPurpose.original,
        PostMediaPurpose.copy,
      ]) {
        expect(postImageVariants(post, purpose: purpose).first, original);
      }
    },
  );
  for (final (ext, type) in [
    ('mp4', MediaType.mp4),
    ('webm', MediaType.webm),
    ('mov', MediaType.otherVideo),
    ('zip', null),
  ]) {
    test('$ext never supplies video/archive bytes to image decoding', () {
      final cover = variant(MediaVariantKind.thumbnail, 'jpg');
      final post = mediaPost([
        cover,
        variant(MediaVariantKind.sample, 'webm'),
        variant(MediaVariantKind.original, ext, type: type),
      ]);
      expect(postMediaFormat(post), PostMediaFormat.video);
      for (final purpose in PostMediaPurpose.values) {
        expect(postImageVariants(post, purpose: purpose), [cover]);
      }
      expect(post.originalMedia.extension_, ext);
    });
  }
  for (final ext in ['swf', 'unknown']) {
    test('$ext has a deterministic unsupported state and retains its file', () {
      final post = mediaPost([
        variant(MediaVariantKind.thumbnail, 'jpg'),
        variant(MediaVariantKind.original, ext),
      ]);
      expect(postMediaFormat(post), PostMediaFormat.unsupported);
      expect(postImageVariants(post), isEmpty);
      expect(postStageMedia(post), isNull);
      expect(post.originalMedia.extension_, ext);
    });
  }
  test(
    'real Danbooru 12408475 API fixture selects the JPEG cover, not MP4 sample',
    () {
      final data =
          jsonDecode(
                File(
                  'test/fixtures/media/danbooru_12408475.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final post = mediaPost([
        MediaVariant(
          kind: MediaVariantKind.thumbnail,
          url: data['preview_file_url'] as String,
          mediaType: MediaType.jpeg,
        ),
        MediaVariant(
          kind: MediaVariantKind.sample,
          url: data['large_file_url'] as String,
          mediaType: MediaType.mp4,
        ),
        MediaVariant(
          kind: MediaVariantKind.original,
          url: data['file_url'] as String,
          mediaType: MediaType.mp4,
          extension_: 'mp4',
        ),
      ]);
      expect(postStageMedia(post)!.kind, MediaVariantKind.thumbnail);
      expect(postStageMedia(post)!.url, endsWith('.jpg'));
      expect(post.originalMedia.url, endsWith('.mp4'));
    },
  );

  late _Service service;
  setUp(() async {
    await SettingsService.initialize(store: _Store());
    LocaleSettings.setLocaleSync(AppLocale.en);
    service = _Service()..useSourcesForTesting([testSource('danbooru')]);
  });
  tearDown(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });
  Widget app(
    Post post, {
    PostMediaPurpose purpose = PostMediaPurpose.stage,
    DisplayedMediaFrame? frame,
  }) => ProviderScope(
    overrides: [booruServiceProvider.overrideWithValue(service)],
    child: browseTestApp(
      Center(
        child: SizedBox(
          width: 320,
          height: 240,
          child: PostMedia(post: post, purpose: purpose, displayedFrame: frame),
        ),
      ),
    ),
  );
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets(
    'copy uses the displayed AVIF fallback frame with no extra request and matching decoded dimensions',
    (tester) async {
      Uint8List? copied;
      final post = mediaPost([
        variant(MediaVariantKind.original, 'avif'),
        variant(MediaVariantKind.sample, 'jpg'),
      ]);
      final frame = DisplayedMediaFrame();
      addTearDown(frame.dispose);
      expect(frame.readyFor(post.postKey), isFalse);
      await expectLater(frame.copy(post.postKey), throwsStateError);
      await tester.pumpWidget(
        app(post, frame: frame, purpose: PostMediaPurpose.original),
      );
      await settle(tester);
      expect(frame.readyFor(post.postKey), isTrue);
      final before = List.of(service.engine.requested);
      await tester.runAsync(
        () => frame.copy(post.postKey, write: (bytes) async => copied = bytes),
      );
      expect(service.engine.requested, before);
      expect(before, [endsWith('.avif'), endsWith('.jpg')]);
      await tester.runAsync(() async {
        final codec = await ui.instantiateImageCodec(copied!);
        final image = (await codec.getNextFrame()).image;
        // The fixture is a 1×1 decoded image despite 320×240 metadata.
        expect((image.width, image.height), (1, 1));
        image.dispose();
        codec.dispose();
      });
      expect(copied!.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'restored video skips local image decoding and recovers an image cover from metadata',
    (tester) async {
      final folder = await tester.runAsync(
        () => Directory.systemTemp.createTemp('booruflow-video-cover-'),
      );
      final file = File('${folder!.path}/video.mp4');
      await tester.runAsync(() => file.writeAsBytes([0, 1, 2]));
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        await tester.runAsync(() async {
          await file.delete();
          await folder.delete();
        });
      });
      service.engine.recovered = mediaPost([
        variant(MediaVariantKind.thumbnail, 'jpg'),
        variant(MediaVariantKind.original, 'mp4'),
      ]).data;
      final restored = BooruDownloadItem(
        snapshot: DownloadTaskSnapshot(
          id: 'video',
          resourceId: 1,
          variantIndex: 0,
          title: '#1',
          filename: 'video.mp4',
          sourceId: 'danbooru',
          postId: '1',
          thumbnailUrl: 'https://example.invalid/old.mp4',
          status: DownloadStatus.downloaded,
          saveState: SaveState.saved,
          receivedBytes: 3,
          totalBytes: 3,
          progress: 1,
          localPath: file.path,
          error: null,
          log: null,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [booruServiceProvider.overrideWithValue(service)],
          child: browseTestApp(
            Center(
              child: SizedBox(
                width: 48,
                height: 48,
                child: DownloadArtwork(task: restored, decodeWidth: 48),
              ),
            ),
          ),
        ),
      );
      await settle(tester);
      expect(service.engine.metadataRequests, 1);
      expect(service.engine.requested, [endsWith('.jpg')]);
      final provider = tester
          .widget<FrostMediaFrame>(find.byType(FrostMediaFrame))
          .image;
      expect(provider, isNot(isA<FileImage>()));
      expect(find.byType(RawImage), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('video cover decodes and exposes the shared play action', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        mediaPost([
          variant(MediaVariantKind.thumbnail, 'jpg'),
          variant(MediaVariantKind.sample, 'mp4'),
          variant(MediaVariantKind.original, 'mp4'),
        ]),
      ),
    );
    await settle(tester);
    expect(service.engine.requested, [endsWith('.jpg')]);
    expect(find.byType(RawImage), findsWidgets);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is FrostButton &&
            widget.icon != null &&
            widget.label == t.frost.play,
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'unsupported types and videos without covers do not prepare or offer retry',
    (tester) async {
      for (final ext in ['mp4', 'swf', 'unknown']) {
        await tester.pumpWidget(
          app(mediaPost([variant(MediaVariantKind.original, ext)])),
        );
        await tester.pumpAndSettle();
        expect(service.engine.requested, isEmpty);
        expect(find.text(t.mediaError.previewUnsupported), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is FrostButton && widget.label == t.generic.retry,
          ),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets(
    'failed AVIF decoding falls back to the same post JPEG automatically',
    (tester) async {
      await tester.pumpWidget(
        app(
          mediaPost([
            variant(MediaVariantKind.original, 'avif'),
            variant(MediaVariantKind.sample, 'jpg'),
          ]),
          purpose: PostMediaPurpose.original,
        ),
      );
      await settle(tester);
      expect(service.engine.requested, [endsWith('.avif'), endsWith('.jpg')]);
      expect(find.byType(RawImage), findsWidgets);
      expect(find.text(t.mediaError.previewUnsupported), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'AVIF without a usable fallback is unsupported; network errors retain retry',
    (tester) async {
      await tester.pumpWidget(
        app(mediaPost([variant(MediaVariantKind.original, 'avif')])),
      );
      await settle(tester);
      expect(find.text(t.mediaError.previewUnsupported), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is FrostButton && widget.label == t.generic.retry,
        ),
        findsNothing,
      );
      await tester.pumpWidget(const SizedBox());
      service.engine.networkFailure = true;
      await tester.pumpWidget(
        app(mediaPost([variant(MediaVariantKind.original, 'png')])),
      );
      await settle(tester);
      expect(find.text(t.mediaError.previewUnsupported), findsNothing);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is FrostButton && widget.label == t.generic.retry,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
