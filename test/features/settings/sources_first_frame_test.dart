import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/settings/settings_page.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_auth.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';

import '../../support/browse_support.dart' show browseTestApp;
import '../discovery/search_interaction_test.dart' show testSource;

BooruSource _accountSource(String id) {
  final source = testSource(id);
  final capabilities = source.capabilities;
  return BooruSource(
    sourceId: id,
    displayName: id,
    protocol: source.protocol,
    enabledByDefault: true,
    isAiSource: false,
    capabilities: SourceCapabilities(
      discovery: capabilities.discovery,
      ratings: capabilities.ratings,
      authKind: AuthKind.loginApiKey,
      supportsSearch: true,
      supportsPostDetail: true,
      supportsAutocomplete: true,
      supportsRelatedPosts: false,
      supportsOriginal: true,
      supportsAuthenticatedMedia: false,
      supportsBackgroundDownload: true,
    ),
  );
}

class _Service extends BooruService {
  @override
  AuthSchema authSchema(String id) =>
      AuthSchema(sourceId: id, usesWebSession: false, fields: const []);
  @override
  AuthState authState(String id) => AuthState(
    sourceId: id,
    status: id == 'signed_in' ? AuthStatus.verified : AuthStatus.notConfigured,
    username: id == 'signed_in' ? 'Tester' : null,
    authRevision: 1,
  );
  @override
  Map<String, String> savedAuth(String id) => const {};
}

String? _subtitle(WidgetTester tester, String title) => tester
    .widget<FrostListRow>(
      find.byWidgetPredicate((w) => w is FrostListRow && w.title == title),
    )
    .subtitle
    ?.text;

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('source rows show their account status from the first frame', (
    tester,
  ) async {
    final service = _Service()
      ..useSourcesForTesting([
        testSource('anonymous'),
        _accountSource('unset'),
        _accountSource('signed_in'),
      ]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [booruServiceProvider.overrideWithValue(service)],
        child: browseTestApp(
          const SettingsPage(section: SettingsSection.sources),
        ),
      ),
    );

    // The first frame already carries the final labels, so no row crossfades
    // from a loading placeholder.
    final first = {
      for (final id in ['anonymous', 'unset', 'signed_in'])
        id: _subtitle(tester, id),
    };
    expect(find.text(t.generic.loading), findsNothing);
    expect(first['anonymous'], t.settings.account.noAccountRequired);
    expect(first['unset'], t.settings.account.statuses.notConfigured);
    expect(
      first['signed_in'],
      '${t.settings.account.statuses.verified} · Tester',
    );

    await tester.pumpAndSettle();
    for (final MapEntry(:key, :value) in first.entries) {
      expect(_subtitle(tester, key), value, reason: key);
    }
  });
}
