import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/features/downloads/booru_download_item.dart';
import 'package:booruflow/features/downloads/widgets/download_task_widgets.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

  for (final locale in AppLocale.values) {
    for (final width in [260.0, 372.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'floating download height stays stable: $locale/$width/$scale',
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
              MaterialApp(
                home: MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                  child: Scaffold(
                    body: Align(
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        width: width,
                        child: StatefulBuilder(
                          builder: (context, setState) {
                            update = setState;
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                DownloadSummaryView(
                                  summary: DownloadSummary.fromTasks([current]),
                                  compact: true,
                                ),
                                DownloadTaskTile(
                                  task: BooruDownloadItem(snapshot: current),
                                  compact: true,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pump(const Duration(milliseconds: 400));
            final tileSize = tester.getSize(find.byType(DownloadTaskTile));
            final summarySize = tester.getSize(
              find.byType(DownloadSummaryView),
            );

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
                expect(
                  tester.getSize(find.byType(DownloadTaskTile)),
                  tileSize,
                  reason:
                      'Task changed size for ${states[index]} after $elapsed ms',
                );
                expect(
                  tester.getSize(find.byType(DownloadSummaryView)),
                  summarySize,
                  reason:
                      'Summary changed size for ${states[index]} after $elapsed ms',
                );
                expect(tester.takeException(), isNull);
              }
            }
            await tester.pumpWidget(const SizedBox.shrink());
          },
        );
      }
    }
  }
}
