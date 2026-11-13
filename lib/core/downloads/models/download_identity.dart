import 'download_enums.dart';
import 'download_task_snapshot.dart';

/// Why a post file cannot be downloaded again right now.
enum DownloadBlock {
  /// A task for the file is queued, running, paused, finished or being saved.
  inProgress,

  /// The file is already saved.
  saved,
}

/// "Already downloaded" is decided by source, post and variant alone. The
/// batch and the Ugoira export only change a job's id, not what it fetches.
class DownloadIdentity {
  const DownloadIdentity({
    required this.sourceId,
    required this.postId,
    required this.variantIndex,
  });

  final String sourceId;
  final String postId;
  final int variantIndex;

  @override
  bool operator ==(Object other) =>
      other is DownloadIdentity &&
      other.sourceId == sourceId &&
      other.postId == postId &&
      other.variantIndex == variantIndex;

  @override
  int get hashCode => Object.hash(sourceId, postId, variantIndex);
}

extension DownloadTaskBlocking on DownloadTaskSnapshot {
  /// Null for tasks that predate source and post metadata.
  DownloadIdentity? get identity {
    final source = sourceId;
    final post = postId;
    return source == null || post == null
        ? null
        : DownloadIdentity(
            sourceId: source,
            postId: post,
            variantIndex: variantIndex,
          );
  }

  /// Failed and cancelled tasks never block: retrying them stays possible.
  DownloadBlock? get block {
    if (saveState == SaveState.saved) return DownloadBlock.saved;
    if (saveState == SaveState.failed) return null;
    return switch (status) {
      DownloadStatus.failed || DownloadStatus.cancelled => null,
      _ => DownloadBlock.inProgress,
    };
  }
}

/// The strongest block that [tasks] place on [identity], or null when a new
/// download of it may start.
DownloadBlock? downloadBlockFor(
  DownloadIdentity identity,
  Iterable<DownloadTaskSnapshot> tasks,
) {
  DownloadBlock? result;
  for (final task in tasks) {
    if (task.identity != identity) continue;
    final block = task.block;
    if (block == DownloadBlock.saved) return block;
    result ??= block;
  }
  return result;
}
