import 'dart:async';
import 'package:booruflow/features/about/about_page.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/settings/widgets/account_editor.dart';
import 'package:booruflow/features/update/logic.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_auth.dart';
import 'package:booruflow/src/rust/api/booru_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import '../discovery/home_page_test.dart' show browseTestApp;
import '../discovery/search_interaction_test.dart' show testSource;

class _Engine implements BooruEngine {
  int verifies = 0;
  @override
  Future<AuthState> verifyAuth({required String sourceId}) async {
    verifies++;
    return AuthState(
      sourceId: sourceId,
      status: AuthStatus.verified,
      authRevision: 1,
      username: 'Tester',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Service extends BooruService {
  _Service({this.web = false});
  final bool web;
  final fakeEngine = _Engine();
  Completer<AuthState>? pending;
  int saves = 0, clears = 0;
  SourceCredentials? credentials;
  String? cookie, agent;
  AuthStatus status = AuthStatus.configuredUnverified;
  @override
  BooruEngine get engine => fakeEngine;
  @override
  Future<AuthSchema> authSchema(String id) async => AuthSchema(
    sourceId: id,
    usesWebSession: web,
    fields: const [
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
    status: status,
    authRevision: 0,
    username: 'Tester',
  );
  @override
  Map<String, String> savedAuth(String id) => {};
  @override
  Future<AuthState> saveCredentials(String id, SourceCredentials value) {
    saves++;
    credentials = value;
    return pending?.future ?? authState(id);
  }

  @override
  Future<AuthState> saveWebSession(
    String id, {
    required String cookieHeader,
    required String userAgent,
  }) {
    saves++;
    cookie = cookieHeader;
    agent = userAgent;
    return authState(id);
  }

  @override
  Future<void> clearAuth(String id) async {
    clears++;
    status = AuthStatus.notConfigured;
  }
}

Finder field(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is FrostTextField && w.label == label),
  matching: find.byType(EditableText),
);
void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));
  Future<void> mountAccount(WidgetTester tester, _Service service) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [booruServiceProvider.overrideWithValue(service)],
        child: browseTestApp(
          SingleChildScrollView(
            primary: false,
            child: AccountEditor(
              source: testSource(service.web ? 'anime_pictures' : 'yande'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(EditableText), findsNothing);
    await tester.tap(find.text(t.settingsV2.editAccount));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'account form validates required fields, preserves secure input and ignores late result after cancel',
    (tester) async {
      final service = _Service()..pending = Completer<AuthState>();
      await mountAccount(tester, service);
      await tester.tap(find.text(t.settings.account.save));
      await tester.pumpAndSettle();
      expect(service.saves, 0);
      await tester.enterText(field(t.settings.account.username), 'Alice');
      await tester.enterText(field(t.settings.account.apiKey), 'secret');
      expect(
        tester
            .widget<EditableText>(field(t.settings.account.apiKey))
            .obscureText,
        true,
      );
      await tester.tap(find.text(t.settings.account.save));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(service.saves, 1);
      expect(service.credentials?.username, 'Alice');
      expect(service.credentials?.apiKey, 'secret');
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(FrostActivityIndicator), findsWidgets);
      await tester.tap(find.text(t.frost.cancel));
      await tester.pumpAndSettle();
      service.pending!.completeError(StateError('Late save failure'));
      await tester.pumpAndSettle();
      expect(find.byType(FrostDialog), findsNothing);
      expect(find.byType(EditableText), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'web account form forwards complete cookie and user-agent values',
    (tester) async {
      final service = _Service(web: true);
      await mountAccount(tester, service);
      await tester.enterText(
        field(t.settings.account.cookieHeader),
        'session=example; token=two',
      );
      await tester.enterText(
        field(t.settings.account.browserUserAgent),
        'Example Agent',
      );
      await tester.tap(find.text(t.settings.account.save));
      await tester.pumpAndSettle();
      expect(service.saves, 1);
      expect(service.cookie, 'session=example; token=two');
      expect(service.agent, 'Example Agent');
      expect(find.byType(FrostDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'verify uses actual auth state and sign-out requires confirmation',
    (tester) async {
      final service = _Service();
      await mountAccount(tester, service);
      await tester.tap(find.text(t.frost.cancel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.settings.account.verify));
      await tester.pumpAndSettle();
      expect(service.fakeEngine.verifies, 1);
      expect(find.text(t.settings.account.statuses.verified), findsOneWidget);
      await tester.tap(find.text(t.settings.account.signOut));
      await tester.pumpAndSettle();
      expect(service.clears, 0);
      await tester.tap(find.text(t.frost.cancel));
      await tester.pumpAndSettle();
      expect(service.clears, 0);
      await tester.tap(find.text(t.settings.account.signOut));
      await tester.pumpAndSettle();
      final confirm = find.descendant(
        of: find.byType(FrostAlert),
        matching: find.text(t.settings.account.signOut),
      );
      await tester.tap(confirm.last);
      await tester.pumpAndSettle();
      expect(service.clears, 1);
      expect(
        find.text(t.settings.account.statuses.notConfigured),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'account failure stays in the form and recovers without replacing field controllers',
    (tester) async {
      final service = _Service()..pending = Completer<AuthState>();
      await mountAccount(tester, service);
      await tester.enterText(field(t.settings.account.username), 'Alice');
      await tester.enterText(field(t.settings.account.apiKey), 'secret');
      final textState = tester.state(field(t.settings.account.username));
      await tester.tap(find.text(t.settings.account.save));
      await tester.pump();
      service.pending!.completeError(StateError('Rejected fixture'));
      await tester.pumpAndSettle();
      expect(find.byType(FrostDialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(FrostDialog),
          matching: find.text(t.generic.loadFailed),
        ),
        findsOneWidget,
      );
      expect(
        identical(tester.state(field(t.settings.account.username)), textState),
        true,
      );
      service.pending = null;
      await tester.tap(find.text(t.settings.account.save));
      await tester.pumpAndSettle();
      expect(service.saves, 2);
      expect(find.byType(FrostDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'update lookup is explicit, runs once while pending and exposes download without launching it',
    (tester) async {
      var calls = 0;
      final pending = Completer<UpdateInfo?>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            updateLookupProvider.overrideWithValue(() {
              calls++;
              return pending.future;
            }),
          ],
          child: browseTestApp(
            const SingleChildScrollView(primary: false, child: AboutPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, 0);
      await tester.tap(find.text(t.settingsV2.checkUpdates));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(FrostActivityIndicator), findsOneWidget);
      await tester.tap(find.text(t.settingsV2.checkUpdates));
      await tester.pump();
      expect(calls, 1);
      pending.complete(
        UpdateInfo(
          version: '1.2.3',
          download: Uri.parse('https://example.test/update.zip'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(t.about.downloadUpdate), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
