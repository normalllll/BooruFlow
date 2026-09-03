import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yande_gui/components/translated_tag/translated_tag.dart';
import 'package:yande_gui/components/yande_image/yande_image.dart';
import 'package:yande_gui/core/downloads/download_models.dart';
import 'package:yande_gui/features/downloads/application/yande_download_controller.dart';
import 'package:yande_gui/features/downloads/domain/yande_download_item.dart';
import 'package:yande_gui/router/app_router.dart';

class DownloadTaskWidget extends ConsumerWidget {
  const DownloadTaskWidget({super.key, required this.task});

  final YandeDownloadItem task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = task.snapshot;
    final post = task.post;
    final thumbnail = post?.previewUrl ?? state.thumbnailUrl;
    final failed =
        state.status == DownloadStatus.failed ||
        state.status == DownloadStatus.cancelled ||
        state.saveState == SaveState.failed;
    final saved = state.saveState == SaveState.saved;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: post == null ? null : () => AppRouter.pushPost(context, post),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: thumbnail == null
                    ? const SizedBox.square(
                        dimension: 112,
                        child: ColoredBox(
                          color: Colors.black12,
                          child: Icon(Icons.image_outlined),
                        ),
                      )
                    : YandeImage(
                        thumbnail,
                        width: 112,
                        height: 112,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 112,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              state.filename,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (failed)
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () => YandeDownloadController.instance
                                  .retry(state.id),
                              icon: const Icon(Icons.refresh_outlined),
                            )
                          else if (saved)
                            const Icon(Icons.check_circle_outline)
                          else
                            const CupertinoActivityIndicator(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: saved ? 1 : state.progress.clamp(0.0, 1.0),
                        color: failed
                            ? Theme.of(context).colorScheme.error
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ID: ${state.resourceId}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (post != null)
                        Expanded(
                          child: ClipRect(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final tag in post.tags.split(' ').take(8))
                                  TranslatedTag(text: tag),
                              ],
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
  }
}
