import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/stage_image_presentation.dart';
import 'package:booruflow/features/posts/widgets/post_image_frame.dart';
import 'package:booruflow/features/posts/widgets/post_media.dart';
import 'package:booruflow/features/posts/widgets/rust_extended_network_image_provider.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:frost_ui/src/feedback/skeleton.dart';
import 'package:frost_ui/src/motion/_material_reveal.dart';
import '../../support/preseeded_media.dart';
import '../discovery/browse_v2_test.dart' show PendingMediaService, browsePost;
import '../discovery/home_page_test.dart' show browseTestApp;
import '../discovery/search_interaction_test.dart' show testSource;

class _Store implements SettingsServiceStore {
  @override
  Map<String, dynamic> load() => {};
  @override
  Future<void> write(String key, dynamic value) async {}
}

Future<void> seed(WidgetTester tester, ImageProvider provider) async {
  final info = await tester.runAsync(() async {
    final codec = await ui.instantiateImageCodec(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
    );
    final frame = await codec.getNextFrame();
    codec.dispose();
    return ImageInfo(image: frame.image);
  });
  PaintingBinding.instance.imageCache.putIfAbsent(
    provider,
    () => OneFrameImageStreamCompleter(Future.value(info!)),
  );
  await tester.pump();
}

const _request = MediaRequest(
  sourceId: 'yande',
  postId: '1',
  variant: MediaVariantKind.sample,
  url: 'https://example.invalid/sample.jpg',
  headers: [],
  routeKey: 'route',
  cacheKey: 'handoff',
  authRevision: 0,
  routeRevision: '0',
  allowDiskCache: false,
);

class _DelayedPreview extends ImageProvider<_DelayedPreview> {
  final frames = <Completer<ImageInfo>>[];
  @override
  Future<_DelayedPreview> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);
  @override
  ImageStreamCompleter loadImage(
    _DelayedPreview key,
    ImageDecoderCallback decode,
  ) {
    final pending = Completer<ImageInfo>();
    frames.add(pending);
    return OneFrameImageStreamCompleter(pending.future);
  }
}

