import 'dart:async';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/posts/media_presentation.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/video_playback.dart';
import 'package:booruflow/features/posts/widgets/post_video.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import '../discovery/home_page_test.dart' show browseTestApp;
import '../discovery/search_interaction_test.dart' show testSource;
import 'media_type_presentation_test.dart' show mediaPost, variant;

class FakePlayback extends PostPlayback {
  bool closed = false, playing = true, looping = true, muted = false;
  int seeks = 0, toggles = 0;
  Duration position = Duration.zero;
  Completer<void>? opening, closing;
  PostPlaybackFailure? fail;
  bool? audio = true;
  @override
  bool? get hasAudio => audio;
  @override
  FrostVideoState get state => FrostVideoState(
    playing: playing,
    looping: looping,
    muted: muted,
    position: position,
    duration: const Duration(seconds: 30),
  );
  @override
  double? get aspectRatio => 2;
  @override
  bool get ready => true;
  @override
  PostPlaybackFailure? get failure => fail;
  @override
  Widget buildVideo(BuildContext context) =>
      const SizedBox.expand(key: ValueKey('decoded-video'));
  @override
  Future<void> open(
    Post post,
    MediaVariant media, {
    required bool looping,
    required Duration position,
    bool muted = false,
  }) async {
    this.looping = looping;
    this.position = position;
    this.muted = muted;
    await opening?.future;
  }

  @override
  Future<void> playPause() async {
    toggles++;
    playing = !playing;
    notifyListeners();
  }

  @override
  Future<void> seek(Duration position) async {
    seeks++;
    this.position = position;
    notifyListeners();
  }

  @override
  Future<void> toggleMute() async {
    muted = !muted;
    notifyListeners();
  }

  @override
  Future<void> setLoop(bool value) async {
    looping = value;
    notifyListeners();
  }

  @override
  Future<void> close() async {
    if (closing case final pending?) await pending.future;
    closed = true;
  }

  void failureNow(bool unsupported) {
    fail = PostPlaybackFailure(
      StateError('test codec'),
      unsupported: unsupported,
    );
    notifyListeners();
  }
}

