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
  late List<BooruSourceDto> _sources;
  late Box<dynamic> _credentials;
  late String _supportDirectory;
  late String _version;

  BooruEngine get engine => _engine;
  List<BooruSourceDto> get sources => List.unmodifiable(_sources);
  BooruSourceDto get currentSource => sourceById(selectedSource.value);

  BooruSourceDto sourceById(String sourceId) =>
      _sources.firstWhere((source) => source.sourceId == sourceId);

  Future<void> initialize(String version) async {
    _version = version;
    _supportDirectory = (await getApplicationSupportDirectory()).path;
    _credentials = await Hive.openBox<dynamic>(_credentialBoxName);
    selectedSource.value = SettingsService.sourceId;
    await _createEngine();
  }

  Future<void> reconfigureNetwork() async {
    await _createEngine();
    revision.value++;
  }

  void selectSource(String sourceId) {
    if (!_sources.any((source) => source.sourceId == sourceId)) return;
    SettingsService.sourceId = sourceId;
    selectedSource.value = sourceId;
  }

  Future<void> _createEngine() async {
    _engine = await BooruEngine.newInstance(
      config: BooruEngineConfigDto(
        appSupportDirectory: _supportDirectory,
        proxyUrl: SettingsService.proxyUrl,
        fallbackMode: SettingsService.networkFallbackMode,
        fallbackToSystemDns: SettingsService.fallbackToSystemDns,
        userAgent: 'BooruFlow/$_version',
      ),
    );
    _sources = await _engine.listSources();
    if (!_sources.any((source) => source.sourceId == selectedSource.value)) {
      selectSource(_sources.first.sourceId);
    }
    await _restoreCredentials();
    if (SettingsService.networkFallbackMode != NetworkFallbackMode.off &&
        SettingsService.proxyUrl == null) {
      try {
        await _engine.initializeRouteCache();
      } catch (_) {
        if (!SettingsService.fallbackToSystemDns) rethrow;
      }
    }
  }

  Future<AuthStateDto> authState(String sourceId) =>
      _engine.authState(sourceId: sourceId);

  Future<AuthSchemaDto> authSchema(String sourceId) =>
      _engine.authSchema(sourceId: sourceId);

  Future<AuthStateDto> saveCredentials(
    String sourceId,
    SourceCredentialsDto value,
  ) async {
    await _credentials.put(sourceId, <String, String?>{
      'username': value.username,
      'userId': value.userId,
      'apiKey': value.apiKey,
    });
    return _engine.setCredentials(sourceId: sourceId, credentials: value);
  }

  Future<AuthStateDto> saveWebSession(
    String sourceId, {
    required String cookieHeader,
    required String userAgent,
  }) async {
    final cookies = _parseCookieHeader(cookieHeader);
    await _credentials.put(sourceId, <String, Object?>{
      'cookieHeader': cookieHeader,
      'userAgent': userAgent,
    });
    return _engine.setWebSession(
      sourceId: sourceId,
      cookies: cookies,
      userAgent: userAgent,
    );
  }

  Future<void> clearAuth(String sourceId) async {
    await _credentials.delete(sourceId);
    await _engine.clearAuth(sourceId: sourceId);
  }

  Map<String, String> savedAuth(String sourceId) {
    final raw = _credentials.get(sourceId);
    if (raw is! Map) return const {};
    return raw.map(
      (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
    );
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
            credentials: SourceCredentialsDto(
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

  List<WebCookieDto> _parseCookieHeader(String value) {
    return value
        .split(';')
        .map((part) => part.trim())
        .where((part) => part.contains('='))
        .map((part) {
          final separator = part.indexOf('=');
          return WebCookieDto(
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
