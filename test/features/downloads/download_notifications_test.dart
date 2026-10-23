import 'package:booruflow/app/app_router.dart';
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/features/downloads/download_notifications.dart';
import 'package:booruflow/features/downloads/downloads_page.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/widgets/download_task_widgets.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../discovery/home_page_test.dart' show browseTestApp;
import 'downloads_v2_test.dart' show task;
import 'support.dart';

void main() {
  setUpAll(initializeDateFormatting);
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));
  test('notice retries its exact network task or failed save', () async {
    final manager = TestDownloadManager();
    await retryNotifiedDownload(
      task: task('network', DownloadStatus.failed).snapshot,
      manager: manager,
    );
    await retryNotifiedDownload(
      task: task(
        'save',
        DownloadStatus.downloaded,
        save: SaveState.failed,
      ).snapshot,
      manager: manager,
    );
    expect(manager.calls, [('retry', 'network'), ('retrySave', 'save')]);
  });
  testWidgets(
    'requested task is revealed lazily once, progress preserves scroll, repeated View selects again',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final items = List.generate(
        80,
        (i) => task('task-$i', DownloadStatus.running),
      );
      final container = ProviderContainer(
        overrides: [
          downloadItemsProvider.overrideWith(() => TestDownloadItems(items)),
          downloadManagerProvider.overrideWithValue(TestDownloadManager()),
        ],
      );
      final request = ValueNotifier('first');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: browseTestApp(
            ValueListenableBuilder(
              valueListenable: request,
              builder: (_, value, _) =>
                  DownloadsPage(taskId: 'task-49', revealRequest: value),
            ),
          ),
        ),
      );
      for (var i = 0; i < 45; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      final selected = tester
          .widgetList<DownloadTaskTile>(find.byType(DownloadTaskTile))
          .where((w) => w.selected);
      expect(selected.map((w) => w.task.snapshot.id), ['task-49']);
      expect(find.byType(DownloadTaskTile).evaluate().length, lessThan(30));
      final scroll = tester
          .widget<CustomScrollView>(
            find.byKey(const PageStorageKey('downloads-scroll')),
          )
          .controller!;
      expect(scroll.offset, greaterThan(0));
      scroll.jumpTo(scroll.offset + 40);
      await tester.pump();
      final before = scroll.offset;
      (container.read(downloadItemsProvider.notifier) as TestDownloadItems)
          .replace(List.of(items));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(scroll.offset, closeTo(before, .001));
      request.value = 'second';
      for (var i = 0; i < 45; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(
        tester
            .widgetList<DownloadTaskTile>(find.byType(DownloadTaskTile))
            .where((w) => w.selected)
            .single
            .task
            .snapshot
            .id,
        'task-49',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      request.dispose();
      container.dispose();
    },
  );
  testWidgets(
    'denied permission notice opens settings only on explicit action',
    (tester) async {
      const channel = MethodChannel('booruflow/download_engine');
      var opened = 0, retried = 0;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'openAppSettings');
        opened++;
        return true;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      await tester.pumpWidget(
        browseTestApp(
          FrostToastHost(child: const SizedBox()),
          navigatorKey: AppRouter.rootNavigatorKey,
        ),
      );
      notifyDownloadEnqueueFailure(
        name: '#42',
        error: const DownloadPermissionDenied('denied'),
        retry: () async {
          retried++;
          return false;
        },
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      expect(opened, 0);
      expect(find.text(t.ugoira.openSettings), findsOneWidget);
      await tester.tap(find.text(t.ugoira.openSettings));
      await tester.pumpAndSettle();
      expect(opened, 1);
      expect(retried, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
