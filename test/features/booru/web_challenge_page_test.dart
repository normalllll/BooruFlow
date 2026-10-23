import 'dart:async';

import 'package:booruflow/features/booru/native_web_challenge_page.dart';
import 'package:booruflow/features/booru/services/web_challenge_service.dart';
import 'package:booruflow/features/booru/web_challenge_browser.dart';
import 'package:booruflow/features/booru/web_challenge_page.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/web_challenge.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';

import '../discovery/home_page_test.dart' show browseTestApp;
import 'web_challenge_service_test.dart' show Backend, candidate, state;

const operation = WebChallengeOperation(
  operationId: 'page-operation',
  spec: WebChallengeSpec(
    sourceId: 'gelbooru',
    displayName: 'Gelbooru',
    entryUrl: 'https://gelbooru.com/',
    navigationHosts: ['gelbooru.com'],
    captureTargets: [],
    timeoutSeconds: 600,
  ),
);

class Browser extends WebChallengeBrowser {
  @override
  Uri get url => Uri.parse('https://gelbooru.com/');
  @override
  bool loading = true;
  @override
  bool available = true;
  @override
  bool failed = false;
  int opens = 0, reloads = 0, captures = 0, clears = 0;
  Completer<void>? pending;
  @override
  Future<void> open(WebChallengeSpec spec) async {
    opens++;
  }

  @override
  Future<void> reload() async {
    reloads++;
    failed = false;
    notifyListeners();
  }

  @override
  Future<WebChallengeCandidate> capture(WebChallengeSpec spec) async {
    captures++;
    await pending?.future;
    return candidate;
  }

  @override
  Future<void> clear() async {
    clears++;
  }

  @override
  Widget content(BuildContext context) =>
      const SizedBox(key: ValueKey('injected-web-content'));
}

class NativeBackend extends Backend {
  final result = Completer<WebChallengeState>();
  @override
  Future<WebChallengeState> runWindow(WebChallengeOperation operation) =>
      result.future;
  @override
  Future<void> cancel(String id) async {
    await super.cancel(id);
    if (!result.isCompleted) result.complete(state);
  }
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'embedded content injection keeps one header and failure recovery $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final browser = Browser()..failed = true;
        final cancellation = ValueNotifier(0);
        await tester.pumpWidget(
          browseTestApp(
            WebChallengePage(
              operation: operation,
              cancellation: cancellation,
              browser: browser,
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(FrostPageHeader), findsOneWidget);
        expect(find.byType(FrostWebChrome), findsNothing);
        expect(find.text(t.verificationPage.failed), findsOneWidget);
        expect(
          tester
              .widget<FrostButton>(
                find.widgetWithText(FrostButton, t.webChallenge.finish),
              )
              .onPressed,
          isNull,
        );
        final header = find.byType(FrostPageHeader);
        expect(
          find.descendant(
            of: header,
            matching: find.text(t.webChallenge.title),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: header, matching: find.text('Gelbooru')),
          findsOneWidget,
        );
        final retry = tester.getRect(
          find.widgetWithText(FrostButton, t.verificationPage.reopen),
        );
        final network = tester.getRect(
          find.widgetWithText(FrostButton, t.verificationPage.networkSettings),
        );
        if (network.top >= retry.bottom) {
          expect(
            network.top - retry.bottom,
            greaterThanOrEqualTo(FrostGap.related),
          );
          expect(network.center.dx, retry.center.dx);
        } else {
          expect(
            network.left - retry.right,
            greaterThanOrEqualTo(FrostGap.related),
          );
        }
        await tester.tap(find.text(t.verificationPage.reopen));
        await tester.pump();
        expect(browser.reloads, 1);
        expect(
          find.byKey(const ValueKey('injected-web-content')),
          findsOneWidget,
        );
        expect(find.text(t.verificationPage.opening), findsOneWidget);
        expect(
          tester
              .widget<FrostButton>(
                find.widgetWithText(FrostButton, t.webChallenge.finish),
              )
              .onPressed,
          isNotNull,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        browser.dispose();
        cancellation.dispose();
      },
    );
  }
  testWidgets(
    'finish captures once and clears before returning the actual candidate',
    (tester) async {
      final browser = Browser()..pending = Completer<void>();
      final cancellation = ValueNotifier(0);
      Object? result;
      await tester.pumpWidget(
        browseTestApp(
          Builder(
            builder: (context) => FrostButton(
              label: 'Open',
              onPressed: () async {
                result = await Navigator.of(context).push<Object?>(
                  FrostDetailPage<Object?>(
                    child: WebChallengePage(
                      operation: operation,
                      cancellation: cancellation,
                      browser: browser,
                    ),
                  ).createRoute(context),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      final finish = tester
          .widget<FrostButton>(
            find.widgetWithText(FrostButton, t.webChallenge.finish),
          )
          .onPressed!;
      finish();
      finish();
      await tester.pump();
      expect(browser.captures, 1);
      browser.pending!.complete();
      await tester.pumpAndSettle();
      expect(result, same(candidate));
      expect(browser.clears, 1);
      expect(find.text('Open'), findsOneWidget);
      browser.dispose();
      cancellation.dispose();
    },
  );
  testWidgets(
    'service cancellation clears browser without capturing or saving',
    (tester) async {
      final browser = Browser();
      final cancellation = ValueNotifier(0);
      Object? result = 'unset';
      await tester.pumpWidget(
        browseTestApp(
          Builder(
            builder: (context) => FrostButton(
              label: 'Open',
              onPressed: () async {
                result = await Navigator.of(context).push<Object?>(
                  FrostDetailPage<Object?>(
                    child: WebChallengePage(
                      operation: operation,
                      cancellation: cancellation,
                      browser: browser,
                    ),
                  ).createRoute(context),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      cancellation.value++;
      await tester.pumpAndSettle();
      expect(browser.captures, 0);
      expect(browser.clears, 1);
      expect(result, isNull);
      browser.dispose();
      cancellation.dispose();
    },
  );
  testWidgets(
    'native shell cancellation releases the session without clearing stored data',
    (tester) async {
      final backend = NativeBackend();
      final changes = <String>[];
      final service = WebChallengeService.forTesting(
        backendFactory: () => backend,
        collector: (_, _, _) =>
            throw StateError('Native must not use embedded collector'),
        changed: (ids) async => changes.addAll(ids),
        nativeWindow: true,
      );
      await tester.pumpWidget(
        browseTestApp(
          Builder(
            builder: (context) => FrostButton(
              label: 'Open',
              onPressed: () {
                Navigator.of(context).push<bool>(
                  FrostDetailPage<bool>(
                    child: NativeWebChallengePage(
                      service: service,
                      sourceId: 'gelbooru',
                      sourceName: 'Gelbooru',
                    ),
                  ).createRoute(context),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      expect(service.activity?.phase, WebChallengePhase.waiting);
      expect(find.text(t.webChallenge.waiting), findsOneWidget);
      Navigator.of(
        tester.element(find.byType(NativeWebChallengePage)),
      ).maybePop();
      await tester.pumpAndSettle();
      expect(service.activity, isNull);
      expect(backend.cleared, isEmpty);
      expect(changes, isEmpty);
      expect(backend.cancelled, isNotEmpty);
      expect(find.text('Open'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
