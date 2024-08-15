import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yande_gui/i18n.dart';
import 'package:yande_gui/pages/downloader/logic.dart';
import 'package:yande_gui/widgets/auto_scaffold/auto_scaffold.dart';

import 'download_task.dart';

class DownloaderPage extends ConsumerWidget {
  const DownloaderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = downloaderProvider;
    final state = ref.watch(provider);
    return AutoScaffold(
      verticalOnlyTitleWidget:  Text(i18n.downloader.title),
      builder: (context, horizontal) {
        return ListView.builder(
          itemCount: state.tasks.length,
          //reverse
          itemBuilder: (context, index) => DownloadTaskWidget(
            provider: state.tasks[state.tasks.length - index - 1],
          ),
        );
      },
    );
  }
}
