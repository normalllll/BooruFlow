import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yande_gui/features/downloads/application/yande_download_controller.dart';
import 'package:yande_gui/features/downloads/domain/yande_download_item.dart';
import 'package:yande_gui/intl/translations.g.dart';
import 'package:yande_gui/widgets/auto_scaffold/auto_scaffold.dart';

import 'download_task.dart';

class DownloadsPage extends ConsumerWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AutoScaffold(
      verticalOnlyTitleWidget: Text(t.downloads.title),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () {
          YandeDownloadController.instance.retryAll();
        },
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
      builder: (context, horizontal) {
        return StreamBuilder<List<YandeDownloadItem>>(
          stream: YandeDownloadController.instance.watchItems,
          builder: (context, snapshot) {
            final list =
                snapshot.data ?? YandeDownloadController.instance.currentItems;
            return ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) =>
                  DownloadTaskWidget(task: list[list.length - index - 1]),
            );
          },
        );
      },
    );
  }
}
