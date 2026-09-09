import 'dart:async';

import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/widgets/download_task_widgets.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:booruflow/shared/widgets/auto_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DownloadsPage extends ConsumerWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return AutoScaffold(
      verticalOnlyTitleWidget: Text(t.downloads.tasksTitle),
      builder: (context, horizontal) {
        final tasks = ref.watch(downloadItemsProvider);
        final summary = DownloadSummary.fromTasks([
          for (final task in tasks) task.snapshot,
        ]);

        return RefreshIndicator(
          onRefresh: () => _syncDownloads(ref),
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
  }

  Future<void> _syncDownloads(WidgetRef ref) async {
    try {
      await ref.read(downloadManagerProvider).sync();
    } catch (error) {
      AppToast.errorWithCause(t.downloads.syncFailed, error);
    }
  }
}
