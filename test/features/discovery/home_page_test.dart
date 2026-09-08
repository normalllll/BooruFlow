import 'package:booruflow/core/settings_service.dart';
import 'package:booruflow/features/booru/booru_service.dart';
import 'package:booruflow/features/discovery/discovery_page.dart';
import 'package:booruflow/features/discovery/logic.dart';
import 'package:booruflow/features/discovery/widgets/home_header.dart';
import 'package:booruflow/features/discovery/widgets/post_collection_view.dart';
import 'package:booruflow/features/discovery/widgets/source_picker.dart';
import 'package:booruflow/features/home/home_page.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/widgets/form_controls.dart';
import 'package:booruflow/shared/widgets/interaction_controls.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:booruflow/src/rust/booru/error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'search_interaction_test.dart' show testSource;

class _Store implements SettingsServiceStore {
  final Map<String, dynamic> values = {};
  @override
  Map<String, dynamic> load() => values;
  @override
  Future<void> write(String key, dynamic value) async {
    values[key] = value;
  }
}

void main() {
  const sources = [
    'yande',
    'konachan_net',
    'danbooru',
    'aibooru',
    'gelbooru',
    'wallhaven',
    'anime_pictures',
  ];
  setUp(() async {
    await SettingsService.initialize(store: _Store());
    BooruService.instance.useSourcesForTesting(
      sources.map(testSource).toList(),
    );
  });

  for (final width in [360.0, 1440.0]) {
    testWidgets(
      'search result toolbar stays compact without a heading at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DiscoveryPage(
                tags: const ['hatsune_miku'],
                sourceId: 'yande',
                loader: (_, _) async =>
                    const PostPage(items: [], exhausted: true),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final source = tester.getRect(find.byType(SourcePicker));
        final query = tester.getRect(
          find.byKey(const ValueKey('search-result-query')),
        );
        expect(find.text(t.discovery.searchResults), findsNothing);
        expect(source.center.dy, query.center.dy);
        expect(query.left - source.right, 8);
        expect(source.top, 12);
        expect(source.height, 36);
        expect(query.height, 36);
        final gallery = tester.getRect(find.byType(PostCollectionView));
        SettingsService.ratings = [ContentRating.general];
        await tester.pumpAndSettle();
        expect(tester.getRect(find.byType(PostCollectionView)), gallery);
        final filterButton = find.widgetWithIcon(AppIconButton, Icons.tune);
        expect(tester.widget<AppIconButton>(filterButton).selected, isTrue);
        SettingsService.ratings = [];
        await tester.pumpAndSettle();
        expect(tester.getRect(find.byType(PostCollectionView)), gallery);
        expect(tester.widget<AppIconButton>(filterButton).selected, isFalse);
        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.controller!.text, 'hatsune_miku');
        expect(
          field.decoration!.contentPadding!.resolve(TextDirection.ltr).left,
          12,
        );
        expect(query.left, greaterThanOrEqualTo(12));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'fresh settings load all home sources without a query or selected ratings',
    (tester) async {
      final calls = <CollectionKey>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomePage(
              loader: (key, _) async {
                calls.add(key);
                return const PostPage(items: [], exhausted: true);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final source in sources.skip(1)) {
        BooruService.instance.selectSource(source);
        await tester.pumpAndSettle();
      }
      expect(calls.map((key) => key.sourceId), sources);
      expect(
        calls.every(
          (key) =>
              key.ratings.isEmpty &&
              key.request is FeedCollectionRequest &&
              (key.request as FeedCollectionRequest).kind == FeedKind.latest,
        ),
        isTrue,
      );
      expect(find.text(t.postList.title), findsNothing);
      expect(find.byTooltip(t.discovery.filters), findsNothing);
      expect(find.byTooltip(t.postSearch.title), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.text(t.generic.notFound), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('clearing the global rating selection reloads default content', (
    tester,
  ) async {
    SettingsService.ratings = [ContentRating.general];
    final calls = <List<ContentRating>>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomePage(
            loader: (key, _) async {
              calls.add(key.ratings);
              return const PostPage(items: [], exhausted: true);
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    SettingsService.ratings = [];
    await tester.pumpAndSettle();
    expect(calls, [
      [ContentRating.general],
      <ContentRating>[],
    ]);
  });

  testWidgets(
    'global selection remains visible even when current source does not support it',
    (tester) async {
      SettingsService.ratings = [ContentRating.explicit];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiscoveryPage(
              tags: const ['sky'],
              sourceId: 'yande',
              loader: (_, _) async =>
                  const PostPage(items: [], exhausted: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(t.discovery.filters));
      await tester.pumpAndSettle();
      final explicit = find.widgetWithText(CheckboxListTile, 'E');
      expect(find.byType(CheckboxListTile), findsNWidgets(4));
      final rows = find.byType(CheckboxListTile);
      expect(
        tester.getRect(rows.at(1)).top - tester.getRect(rows.first).bottom,
        10,
      );
      expect(
        tester.widget<CheckboxListTile>(rows.first).contentPadding,
        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      );
      expect(tester.widget<CheckboxListTile>(explicit).value, isTrue);
      await tester.ensureVisible(explicit);
      await tester.tap(explicit);
      await tester.pumpAndSettle();
      expect(SettingsService.ratings, isEmpty);
    },
  );

  for (final width in [320.0, 600.0, 1440.0]) {
    testWidgets('feed range and date never move the gallery at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final scale in [1.0, 2.0]) {
        double? galleryTop;
        for (final kind in [
          FeedKind.latest,
          FeedKind.recentPopular,
          FeedKind.historicalPopular,
        ]) {
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 800),
                  textScaler: TextScaler.linear(scale),
                ),
                child: Scaffold(
                  body: Column(
                    children: [
                      HomeHeader(
                        sourceId: 'yande',
                        kind: kind,
                        modes: const [
                          FeedKind.latest,
                          FeedKind.recentPopular,
                          FeedKind.historicalPopular,
                        ],
                        modeLabel: (mode) => mode.name,
                        onSource: (_) {},
                        onMode: (_) {},
                        details: kind == FeedKind.latest
                            ? null
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(
                                    width: 180,
                                    child: AppSelect<int>(
                                      value: 1,
                                      items: const [
                                        AppSelectItem(value: 1, label: 'Month'),
                                      ],
                                      onChanged: (_) {},
                                    ),
                                  ),
                                  if (kind == FeedKind.historicalPopular)
                                    AppButton(
                                      label: '2026-09-05',
                                      compact: true,
                                      onPressed: () {},
                                    ),
                                ],
                              ),
                      ),
                      const Expanded(child: SizedBox(key: ValueKey('gallery'))),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final top = tester
              .getTopLeft(find.byKey(const ValueKey('gallery')))
              .dy;
          galleryTop ??= top;
          expect(top, galleryTop);
          final pickerRect = tester.getRect(find.byType(SourcePicker));
          expect(pickerRect.top, 12);
          for (final button in find.byType(AppButton).evaluate()) {
            final material = find
                .descendant(
                  of: find.byWidget(button.widget),
                  matching: find.byType(Material),
                )
                .first;
            expect(tester.getRect(material).height, pickerRect.height);
            expect(tester.getRect(material).top, pickerRect.top);
          }
          expect(tester.getTopLeft(find.byType(SourcePicker)).dx, 12);
          expect(tester.getSize(find.byType(HomeHeader)).width, width);
          expect(top, pickerRect.height + 20);
          expect(tester.takeException(), isNull);
        }
      }
    });
    testWidgets('home keeps browsing space at $width with large text', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 800),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              body: HomePage(
                loader: (_, _) async =>
                    const PostPage(items: [], exhausted: true),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(HomeHeader)).height, lessThan(180));
      expect(
        tester.getSize(find.byType(PostCollectionView)).height,
        greaterThan(500),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('home request failures retain the source and HTTP diagnostics', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomePage(
            loader: (_, _) async {
              throw const BooruError(
                code: BooruErrorCode.sourceUnavailable,
                sourceId: 'yande',
                httpStatus: 503,
                userMessageKey: 'booru.error.sourceUnavailable',
                diagnosticId: 'home-test',
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('source=yande'), findsOneWidget);
    expect(find.textContaining('HTTP=503'), findsOneWidget);
    expect(find.text(t.generic.notFound), findsNothing);
  });
}
