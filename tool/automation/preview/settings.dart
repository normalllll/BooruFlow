// Settings snapshots and test services belong only to the automation entrypoint.
import 'package:booruflow/features/settings/network/network_logic.dart';
import 'package:booruflow/features/settings/network/proxy_logic.dart';
import 'package:booruflow/features/update/logic.dart';
import 'package:booruflow/src/rust/api/booru_auth.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:booruflow/src/rust/api/web_challenge.dart';
import 'fixture.dart';

String settingsPreviewRoute(String board) => switch (board) {
  'P01' || 'P13' => '/settings/appearance',
  'P02' => '/settings/browsing',
  'P03' => '/settings/sources',
  'P04' || 'P05' => '/settings/sources?source=danbooru',
  'P06' || 'P07' || 'P14' => '/settings/network',
  'P08' => '/settings/downloads',
  'P09' => '/settings/web',
  'P10' => '/settings/general',
  'P11' || 'P15' => '/settings/about',
  _ => '/settings',
};

class PreviewSettingsService extends PreviewService {
  PreviewSettingsService(super.data, super.sources)
    : super(engine: PreviewSettingsEngine(data));
  @override
  Map<String, String> savedAuth(String id) => id == 'danbooru'
      ? {'username': 'mika', 'apiKey': 'fixture-not-a-real-secret-3f9a'}
      : {};
  @override
  Future<AuthSchema> authSchema(String id) async => AuthSchema(
    sourceId: id,
    usesWebSession: id == 'anime_pictures',
    fields: sourceById(id).capabilities.authKind == AuthKind.none
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
  Future<AuthState> authState(String id) async => AuthState(
    sourceId: id,
    status: switch (id) {
      'danbooru' => AuthStatus.verified,
      'gelbooru' => AuthStatus.configuredUnverified,
      _ => AuthStatus.notConfigured,
    },
    username: id == 'danbooru' ? 'mika' : null,
    authRevision: 1,
  );
}

class PreviewSettingsEngine extends PreviewEngine {
  PreviewSettingsEngine(super.data);
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
    hasSavedData: {'danbooru', 'gelbooru'}.contains(sourceId),
    verified: sourceId == 'danbooru',
    revision: 1,
  );
}

RouteCacheState previewRoutes() => RouteCacheState(
  initialized: true,
  refreshing: false,
  routeRevision: 'preview',
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
NetworkProbeBackend previewNetworkBackend(List<BooruSource> sources) =>
    NetworkProbeBackend(
      sources: sources,
      read: () async => previewRoutes(),
      refresh: () async => previewRoutes(),
      probe: (id) async => SourceConnectionCheck(
        sourceId: id,
        apiAvailable: true,
        mediaAvailable: true,
      ),
      load: () => null,
      save: (_) async {},
    );

class PreviewNetworkStatus extends NetworkStatus {
  @override
  NetworkStatusState build() => NetworkStatusState(
    routes: previewRoutes(),
    checks: const {
      'danbooru': SourceCheckStatus.available,
      'gelbooru': SourceCheckStatus.checking,
      'yande': SourceCheckStatus.available,
      'konachan_net': SourceCheckStatus.partial,
      'konachan_com': SourceCheckStatus.available,
      'aibooru': SourceCheckStatus.failed,
    },
  );
}

class PreviewProxySettings extends ProxySettings {
  @override
  ProxySettingsState build() => ProxySettingsState.fromUrl(
    'http://127.0.0.1:7890',
  ).copyWith(reachable: true);
}

class PreviewUpdateCheck extends UpdateCheck {
  @override
  UpdateCheckState build() => UpdateCheckState(
    result: UpdateInfo(
      version: '0.12.0',
      download: Uri.parse('https://example.invalid/update.zip'),
    ),
  );
}
