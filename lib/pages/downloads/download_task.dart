import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yande_gui/components/translated_tag/translated_tag.dart';
import 'package:yande_gui/components/yande_image/yande_image.dart';
import 'package:yande_gui/pages/downloads/logic.dart';
import 'package:yande_gui/pages/post_detail/post_detail_page.dart';

class DownloadTaskWidget extends ConsumerWidget {
  final DownloadTaskProvider provider;

  const DownloadTaskWidget({super.key, required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(provider);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => PostDetailPage(post: provider.post)));
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              YandeImage(provider.post.previewUrl, width: 150, height: 150),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 150,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'ID:${provider.post.id}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${(provider.post.fileSize / 1024 / 1024).toStringAsFixed(2)}MB',
                            style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.secondary),
                          ),
                          const SizedBox(width: 5),
                          switch (state.type) {
                            DownloadTaskStateType.idle => GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: () {
                                  ref.read(provider.notifier).doDownload();
                                },
                                child: const Icon(Icons.download_outlined),
                              ),
                            DownloadTaskStateType.waiting => const Icon(Icons.pause_outlined),
                            DownloadTaskStateType.busying => const CupertinoActivityIndicator(),
                            DownloadTaskStateType.completed => GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: () {
                                  ref.read(provider.notifier).doDownload(retry: true);
                                },
                                child: const Icon(Icons.check_outlined),
                              ),
                            DownloadTaskStateType.failed => GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: () {
                                  ref.read(provider.notifier).doDownload(retry: true);
                                },
                                child: const Icon(Icons.error_outline),
                              ),
                          }
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
                              children: [
                                for (final tag in provider.post.tags.split(' '))
                                  TranslatedTag(
                                    text: tag,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
