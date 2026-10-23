import 'dart:async';

import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/booru/services/web_challenge_service.dart';
import 'package:booruflow/features/booru/web_challenge_logic.dart';
import 'package:booruflow/features/booru/widgets/web_challenge_data_panel.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/loading_content.dart';
import 'package:booruflow/src/rust/api/web_challenge.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';

import '../discovery/home_page_test.dart' show browseTestApp;
import '../discovery/search_interaction_test.dart' show testSource;
import 'web_challenge_service_test.dart' show Backend;

WebChallengeState savedState(String id, {bool saved = true}) =>
    WebChallengeState(
      sourceId: id,
      hasSavedData: saved,
      verified: saved,
      revision: 1,
    );

class _PendingClearBackend extends Backend {
  final pending = Completer<void>();
  @override
  Future<void> clear(String sourceId) async {
    cleared.add(sourceId);
    await pending.future;
  }
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));
  const ids = ['yande', 'danbooru', 'gelbooru'];
  final sources = ids.map(testSource).toList();

  Future<void> pumpPanel(
    WidgetTester tester, {
    required Future<WebChallengeState> Function(String) read,
    required WebChallengeService controller,
  }) => tester.pumpWidget(
    ProviderScope(
      overrides: [
        booruServiceProvider.overrideWithValue(
          BooruService()..useSourcesForTesting(sources),
        ),
      ],
      child: browseTestApp(
        FrostToastHost(
          child: SingleChildScrollView(
            child: WebChallengeDataPanel(
              sources: sources,
              savedOnly: true,
              controller: controller,
              readState: read,
            ),
          ),
        ),
      ),
    ),
  );

  WebChallengeService service(Backend backend) =>
      WebChallengeService.forTesting(
        backendFactory: () => backend,
        collector: (_, _, _) async => null,
        changed: (_) async {},
      );

  Finder sourceRows() => find.byWidgetPredicate(
    (w) =>
        w is FrostListRow &&
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('web-data-'),
  );

  testWidgets(
    'saved sources never flash unresolved or partially filtered rows',
    (tester) async {
      final pending = {
        for (final id in ids) id: Completer<WebChallengeState>(),
      };
      Future<WebChallengeState> read(String id) => pending[id]!.future;
      await pumpPanel(tester, read: read, controller: service(Backend()));
      expect(sourceRows(), findsNothing);
      expect(find.byType(AppLoadingContent), findsOneWidget);
      expect(find.byType(FrostActivityIndicator), findsNothing);
      expect(find.text(t.webChallenge.empty), findsNothing);
      pending['danbooru']!.complete(savedState('danbooru'));
      await tester.pump();
      expect(sourceRows(), findsNothing);
      pending['yande']!.complete(savedState('yande', saved: false));
      pending['gelbooru']!.complete(savedState('gelbooru', saved: false));
      await tester.pumpAndSettle();
      expect(sourceRows(), findsOneWidget);
      expect(find.byKey(const ValueKey('web-data-danbooru')), findsOneWidget);
      expect(find.text('yande'), findsNothing);
      expect(find.text('gelbooru'), findsNothing);
      final rowState = tester.state(
        find.byKey(const ValueKey('web-data-danbooru')),
      );
      final scope = ProviderScope.containerOf(
        tester.element(find.byType(WebChallengeDataPanel)),
      );
      pending['danbooru'] = Completer<WebChallengeState>();
      scope.invalidate(
        webChallengeDataProvider((sourceId: 'danbooru', read: read)),
      );
      await tester.pump();
      expect(sourceRows(), findsOneWidget);
      expect(
        tester.state(find.byKey(const ValueKey('web-data-danbooru'))),
        same(rowState),
      );
      pending['danbooru']!.complete(savedState('danbooru', saved: false));
      await tester.pumpAndSettle();
      expect(sourceRows(), findsNothing);
      expect(find.text(t.webChallenge.empty), findsOneWidget);
    },
  );

  testWidgets(
    'read failure is explicit and retry does not invent a saved row',
    (tester) async {
      var failed = true;
      Future<WebChallengeState> read(String id) async {
        if (id == 'yande' && failed) throw StateError('fixture read failed');
        return savedState(id, saved: id == 'danbooru');
      }

      await pumpPanel(tester, read: read, controller: service(Backend()));
      await tester.pumpAndSettle();
      expect(sourceRows(), findsOneWidget);
      expect(find.text(t.webChallenge.failed), findsOneWidget);
      expect(find.text(t.webChallenge.empty), findsNothing);
      failed = false;
      await tester.tap(find.text(t.generic.retry));
      await tester.pumpAndSettle();
      expect(sourceRows(), findsOneWidget);
      expect(find.text(t.webChallenge.failed), findsNothing);
    },
  );

  testWidgets(
    'clear all is one destructive row with no nested button and one confirmation',
    (tester) async {
      final backend = _PendingClearBackend();
      final controller = service(backend);
      Future<WebChallengeState> read(String id) async =>
          savedState(id, saved: !backend.cleared.contains(id));
      await pumpPanel(tester, read: read, controller: controller);
      await tester.pumpAndSettle();
      final row = find.byKey(const ValueKey('clear-all-web-data'));
      expect(tester.widget<FrostListRow>(row).destructive, isTrue);
      expect(
        find.descendant(of: row, matching: find.byType(FrostButton)),
        findsNothing,
      );
      expect(find.text(t.webChallenge.clearDescription), findsOneWidget);
      // Hit the otherwise empty end of the row, outside its text.
      await tester.tapAt(tester.getTopRight(row) + const Offset(-4, 20));
      await tester.pumpAndSettle();
      expect(find.byType(FrostAlert), findsOneWidget);
      await tester.tap(find.text(t.webChallenge.clear).hitTestable().last);
      await tester.pump();
      expect(controller.clearing, isTrue);
      expect(tester.widget<FrostListRow>(row).onPressed, isNull);
      expect(backend.cleared, ['yande']);
      backend.pending.complete();
      await tester.pumpAndSettle();
      expect(backend.cleared, ids);
      expect(find.byType(FrostAlert), findsNothing);
      expect(sourceRows(), findsNothing);
      expect(tester.widget<FrostListRow>(row).onPressed, isNull);
    },
  );
}
