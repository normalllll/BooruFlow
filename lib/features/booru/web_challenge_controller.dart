import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:booruflow/core/settings_service.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_engine.dart';
import 'package:booruflow/src/rust/api/web_challenge.dart';
import 'booru_service.dart';
import 'web_challenge_failure.dart';
import 'web_challenge_page.dart';

enum WebChallengePhase { opening, waiting, verifying }

class WebChallengeActivity {
  const WebChallengeActivity(this.sourceId, this.phase);
  final String sourceId;
  final WebChallengePhase phase;
}

abstract interface class WebChallengeBackend {
  Future<WebChallengeOperation> begin(String sourceId);
  Future<WebChallengeState> runWindow(WebChallengeOperation operation);
  Future<WebChallengeState> complete(
    String id,
    WebChallengeCandidate candidate,
  );
  Future<void> cancel(String id);
  Future<void> clear(String sourceId);
}

class _RustChallengeBackend implements WebChallengeBackend {
  _RustChallengeBackend() : _engine = BooruService.instance.engine;
  // Keep the initiating engine. Rust rejects this operation if transport changes.
  final BooruEngine _engine;
  @override
  Future<WebChallengeOperation> begin(String sourceId) =>
      _engine.beginWebChallenge(sourceId: sourceId);
  @override
  Future<WebChallengeState> runWindow(WebChallengeOperation operation) =>
      _engine.runWindowsWebChallenge(
        operationId: operation.operationId,
        title: t.webChallenge.windowTitle(source: operation.spec.displayName),
        finishLabel: t.webChallenge.finish,
        cancelLabel: t.generic.cancel,
      );
  @override
  Future<WebChallengeState> complete(
    String id,
    WebChallengeCandidate candidate,
  ) => _engine.completeWebChallenge(operationId: id, candidate: candidate);
  @override
  Future<void> cancel(String id) => _engine.cancelWebChallenge(operationId: id);
  @override
  Future<void> clear(String sourceId) async {
    await _engine.clearWebChallenge(sourceId: sourceId);
  }
}

typedef WebChallengeCollector =
    Future<Object?> Function(
      BuildContext context,
      WebChallengeOperation operation,
      ValueListenable<int> cancellation,
    );

/// Owns the single browser lifecycle, including cleanup and late-result rejection.
class WebChallengeController {
  WebChallengeController._()
    : _backendFactory = _RustChallengeBackend.new,
      _nativeWindow = Platform.isWindows,
      _collector = ((context, operation, cancellation) =>
          Navigator.of(context, rootNavigator: true).push<Object?>(
            MaterialPageRoute<Object?>(
              fullscreenDialog: true,
              builder: (_) => WebChallengePage(
                operation: operation,
                cancellation: cancellation,
              ),
            ),
          )),
      _changed = BooruService.instance.recordWebChallengeChanges,
      _cleanup = clearEmbeddedWebData;

  @visibleForTesting
  WebChallengeController.forTesting({
    required WebChallengeBackend Function() backendFactory,
    required WebChallengeCollector collector,
    required Future<void> Function(List<String>) changed,
    Future<void> Function()? cleanup,
    bool nativeWindow = false,
    // Public parameter names keep test callers independent of private fields.
    // ignore: prefer_initializing_formals
  }) : _backendFactory = backendFactory,
       // ignore: prefer_initializing_formals
       _collector = collector,
       // ignore: prefer_initializing_formals
       _changed = changed,
       _cleanup = cleanup ?? (() async {}),
       // ignore: prefer_initializing_formals
       _nativeWindow = nativeWindow;

  static final instance = WebChallengeController._();
  final WebChallengeBackend Function() _backendFactory;
  final WebChallengeCollector _collector;
  final Future<void> Function(List<String>) _changed;
  final Future<void> Function() _cleanup;
  final bool _nativeWindow;
  final activity = ValueNotifier<WebChallengeActivity?>(null);
  final clearing = ValueNotifier<bool>(false);
  final _cancellation = ValueNotifier<int>(0);
  int _generation = 0;
  String? _operationId;
  WebChallengeBackend? _activeBackend;
  Completer<void>? _closed;

  Future<bool> resolve(BuildContext context, String sourceId) async {
    if (activity.value != null || clearing.value) {
      throw const WebChallengeFailure('busy');
    }
    if (identical(this, instance) &&
        !_nativeWindow &&
        (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS)) {
      throw const WebChallengeFailure('webViewUnavailable');
    }
    if (identical(this, instance) &&
        !_nativeWindow &&
        SettingsService.proxyUrl != null) {
      throw const WebChallengeFailure('proxyUnsupported');
    }
    final generation = ++_generation;
    final backend = _backendFactory();
    _activeBackend = backend;
    final closed = Completer<void>();
    _closed = closed;
    activity.value = WebChallengeActivity(sourceId, WebChallengePhase.opening);
    try {
      final operation = await backend.begin(sourceId);
      _operationId = operation.operationId;
      if (generation != _generation || !context.mounted) return false;
      activity.value = WebChallengeActivity(
        sourceId,
        WebChallengePhase.waiting,
      );
      if (_nativeWindow) {
        await backend.runWindow(operation);
      } else {
        final captured = await _collector(context, operation, _cancellation);
        if (captured is WebChallengeFailure) throw captured;
        if (generation != _generation || captured == null) return false;
        if (captured is! WebChallengeCandidate) {
          throw const WebChallengeFailure('captureFailed');
        }
        activity.value = WebChallengeActivity(
          sourceId,
          WebChallengePhase.verifying,
        );
        await backend.complete(operation.operationId, captured);
      }
      if (generation != _generation) return false;
      await _changed([sourceId]);
      return true;
    } finally {
      final id = _operationId;
      if (id != null) {
        try {
          await backend.cancel(id);
        } catch (_) {
          /* A committed result remains committed. */
        }
      }
      if (!_nativeWindow) {
        try {
          await _cleanup();
        } catch (_) {
          /* The page reports capture/cleanup failures itself. */
        }
      }
      _operationId = null;
      _activeBackend = null;
      _closed = null;
      closed.complete();
      activity.value = null;
    }
  }

  Future<void> clearSources(Iterable<String> sources) async {
    if (clearing.value) throw const WebChallengeFailure('busy');
    clearing.value = true;
    final ids = sources.toSet().toList();
    final affectsBrowser = ids.contains(activity.value?.sourceId);
    final closed = affectsBrowser ? _closed?.future : null;
    Object? failure;
    final cleared = <String>[];
    try {
      if (affectsBrowser) {
        _generation++;
        _cancellation.value++;
        final id = _operationId;
        if (id != null) {
          try {
            await _activeBackend?.cancel(id);
          } catch (error) {
            failure ??= error;
          }
        }
      }
      final backend = _backendFactory();
      for (final source in ids) {
        try {
          await backend.clear(source);
          cleared.add(source);
        } catch (error) {
          failure ??= error;
        }
      }
      if (closed != null) {
        try {
          await closed.timeout(const Duration(seconds: 30));
        } catch (_) {
          failure ??= const WebChallengeFailure('cleanupFailed');
        }
      }
      // Another source's open mobile browser must not be cleared accidentally.
      if (activity.value == null) {
        try {
          await _cleanup();
        } catch (_) {
          failure ??= const WebChallengeFailure('cleanupFailed');
        }
      }
      if (cleared.isNotEmpty) await _changed(cleared);
      if (failure != null) throw failure;
    } finally {
      clearing.value = false;
    }
  }
}
