import 'dart:convert';

import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/search/logic.dart';
import 'package:booruflow/features/tags/tag_menu.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

import '../../support/browse_support.dart' show PendingMediaService;
import '../../support/frost_app_layers.dart';
import '../discovery/search_interaction_test.dart' show testSource;

/// What selecting a tag menu entry did.
typedef _Outcome = ({List<String>? pushed, String? searchText});

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));

  /// Mounts the entries of the tag `dog` and selects the one labelled [label].
  Future<_Outcome> select(
    WidgetTester tester,
    String label, {
    required List<String> query,
  }) async {
    List<String>? pushed;
    final service = PendingMediaService()
      ..useSourcesForTesting([testSource('yande')]);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Center(
            child: FrostButton(
              label: 'run',
              onPressed: () {
                final entry =
                    tagMenuEntries(
                      context,
                      'dog',
                      sourceId: 'yande',
                      query: query,
                    ).whereType<FrostMenuAction>().firstWhere(
                      (entry) => entry.label == label,
                    );
                entry.onSelected?.call();
              },
            ),
          ),
        ),
        GoRoute(
          path: AppRoute.results.path,
          name: AppRoute.results.name,
          builder: (_, state) {
            pushed = [
              for (final tag
                  in jsonDecode(state.uri.queryParameters['tags']!) as List)
                tag as String,
            ];
            return const Text('results');
          },
        ),
        GoRoute(
          path: AppRoute.tags.path,
          builder: (_, _) => const Text('tags'),
        ),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      router.dispose();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [booruServiceProvider.overrideWithValue(service)],
        child: TranslationProvider(
          child: FrostScope(
            config: appFrostConfig,
            child: MaterialApp.router(
              routerConfig: router,
              theme: FrostTheme.build(
                config: appFrostConfig,
                brightness: Brightness.light,
                platform: TargetPlatform.windows,
                locale: const Locale('en'),
              ),
              builder: (context, child) =>
                  FrostLayoutScope(child: frostAppLayers(child!)),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('run'));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    return (
      pushed: pushed,
      searchText: container.read(pendingSearchProvider)?.text,
    );
  }

  group('with the query [cat]', () {
    const query = ['cat'];

    testWidgets('Exclude pushes the query plus the excluded tag', (
      tester,
    ) async {
      final outcome = await select(
        tester,
        t.postDetail.excludeTag,
        query: query,
      );
      expect(outcome.pushed, ['cat', '-dog']);
    });

    testWidgets('Add to search pushes the query plus the tag', (tester) async {
      final outcome = await select(
        tester,
        t.postDetail.addToSearch,
        query: query,
      );
      expect(outcome.pushed, ['cat', 'dog']);
    });

    testWidgets('Add to search does not duplicate a tag already queried', (
      tester,
    ) async {
      final outcome = await select(
        tester,
        t.postDetail.addToSearch,
        query: const ['cat', 'dog'],
      );
      expect(outcome.pushed, ['cat', 'dog']);
    });

    testWidgets('Exclude does not duplicate an already excluded tag', (
      tester,
    ) async {
      final outcome = await select(
        tester,
        t.postDetail.excludeTag,
        query: const ['cat', '-dog'],
      );
      expect(outcome.pushed, ['cat', '-dog']);
    });

    testWidgets('Search this tag pushes only that tag', (tester) async {
      final outcome = await select(
        tester,
        t.postDetail.searchTag,
        query: query,
      );
      expect(outcome.pushed, ['dog']);
    });
  });

  group('with an empty query', () {
    testWidgets('Add to search keeps the openSearch behaviour', (tester) async {
      final outcome = await select(
        tester,
        t.postDetail.addToSearch,
        query: const [],
      );
      // No title row holds the search here, so it opens the results.
      expect(outcome.pushed, ['dog']);
      expect(outcome.searchText, isNull);
    });

    testWidgets('Exclude pushes only the excluded tag', (tester) async {
      final outcome = await select(
        tester,
        t.postDetail.excludeTag,
        query: const [],
      );
      expect(outcome.pushed, ['-dog']);
    });
  });
}
