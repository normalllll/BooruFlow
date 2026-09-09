import 'dart:async';
import 'dart:io';

import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/booru/models/web_challenge_failure.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/booru/web_challenge_page.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_engine.dart';
import 'package:booruflow/src/rust/api/web_challenge.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
  _RustChallengeBackend(this._engine);
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
class WebChallengeService {
  WebChallengeService(BooruService service)
    : _backendFactory = (() => _RustChallengeBackend(service.engine)),
      _platformChecks = true,
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
      _changed = service.recordWebChallengeChanges,
      _cleanup = clearEmbeddedWebData;

  @visibleForTesting
  WebChallengeService.forTesting({
    required WebChallengeBackend Function() backendFactory,
    required WebChallengeCollector collector,
    required Future<void> Function(List<String>) changed,
    Future<void> Function()? cleanup,
    bool nativeWindow = false,
    // Public parameter names keep test callers independent of private fields.
    // ignore: prefer_initializing_formals
  }) : _platformChecks = false,
       // ignore: prefer_initializing_formals
       _backendFactory = backendFactory,
       // ignore: prefer_initializing_formals
       _collector = collector,
       // ignore: prefer_initializing_formals
       _changed = changed,
       _cleanup = cleanup ?? (() async {}),
       // ignore: prefer_initializing_formals
       _nativeWindow = nativeWindow;

  final bool _platformChecks;
  final WebChallengeBackend Function() _backendFactory;
  final WebChallengeCollector _collector;
  final Future<void> Function(List<String>) _changed;
  final Future<void> Function() _cleanup;
  final bool _nativeWindow;
  final _changes = StreamController<WebChallengeSessionState>.broadcast(
    sync: true,
  );
  Stream<WebChallengeSessionState> get changes => _changes.stream;
  WebChallengeActivity? _activity;
  bool _clearing = false;
  WebChallengeSessionState get session =>
      WebChallengeSessionState(activity: _activity, clearing: _clearing);
  WebChallengeActivity? get activity => _activity;
  set activity(WebChallengeActivity? value) {
    _activity = value;
    _changes.add(session);
  }

  bool get clearing => _clearing;
  set clearing(bool value) {
    _clearing = value;
    _changes.add(session);
  }

  final _cancellation = ValueNotifier<int>(0);
  int _generation = 0;
  String? _operationId;
  WebChallengeBackend? _activeBackend;
  Completer<void>? _closed;

  Future<bool> resolve(BuildContext context, String sourceId) async {
    if (activity != null || clearing) {
      throw const WebChallengeFailure('busy');
    }
    if (_platformChecks &&
        !_nativeWindow &&
        (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS)) {
      throw const WebChallengeFailure('webViewUnavailable');
    }
    if (_platformChecks && !_nativeWindow && SettingsService.proxyUrl != null) {
      throw const WebChallengeFailure('proxyUnsupported');
    }
    final generation = ++_generation;
    final backend = _backendFactory();
    _activeBackend = backend;
    final closed = Completer<void>();
    _closed = closed;
    activity = WebChallengeActivity(sourceId, WebChallengePhase.opening);
    try {
      final operation = await backend.begin(sourceId);
      _operationId = operation.operationId;
      if (generation != _generation || !context.mounted) return false;
      activity = WebChallengeActivity(sourceId, WebChallengePhase.waiting);
      if (_nativeWindow) {
        await backend.runWindow(operation);
      } else {
        final captured = await _collector(context, operation, _cancellation);
        if (captured is WebChallengeFailure) throw captured;
        if (generation != _generation || captured == null) return false;
        if (captured is! WebChallengeCandidate) {
          throw const WebChallengeFailure('captureFailed');
        }
        activity = WebChallengeActivity(sourceId, WebChallengePhase.verifying);
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
      activity = null;
    }
  }

  Future<void> clearSources(Iterable<String> sources) async {
    if (clearing) throw const WebChallengeFailure('busy');
    clearing = true;
    final ids = sources.toSet().toList();
    final affectsBrowser = ids.contains(activity?.sourceId);
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
      if (activity == null) {
        try {
          await _cleanup();
        } catch (_) {
          failure ??= const WebChallengeFailure('cleanupFailed');
        }
      }
      if (cleared.isNotEmpty) await _changed(cleared);
      if (failure != null) throw failure;
    } finally {
      clearing = false;
    }
  }
}

class WebChallengeSessionState {
  const WebChallengeSessionState({this.activity, this.clearing = false});
  final WebChallengeActivity? activity;
  final bool clearing;
}
