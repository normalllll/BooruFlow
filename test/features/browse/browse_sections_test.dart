import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/browse/browse_page.dart';
import 'package:booruflow/features/browse/collection_logic.dart';
import 'package:booruflow/features/browse/widgets/browse_card.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_page.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';

import '../../support/browse_support.dart';
import '../discovery/search_interaction_test.dart' show testSource;

class _Store implements SettingsServiceStore {
  @override
  Map<String, dynamic> load() => {};
  @override
  Future<void> write(String key, dynamic value) async {}
}

BooruSource _popularSource() {
  final base = testSource('yande');
  return BooruSource(
    sourceId: base.sourceId,
    displayName: base.displayName,
    protocol: base.protocol,
    enabledByDefault: true,
    isAiSource: false,
    capabilities: SourceCapabilities(
      ratings: base.capabilities.ratings,
      authKind: base.capabilities.authKind,
      supportsSearch: true,
      supportsPostDetail: true,
      supportsAutocomplete: true,
      supportsRelatedPosts: false,
      supportsOriginal: true,
      supportsAuthenticatedMedia: false,
      supportsBackgroundDownload: true,
      discovery: const DiscoveryCapabilities(
        popular: CapabilityAvailability.available,
        commonTags: CapabilityAvailability.available,
        popularRanges: [PopularRange.day, PopularRange.week],
        historicalRanges: [PopularRange.day],
        timeBasis: PopularTimeBasis.indexTimeWindow,
        additionalFeeds: [],
        autocompleteMinChars: 1,
      ),
    ),
  );
}

