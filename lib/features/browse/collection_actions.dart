import 'dart:async';

import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/browse/collection_logic.dart';
import 'package:booruflow/features/browse/widgets/rating_filter.dart';
import 'package:booruflow/features/downloads/batch/batch_download_dialog.dart';
import 'package:booruflow/features/downloads/batch/logic.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';

/// What browse and results share besides the grid: the collection they show,
/// its batch download, the query link and the header actions.
mixin CollectionActions<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  BatchDownloadRequest? _batchRequest;

  String get sourceId;
  CollectionKey get collectionKey;

  BooruService get service => ref.read(booruServiceProvider);
  BooruSource get source => service.sourceById(sourceId);

  /// Rebuilds this page while a batch download it opened is running.
  void watchBatch() {
    if (_batchRequest case final request?) {
      ref.watch(batchDownloadProvider(request));
    }
  }

  Future<void> openBatchDownload() async {
    final request =
        _batchRequest ??
        BatchDownloadRequest(
          key: collectionKey,
          sourceName: source.displayName,
        );
    setState(() => _batchRequest = request);
    final done = await showBatchDownloadDialog(context, request);
    if (!mounted) return;
    final state = ref.read(batchDownloadProvider(request));
    if (state.phase == BatchPhase.enqueueing ||
        (state.phase == BatchPhase.finished &&
            state.failed.isNotEmpty &&
            done != true)) {
      return;
    }
    ref.read(batchDownloadProvider(request).notifier).stopFetching();
    setState(() => _batchRequest = null);
  }

  Future<void> copyQueryLink() async {
    try {
      final key = collectionKey;
      final ratings = ratingsForSource(key, source.capabilities.ratings);
      final url = await switch (key.request) {
        TagSearchCollectionRequest(:final tags) => service.engine.searchWebUrl(
          request: SearchRequest(
            sourceId: key.sourceId,
            queryText: tags.join(' '),
            ratings: ratings,
            pageSize: 40,
          ),
        ),
        FeedCollectionRequest(:final kind, :final range, :final date) =>
          service.engine.feedWebUrl(
            request: FeedRequest(
              sourceId: key.sourceId,
              kind: kind,
              range: range,
              date: date,
              ratings: ratings,
              pageSize: 40,
            ),
          ),
      };
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) FrostToast.copied(t.verificationPage.linkCopied);
    } catch (error) {
      if (mounted) FrostToast.fromError(context, error);
    }
  }

  /// Filter, batch download and the more menu. Batch download moves into the
  /// more menu where the layout is the compact bottom bar.
  List<FrostToolbarItem> toolbar(
    PostListSource collection, {
    List<FrostMenuEntry> more = const [],
  }) {
    final compact = !FrostAutoScaffold.usesHorizontalLayoutOf(context);
    final batchReady =
        collection.lastError == null || collection.items.isNotEmpty;
    return [
      FrostToolbarItem.custom(
        minWidth: FrostDensity.of(context).targetHeight,
        priority: FrostToolbarPriority.high,
        builder: (_) => const RatingFilterButton(),
        overflowEntry: FrostMenuAction(
          t.discovery.filters,
          leading: FrostGlyph.icon(appIcons.filter),
          onSelected: () => showRatingFilterSheet(context),
        ),
      ),
      if (!compact)
        FrostToolbarItem.action(
          icon: appIcons.download,
          label: t.batchDownload.title,
          onPressed: batchReady ? openBatchDownload : null,
        ),
      FrostToolbarItem.menu(
        label: t.frost.more,
        icon: appIcons.more,
        showsLabel: false,
        entries: [
          if (compact)
            FrostMenuAction(
              t.batchDownload.title,
              leading: FrostGlyph.icon(appIcons.download),
              enabled: batchReady,
              onSelected: openBatchDownload,
            ),
          FrostMenuAction(
            t.generic.refresh,
            leading: FrostGlyph.icon(appIcons.refresh),
            onSelected: () => unawaited(collection.refresh(true)),
          ),
          ...more,
          FrostMenuAction(
            t.discovery.copyQueryLink,
            leading: FrostGlyph.icon(appIcons.link),
            onSelected: copyQueryLink,
          ),
        ],
      ),
    ];
  }
}
