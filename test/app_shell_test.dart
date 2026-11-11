import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:booruflow/app/app_router.dart';
import 'package:booruflow/app/booru_flow_app.dart';
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/settings/background.dart';
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/booru/web_challenge_page.dart';
import 'package:booruflow/features/browse/collection_logic.dart';
import 'package:booruflow/features/downloads/download_notifications.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/features/downloads/widgets/download_task_details.dart';
import 'package:booruflow/features/downloads/widgets/download_task_widgets.dart';
import 'package:booruflow/features/search/logic.dart';
import 'package:booruflow/features/tags/my_tags_page.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:booruflow/ui/custom/download_flight.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';

import 'features/discovery/search_interaction_test.dart'
    show testSource, SearchRepositoryFake;
import 'features/downloads/download_tasks_test.dart' show task;
import 'features/downloads/support.dart' show TestDownloadManager;

final class _MemoryStore implements SettingsServiceStore {
  final values = <String, dynamic>{};
  @override
  Map<String, dynamic> load() => Map.of(values);
  @override
  Future<void> write(String key, dynamic value) async => values[key] = value;
}

class _NoDownloads extends DownloadItems {
  _NoDownloads(this.items);
  final List<BooruDownloadItem> items;
  @override
  List<BooruDownloadItem> build() => items;
}

// GoRouter first publishes shell navigation, then mounts its new Page on the
// next frame. The previous root header must stay still during that interval.
Future<void> pumpIncomingPage(WidgetTester tester, Finder page) async {
  for (var frame = 0; frame < 3 && page.evaluate().isEmpty; frame++) {
    expect(
      find.byType(FrostCompactBackButton),
      findsNothing,
      reason: 'A covered root must not gain the incoming page back control.',
    );
    await tester.pump();
  }
  expect(
    page,
    findsOneWidget,
    reason: 'Inspect the first frame that actually mounts the incoming page.',
  );
}

Finder _captionButton(String label) => find.ancestor(
  of: find.byWidgetPredicate(
    (widget) => widget is Semantics && widget.properties.label == label,
  ),
  matching: find.byType(IconButton),
);

