import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yande_gui/downloader/downloader.dart';
import 'package:yande_gui/i18n.dart';
import 'package:yande_gui/widgets/auto_scaffold/auto_scaffold.dart';

import 'download_task.dart';

class DownloadsPage extends ConsumerWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AutoScaffold(
      verticalOnlyTitleWidget: Text(i18n.downloads.title),
      floatingActionButton: FloatingActionButton(
        heroTag: '${runtimeType}FloatingActionButton',
        onPressed: () {
          Downloader.instance.retryAll();
        },
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
      builder: (context, horizontal) {
        return StreamBuilder(
          stream: Downloader.instance.taskListStream,
          builder: (context, snapshot) {
            final list = snapshot.data ?? Downloader.instance.taskList;
            return ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) => DownloadTaskWidget(task: list[list.length - index - 1]),
            );
          },
        );
      },
    );
  }
}
