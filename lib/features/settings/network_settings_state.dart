import 'dart:async';
import 'dart:convert';

import 'package:booruflow/core/settings_service.dart';
import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/features/booru/booru_service.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NetworkProbeBackend {
  const NetworkProbeBackend({
    required this.sources,
    required this.read,
    required this.refresh,
    required this.probe,
    required this.load,
    required this.save,
  });
  final List<BooruSource> sources;
  final Future<RouteCacheState> Function() read;
  final Future<RouteCacheState> Function() refresh;
  final Future<SourceConnectionCheck> Function(String) probe;
  final String? Function() load;
  final Future<void> Function(String) save;
}

final networkProbeBackendProvider = Provider<NetworkProbeBackend>((ref) {
  final service = BooruService.instance;
  return NetworkProbeBackend(
    sources: service.sources,
    read: () => service.engine.routeCacheState(),
    refresh: service.refreshNetworkRoutes,
    probe: (id) => service.engine.probeSourceConnection(sourceId: id),
    load: () => SettingsService.savedNetworkChecks,
    save: SettingsService.saveNetworkChecks,
  );
});

class NetworkStatusState {
  const NetworkStatusState({
    this.routes,
    this.checks = const {},
    this.details = const {},
    this.errors = const {},
    this.busy = false,
    this.error,
  });
  final RouteCacheState? routes;
  final Map<String, String> checks;
  final Map<String, SourceConnectionCheck> details;
  final Map<String, String> errors;
  final bool busy;
  final String? error;
  NetworkStatusState copyWith({
    RouteCacheState? routes,
    Map<String, String>? checks,
    Map<String, SourceConnectionCheck>? details,
    Map<String, String>? errors,
    bool? busy,
    String? error,
    bool clearError = false,
  }) => NetworkStatusState(
    routes: routes ?? this.routes,
    checks: checks ?? this.checks,
    details: details ?? this.details,
    errors: errors ?? this.errors,
    busy: busy ?? this.busy,
    error: clearError ? null : error ?? this.error,
  );
}

// Deliberately not auto-disposed: navigation must not discard completed probes.
final networkStatusProvider =
    NotifierProvider<NetworkStatusController, NetworkStatusState>(
      NetworkStatusController.new,
    );

class NetworkStatusController extends Notifier<NetworkStatusState> {
  Timer? _poll;
  int _listeners = 0;
  bool _reading = false;
  final _saved = <String, Map<String, dynamic>>{};
  Future<void> _writes = Future.value();
  NetworkProbeBackend get _backend => ref.read(networkProbeBackendProvider);

  @override
  NetworkStatusState build() {
    ref.onDispose(() => _poll?.cancel());
    final checks = <String, String>{};
    final details = <String, SourceConnectionCheck>{};
    final errors = <String, String>{};
    try {
      final decoded = jsonDecode(_backend.load() ?? '{}');
      if (decoded is Map) {
        for (final source in _backend.sources) {
          final entry = decoded[source.sourceId];
          if (entry is! Map ||
              !['available', 'partial', 'failed'].contains(entry['status'])) {
            continue;
          }
          final id = source.sourceId;
          checks[id] = entry['status'] as String;
          if (entry['api'] is bool && entry['media'] is bool) {
            details[id] = SourceConnectionCheck(
              sourceId: id,
              apiAvailable: entry['api'] as bool,
              mediaAvailable: entry['media'] as bool,
            );
          }
          if (entry['error'] is String) errors[id] = entry['error'] as String;
          _saved[id] = Map<String, dynamic>.from(entry);
        }
      }
    } on FormatException {
      // A damaged cache cannot prevent opening network settings.
    }
    return NetworkStatusState(checks: checks, details: details, errors: errors);
  }

