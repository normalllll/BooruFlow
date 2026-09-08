import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:booruflow/core/settings_service.dart';
import 'package:booruflow/src/rust/api/booru_auth.dart';
import 'package:booruflow/src/rust/api/booru_engine.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';

final class BooruService {
  BooruService._();

  static final instance = BooruService._();
  static const _credentialBoxName = 'booru_credentials';

  final selectedSource = ValueNotifier<String>('yande');
  final revision = ValueNotifier<int>(0);
  late BooruEngine _engine;
  late List<BooruSource> _sources;
  late Box<dynamic> _credentials;
  late String _supportDirectory;
  late String _version;

  BooruEngine get engine => _engine;
  List<BooruSource> get sources => List.unmodifiable(_sources);
  @visibleForTesting
  void useSourcesForTesting(List<BooruSource> sources) {
    _sources = List.unmodifiable(sources);
    selectedSource.value = sources.first.sourceId;
  }

  BooruSource get currentSource => sourceById(selectedSource.value);
  String cacheRevision(String sourceId) =>
      _storedRevision('$sourceId:revision', 'anonymous');
  String get networkCacheRevision =>
      _storedRevision('networkRevision', 'initial');

  String _storedRevision(String key, String fallback) {
    final value = _credentials.get(key);
    if (value is String && value.isNotEmpty) return value;
    if (value != null) unawaited(_credentials.delete(key));
    return fallback;
  }

  BooruSource sourceById(String sourceId) =>
      _sources.firstWhere((source) => source.sourceId == sourceId);

  Future<void> initialize(String version) async {
    _version = version;
    _supportDirectory = (await getApplicationSupportDirectory()).path;
    _credentials = await Hive.openBox<dynamic>(_credentialBoxName);
    selectedSource.value = SettingsService.defaultSourceId;
    await _createEngine();
  }

  Future<void> reconfigureNetwork() async {
    await _createEngine();
    await _credentials.put(
      'networkRevision',
      DateTime.now().microsecondsSinceEpoch.toString(),
    );
    revision.value++;
  }

  Future<RouteCacheState> refreshNetworkRoutes() async {
    final state = await _engine.refreshRouteCache();
    await _credentials.put(
      'networkRevision',
      DateTime.now().microsecondsSinceEpoch.toString(),
    );
    revision.value++;
    return state;
  }

  void selectSource(String sourceId) {
    if (!_sources.any((source) => source.sourceId == sourceId)) return;
    selectedSource.value = sourceId;
  }

  Future<void> _createEngine() async {
    _engine = await BooruEngine.newInstance(
      config: BooruEngineConfig(
        appSupportDirectory: _supportDirectory,
        proxyUrl: SettingsService.proxyUrl,
        fallbackMode: SettingsService.networkFallbackMode,
        dnsProvider: SettingsService.dnsProvider,
        userAgent: 'BooruFlow/$_version',
      ),
    );
    _sources = await _engine.listSources();
    if (!_sources.any((source) => source.sourceId == selectedSource.value)) {
      selectSource(_sources.first.sourceId);
    }
    await _restoreCredentials();
    // Load persisted routes only. DNS refresh is an explicit, visible action.
    await _engine.initializeRouteCache();
  }

  Future<AuthState> authState(String sourceId) =>
      _engine.authState(sourceId: sourceId);

  Future<AuthSchema> authSchema(String sourceId) =>
      _engine.authSchema(sourceId: sourceId);

  Future<AuthState> saveCredentials(
    String sourceId,
    SourceCredentials value,
  ) async {
    await _credentials.put(sourceId, <String, String?>{
      'username': value.username,
      'userId': value.userId,
      'apiKey': value.apiKey,
    });
    final state = await _engine.setCredentials(
      sourceId: sourceId,
      credentials: value,
    );
    await _credentials.put(
      '$sourceId:revision',
      DateTime.now().microsecondsSinceEpoch.toString(),
    );
    revision.value++;
    return state;
  }

  Future<AuthState> saveWebSession(
    String sourceId, {
    required String cookieHeader,
    required String userAgent,
  }) async {
    final cookies = _parseCookieHeader(cookieHeader);
    await _credentials.put(sourceId, <String, Object?>{
      'cookieHeader': cookieHeader,
      'userAgent': userAgent,
    });
    final state = await _engine.setWebSession(
      sourceId: sourceId,
      cookies: cookies,
      userAgent: userAgent,
    );
    await _credentials.put(
      '$sourceId:revision',
      DateTime.now().microsecondsSinceEpoch.toString(),
    );
    revision.value++;
    return state;
  }

  Future<void> clearAuth(String sourceId) async {
    await _credentials.delete(sourceId);
    await _engine.clearAuth(sourceId: sourceId);
    await _credentials.put(
      '$sourceId:revision',
      DateTime.now().microsecondsSinceEpoch.toString(),
    );
    revision.value++;
  }

  Map<String, String> savedAuth(String sourceId) {
    final raw = _credentials.get(sourceId);
    const fields = {
      'username',
      'userId',
      'apiKey',
      'cookieHeader',
      'userAgent',
    };
    if (raw is! Map ||
        raw.entries.any(
          (entry) => !fields.contains(entry.key) || entry.value is! String,
        )) {
      if (raw != null) unawaited(_credentials.delete(sourceId));
      return const {};
    }
    return Map<String, String>.from(raw);
  }

  Future<void> _restoreCredentials() async {
    for (final source in _sources) {
      final saved = savedAuth(source.sourceId);
      if (saved.isEmpty) continue;
      try {
        if (source.capabilities.authKind == AuthKind.webSession) {
          await _engine.setWebSession(
            sourceId: source.sourceId,
            cookies: _parseCookieHeader(saved['cookieHeader'] ?? ''),
            userAgent: saved['userAgent'] ?? '',
          );
        } else {
          await _engine.setCredentials(
            sourceId: source.sourceId,
            credentials: SourceCredentials(
              username: _nullIfEmpty(saved['username']),
              userId: _nullIfEmpty(saved['userId']),
              apiKey: _nullIfEmpty(saved['apiKey']),
            ),
          );
        }
      } catch (_) {
        // A stale optional account must never prevent anonymous browsing.
      }
    }
  }

  List<WebCookie> _parseCookieHeader(String value) {
    return value
        .split(';')
        .map((part) => part.trim())
        .where((part) => part.contains('='))
        .map((part) {
          final separator = part.indexOf('=');
          return WebCookie(
            name: part.substring(0, separator).trim(),
            value: part.substring(separator + 1).trim(),
            domain: '.anime-pictures.net',
            path: '/',
            secure: true,
          );
        })
        .where((cookie) => cookie.name.isNotEmpty)
        .toList(growable: false);
  }
}

String? _nullIfEmpty(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
