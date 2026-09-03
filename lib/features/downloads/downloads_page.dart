import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yande_gui/core/downloads/download_manager.dart';
import 'package:yande_gui/core/downloads/download_models.dart';
import 'package:yande_gui/features/downloads/widgets/download_task_widgets.dart';
import 'package:yande_gui/features/downloads/logic.dart';
import 'package:yande_gui/features/downloads/yande_download_item.dart';
import 'package:yande_gui/intl/translations.g.dart';
import 'package:yande_gui/shared/app_navigation.dart';
import 'package:yande_gui/shared/app_toast.dart';
import 'package:yande_gui/shared/widgets/auto_scaffold.dart';

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AutoScaffold(
      verticalOnlyTitleWidget: Text(t.downloads.tasksTitle),
      builder: (context, horizontal) {
        return StreamBuilder<List<YandeDownloadItem>>(
          stream: YandeDownloads.instance.watchItems,
          builder: (context, snapshot) {
            final tasks = snapshot.data ?? YandeDownloads.instance.currentItems;
            final summary = DownloadSummary.fromTasks([
              for (final task in tasks) task.snapshot,
            ]);

            return RefreshIndicator(
              onRefresh: _syncDownloads,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Material(
                    color: colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: DownloadSummaryView(summary: summary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Material(
                    color: colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: DownloadTaskList(
                        tasks: tasks,
                        onTaskTap: (task) {
                          final post = task.post;
                          if (post != null) {
                            unawaited(context.pushPost(post));
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _syncDownloads() async {
    try {
      await downloadManager.sync();
    } catch (error) {
      AppToast.errorWithCause(t.downloads.syncFailed, error);
    }
  }
}