void main() {
  test(
    'readiness requires a current frame, including paused/nonzero/loop cases',
    () async {
      for (final description in ['paused', 'nonzero', 'loop through zero']) {
        var current = false, completed = false;
        final closed = Completer<void>();
        final ready = waitForVideoFrame(
          surfaceReady: Future.value(),
          hasCurrentFrame: () async => current,
          closed: closed.future,
        );
        unawaited(ready.then((_) => completed = true));
        await Future<void>.delayed(const Duration(milliseconds: 5));
        expect(completed, false, reason: description);
        current = true;
        expect(await ready, true, reason: description);
      }
    },
  );
  test(
    'a missing first frame times out and closing cancels readiness',
    () async {
      await expectLater(
        waitForVideoFrame(
          surfaceReady: Future.value(),
          hasCurrentFrame: () async => false,
          closed: Completer<void>().future,
          timeout: const Duration(milliseconds: 20),
        ),
        throwsA(isA<TimeoutException>()),
      );
      final closed = Completer<void>();
      final ready = waitForVideoFrame(
        surfaceReady: Completer<void>().future,
        hasCurrentFrame: () async => false,
        closed: closed.future,
      );
      closed.complete();
      expect(await ready, false);
    },
  );

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
    BooruService.instance.useSourcesForTesting([testSource('danbooru')]);
  });
  final post = mediaPost([variant(MediaVariantKind.original, 'mp4')]);
  Future<ProviderContainer> mount(
    WidgetTester tester,
    List<FakePlayback> created, {
    Completer<void>? pending,
    Widget Function(Widget)? wrap,
    void Function(Duration, bool)? onFullscreen,
    Duration? initialPosition,
    bool initialMuted = false,
    bool? hasAudio = true,
  }) async {
    final container = ProviderContainer(
      overrides: [
        postPlaybackFactoryProvider.overrideWithValue(() {
          final playback = FakePlayback()
            ..opening = pending
            ..audio = hasAudio;
          created.add(playback);
          return playback;
        }),
      ],
    );
    addTearDown(container.dispose);
    final video = PostVideo(
      post: post,
      onFullscreen: onFullscreen,
      initialPosition: initialPosition,
      initialMuted: initialMuted,
      cover: (start) => FrostButton(label: 'start', onPressed: start),
      stage: (_, child) => SizedBox(width: 700, height: 320, child: child),
    );
    await tester.pumpWidget(
      browseTestApp(
        UncontrolledProviderScope(
          container: container,
          child: wrap?.call(video) ?? video,
        ),
      ),
    );
    await tester.pump();
    return container;
  }

  test(
    'ugoira plays WebM sample while original archive remains a download',
    () {
      final archive = variant(MediaVariantKind.original, 'zip');
      final sample = variant(MediaVariantKind.sample, 'webm');
      expect(postPlaybackMedia(mediaPost([archive, sample])), sample);
      expect(postPlaybackMedia(mediaPost([archive])), isNull);
      expect(
        postPlaybackMedia(
          mediaPost([variant(MediaVariantKind.original, 'swf')]),
        ),
        isNull,
      );
      expect(
        unsupportedDecoderMessage('Failed to recognize file format'),
        true,
      );
      expect(unsupportedDecoderMessage('HTTP error 503'), false);
    },
  );
  testWidgets(
    'cover creates no decoder; click opens one with loop default on',
    (tester) async {
      final created = <FakePlayback>[];
      await mount(tester, created);
      expect(created, isEmpty);
      await tester.tap(find.text('start'));
      await tester.pump();
      expect(created, hasLength(1));
      expect(created.single.looping, true);
      expect(find.byType(FrostVideoFrame), findsOneWidget);
      expect(find.byKey(const ValueKey('decoded-video')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(created.single.closed, true);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Tab enters playback controls; keys seek once and mute without automatic focus transfer',
    (tester) async {
      final created = <FakePlayback>[];
      await mount(tester, created);
      await tester.tap(find.text('start'));
      await tester.pump();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(created.single.toggles, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(created.single.seeks, 1);
      expect(created.single.position, const Duration(seconds: 5));
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      await tester.pump();
      expect(created.single.muted, true);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
  testWidgets('a file without an audio track offers no mute control', (
    tester,
  ) async {
    final created = <FakePlayback>[];
    await mount(tester, created, hasAudio: false);
    await tester.tap(find.text('start'));
    await tester.pump();
    await tester.pump();
    expect(find.bySemanticsLabel(t.frost.mute), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
    await tester.pump();
    expect(created.single.muted, false);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
  testWidgets(
    'fullscreen snapshots position and mute; a new view resumes both',
    (tester) async {
      final created = <FakePlayback>[];
      Duration? position;
      bool? muted;
      await mount(
        tester,
        created,
        onFullscreen: (p, m) {
          position = p;
          muted = m;
        },
      );
      await tester.tap(find.text('start'));
      await tester.pump();
      await created.single.seek(const Duration(seconds: 7));
      await created.single.toggleMute();
      await tester.pump();
      tester
          .widget<FrostVideoFrame>(find.byType(FrostVideoFrame))
          .onFullscreenToggle!();
      await tester.pump();
      expect(position, const Duration(seconds: 7));
      expect(muted, true);
      expect(created.single.closed, true);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(created.single.closed, true);
      final resumed = <FakePlayback>[];
      await mount(
        tester,
        resumed,
        initialPosition: position,
        initialMuted: muted!,
      );
      await tester.pump();
      expect(resumed.single.position, position);
      expect(resumed.single.muted, true);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
  test('native fatal video output errors are not silently lost', () {
    expect(
      fatalVideoOutputLog(
        'vo/gpu/opengl',
        'fatal',
        'Could not create EGL context',
      ),
      true,
    );
    expect(
      fatalVideoOutputLog(
        'cplayer',
        'fatal',
        'Error opening/initializing the selected video_out (--vo) device.',
      ),
      true,
    );
    expect(
      fatalVideoOutputLog('vo/gpu', 'warn', 'temporary surface resize'),
      false,
    );
    expect(
      fatalVideoOutputLog('lavf', 'error', 'Failed to create file cache.'),
      false,
    );
  });
  testWidgets(
    'fullscreen awaits decoder disposal and ignores repeated requests',
    (tester) async {
      final created = <FakePlayback>[];
      var entered = 0;
      await mount(tester, created, onFullscreen: (_, _) => entered++);
      await tester.tap(find.text('start'));
      await tester.pump();
      final closed = Completer<void>();
      created.single.closing = closed;
      final enter = tester
          .widget<FrostVideoFrame>(find.byType(FrostVideoFrame))
          .onFullscreenToggle!;
      enter();
      enter();
      await tester.pump();
      expect(entered, 0);
      await tester.tap(find.text('start'));
      await tester.pump();
      expect(created, hasLength(1));
      closed.complete();
      await tester.pump();
      expect(entered, 1);
      expect(created.single.closed, true);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'cancelled handoff does not leave the detail play button locked',
    (tester) async {
      final created = <FakePlayback>[];
      var entered = 0;
      await mount(tester, created, onFullscreen: (_, _) => entered++);
      await tester.tap(find.text('start'));
      await tester.pump();
      final closed = Completer<void>();
      created.single.closing = closed;
      tester
          .widget<FrostVideoFrame>(find.byType(FrostVideoFrame))
          .onFullscreenToggle!();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      closed.complete();
      await tester.pump();
      expect(entered, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.tap(find.text('start'));
      await tester.pump();
      expect(created, hasLength(2));
      expect(created.last.closed, false);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'loop change survives session release but not a new runtime scope',
    (tester) async {
      final created = <FakePlayback>[];
      final container = await mount(tester, created);
      await tester.tap(find.text('start'));
      await tester.pump();
      final loop = find.byWidgetPredicate(
        (w) => w is FrostButton && w.label == 'Loop',
      );
      await tester.tap(loop);
      await tester.pump();
      expect(container.read(videoLoopPreferenceProvider), false);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(created.single.closed, true);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.tap(find.text('start'));
      await tester.pump();
      expect(created.last.looping, false);
      final newRuntime = ProviderContainer();
      expect(newRuntime.read(videoLoopPreferenceProvider), true);
      newRuntime.dispose();
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
  testWidgets(
    'background cancels pending open; late completion cannot restart player',
    (tester) async {
      final pending = Completer<void>(), created = <FakePlayback>[];
      await mount(tester, created, pending: pending);
      await tester.tap(find.text('start'));
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(created.single.closed, true);
      pending.complete();
      await tester.pump();
      expect(
        created,
        hasLength(1),
        reason: 'a late open cannot create another player',
      );
      expect(tester.binding.framesEnabled, isFalse);
      expect(created.single.closed, isTrue);
      // Paused applications do not render. Check the retained logical release
      // above, then its visible result when normal frame delivery resumes.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.byType(FrostVideoFrame), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
  for (final unsupported in [true, false]) {
    testWidgets(
      'error class unsupported=$unsupported preserves browser/details and only transient retry',
      (tester) async {
        final created = <FakePlayback>[];
        await mount(tester, created);
        await tester.tap(find.text('start'));
        await tester.pump();
        created.single.failureNow(unsupported);
        await tester.pump();
        expect(created.single.closed, true);
        expect(find.byType(FrostErrorDetails), findsOneWidget);
        expect(find.text('Open in browser'), findsOneWidget);
        expect(find.text('Retry'), unsupported ? findsNothing : findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('covered route releases its decoder immediately', (tester) async {
    final created = <FakePlayback>[];
    late BuildContext routeContext;
    await mount(
      tester,
      created,
      wrap: (video) => Builder(
        builder: (context) {
          routeContext = context;
          return video;
        },
      ),
    );
    await tester.tap(find.text('start'));
    await tester.pump();
    unawaited(
      Navigator.of(
        routeContext,
      ).push(MaterialPageRoute<void>(builder: (_) => const SizedBox())),
    );
    await tester.pump();
    expect(created.single.closed, true);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
