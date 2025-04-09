import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yande_gui/components/translated_tag/translated_tag.dart';
import 'package:yande_gui/components/yande_image/yande_image.dart';
import 'package:yande_gui/downloader/download_task.dart';
import 'package:yande_gui/downloader/downloader.dart';
import 'package:yande_gui/pages/post_detail/post_detail_page.dart';
import 'package:yande_gui/src/rust/yande/model/post.dart';

class DownloadTaskWidget extends ConsumerWidget {
  final DownloadTask<Post> task;

  const DownloadTaskWidget({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder(
      stream: task.stream,
      builder: (BuildContext context, AsyncSnapshot<DownloadTaskState> snapshot) {
        final state = snapshot.data ?? task.state;

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => PostDetailPage(post: task.inner)));
          },
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  YandeImage(task.inner.previewUrl, width: 150, height: 150),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 150,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('ID:${task.inner.id}', style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 5),
                              Text(
                                '${(task.inner.fileSize / 1024 / 1024).toStringAsFixed(2)}MB',
                                style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.secondary),
                              ),
                              const SizedBox(width: 5),
                              switch (state.status) {
                                DownloadStatus.idle => GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: () {
                                    Downloader.instance.startTask(task.taskId);
                                  },
                                  child: const Icon(Icons.download_outlined),
                                ),
                                DownloadStatus.waiting => const Icon(Icons.pause_outlined),
                                DownloadStatus.busying => const CupertinoActivityIndicator(),
                                DownloadStatus.completed => GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: () {
                                    Downloader.instance.startTask(task.taskId);
                                  },
                                  child: const Icon(Icons.check_outlined),
                                ),
                                DownloadStatus.failed => GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: () {
                                    Downloader.instance.startTask(task.taskId);
                                  },
                                  child: const Icon(Icons.error_outline),
                                ),
                              },
                            ],
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(value: state.progress),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: ClipRect(
                                child: Wrap(
                                  runSpacing: 14,
                                  spacing: 6,
                                  children: [for (final tag in task.inner.tags.split(' ')) TranslatedTag(text: tag)],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
