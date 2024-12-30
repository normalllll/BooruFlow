import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yande_gui/i18n.dart';
import 'package:yande_gui/pages/downloads/logic.dart';
import 'package:yande_gui/widgets/auto_scaffold/auto_scaffold.dart';

import 'download_task.dart';

class DownloadsPage extends ConsumerWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = downloaderProvider;
    final state = ref.watch(provider);
    return AutoScaffold(
      verticalOnlyTitleWidget: Text(i18n.downloads.title),
      floatingActionButton: FloatingActionButton(
        heroTag: '${runtimeType}FloatingActionButton',
        onPressed: () {
          ref.read(downloaderProvider.notifier).doRetryAll();
        },
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
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