void main() {
  setUp(() async {
    await SettingsService.initialize(store: _Store());
    LocaleSettings.setLocaleSync(AppLocale.en);
    BooruService.instance.useSourcesForTesting([_popularSource()]);
  });

  Future<void> pumpSections(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    TargetPlatform platform = TargetPlatform.android,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      browseTestApp(
        ProviderScope(
          overrides: [
            collectionLoaderProvider.overrideWithValue(
              (key, _) async => PostPage(
                items: List.generate(100, browsePost),
                exhausted: true,
              ),
            ),
          ],
          child: const BrowsePage(),
        ),
        platform: platform,
      ),
    );
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('the tab indicator reaches a tapped tab once and stays', (
    tester,
  ) async {
    await pumpSections(tester);
    final tabs = tester
        .widget<FrostTabBar>(find.byType(FrostTabBar))
        .controller!;
    await tester.tap(find.text(t.discovery.popular).hitTestable().last);
    final values = <double>[];
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      values.add(tabs.animation!.value);
    }
    for (var i = 1; i < values.length; i++) {
      expect(values[i], greaterThanOrEqualTo(values[i - 1]));
    }
    expect(values.last, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the tab indicator follows a sideways drag', (tester) async {
    await pumpSections(tester);
    final tabs = tester
        .widget<FrostTabBar>(find.byType(FrostTabBar))
        .controller!;
    final drag = await tester.startGesture(const Offset(300, 400));
    await drag.moveBy(const Offset(-20, 0));
    await tester.pump();
    await drag.moveBy(const Offset(-100, 0));
    await tester.pump();
    expect(tabs.animation!.value, greaterThan(.2));
    expect(tabs.animation!.value, lessThan(.5));
    await drag.up();
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('the header row hides on scrolling on and returns on scrolling '
      'back, while the tabs stay', (tester) async {
    await pumpSections(tester);
    final menu = find.byType(FrostTitleMenu);
    final tabs = find.byType(FrostTabBar);
    final top = tester.getTopLeft(tabs).dy;
    expect(menu.hitTestable(), findsOneWidget);
    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -400),
    );
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(menu.hitTestable(), findsNothing);
    expect(tester.getTopLeft(tabs).dy, lessThan(top));
    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, 100),
    );
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(menu.hitTestable(), findsOneWidget);
    expect(tester.getTopLeft(tabs).dy, top);
    expect(tester.takeException(), isNull);
  });

  testWidgets('with room the tabs sit in the header row', (tester) async {
    tester.view.physicalSize = const Size(1147, 717);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final tabs = FrostTabController(length: 2, vsync: const TestVSync());
    addTearDown(tabs.dispose);
    await tester.pumpWidget(
      browseTestApp(
        AppSectionPage(
          controller: tabs,
          header: const FrostPageHeader(title: FrostText('Page')),
          tabs: FrostTabBar(
            controller: tabs,
            tabs: const [
              FrostTab(label: 'A'),
              FrostTab(label: 'B'),
            ],
          ),
          sectionBuilder: (_, _) => const AppSection(slivers: []),
        ),
      ),
    );
    await tester.pump();
    final header = tester.getRect(find.byType(FrostPageHeader));
    expect(
      tester.getCenter(find.byType(FrostTabBar)).dy,
      inInclusiveRange(header.top, header.bottom),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tabs beside a header row middle stay clear of it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1147, 717);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final tabs = FrostTabController(length: 2, vsync: const TestVSync());
    addTearDown(tabs.dispose);
    await tester.pumpWidget(
      browseTestApp(
        AppSectionPage(
          controller: tabs,
          header: const FrostPageHeader(
            title: FrostText('Page'),
            middle: SizedBox(key: ValueKey('middle'), width: 360, height: 32),
          ),
          tabs: FrostTabBar(
            controller: tabs,
            tabs: const [
              FrostTab(label: 'A'),
              FrostTab(label: 'B'),
            ],
          ),
          sectionBuilder: (_, _) => const AppSection(slivers: []),
        ),
      ),
    );
    await tester.pump();
    final middle = tester.getRect(find.byKey(const ValueKey('middle')));
    expect(
      tester.getTopLeft(find.byType(FrostTabBar)).dx,
      greaterThanOrEqualTo(middle.right),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the content stays put while the header row slides away', (
    tester,
  ) async {
    await pumpSections(tester);
    final scroller = find.byType(CustomScrollView).first;
    final card = find.byType(BrowseCard).first;
    final gesture = await tester.startGesture(tester.getCenter(scroller));
    await gesture.moveBy(const Offset(0, -20));
    await tester.pump();
    await gesture.moveBy(const Offset(0, -100));
    await tester.pump();
    final before = tester.getTopLeft(card).dy;
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.getTopLeft(card).dy, before);
    }
    await gesture.up();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('only the section on screen follows the primary controller, and '
      'the one left keeps its position', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final tabs = FrostTabController(length: 2, vsync: const TestVSync());
    addTearDown(tabs.dispose);
    final primary = ScrollController();
    addTearDown(primary.dispose);
    await tester.pumpWidget(
      browseTestApp(
        PrimaryScrollController(
          controller: primary,
          child: AppSectionPage(
            controller: tabs,
            header: const FrostPageHeader(title: FrostText('Page')),
            tabs: FrostTabBar(
              controller: tabs,
              tabs: const [
                FrostTab(label: 'A'),
                FrostTab(label: 'B'),
              ],
            ),
            sectionBuilder: (_, index) => AppSection(
              onRefresh: index == 0 ? () async => true : null,
              slivers: const [
                SliverToBoxAdapter(child: SizedBox(height: 4000)),
              ],
            ),
          ),
        ),
        platform: TargetPlatform.iOS,
      ),
    );
    await tester.pump();
    expect(primary.positions, hasLength(1));
    primary.jumpTo(600);
    await tester.pump();
    final first = primary.position;

    tabs.index = 1;
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(primary.positions, hasLength(1));
    expect(primary.position, isNot(same(first)));
    expect(primary.offset, 0);
    expect(first.pixels, 600);

    primary.jumpTo(300);
    tabs.index = 0;
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(primary.positions, hasLength(1));
    expect(primary.offset, 600);
    expect(tester.takeException(), isNull);
  });

  testWidgets('each section keeps its own list and scroll position', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1147, 717);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final loads = <FeedKind, int>{};
    await tester.pumpWidget(
      browseTestApp(
        ProviderScope(
          overrides: [
            collectionLoaderProvider.overrideWithValue((key, _) async {
              final kind = (key.request as FeedCollectionRequest).kind;
              loads[kind] = (loads[kind] ?? 0) + 1;
              return PostPage(
                items: List.generate(100, browsePost),
                exhausted: true,
              );
            }),
          ],
          child: const BrowsePage(),
        ),
      ),
    );
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byType(AppSectionPage), findsOneWidget);
    expect(loads, {FeedKind.latest: 1});

    final latest = find.byType(CustomScrollView).first;
    await tester.drag(latest, const Offset(0, -900));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    double offset() => tester
        .state<ScrollableState>(
          find
              .descendant(
                of: find.byType(CustomScrollView).first,
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position
        .pixels;
    final scrolled = offset();
    expect(scrolled, greaterThan(0));

    await tester.tap(find.text(t.discovery.popular).hitTestable().last);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(loads, {FeedKind.latest: 1, FeedKind.recentPopular: 1});
    expect(find.byType(BrowseCard), findsWidgets);

    await tester.tap(find.text(t.discovery.latest).hitTestable().last);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(loads, {
      FeedKind.latest: 1,
      FeedKind.recentPopular: 1,
    }, reason: 'switching back does not reload a section');
    expect(offset(), scrolled, reason: 'the first section kept its position');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a touch swipe sideways switches to the next section', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final feeds = <FeedKind>[];
    await tester.pumpWidget(
      browseTestApp(
        ProviderScope(
          overrides: [
            collectionLoaderProvider.overrideWithValue((key, _) async {
              feeds.add((key.request as FeedCollectionRequest).kind);
              return PostPage(
                items: List.generate(40, browsePost),
                exhausted: true,
              );
            }),
          ],
          child: const BrowsePage(),
        ),
        platform: TargetPlatform.android,
      ),
    );
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(feeds, [FeedKind.latest]);
    await tester.fling(
      find.byType(BrowseCard).first,
      const Offset(-300, 0),
      1200,
    );
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(feeds, [FeedKind.latest, FeedKind.recentPopular]);
    expect(tester.takeException(), isNull);
  });
}