  void attach() {
    if (_listeners++ != 0) return;
    unawaited(readRoutes());
    _poll = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => readRoutes(),
    );
  }

  void detach() {
    if (_listeners > 0 && --_listeners == 0) {
      _poll?.cancel();
      _poll = null;
    }
  }

  Future<void> readRoutes() async {
    if (_reading) return;
    _reading = true;
    try {
      final routes = await _backend.read().timeout(const Duration(seconds: 3));
      if (ref.mounted) state = state.copyWith(routes: routes);
    } catch (error) {
      if (ref.mounted) state = state.copyWith(error: describeBooruError(error));
    } finally {
      _reading = false;
    }
  }

  Future<void> refreshRoutes() async {
    if (state.busy || ref.read(networkConfigProvider).busy) return;
    state = state.copyWith(busy: true, clearError: true);
    try {
      final routes = await _backend.refresh().timeout(
        const Duration(seconds: 45),
      );
      if (ref.mounted) state = state.copyWith(routes: routes);
    } catch (error) {
      if (ref.mounted) state = state.copyWith(error: describeBooruError(error));
    } finally {
      if (ref.mounted) state = state.copyWith(busy: false);
    }
  }

  Future<void> checkSources(List<BooruSource> sources) async {
    if (state.busy || ref.read(networkConfigProvider).busy) return;
    state = state.copyWith(
      busy: true,
      checks: {
        ...state.checks,
        for (final source in sources) source.sourceId: 'checking',
      },
    );
    try {
      await Future.wait(
        sources.map((source) async {
          SourceConnectionCheck? result;
          String? error;
          try {
            result = await _backend
                .probe(source.sourceId)
                .timeout(const Duration(seconds: 26));
            final cause = result.apiError ?? result.mediaError;
            if (cause != null) error = describeBooruError(cause);
          } catch (cause) {
            error = describeBooruError(cause);
          }
          if (!ref.mounted) return;
          final id = source.sourceId;
          final status = switch ((
            result?.apiAvailable,
            result?.mediaAvailable,
          )) {
            (true, true) => 'available',
            (true, _) || (_, true) => 'partial',
            _ => 'failed',
          };
          final details = {...state.details}..remove(id);
          if (result != null) details[id] = result;
          final errors = {...state.errors}..remove(id);
          if (error != null) errors[id] = error;
          state = state.copyWith(
            checks: {...state.checks, id: status},
            details: details,
            errors: errors,
          );
          _saved[id] = {
            'status': status,
            'api': result?.apiAvailable,
            'media': result?.mediaAvailable,
            'error': error,
            'checkedAt': DateTime.now().toUtc().toIso8601String(),
          };
          final encoded = jsonEncode(_saved);
          // Serialize writes so a slow earlier write never overwrites newer results.
          final backend = _backend;
          _writes = _writes.then((_) => backend.save(encoded)).catchError((
            Object failure,
          ) {
            if (ref.mounted) {
              state = state.copyWith(error: describeBooruError(failure));
            }
          });
        }),
      );
      await _writes;
    } finally {
      if (ref.mounted) state = state.copyWith(busy: false);
    }
  }
}

class NetworkConfigState {
  const NetworkConfigState({
    required this.mode,
    required this.dns,
    this.proxy,
    this.busy = false,
  });
  final NetworkFallbackMode mode;
  final RouteProvider dns;
  final String? proxy;
  final bool busy;
}

final networkConfigProvider =
    NotifierProvider<NetworkConfigController, NetworkConfigState>(
      NetworkConfigController.new,
    );

class NetworkConfigController extends Notifier<NetworkConfigState> {
  @override
  NetworkConfigState build() => NetworkConfigState(
    mode: SettingsService.networkFallbackMode,
    dns: SettingsService.dnsProvider,
    proxy: SettingsService.proxyUrl,
  );
  Future<bool> apply({
    NetworkFallbackMode? mode,
    RouteProvider? dns,
    String? proxy,
    bool updateProxy = false,
  }) async {
    if (state.busy || ref.read(networkStatusProvider).busy) return false;
    final previous = state;
    state = NetworkConfigState(
      mode: previous.mode,
      dns: previous.dns,
      proxy: previous.proxy,
      busy: true,
    );
    try {
      if (mode != null) SettingsService.networkFallbackMode = mode;
      if (dns != null) SettingsService.dnsProvider = dns;
      if (updateProxy) SettingsService.proxyUrl = proxy;
      await BooruService.instance.reconfigureNetwork();
      state = build();
      unawaited(ref.read(networkStatusProvider.notifier).readRoutes());
      return true;
    } catch (_) {
      SettingsService.networkFallbackMode = previous.mode;
      SettingsService.dnsProvider = previous.dns;
      SettingsService.proxyUrl = previous.proxy;
      state = previous;
      rethrow;
    }
  }
}