void main() {
  const channel = MethodChannel('frost_window');
  late _MemoryStore store;
  setUp(() async {
    store = _MemoryStore();
    await SettingsService.initialize(store: store);
    LocaleSettings.setLocaleSync(AppLocale.en);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (call) async => call.method == 'getState'
              ? {
                  'revision': 0,
                  'active': true,
                  'captionMode': defaultTargetPlatform == TargetPlatform.macOS
                      ? 'nativeControls'
                      : 'client',
                  'leftButtons': <String>[],
                  'rightButtons': defaultTargetPlatform == TargetPlatform.macOS
                      ? <String>[]
                      : ['minimize', 'maximize', 'close'],
                  'nativeControls':
                      defaultTargetPlatform == TargetPlatform.macOS
                      ? [12.0, 12.0, 72.0, 28.0]
                      : [0.0, 0.0, 0.0, 0.0],
                }
              : null,
        );
    AppRouter.router.go('/');
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<void> mount(
    WidgetTester tester, {
    TransitionBuilder? builder,
    List<BooruDownloadItem> downloads = const [],
  }) async {
    addTearDown(() => tester.pumpWidget(const SizedBox()));
    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            downloadItemsProvider.overrideWith(() => _NoDownloads(downloads)),
            downloadManagerProvider.overrideWithValue(TestDownloadManager()),
            tagSuggestionRepositoryProvider.overrideWithValue(
              SearchRepositoryFake(),
            ),
            booruServiceProvider.overrideWithValue(
              BooruService()..useSourcesForTesting([testSource('yande')]),
            ),
            collectionLoaderProvider.overrideWithValue(
              (_, _) async => const PostPage(items: [], exhausted: true),
            ),
          ],
          child: BooruFlowApp(
            windowController: FrostWindowController(
              minimumSize: const Size(320, 480),
            ),
            checkUpdates: false,
            builder: builder,
          ),
        ),
      ),
    );
    for (var frame = 0; frame < 12; frame++) {
      await tester.pump();
    }
  }

  testWidgets(
    'title bar search keeps its query, caret and focus across 1024, 1440 and 1920',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await mount(tester);
      AppRouter.router.go('/tags');
      await tester.pumpAndSettle();
      final titleEditor = find.descendant(
        of: find.byType(FrostCaptionSearch),
        matching: find.byType(EditableText),
      );
      final initial = tester.state(titleEditor);
      final input = tester.widget<EditableText>(titleEditor);
      input.focusNode.requestFocus();
      await tester.pumpAndSettle();
      input.controller.value = const TextEditingValue(
        text: 'retained query',
        selection: TextSelection.collapsed(offset: 5),
      );
      await tester.pump();
      for (final width in [1024.0, 1025.0, 1440.0, 1920.0]) {
        tester.view.physicalSize = Size(width, 900);
        await tester.pump();
        expect(
          find.descendant(
            of: find.byType(FrostPageHeader),
            matching: find.byType(FrostSearchInput),
          ),
          findsNothing,
          reason: 'the page header carries no search beside the sidebar',
        );
        expect(tester.state(titleEditor), same(initial));
        expect(input.controller.text, 'retained query');
        expect(input.controller.selection.extentOffset, 5);
        expect(input.focusNode.hasFocus, isTrue);
      }
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );
  testWidgets(
    'downloads tooltips survive expanded rows, batch reveals and shell changes',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await mount(
        tester,
        downloads: [
          task('running', DownloadStatus.running),
          task('batch-a', DownloadStatus.running, batch: 'batch'),
          task('batch-b', DownloadStatus.queued, batch: 'batch'),
          task('failed', DownloadStatus.failed),
        ],
      );
      AppRouter.router.go('/downloads');
      await tester.pumpAndSettle();
      await tester.tap(find.text('running.png'));
      await tester.pumpAndSettle();
      expect(find.byType(DownloadTaskDetails), findsOneWidget);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      Future<void> hover(Finder target) async {
        await mouse.moveTo(tester.getCenter(target));
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pump(const Duration(milliseconds: 300));
        for (final tooltip in find.byType(RawTooltip).evaluate()) {
          expect(Overlay.maybeOf(tooltip), isNotNull);
        }
        expect(tester.takeException(), isNull);
      }

      final row = find.ancestor(
        of: find.text('running.png'),
        matching: find.byType(DownloadTaskTile),
      );
      // Pointer actions belong to the row, not to the details below it.
      Finder rowOnly(Finder tile) =>
          find.descendant(of: tile, matching: find.byType(FrostSwipeActions));
      await hover(rowOnly(row));
      for (final label in [t.downloads.pause, t.frost.more]) {
        await hover(
          find
              .descendant(
                of: row,
                matching: find.byWidgetPredicate(
                  (w) => w is FrostTooltip && w.message == label,
                ),
              )
              .hitTestable()
              .first,
        );
      }
      final batch = find.byWidgetPredicate(
        (w) => w is FrostListRow && w.title.contains(t.downloads.batch),
      );
      expect(batch, findsOneWidget);
      if (find.text('batch-a.png').evaluate().isEmpty) {
        await tester.tap(batch);
        await tester.pumpAndSettle();
      }
      expect(find.text('batch-a.png'), findsOneWidget);
      await hover(
        find.ancestor(
          of: find.text('batch-a.png'),
          matching: find.byType(DownloadTaskTile),
        ),
      );
      await tester.tap(batch);
      await tester.pumpAndSettle();
      expect(row.hitTestable(), findsOneWidget);
      for (final mode in [ThemeMode.dark, ThemeMode.light]) {
        await SettingsService.saveAppearance(
          SettingsService.appearance.copyWith(mode: mode),
        );
        await tester.pumpAndSettle();
      }
      AppRouter.router.go('/tags');
      await tester.pumpAndSettle();
      AppRouter.router.go('/downloads');
      await tester.pumpAndSettle();
      await hover(
        rowOnly(
          find.ancestor(
            of: find.text('running.png'),
            matching: find.byType(DownloadTaskTile),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );
  testWidgets(
    'result toast View opens Downloads and selects its exact task through the real router',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await mount(
        tester,
        downloads: [task('toast-target', DownloadStatus.running)],
      );
      notifyDownloadAdded(taskId: 'toast-target', name: '#42');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      await tester.tap(find.text(t.verificationPage.view));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(AppRouter.currentUri.path, '/downloads');
      expect(AppRouter.currentUri.queryParameters['task'], 'toast-target');
      expect(
        tester
            .widgetList<DownloadTaskTile>(find.byType(DownloadTaskTile))
            .where((w) => w.expanded)
            .single
            .task
            .snapshot
            .id,
        'toast-target',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'router Back excludes popups, follows replacement and handles deep-linked parents synchronously',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await mount(tester);
      final shellState = tester.state(find.byType(FrostShell));
      FrostShell shell() => tester.widget<FrostShell>(find.byType(FrostShell));
      final context = tester.element(find.byType(FrostPageHeader));
      final popup = showFrostDialog<void>(
        context: context,
        builder: (_) =>
            FrostDialog(title: 'Popup', content: const Text('Content')),
      );
      await tester.pump();
      expect(shell().canGoBack, isFalse);
      Navigator.of(tester.element(find.byType(FrostDialog))).pop();
      await tester.pumpAndSettle();
      await popup;
      final result = AppRouter.pushContent<bool>(
        context,
        const FrostPageHeader(title: Text('Transient')),
      );
      await tester.pump();
      expect(shell().canGoBack, isTrue);
      expect(shell().atDestinationRoot, isFalse);
      await pumpIncomingPage(tester, find.text('Transient'));
      expect(find.byType(FrostCompactBackButton), findsOneWidget);
      AppRouter.router.pop(true);
      await tester.pumpAndSettle();
      expect(await result, isTrue);
      expect(shell().canGoBack, isFalse);
      expect(tester.takeException(), isNull, reason: 'before deep link');
      AppRouter.router.go('/settings/about');
      await tester.pump();
      expect(
        shell().canGoBack,
        isTrue,
        reason:
            'a secondary deep link has a logical parent without a pushed route',
      );
      expect(tester.takeException(), isNull, reason: 'deep link first frame');
      AppRouter.popRightNavigator();
      await tester.pumpAndSettle();
      expect(AppRouter.currentUri.path, '/settings');
      expect(shell().canGoBack, isFalse);
      expect(tester.state(find.byType(FrostShell)), same(shellState));
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
  testWidgets(
    'one destination bar stays while real secondary routes cover its full viewport',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      // The floating downloads entry is the bar-layout widget the shell
      // retains across destinations and content pages.
      await mount(
        tester,
        downloads: [task('secondary', DownloadStatus.running)],
      );
      await tester.pumpAndSettle();
      final target = find.byType(DownloadFlightTarget);
      final state = tester.state(target);
      // A destination root stays built, offstage, below the content pages.
      final root = find.byType(FrostShellDestination, skipOffstage: false);
      final rootElement = root.evaluate().single;
      final barRect = tester.getRect(target);
      for (final path in ['/tags', '/downloads', '/settings', '/']) {
        AppRouter.router.go(path);
        await tester.pumpAndSettle();
        expect(root.evaluate().single, same(rootElement));
        expect(tester.state(target), same(state));
        expect(tester.getRect(target), barRect);
      }
      const page = ValueKey('secondary viewport');
      AppRouter.pushContent<void>(
        tester.element(root),
        const SizedBox.expand(
          key: page,
          child: FrostPageHeader(title: Text('Secondary')),
        ),
      );
      await tester.pump();
      await pumpIncomingPage(tester, find.byKey(page));
      for (var frame = 0; frame < 30; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(
          tester.getSize(find.byKey(page)),
          const Size(390, 844),
          reason: 'Native entry may translate, but the viewport never resizes',
        );
        expect(
          find
              .byType(FrostShellDestination, skipOffstage: false)
              .evaluate()
              .single,
          same(rootElement),
        );
        expect(
          tester.state(find.byType(DownloadFlightTarget, skipOffstage: false)),
          same(state),
        );
      }
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byKey(page)),
        const Rect.fromLTWH(0, 0, 390, 844),
      );
      AppRouter.router.pop();
      await tester.pumpAndSettle();
      expect(tester.getRect(target), barRect);
      expect(tester.state(target), same(state));
      expect(
        tester
            .widget<Scaffold>(
              find
                  .descendant(
                    of: find.byType(FrostShell),
                    matching: find.byType(Scaffold),
                  )
                  .first,
            )
            .bottomNavigationBar,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'verification content navigation keeps the shell and hides root navigation',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await mount(tester);
      final shell = tester.state(find.byType(FrostShell));
      final context = tester.element(find.byType(FrostPageHeader));
      final result = AppRouter.pushContent<void>(
        context,
        const WebChallengeLayout(sourceName: 'Gelbooru', content: SizedBox()),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(tester.state(find.byType(FrostShell)), same(shell));
      expect(
        tester
            .widget<FrostShell>(find.byType(FrostShell))
            .showsMobileNavigation,
        isTrue,
      );
      expect(
        tester.widget<FrostShell>(find.byType(FrostShell)).canGoBack,
        isTrue,
      );
      expect(find.byType(FrostPageHeader), findsOneWidget);
      AppRouter.popRightNavigator();
      await tester.pumpAndSettle();
      await result;
      expect(
        tester.widget<FrostShell>(find.byType(FrostShell)).canGoBack,
        isFalse,
      );
      expect(tester.state(find.byType(FrostShell)), same(shell));
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'application composition reads live safe metrics below MaterialApp without duplicating phone header',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await mount(
        tester,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: 47, bottom: 34),
            viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
          ),
          child: child!,
        ),
      );
      final header = find.byType(FrostPageHeader);
      expect(header, findsOneWidget);
      expect(tester.getRect(header).top, 47);
      expect(tester.getSize(header).height, 48);
      expect(
        tester
            .widget<FrostShell>(find.byType(FrostShell))
            .showsMobileNavigation,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  for (final width in [390.0, 720.0, 1024.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets(
        'first frame and three destinations width=$width dark=$dark',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await SettingsService.saveAppearance(
            SettingsService.appearance.copyWith(
              mode: dark ? ThemeMode.dark : ThemeMode.light,
            ),
          );
          await mount(tester);
          final shell = tester.widget<FrostShell>(find.byType(FrostShell));
          expect(shell.destinations.map((item) => item.label), [
            'Browse',
            'Tags',
            'Settings',
          ]);
          expect(_captionButton(t.frost.close), findsOneWidget);
          // A landscape window has the sidebar and the one Back is the title
          // bar's, disabled on a root page. A portrait window has the bottom
          // bar, and a root page has no Back.
          final sidebar = width >= 900;
          final back = find.bySemanticsLabel(t.frost.back);
          if (sidebar) {
            expect(back, findsOneWidget);
            expect(tester.getCenter(back).dx, closeTo(30, .01));
            final browse = find.byWidgetPredicate(
              (w) => w is FrostNavItem && w.label == 'Browse',
            );
            final icon = find
                .descendant(of: browse, matching: find.byType(FrostIcon))
                .first;
            expect(tester.getCenter(icon).dx, closeTo(30, .01));
            expect(
              tester
                  .getSemantics(back)
                  .getSemanticsData()
                  .flagsCollection
                  .isEnabled,
              Tristate.isFalse,
            );
          } else {
            expect(back, findsNothing);
          }
          expect(find.byType(FrostCompactBackButton), findsNothing);
          expect(tester.getSize(_captionButton(t.frost.close)).height, 40);
          final pageHeader = tester.getRect(find.byType(FrostPageHeader));
          expect(pageHeader.top, 40);
          expect(pageHeader.height, width < 600 ? 48 : 52);
          expect(find.text('BooruFlow'), findsOneWidget);
          expect(
            FrostThemeTokens.of(
              tester.element(find.byType(FrostPageHeader)),
            ).brightness,
            dark ? Brightness.dark : Brightness.light,
          );
          await tester.tap(
            sidebar
                ? find.byWidgetPredicate(
                    (widget) =>
                        widget is FrostNavItem && widget.label == 'Tags',
                  )
                : find.text('Tags').hitTestable(),
          );
          await tester.pumpAndSettle();
          expect(
            AppRouter.router.routeInformationProvider.value.uri.path,
            '/tags',
          );
          expect(
            tester.widget<FrostShell>(find.byType(FrostShell)).selectedIndex,
            1,
          );
          // The search is the title bar's while it is in the title row,
          // otherwise the page's.
          final header = find.byType(FrostPageHeader);
          expect(
            find.descendant(
              of: header,
              matching: find.byType(FrostSearchInput),
            ),
            sidebar ? findsNothing : findsOneWidget,
          );
          expect(
            find.byType(FrostCaptionSearch),
            sidebar ? findsOneWidget : findsNothing,
          );
          if (!sidebar) {
            // The hidden title bar search leaves a request to the inline one.
            ProviderScope.containerOf(
              tester.element(header),
            ).read(pendingSearchProvider.notifier).request('dog');
            await tester.pumpAndSettle();
            expect(
              find.byWidgetPredicate(
                (w) => w is EditableText && w.controller.text.contains('dog'),
                skipOffstage: false,
              ),
              findsOneWidget,
            );
            expect(
              find.descendant(of: header, matching: find.byType(EditableText)),
              findsOneWidget,
            );
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
        },
        variant: TargetPlatformVariant.only(TargetPlatform.windows),
      );
    }
  }

  testWidgets(
    'sidebar preference and live appearance survive shell navigation',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await mount(tester);
      void expectIconColumn() {
        final back = find.bySemanticsLabel(t.frost.back);
        final browse = find.byWidgetPredicate(
          (w) => w is FrostNavItem && w.label == 'Browse',
        );
        final icon = find
            .descendant(of: browse, matching: find.byType(FrostIcon))
            .first;
        expect(tester.getCenter(back).dx, closeTo(30, .01));
        expect(tester.getCenter(icon).dx, closeTo(30, .01));
      }

      expectIconColumn();
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is FrostTooltip && widget.message == 'Collapse sidebar',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expectIconColumn();
      await tester.pumpAndSettle();
      expectIconColumn();
      expect(SettingsService.sidebarExpanded, false);
      expect(store.values['sidebarExpanded'], false);
      final before = AppRouter.router.routeInformationProvider.value.uri;
      await SettingsService.saveAppearance(
        SettingsService.appearance.copyWith(mode: ThemeMode.dark),
      );
      await SettingsService.saveBackground(
        const BackgroundSettings(material: BackgroundMaterial.off),
      );
      await tester.pumpAndSettle();
      expect(AppRouter.router.routeInformationProvider.value.uri, before);
      expect(
        FrostScope.solidSurfaces(tester.element(find.byType(FrostPageHeader))),
        isTrue,
      );
      expect(
        FrostThemeTokens.of(
          tester.element(find.byType(FrostPageHeader)),
        ).brightness,
        Brightness.dark,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );
  for (final width in [1024.0, 1440.0, 2560.0]) {
    testWidgets(
      'search and downloads share their header text keyline at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await mount(
          tester,
          downloads: [
            BooruDownloadItem(
              snapshot: DownloadTaskSnapshot(
                id: 'keyline',
                resourceId: 1,
                variantIndex: 0,
                title: 'keyline',
                filename: 'keyline.png',
                status: DownloadStatus.running,
                saveState: SaveState.none,
                receivedBytes: 50,
                totalBytes: 100,
                progress: .5,
                localPath: null,
                error: null,
                log: null,
                createdAt: DateTime(2026),
                updatedAt: DateTime(2026),
              ),
            ),
          ],
        );
        double textLeft(Finder finder) {
          final paragraph = tester.renderObject<RenderParagraph>(finder);
          final first = paragraph
              .getBoxesForSelection(
                const TextSelection(baseOffset: 0, extentOffset: 1),
              )
              .first;
          return paragraph.localToGlobal(Offset(first.left, first.top)).dx;
        }

        AppRouter.router.go('/tags');
        await tester.pumpAndSettle();
        final source = find
            .descendant(
              of: find.byType(FrostPageHeader),
              matching: find.text('yande'),
            )
            .first;
        final recent = find.text(t.discovery.commonTags);
        // Font roles add up to .1 logical pixel of glyph tracking; their
        // paragraph keylines must still coincide exactly on the cold frame.
        expect(
          tester.getRect(source).left,
          closeTo(tester.getRect(recent).left, .01),
        );
        expect(textLeft(source), closeTo(textLeft(recent), .25));
        // Tags fills the content area, so its text starts at the area's
        // keyline, as on the other destinations.
        // The sidebar is as wide as its longest destination label (Settings);
        // Downloads is the entry below them.
        final keyline = textLeft(recent);
        expect(keyline, closeTo(width < 1200 ? 84 : 234, .25));
        AppRouter.router.go('/downloads');
        await tester.pumpAndSettle();
        final title = find
            .descendant(
              of: find.byType(FrostPageHeader),
              matching: find.text(t.downloads.title),
            )
            .first;
        final active = find.text(t.downloads.activeTasks(count: '1'));
        expect(
          tester.getRect(title).left,
          closeTo(tester.getRect(active).left, .01),
        );
        expect(textLeft(title), closeTo(textLeft(active), .25));
        // Downloads fills the content area too.
        expect(textLeft(active), closeTo(keyline, .25));
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.windows),
    );
  }
  testWidgets(
    'four languages update navigation and the current header without navigation reset',
    (tester) async {
      await mount(tester);
      for (final language in [1, 2, 3, 0]) {
        SettingsService.language = language;
        await tester.pumpAndSettle();
        expect(AppRouter.router.routeInformationProvider.value.uri.path, '/');
        final shell = tester.widget<FrostShell>(find.byType(FrostShell));
        expect(shell.destinations.first.label, t.navigation.browse);
        expect(
          find.descendant(
            of: find.byType(FrostPageHeader),
            matching: find.byType(FrostTitleMenu),
          ),
          findsOneWidget,
        );
        final context = tester.element(find.byType(FrostPageHeader));
        expect(
          FrostScope.labelsOf(context).navigationStatus(2, 50),
          isNotEmpty,
        );
        expect(FrostScope.labelsOf(context).retry, t.frost.retry);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
  for (final platform in [TargetPlatform.linux, TargetPlatform.macOS]) {
    testWidgets(
      '$platform places content below the single integrated title row',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await mount(tester);
        expect(
          _captionButton(t.frost.close),
          platform == TargetPlatform.macOS ? findsNothing : findsOneWidget,
        );
        final headerTop = tester.getRect(find.byType(FrostPageHeader)).top;
        if (platform == TargetPlatform.macOS) {
          final host = tester.widget<FrostWindowHost>(
            find.byType(FrostWindowHost),
          );
          final native = host.controller.state.nativeControls;
          expect(headerTop, greaterThan(native.bottom));
          // Back shares the title row with the traffic lights, after them.
          final back = tester.getRect(
            find.byKey(const ValueKey('frost-shell-back')),
          );
          expect(back.bottom, lessThanOrEqualTo(headerTop));
          expect(back.left, greaterThanOrEqualTo(native.right));
        } else {
          expect(headerTop, 40);
        }
        expect(
          tester
              .getRect(
                find.byWidgetPredicate(
                  (widget) =>
                      widget is FrostTooltip &&
                      widget.message == 'Collapse sidebar',
                ),
              )
              .top,
          greaterThan(800),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
      variant: TargetPlatformVariant.only(platform),
    );
  }
  for (final platform in [
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.macOS,
    TargetPlatform.android,
    TargetPlatform.iOS,
  ]) {
    for (final width in [390.0, 1440.0]) {
      testWidgets(
        'fixed shell Back real route push and pop $platform width=$width',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await mount(tester);
          final pointer =
              platform != TargetPlatform.android &&
              platform != TargetPlatform.iOS;
          final horizontal = width >= 480 && width / 900 >= (pointer ? 1 : 1.3);
          Finder back() => find
              .byWidgetPredicate(
                (w) => w is FrostTooltip && w.message == t.frost.back,
              )
              .hitTestable();
          final initial = horizontal ? tester.getRect(back()) : null;
          if (horizontal) {
            expect(
              tester
                  .getSemantics(find.bySemanticsLabel(t.frost.back))
                  .getSemanticsData()
                  .flagsCollection
                  .isEnabled,
              Tristate.isFalse,
            );
          } else {
            expect(back(), findsNothing);
          }
          AppRouter.router.push<void>(AppRoute.userTags.path);
          await tester.pump();
          expect(
            tester.widget<FrostShell>(find.byType(FrostShell)).canGoBack,
            isTrue,
            reason: 'Back exists on the first routed frame',
          );
          await pumpIncomingPage(tester, find.byType(MyTagsPage));
          expect(
            find.byType(FrostCompactBackButton),
            horizontal ? findsNothing : findsOneWidget,
          );
          await tester.pumpAndSettle();
          expect(AppRouter.currentUri.path, AppRoute.userTags.path);
          final shell = tester.widget<FrostShell>(find.byType(FrostShell));
          expect(shell.showsMobileNavigation, isTrue);
          expect(shell.atDestinationRoot, isFalse);
          expect(shell.selectedIndex, 1);
          if (!horizontal) {
            for (final label in ['Browse', 'Tags', 'Settings']) {
              expect(find.text(label).hitTestable(), findsNothing);
            }
          }
          expect(back(), findsOneWidget);
          final headerBack = find.descendant(
            of: find.byType(FrostPageHeader),
            matching: find.byType(FrostCompactBackButton),
          );
          expect(headerBack, horizontal ? findsNothing : findsOneWidget);
          if (horizontal) expect(tester.getRect(back()), initial);
          await tester.tap(back());
          await tester.pumpAndSettle();
          expect(AppRouter.currentUri.path, '/');
          if (horizontal) {
            expect(tester.getRect(back()), initial);
            expect(
              tester
                  .getSemantics(find.bySemanticsLabel(t.frost.back))
                  .getSemanticsData()
                  .flagsCollection
                  .isEnabled,
              Tristate.isFalse,
            );
          } else {
            expect(back(), findsNothing);
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
        },
        variant: TargetPlatformVariant.only(platform),
      );
    }
  }

  testWidgets('the title bar search shows the shortcut that focuses it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await mount(tester);
    final search = find.byType(FrostCaptionSearch);
    final hint = find.descendant(
      of: search,
      matching: find.text(
        const FrostShortcut(
          LogicalKeyboardKey.keyK,
          primary: true,
        ).hintLabel(tester.element(search)),
      ),
    );
    expect(hint, findsOneWidget);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.descendant(
        of: search,
        matching: find.byWidgetPredicate(
          (w) => w is EditableText && w.focusNode.hasFocus,
        ),
      ),
      findsOneWidget,
    );
    expect(hint, findsNothing);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  group('Escape', () {
    Future<void> open(WidgetTester tester, Widget page) async {
      unawaited(
        AppRouter.pushContent<void>(
          tester.element(find.byType(FrostPageHeader).first),
          page,
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();
    }

    Future<void> escape(WidgetTester tester) async {
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
    }

    bool atRoot(WidgetTester tester) =>
        !tester.widget<FrostShell>(find.byType(FrostShell)).canGoBack;

    testWidgets('goes back one page at a time and stops at the root', (
      tester,
    ) async {
      await mount(tester);
      await open(tester, const FrostPageHeader(title: Text('First')));
      await open(tester, const FrostPageHeader(title: Text('Second')));
      await escape(tester);
      expect(find.text('Second'), findsNothing);
      // The title row shows the page title; the header keeps a copy for
      // screen readers.
      expect(find.text('First'), findsWidgets);
      await escape(tester);
      expect(find.text('First'), findsNothing);
      expect(atRoot(tester), isTrue);
      await escape(tester);
      expect(atRoot(tester), isTrue);
      expect(AppRouter.currentUri.path, '/');
      expect(tester.takeException(), isNull);
    });

    testWidgets('drops the focus of a field before leaving the page', (
      tester,
    ) async {
      final controller = TextEditingController();
      final focus = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focus.dispose);
      await mount(tester);
      await open(
        tester,
        Column(
          children: [
            const FrostPageHeader(title: Text('Form')),
            FrostTextField(controller: controller, focusNode: focus),
          ],
        ),
      );
      focus.requestFocus();
      await tester.pump();
      expect(focus.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(focus.hasFocus, isFalse);
      expect(find.text('Form'), findsWidgets);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Form'), findsNothing);
      expect(atRoot(tester), isTrue);
    });

    testWidgets('closes an open menu before leaving the page', (tester) async {
      await mount(tester);
      await open(
        tester,
        FrostPageHeader(
          leading: [
            FrostTitleMenu(
              title: 'Menu',
              entries: [FrostMenuAction('Entry', onSelected: () {})],
            ),
          ],
        ),
      );
      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();
      expect(find.text('Entry'), findsOneWidget);
      await escape(tester);
      expect(find.text('Entry'), findsNothing);
      expect(find.text('Menu'), findsOneWidget);
      await escape(tester);
      expect(find.text('Menu'), findsNothing);
      expect(atRoot(tester), isTrue);
    });
  });
}