void main() {
  late PendingMediaService service;
  setUp(() async {
    await SettingsService.initialize(store: _Store());
    service = PendingMediaService()
      ..useSourcesForTesting([testSource('yande')]);
  });
  tearDown(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });
  Widget app(Widget child) => ProviderScope(
    overrides: [booruServiceProvider.overrideWithValue(service)],
    child: browseTestApp(
      Center(child: SizedBox(width: 240, height: 320, child: child)),
    ),
  );

  testWidgets(
    'visited streams reuse preparation only within the current authentication cache',
    (tester) async {
      final post = Post(browsePost(1));
      final presentation = StageImagePresentation(post: post);
      const provider = RustExtendedNetworkImageProvider(
        mediaStream: preseededMedia,
        request: _request,
      );
      await seed(tester, provider);
      var visible = true;
      late StateSetter update;
      await tester.pumpWidget(
        app(
          StatefulBuilder(
            builder: (_, set) {
              update = set;
              return visible
                  ? PostMedia(post: post, presentation: presentation)
                  : const SizedBox();
            },
          ),
        ),
      );
      expect(service.mediaEngine.pending, hasLength(1));
      service.mediaEngine.pending.single.complete(_request);
      await tester.pump();
      await tester.pump();
      expect(presentation.preview, provider);
      update(() => visible = false);
      await tester.pump();
      update(() => visible = true);
      await tester.pump();
      await tester.pump();
      expect(
        service.mediaEngine.pending,
        hasLength(1),
        reason: 'returning to a visited member reuses its stream',
      );
      service.notifyChanged();
      await tester.pump();
      await tester.pump();
      expect(
        service.mediaEngine.pending,
        hasLength(2),
        reason: 'a session revision must prepare a new authenticated request',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      presentation.dispose();
    },
  );

  for (final dimensions in [
    const Size(400, 200),
    const Size(200, 400),
    const Size(1080, 1915),
    const Size(128, 1024),
  ]) {
    testWidgets(
      'R3 decoded geometry $dimensions replaces metadata with one natural media rectangle',
      (tester) async {
        const provider = RustExtendedNetworkImageProvider(
          mediaStream: preseededMedia,
          request: _request,
          decodeWidth: 240,
        );
        final decoded = Completer<ImageInfo>();
        PaintingBinding.instance.imageCache.putIfAbsent(
          provider,
          () => OneFrameImageStreamCompleter(decoded.future),
        );
        final post = Post(browsePost(1));
        final hero = FrostMediaHeroTag(
          image: provider,
          aspectRatio: post.aspectRatio,
          sourceRadius: BorderRadius.zero,
        );
        await tester.pumpWidget(
          app(
            SingleChildScrollView(
              child: Column(
                children: [
                  PostMedia(
                    post: post,
                    decodeWidth: 240,
                    fit: BoxFit.contain,
                    stageBuilder: (_, ratio, child) =>
                        FrostMediaStage(aspectRatio: ratio, child: child),
                    frameBuilder: (child) => FrostMediaHero(
                      tag: hero,
                      radius: BorderRadius.zero,
                      fit: BoxFit.contain,
                      child: child,
                    ),
                  ),
                  const Text('After media'),
                ],
              ),
            ),
          ),
        );
        final frames = find.byType(FrostMediaFrame);
        final initial = tester.getSize(frames.first);
        expect(
          initial.width / initial.height,
          closeTo(post.aspectRatio, .00001),
        );
        service.mediaEngine.pending.single.complete(_request);
        await tester.pump();
        final image = (await tester.runAsync(() async {
          final recorder = ui.PictureRecorder();
          ui.Canvas(
            recorder,
          ).drawColor(const ui.Color(0xff24b0cc), ui.BlendMode.src);
          final picture = recorder.endRecording();
          final image = await picture.toImage(
            dimensions.width.toInt(),
            dimensions.height.toInt(),
          );
          picture.dispose();
          return image;
        }))!;
        decoded.complete(ImageInfo(image: image));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        final middle = tester.getSize(frames.first).height;
        final target = 240 * dimensions.height / dimensions.width;
        if ((target - initial.height).abs() > 1) {
          expect(
            middle,
            greaterThan(initial.height < target ? initial.height : target),
          );
          expect(
            middle,
            lessThan(initial.height > target ? initial.height : target),
          );
        }
        await tester.pumpAndSettle();
        expect(frames, findsOneWidget);
        expect(tester.getSize(frames), Size(240, target));
        expect(tester.getRect(find.byType(RawImage)), tester.getRect(frames));
        expect(
          tester.widget<PostImageFrame>(find.byType(PostImageFrame)).provider,
          provider,
        );
        expect(service.mediaEngine.pending, hasLength(1));
        if (target > 320) {
          await tester.drag(
            find.byType(SingleChildScrollView),
            const Offset(0, -3000),
          );
          await tester.pumpAndSettle();
          expect(find.text('After media').hitTestable(), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('decoded preview and target Hero are present on the first frame', (
    tester,
  ) async {
    final preview = MemoryImage(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
    );
    await seed(tester, preview);
    final tag = FrostMediaHeroTag(
      image: preview,
      aspectRatio: .75,
      sourceRadius: FrostRadius.borderRadius(FrostRadius.lg),
    );
    await tester.pumpWidget(
      app(
        PostMedia(
          post: Post(browsePost(1)),
          preview: preview,
          fit: BoxFit.contain,
          frameBuilder: (image) => FrostMediaHero(
            tag: tag,
            radius: FrostRadius.borderRadius(FrostRadius.lg),
            fit: BoxFit.contain,
            child: image,
          ),
        ),
      ),
    );
    expect(find.byType(FrostMediaHero), findsOneWidget);
    final pixels = tester.renderObject<RenderImage>(find.byType(RawImage));
    expect(pixels.image, isNotNull);
    expect(tester.widget<Image>(find.byType(Image)).fit, BoxFit.contain);
    expect(service.mediaEngine.pending, hasLength(1));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'ready notification comes directly from a load event outside build and flight child has no loading fade',
    (tester) async {
      const provider = RustExtendedNetworkImageProvider(
        mediaStream: preseededMedia,
        request: _request,
      );
      await seed(tester, provider);
      final received = <ImageProvider?>[];
      final phases = <SchedulerPhase>[];
      await tester.pumpWidget(
        app(
          PostMedia(
            post: Post(browsePost(1)),
            onImageReady: (image) {
              received.add(image);
              phases.add(SchedulerBinding.instance.schedulerPhase);
            },
            frameBuilder: (image) => KeyedSubtree(
              key: const ValueKey('decoded-flight'),
              child: image,
            ),
          ),
        ),
      );
      service.mediaEngine.pending.single.complete(_request);
      await tester.pump();
      await tester.pump();
      expect(received.whereType<ImageProvider>().single, provider);
      expect(
        phases.every((phase) => phase != SchedulerPhase.persistentCallbacks),
        isTrue,
      );
      final frame = find.byKey(const ValueKey('decoded-flight'));
      expect(frame, findsOneWidget);
      expect(
        find.descendant(
          of: frame,
          matching: find.byType(TweenAnimationBuilder<double>),
        ),
        findsNothing,
      );
      expect(
        tester
            .renderObject<RenderImage>(
              find.descendant(of: frame, matching: find.byType(RawImage)),
            )
            .image,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'failed original preserves preview and recovery actions; unmount discards pending readiness',
    (tester) async {
      final preview = MemoryImage(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        ),
      );
      await seed(tester, preview);
      final received = <ImageProvider?>[];
      await tester.pumpWidget(
        app(
          PostMedia(
            post: Post(browsePost(1)),
            preview: preview,
            onImageReady: received.add,
          ),
        ),
      );
      service.mediaEngine.pending.single.completeError(
        StateError('original failed'),
      );
      await tester.pump();
      expect(find.byType(RawImage), findsWidgets);
      expect(find.byType(FrostSurface), findsWidgets);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is FrostButton && widget.icon != null,
        ),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        app(PostMedia(post: Post(browsePost(2)), onImageReady: received.add)),
      );
      await tester.pumpWidget(const SizedBox());
      final count = received.length;
      service.mediaEngine.pending.last.completeError(StateError('disposed'));
      await tester.pump();
      expect(received, hasLength(count));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'layout width and metadata changes retain the live decode without another preparation',
    (tester) async {
      const provider = RustExtendedNetworkImageProvider(
        mediaStream: preseededMedia,
        request: _request,
        decodeWidth: 200,
      );
      await seed(tester, provider);
      var width = 200;
      late StateSetter update;
      final received = <ImageProvider?>[];
      await tester.pumpWidget(
        app(
          StatefulBuilder(
            builder: (_, setState) {
              update = setState;
              return PostMedia(
                post: Post(browsePost(1)),
                decodeWidth: width,
                onImageReady: received.add,
              );
            },
          ),
        ),
      );
      service.mediaEngine.pending.single.complete(_request);
      await tester.pump();
      await tester.pump();
      final state = tester.state(find.byType(PostMedia));
      final image = tester
          .renderObject<RenderImage>(find.byType(RawImage))
          .image;
      final count = received.length;
      for (final next in [180, 160, 140, 120, 220, 350, 200]) {
        update(() => width = next);
        await tester.pump();
        expect(tester.state(find.byType(PostMedia)), same(state));
        expect(
          tester.renderObject<RenderImage>(find.byType(RawImage)).image,
          same(image),
        );
        expect(
          tester.widget<PostImageFrame>(find.byType(PostImageFrame)).provider,
          provider,
        );
        expect(service.mediaEngine.pending, hasLength(1));
        expect(received, hasLength(count));
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'a decoded original immediately sharpens pixels inside one stable Hero',
    (tester) async {
      final preview = MemoryImage(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        ),
      );
      await seed(tester, preview);
      final tag = FrostMediaHeroTag(
        image: preview,
        aspectRatio: .75,
        sourceRadius: BorderRadius.zero,
      );
      const originalRequest = MediaRequest(
        sourceId: 'yande',
        postId: '1',
        variant: MediaVariantKind.original,
        url: 'https://example.invalid/original.png',
        headers: [],
        routeKey: 'route',
        cacheKey: 'original-handoff',
        authRevision: 0,
        routeRevision: '0',
        allowDiskCache: false,
      );
      const provider = RustExtendedNetworkImageProvider(
        mediaStream: preseededMedia,
        request: originalRequest,
      );
      final decoded = Completer<ImageInfo>();
      PaintingBinding.instance.imageCache.putIfAbsent(
        provider,
        () => OneFrameImageStreamCompleter(decoded.future),
      );
      await tester.pumpWidget(
        app(
          PostMedia(
            post: Post(browsePost(1)),
            preview: preview,
            frameBuilder: (image) => FrostMediaHero(
              tag: tag,
              radius: BorderRadius.zero,
              child: image,
            ),
            media: const MediaVariant(
              kind: MediaVariantKind.original,
              url: 'https://example.invalid/original.png',
            ),
          ),
        ),
      );
      service.mediaEngine.pending.single.complete(originalRequest);
      await tester.pump();
      expect(
        tester.renderObject<RenderImage>(find.byType(RawImage)).image!.width,
        1,
      );
      final before = tester
          .widget<FrostLayoutCrossfade>(find.byType(FrostLayoutCrossfade))
          .layoutIdentity;
      final heroState = tester.state(find.byType(FrostMediaHero));
      final original = await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        ui.Canvas(
          recorder,
        ).drawColor(const ui.Color(0xff24b0cc), ui.BlendMode.src);
        final picture = recorder.endRecording();
        final image = await picture.toImage(40, 30);
        picture.dispose();
        return image;
      });
      decoded.complete(ImageInfo(image: original!));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.byType(FrostMediaHero), findsOneWidget);
      for (final fade
          in find
              .ancestor(
                of: find.byType(RawImage),
                matching: find.byType(FrostContentFade),
              )
              .evaluate()) {
        expect((fade.renderObject! as RenderFrostContentFade).opacity, 1);
      }
      expect(tester.state(find.byType(FrostMediaHero)), same(heroState));
      expect(
        find.descendant(
          of: find.byType(FrostMediaHero),
          matching: find.byType(FrostLayoutCrossfade),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FrostLayoutCrossfade>(find.byType(FrostLayoutCrossfade))
            .layoutIdentity,
        before,
      );
      final pixels = tester
          .renderObject<RenderImage>(find.byType(RawImage))
          .image!;
      expect(pixels.width, 40);
      expect(pixels.height, 30);
      expect(
        tester.widget<PostImageFrame>(find.byType(PostImageFrame)).provider,
        provider,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'mobile returned preview reuses its retained pixels after cache eviction',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final preview = _DelayedPreview();
      var visible = true;
      late StateSetter update;
      await tester.pumpWidget(
        app(
          StatefulBuilder(
            builder: (_, set) {
              update = set;
              return PostMedia(
                post: Post(browsePost(1)),
                preview: preview,
                frameBuilder: (child) => visible ? child : const SizedBox(),
              );
            },
          ),
        ),
      );
      expect(find.byType(FrostSkeletonLeaf), findsWidgets);
      final image = await tester.runAsync(() async {
        final codec = await ui.instantiateImageCodec(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
          ),
        );
        final frame = await codec.getNextFrame();
        codec.dispose();
        return frame.image;
      });
      preview.frames.single.complete(ImageInfo(image: image!));
      await tester.pumpAndSettle();
      expect(
        tester.renderObject<RenderImage>(find.byType(RawImage)).image,
        isNotNull,
      );
      // A Hero flight unmounts its image child while PostMedia itself retains
      // its live subscription. Force a cache eviction during that interval.
      update(() => visible = false);
      await tester.pump();
      PaintingBinding.instance.imageCache.evict(preview);
      update(() => visible = true);
      await tester.pump();
      expect(preview.frames, hasLength(1));
      expect(find.byType(FrostSkeletonLeaf), findsNothing);
      expect(
        tester
            .renderObject<RenderImage>(find.byType(RawImage))
            .image!
            .isCloneOf(image),
        isTrue,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
