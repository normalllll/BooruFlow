import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/features/downloads/download_presentation.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/features/downloads/widgets/download_task_widgets.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';

import '../../support/browse_support.dart' show browseTestApp;
import 'support.dart';

DownloadTaskSnapshot snapshot(
  DownloadStatus status,
  SaveState saveState,
  int index,
) {
  return DownloadTaskSnapshot(
    id: 'job-1',
    resourceId: 1234567890,
    variantIndex: 0,
    title: 'Anime-Pictures #1234567',
    filename: '1234567.png',
    status: status,
    saveState: saveState,
    receivedBytes: index == 0 ? 0 : 9876543210,
    totalBytes: index == 0 ? null : 9876543210,
    progress: index == 0 ? 0 : 1,
    localPath: saveState == SaveState.saved ? '/downloads/1234567.png' : null,
    error: status == DownloadStatus.failed ? 'Download failed' : null,
    log: index.isEven ? null : 'A detailed task log',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

void main() {
  final states = [
    for (final status in DownloadStatus.values)
      if (status == DownloadStatus.downloaded)
        for (final saveState in SaveState.values) (status, saveState)
      else
        (status, SaveState.none),
  ];

  testWidgets('a row keeps its height from queued to running', (tester) async {
    tester.view.physicalSize = const Size(411, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var current = snapshot(DownloadStatus.queued, SaveState.none, 0);
    late StateSetter update;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          downloadManagerProvider.overrideWithValue(TestDownloadManager()),
        ],
        child: browseTestApp(
          Align(
            alignment: Alignment.topLeft,
            child: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return SizedBox(
                  width: 411,
                  child: DownloadTaskTile(
                    task: BooruDownloadItem(snapshot: current),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    final queued = tester.getSize(find.byType(DownloadTaskTile)).height;
    update(() => current = snapshot(DownloadStatus.running, SaveState.none, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.getSize(find.byType(DownloadTaskTile)).height, queued);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final locale in AppLocale.values) {
    for (final width in [260.0, 372.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'shared download rows wrap all states: $locale/$width/$scale',
          (tester) async {
            LocaleSettings.setLocaleSync(locale);
            addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));
            tester.view.physicalSize = const Size(800, 1400);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            var current = snapshot(states.first.$1, states.first.$2, 0);
            late StateSetter update;
            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  downloadManagerProvider.overrideWithValue(
                    TestDownloadManager(),
                  ),
                ],
                child: browseTestApp(
                  Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: width,
                      child: StatefulBuilder(
                        builder: (context, setState) {
                          update = setState;
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DownloadTaskTile(
                                task: BooruDownloadItem(snapshot: current),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  scale: scale,
                ),
              ),
            );
            await tester.pump(const Duration(milliseconds: 400));

            for (var index = 0; index < states.length; index++) {
              update(
                () => current = snapshot(
                  states[index].$1,
                  states[index].$2,
                  index,
                ),
              );
              await tester.pump();
              for (final elapsed in [80, 400]) {
                await tester.pump(Duration(milliseconds: elapsed));
                if (downloadCompleted(current)) {
                  final row = tester.widget<FrostListRow>(
                    find.byType(FrostListRow),
                  );
                  expect(row.title, current.filename);
                  expect(find.byType(FrostTaskRow), findsNothing);
                } else {
                  final row = tester.widget<FrostTaskRow>(
                    find.byType(FrostTaskRow),
                  );
                  expect(row.title, current.filename);
                  expect(row.status, downloadTaskStatus(current));
                }
                expect(
                  tester.getSize(find.byType(DownloadTaskTile)).height,
                  greaterThanOrEqualTo(40),
                );
                expect(
                  tester.getSize(find.byType(DownloadTaskTile)).width,
                  lessThanOrEqualTo(width),
                );
                expect(
                  tester.takeException(),
                  isNull,
                  reason: "${current.status}/${current.saveState}",
                );
              }
            }
            await tester.pumpWidget(const SizedBox.shrink());
          },
        );
      }
    }
  }
}
