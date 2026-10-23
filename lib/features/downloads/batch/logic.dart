import 'dart:convert';
import 'dart:math';

import 'package:booruflow/core/downloads/download_file_system.dart';
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/downloads/download_platform.dart';
import 'package:booruflow/core/file_paths.dart';
import 'package:booruflow/core/settings/logic.dart';
import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/discovery/collection_logic.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/intl/number_format.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:booruflow/src/rust/booru/error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'logic.g.dart';

class BatchDownloadRequest {
  BatchDownloadRequest({
    required this.key,
    required this.sourceName,
    this.loader,
  });
  final CollectionKey key;
  final String sourceName;
  final CollectionLoader? loader;
  String get query => switch (key.request) {
    TagSearchCollectionRequest(:final tags) => tags.join(' '),
    _ => '',
  };
}

enum BatchPhase { setup, fetching, ready, enqueueing, finished }

enum BatchFetchEnd { exhausted, limit, stopped }

enum BatchFetchIssue { stalled, sessionChanged }

class BatchDownloadState {
  BatchDownloadState({
    this.phase = BatchPhase.setup,
    this.limit = 2000,
    List<Post> items = const [],
    this.selected = 0,
    this.folder = '',
    this.fetchEnd,
    this.error,
    this.processed = 0,
    this.attemptTotal = 0,
    this.enqueued = 0,
    List<Post> failed = const [],
    this.saveTarget,
  }) : items = List.unmodifiable(items),
       failed = List.unmodifiable(failed);

  final BatchPhase phase;
  final int limit, selected, processed, attemptTotal, enqueued;
  final List<Post> items, failed;
  final String folder;
  final BatchFetchEnd? fetchEnd;
  final Object? error;
  final SaveTarget? saveTarget;

  BatchDownloadState copyWith({
    BatchPhase? phase,
    int? limit,
    List<Post>? items,
    int? selected,
    String? folder,
    BatchFetchEnd? fetchEnd,
    Object? error,
    bool clearError = false,
    int? processed,
    int? attemptTotal,
    int? enqueued,
    List<Post>? failed,
    SaveTarget? saveTarget,
  }) => BatchDownloadState(
    phase: phase ?? this.phase,
    limit: limit ?? this.limit,
    items: items ?? this.items,
    selected: selected ?? this.selected,
    folder: folder ?? this.folder,
    fetchEnd: fetchEnd ?? this.fetchEnd,
    error: clearError ? null : error ?? this.error,
    processed: processed ?? this.processed,
    attemptTotal: attemptTotal ?? this.attemptTotal,
    enqueued: enqueued ?? this.enqueued,
    failed: failed ?? this.failed,
    saveTarget: saveTarget ?? this.saveTarget,
  );
}

bool validBatchFolder(String value) =>
    value.isNotEmpty &&
    value != '.' &&
    value != '..' &&
    value == safeDownloadFilename(value) &&
    value.length <= 100 &&
    utf8.encode(value).length <= 255 &&
    !RegExp(r'^(COM|LPT)[¹²³](\.|$)', caseSensitive: false).hasMatch(value) &&
    !RegExp(r'[\x7F]').hasMatch(value);

class BatchSaveLocation {
  const BatchSaveLocation({required this.root, required this.target});
  final String root;
  final SaveTarget target;

  SaveTarget folder(String name) {
    if (!validBatchFolder(name)) throw ArgumentError.value(name, 'folder');
    return SaveTarget(
      type: target.type,
      directory: target.directory,
      subdirectory: localPathContext(
        style: target.type == SaveTargetType.downloadsFolder
            ? null
            : p.Style.posix,
      ).join(target.subdirectory ?? '', name),
    );
  }
}

@riverpod
Future<BatchSaveLocation> batchSaveLocation(Ref ref, String sourceId) async {
  final custom = ref.watch(
    settingsProvider.select((settings) => settings.downloadPath),
  );
  final platform = ref.watch(downloadPlatformProvider);
  if (platform == DownloadPlatform.android) {
    return BatchSaveLocation(
      root: 'Pictures/BooruFlow/$sourceId',
      target: SaveTarget.mediaStore(subdirectory: sourceId),
    );
  }
  if (platform == DownloadPlatform.ios) {
    return BatchSaveLocation(
      root: '${t.batchDownload.photos}/BooruFlow/$sourceId',
      target: SaveTarget.photos(subdirectory: sourceId),
    );
  }
  final root = await resolveDesktopDownloadDirectory(explicitDirectory: custom);
  return BatchSaveLocation(
    root: p.join(root, sourceId),
    target: SaveTarget.downloadsFolder(
      directory: p.dirname(root),
      subdirectory: sourceId,
    ),
  );
}

