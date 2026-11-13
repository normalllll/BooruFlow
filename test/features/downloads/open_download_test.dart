import 'dart:io';

import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/downloads/download_path_reveal.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/features/downloads/widgets/download_task_details.dart';
import 'package:booruflow/features/downloads/widgets/download_task_widgets.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';

import '../../support/browse_support.dart' show browseTestApp;
import 'support.dart';

DownloadTaskSnapshot _snapshot({
  required DownloadStatus status,
  String? localPath,
  SaveState saveState = SaveState.none,
}) => DownloadTaskSnapshot(
  id: 'job-1',
  resourceId: 42,
  variantIndex: 0,
  title: 'Yande #42',
  filename: '42.png',
  status: status,
  saveState: saveState,
  receivedBytes: 10,
  totalBytes: 10,
  progress: 1,
  localPath: localPath,
  error: status == DownloadStatus.failed ? 'Download failed' : null,
  log: null,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));

  group('DownloadPathRevealer.open', () {
    const path = '/downloads/42.png';

    test('opens an existing file through a file URI', () async {
      final opened = <Uri>[];
      final revealer = DownloadPathRevealer(
        operatingSystem: 'linux',
        probe: (_) async => FileSystemEntityType.file,
        openUri: (uri) async {
          opened.add(uri);
          return true;
        },
      );
      await revealer.open(path);
      expect(opened, hasLength(1));
      expect(opened.single.scheme, 'file');
      expect(opened.single.toFilePath(windows: false), path);
    });

    test('hands a content URI over unchanged', () async {
      const content = 'content://com.android.providers/document/42';
      final opened = <Uri>[];
      final revealer = DownloadPathRevealer(
        operatingSystem: 'android',
        probe: (_) async => FileSystemEntityType.notFound,
        openUri: (uri) async {
          opened.add(uri);
          return true;
        },
      );
      await revealer.open(content);
      expect(opened.map((uri) => uri.toString()), [content]);
    });

    test('reports a missing file without opening anything', () async {
      var opens = 0;
      final revealer = DownloadPathRevealer(
        operatingSystem: 'linux',
        probe: (_) async => FileSystemEntityType.notFound,
        openUri: (_) async {
          opens++;
          return true;
        },
      );
      final status = await revealer.open(path);
      expect(
        status,
        anyOf(DownloadRevealStatus.fileMissing, DownloadRevealStatus.missing),
      );
      expect(opens, 0);
    });

    test('throws when no app can open the file', () async {
      final revealer = DownloadPathRevealer(
        operatingSystem: 'linux',
        probe: (_) async => FileSystemEntityType.file,
        openUri: (_) async => false,
      );
      await expectLater(revealer.open(path), throwsA(anything));
    });
  });

  group('DownloadTaskTile open action', () {
    Future<void> mount(WidgetTester tester, DownloadTaskSnapshot task) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            downloadManagerProvider.overrideWithValue(TestDownloadManager()),
          ],
          child: browseTestApp(
            Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 600,
                child: DownloadTaskTile(
                  task: BooruDownloadItem(snapshot: task),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      addTearDown(() => tester.pumpWidget(const SizedBox()));
    }

    Finder openButton() => find.byWidgetPredicate(
      (w) => w is FrostButton && w.label == t.downloads.open,
    );
    Finder retryButton() => find.byWidgetPredicate(
      (w) => w is FrostButton && w.label == t.generic.retry,
    );

    /// Opens the row's context menu and reports whether it gained an Open
    /// entry, so the always-visible button is not mistaken for the entry.
    Future<bool> menuGainsOpen(WidgetTester tester) async {
      final before = find.text(t.downloads.open).evaluate().length;
      final pointer = await tester.startGesture(
        tester.getCenter(find.byType(DownloadTaskTile)),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await pointer.up();
      await tester.pumpAndSettle();
      expect(find.text(t.downloads.remove), findsWidgets);
      return find.text(t.downloads.open).evaluate().length > before;
    }

    testWidgets('a completed row with a path shows Open without hover', (
      tester,
    ) async {
      await mount(
        tester,
        _snapshot(
          status: DownloadStatus.downloaded,
          saveState: SaveState.saved,
          localPath: '/downloads/42.png',
        ),
      );
      expect(openButton().hitTestable(), findsOneWidget);
      expect(await menuGainsOpen(tester), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('details show no MediaStore handle and no second Open', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            downloadManagerProvider.overrideWithValue(TestDownloadManager()),
          ],
          child: browseTestApp(
            SingleChildScrollView(
              child: DownloadTaskDetails(
                task: BooruDownloadItem(
                  snapshot: _snapshot(
                    status: DownloadStatus.downloaded,
                    saveState: SaveState.saved,
                    localPath: 'content://media/external/images/media/1',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('content://'), findsNothing);
      expect(find.text(t.downloads.copyPath), findsNothing);
      expect(openButton(), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a completed row without a path offers no Open', (
      tester,
    ) async {
      await mount(
        tester,
        _snapshot(status: DownloadStatus.downloaded, localPath: ''),
      );
      expect(openButton(), findsNothing);
      expect(await menuGainsOpen(tester), isFalse);
    });

    testWidgets('a failed row keeps Retry and has no Open', (tester) async {
      await mount(
        tester,
        _snapshot(
          status: DownloadStatus.failed,
          localPath: '/downloads/42.png',
        ),
      );
      expect(retryButton().hitTestable(), findsOneWidget);
      expect(openButton(), findsNothing);
      expect(await menuGainsOpen(tester), isFalse);
      expect(tester.takeException(), isNull);
    });
  });
}
