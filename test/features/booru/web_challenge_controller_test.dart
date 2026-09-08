import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:booruflow/features/booru/web_challenge_controller.dart';
import 'package:booruflow/features/booru/web_challenge_failure.dart';
import 'package:booruflow/src/rust/api/web_challenge.dart';

const candidate = WebChallengeCandidate(
  cookies: [],
  snapshots: [],
  userAgent: 'fixture',
);
const state = WebChallengeState(
  sourceId: 'konachan_com',
  hasSavedData: true,
  verified: true,
  revision: 1,
);

class Backend implements WebChallengeBackend {
  final cancelled = <String>[];
  final cleared = <String>[];
  int completions = 0;
  Object? failure;
  @override
  Future<WebChallengeOperation> begin(String sourceId) async =>
      WebChallengeOperation(
        operationId: 'operation',
        spec: WebChallengeSpec(
          sourceId: sourceId,
          displayName: sourceId,
          entryUrl: 'https://konachan.com/',
          navigationHosts: const ['konachan.com'],
          captureTargets: const [],
          timeoutSeconds: 600,
        ),
      );
  @override
  Future<WebChallengeState> complete(
    String id,
    WebChallengeCandidate candidate,
  ) async {
    completions++;
    if (failure != null) throw failure!;
    return state;
  }

  @override
  Future<WebChallengeState> runWindow(WebChallengeOperation operation) async =>
      state;
  @override
  Future<void> cancel(String id) async {
    cancelled.add(id);
  }

  @override
  Future<void> clear(String sourceId) async {
    cleared.add(sourceId);
  }
}

void main() {
  testWidgets(
    'successful capture publishes once and releases global activity',
    (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (value) {
              context = value;
              return const SizedBox();
            },
          ),
        ),
      );
      final backend = Backend();
      final changes = <String>[];
      var cleanups = 0;
      final controller = WebChallengeController.forTesting(
        backendFactory: () => backend,
        collector: (_, _, _) async => candidate,
        changed: (ids) async => changes.addAll(ids),
        cleanup: () async {
          cleanups++;
        },
      );
      expect(await controller.resolve(context, 'konachan_com'), isTrue);
      expect(backend.completions, 1);
      expect(changes, ['konachan_com']);
      expect(cleanups, 1);
      expect(controller.activity.value, isNull);
    },
  );

  testWidgets('clear cancels open collector and rejects its late candidate', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (value) {
            context = value;
            return const SizedBox();
          },
        ),
      ),
    );
    final backend = Backend();
    final capture = Completer<Object?>();
    final changes = <String>[];
    final controller = WebChallengeController.forTesting(
      backendFactory: () => backend,
      collector: (_, _, _) => capture.future,
      changed: (ids) async => changes.addAll(ids),
    );
    final pending = controller.resolve(context, 'konachan_com');
    await tester.pump();
    await expectLater(
      controller.resolve(context, 'yande'),
      throwsA(isA<WebChallengeFailure>()),
    );
    final clearing = controller.clearSources(['konachan_com']);
    capture.complete(candidate);
    expect(await pending, isFalse);
    await clearing;
    expect(backend.completions, 0);
    expect(backend.cleared, ['konachan_com']);
    expect(changes, ['konachan_com']);
    expect(controller.activity.value, isNull);
    expect(controller.clearing.value, isFalse);
  });

  testWidgets('verification failure releases activity without publishing', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (value) {
            context = value;
            return const SizedBox();
          },
        ),
      ),
    );
    final backend = Backend()
      ..failure = const WebChallengeFailure('verificationFailed');
    final changes = <String>[];
    final controller = WebChallengeController.forTesting(
      backendFactory: () => backend,
      collector: (_, _, _) async => candidate,
      changed: (ids) async => changes.addAll(ids),
    );
    await expectLater(
      controller.resolve(context, 'konachan_com'),
      throwsA(isA<WebChallengeFailure>()),
    );
    expect(changes, isEmpty);
    expect(controller.activity.value, isNull);
    backend.failure = null;
    expect(await controller.resolve(context, 'konachan_com'), isTrue);
  });
}