@riverpod
class BatchDownload extends _$BatchDownload {
  int _generation = 0;
  String? _cursor;
  final _seenCursors = <String>{};
  final _seenPosts = <String>{};
  final _prepared = <String, DownloadJob>{};
  final _batchId =
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}-${Random.secure().nextInt(1 << 32).toRadixString(16)}';

  @override
  BatchDownloadState build(BatchDownloadRequest request) {
    ref.onDispose(() {
      _generation++;
    });
    return BatchDownloadState();
  }

  Future<void> fetch(int limit) async {
    if (limit < 1 || state.phase != BatchPhase.setup) return;
    _cursor = null;
    _seenCursors.clear();
    _seenPosts.clear();
    _pagesWithoutNewImages = 0;
    state = BatchDownloadState(phase: BatchPhase.fetching, limit: limit);
    await _fetchPages();
  }

  Future<void> retryFetch() async {
    if (state.phase != BatchPhase.ready ||
        state.error == null ||
        state.error == BatchFetchIssue.sessionChanged) {
      return;
    }
    _pagesWithoutNewImages = 0;
    state = state.copyWith(phase: BatchPhase.fetching, clearError: true);
    await _fetchPages();
  }

  Future<void> _fetchPages() async {
    final generation = ++_generation;
    final CollectionLoader loader =
        request.loader ?? ref.read(collectionLoaderProvider);
    try {
      while (ref.mounted && generation == _generation) {
        if (ref.read(booruSessionProvider).revision != request.key.revision) {
          throw BatchFetchIssue.sessionChanged;
        }
        final page = await loader(request.key, _cursor);
        if (!ref.mounted || generation != _generation) return;
        if (ref.read(booruSessionProvider).revision != request.key.revision) {
          throw BatchFetchIssue.sessionChanged;
        }
        final items = [...state.items];
        final before = items.length;
        var consumed = 0;
        for (final data in page.items) {
          consumed++;
          if (_seenPosts.add(data.postKey)) items.add(Post(data));
          if (items.length == state.limit) break;
        }
        state = state.copyWith(items: items, selected: items.length);
        if (items.length >= state.limit || page.exhausted) {
          state = state.copyWith(
            phase: BatchPhase.ready,
            fetchEnd: page.exhausted && consumed == page.items.length
                ? BatchFetchEnd.exhausted
                : BatchFetchEnd.limit,
          );
          return;
        }
        final next = page.nextCursor;
        if (next == null || next == _cursor || _seenCursors.contains(next)) {
          throw BatchFetchIssue.stalled;
        }
        // Filtering or a changing source may produce empty/duplicate pages.
        // Allow forward progress, but never loop indefinitely without results.
        if (items.length == before) {
          _pagesWithoutNewImages++;
          if (_pagesWithoutNewImages >= 5) throw BatchFetchIssue.stalled;
        } else {
          _pagesWithoutNewImages = 0;
        }
        _seenCursors.add(next);
        _cursor = next;
      }
    } catch (error) {
      if (ref.mounted && generation == _generation) {
        state = state.copyWith(phase: BatchPhase.ready, error: error);
      }
    }
  }

  int _pagesWithoutNewImages = 0;

  void stopFetching() {
    if (state.phase != BatchPhase.fetching) return;
    _generation++;
    state = state.copyWith(
      phase: BatchPhase.ready,
      fetchEnd: BatchFetchEnd.stopped,
    );
  }

  void reset() {
    if (state.phase == BatchPhase.enqueueing) return;
    _generation++;
    _pagesWithoutNewImages = 0;
    _prepared.clear();
    state = BatchDownloadState(limit: state.limit);
  }

  void select(int count) {
    if (state.phase == BatchPhase.ready &&
        count >= 1 &&
        count <= state.items.length) {
      state = state.copyWith(selected: count);
    }
  }

  void setFolder(String name) {
    if (state.phase == BatchPhase.ready) state = state.copyWith(folder: name);
  }

  Future<void> enqueue(BatchSaveLocation location) async {
    if (state.phase != BatchPhase.ready ||
        state.selected < 1 ||
        !validBatchFolder(state.folder)) {
      return;
    }
    state = state.copyWith(saveTarget: location.folder(state.folder));
    await _enqueue(state.items.take(state.selected).toList());
  }

  Future<void> retryEnqueue() async {
    if (state.phase != BatchPhase.finished || state.failed.isEmpty) return;
    await _enqueue(state.failed);
  }

  Future<void> _enqueue(List<Post> candidates) async {
    // Closing the dialog can cancel collection, but cannot abandon a submission
    // after some of its tasks have already been persisted.
    final retention = ref.keepAlive();
    final downloads = ref.read(booruDownloadsProvider);
    final manager = ref.read(downloadManagerProvider);
    final accepted = <String>{};
    final previouslyEnqueued = state.enqueued;
    var processed = 0;
    state = state.copyWith(
      phase: BatchPhase.enqueueing,
      attemptTotal: candidates.length,
      processed: 0,
      failed: [],
      clearError: true,
    );
    downloads.beginBatch(_batchId);
    try {
      await downloads.initialize();
      if (!ref.mounted) return;
      // Query persisted identities before retrying, including completed tasks.
      // An interrupted enqueue response must never reset a successful task.
      final existing = (await manager.listTasks())
          .map((task) => task.id)
          .toSet();
      if (!ref.mounted) return;
      for (var start = 0; start < candidates.length; start += 20) {
        final chunk = candidates.skip(start).take(20).toList();
        final prepared = <(Post, DownloadJob)>[];
        for (final post in chunk) {
          final id = downloadJobId(
            sourceId: post.sourceId,
            postId: post.id,
            variantIndex: MediaVariantKind.original.index,
            batchId: _batchId,
          );
          if (existing.contains(id)) {
            accepted.add(post.postKey);
          } else {
            try {
              final job =
                  _prepared[post.postKey] ??
                  await downloads.prepare(
                    post,
                    batchId: _batchId,
                    saveTarget: state.saveTarget,
                  );
              if (!ref.mounted) return;
              _prepared[post.postKey] = job;
              prepared.add((post, job));
            } catch (error) {
              if (!ref.mounted) return;
              if (_stopsBatch(error)) rethrow;
              state = state.copyWith(error: error);
            }
          }
          processed++;
          state = state.copyWith(
            processed: processed,
            enqueued: previouslyEnqueued + accepted.length,
          );
        }
        if (prepared.isNotEmpty) {
          try {
            await manager.enqueue(prepared.map((entry) => entry.$2).toList());
            if (!ref.mounted) return;
            accepted.addAll(prepared.map((entry) => entry.$1.postKey));
          } catch (error) {
            if (!ref.mounted) return;
            state = state.copyWith(error: error);
            // enqueue may have persisted part of a chunk before failing.
            Set<String> persisted = {};
            try {
              persisted = (await manager.listTasks())
                  .map((task) => task.id)
                  .toSet();
            } catch (_) {
              // A later retry performs the identity check again before writing.
            }
            if (!ref.mounted) return;
            for (final (post, job) in prepared) {
              if (persisted.contains(job.id)) accepted.add(post.postKey);
            }
            // Permission or storage failures affect the entire submission.
            // Keep all remaining candidates for an explicit retry.
            break;
          }
        }
        state = state.copyWith(enqueued: previouslyEnqueued + accepted.length);
      }
    } catch (error) {
      if (ref.mounted) state = state.copyWith(error: error);
    } finally {
      final failures = candidates
          .where((post) => !accepted.contains(post.postKey))
          .toList();
      final enqueued = previouslyEnqueued + accepted.length;
      try {
        if (ref.mounted) {
          state = state.copyWith(
            phase: BatchPhase.finished,
            enqueued: enqueued,
            failed: failures,
          );
          AppToast.show(
            t.batchDownload.queued(
              added: formatCount(enqueued),
              failed: formatCount(failures.length),
            ),
          );
        }
      } finally {
        downloads.endBatch(_batchId);
        retention.close();
      }
    }
  }
}

bool _stopsBatch(Object error) {
  final cause = switch (error) {
    BooruReadableException(:final cause) => cause,
    BooruError value => value,
    _ => null,
  };
  return switch (cause?.code) {
    BooruErrorCode.rateLimited ||
    BooruErrorCode.authenticationRequired ||
    BooruErrorCode.authenticationRejected ||
    BooruErrorCode.challengeRequired ||
    BooruErrorCode.sourceUnavailable ||
    BooruErrorCode.network ||
    BooruErrorCode.timeout => true,
    _ => false,
  };
}
