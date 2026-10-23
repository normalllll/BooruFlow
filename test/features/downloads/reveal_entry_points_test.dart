import 'package:booruflow/app/app_router.dart';
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/downloads/download_path_reveal.dart';
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/downloads/downloads_page.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/features/downloads/widgets/download_task_widgets.dart';
import 'package:booruflow/features/settings/settings_page.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import '../discovery/home_page_test.dart' show browseTestApp;
import '../discovery/search_interaction_test.dart' show testSource;
import 'support.dart';

class _Revealer extends DownloadPathRevealer {
  _Revealer(this.result);
  final DownloadRevealStatus result;
  final calls = <(String, bool)>[];
  @override
  Future<DownloadRevealStatus> reveal(
    String path, {
    bool directory = false,
  }) async {
    calls.add((path, directory));
    return result;
  }
}

class _Store implements SettingsServiceStore {
  final values = <String, dynamic>{
    'downloadPath': r'D:\Missing Download Folder',
  };
  @override
  Map<String, dynamic> load() => Map.of(values);
  @override
  Future<void> write(String key, dynamic value) async => values[key] = value;
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));
  final item = BooruDownloadItem(
    snapshot: DownloadTaskSnapshot(
      id: 'task',
      postId: '363100',
      resourceId: 363100,
      variantIndex: 0,
      title: '#363100',
      filename: '363100 (1).png',
      status: DownloadStatus.downloaded,
      saveState: SaveState.saved,
      receivedBytes: 128,
      totalBytes: 128,
      progress: 1,
      localPath:
          r'C:\Users\fixture\Downloads\BooruFlow\yande/muryo\363100 (1).png',
      error: null,
      log: null,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ),
  );
  Future<void> secondary(WidgetTester tester, Finder target) async {
    final pointer = await tester.startGesture(
      tester.getCenter(target),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await pointer.up();
    await tester.pumpAndSettle();
  }

  Future<void> mount(
    WidgetTester tester,
    _Revealer revealer,
    TestDownloadManager manager,
    Widget body,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          booruSourcesProvider.overrideWithValue([testSource('yande')]),
          downloadItemsProvider.overrideWith(() => TestDownloadItems([item])),
          downloadManagerProvider.overrideWithValue(manager),
          downloadPathRevealerProvider.overrideWith((_) => revealer),
        ],
        child: browseTestApp(
          FrostToastHost(child: body),
          navigatorKey: AppRouter.rootNavigatorKey,
        ),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(() => tester.pumpWidget(const SizedBox()));
  }

  for (final entry in ['context menu', 'inspector']) {
    for (final result in [
      DownloadRevealStatus.file,
      DownloadRevealStatus.fileMissing,
      DownloadRevealStatus.missing,
    ]) {
      testWidgets(
        '$entry shares normalized reveal, missing feedback and real retry entry: $result',
        (tester) async {
          final revealer = _Revealer(result);
          final manager = TestDownloadManager();
          await mount(tester, revealer, manager, const DownloadsPage());
          final row = find.byType(DownloadTaskTile);
          if (entry == 'context menu') {
            await secondary(tester, row);
            await tester.tap(find.text(t.frost.showInFolder).hitTestable());
          } else {
            await tester.tap(row);
            await tester.pumpAndSettle();
            final button = find
                .byWidgetPredicate(
                  (w) => w is FrostButton && w.label == t.frost.showInFolder,
                )
                .hitTestable();
            await tester.ensureVisible(button);
            await tester.tap(button);
          }
          await tester.pumpAndSettle();
          expect(revealer.calls, [(item.snapshot.localPath!, false)]);
          if (result == DownloadRevealStatus.fileMissing) {
            expect(find.text(t.downloads.fileMissing), findsOneWidget);
            expect(find.text(t.downloads.redownload), findsNothing);
          } else if (result == DownloadRevealStatus.missing) {
            expect(find.text(t.downloads.locationMissing), findsOneWidget);
            await tester.tap(find.text(t.downloads.redownload).hitTestable());
            await tester.pumpAndSettle();
            expect(manager.calls, [('retry', 'task')]);
          } else {
            expect(find.text(t.downloads.locationMissing), findsNothing);
            expect(find.text(t.downloads.fileMissing), findsNothing);
          }
        },
      );
    }
  }
  testWidgets(
    'settings directory context menu uses the same revealer and explains missing directory',
    (tester) async {
      await SettingsService.initialize(store: _Store());
      final revealer = _Revealer(DownloadRevealStatus.missing);
      await mount(
        tester,
        revealer,
        TestDownloadManager(),
        const SettingsPage(section: SettingsSection.downloads),
      );
      final row = find.byWidgetPredicate(
        (w) => w is FrostListRow && w.title == t.settings.downloadDirectory,
      );
      await secondary(tester, row);
      await tester.tap(find.text(t.frost.showInFolder).hitTestable());
      await tester.pumpAndSettle();
      expect(revealer.calls, [(SettingsService.downloadPath!, true)]);
      expect(find.text(t.downloads.locationMissing), findsOneWidget);
      expect(find.text(t.downloads.redownload), findsNothing);
    },
  );
}
