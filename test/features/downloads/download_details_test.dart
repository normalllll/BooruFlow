import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/features/downloads/widgets/download_task_details.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../support/browse_support.dart' show browseTestApp;
import '../discovery/search_interaction_test.dart' show testSource;

void main() {
  setUpAll(initializeDateFormatting);
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));
  for (final available in [false, true]) {
    testWidgets(
      'details use actual metadata, omit missing data and fold logs $available',
      (tester) async {
        final task = BooruDownloadItem(
          snapshot: DownloadTaskSnapshot(
            id: 'task',
            resourceId: 101,
            variantIndex: 0,
            title: 'Task',
            filename: '101.png',
            status: DownloadStatus.downloaded,
            saveState: SaveState.saved,
            receivedBytes: available ? 128 : 0,
            totalBytes: available ? 128 : null,
            progress: 1,
            localPath: available ? r'C:\Downloads\101.png' : null,
            error: null,
            log: available ? 'Saved 101.png' : null,
            sourceId: available ? 'yande' : null,
            postId: available ? '101' : null,
            createdAt: DateTime(2026, 10, 18, 9, 30),
            updatedAt: DateTime(2026, 10, 18, 9, 31),
          ),
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              booruSourcesProvider.overrideWithValue([testSource('yande')]),
            ],
            child: browseTestApp(
              Center(
                child: SizedBox(
                  width: 300,
                  height: 850,
                  child: SingleChildScrollView(
                    child: DownloadTaskDetails(task: task, start: 0),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final entries = tester
            .widget<FrostKeyValueList>(find.byType(FrostKeyValueList))
            .entries;
        expect(
          entries.map((e) => e.label),
          available
              ? [
                  t.downloads.path,
                  t.postDetail.source,
                  t.postDetail.size,
                  t.downloads.format,
                  t.downloads.startedAt,
                ]
              : [t.downloads.format, t.downloads.startedAt],
        );
        expect(entries.every((e) => e.value.trim().isNotEmpty), isTrue);
        expect(
          find.byWidgetPredicate(
            (w) => w is FrostButton && w.label == t.downloads.openPost,
          ),
          available ? findsOneWidget : findsNothing,
        );
        if (available) {
          expect(find.text('Saved 101.png').hitTestable(), findsNothing);
          await tester.ensureVisible(find.byType(FrostDisclosure));
          await tester.tap(find.text(t.downloads.viewLog).hitTestable());
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.byType(FrostCodeBlock));
          await tester.pumpAndSettle();
          expect(find.byType(FrostCodeBlock).hitTestable(), findsOneWidget);
          expect(
            tester.widget<FrostCodeBlock>(find.byType(FrostCodeBlock)).text,
            'Saved 101.png',
          );
        } else {
          expect(find.byType(FrostDisclosure), findsNothing);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
