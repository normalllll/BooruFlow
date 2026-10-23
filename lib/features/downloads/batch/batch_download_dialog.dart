import 'dart:async';

import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/downloads/download_permission_guard.dart';
import 'package:booruflow/core/downloads/download_platform.dart';
import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/features/downloads/batch/logic.dart';
import 'package:booruflow/intl/number_format.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

Future<bool?> showBatchDownloadDialog(
  BuildContext context,
  BatchDownloadRequest request,
) => showFrostAdaptiveDialog<bool>(
  context: context,
  barrierDismissible: false,
  sheetDetents: const [FrostSheetDetent.large],
  builder: (_) => BatchDownloadDialog(request: request),
);

class BatchDownloadDialog extends ConsumerStatefulWidget {
  const BatchDownloadDialog({required this.request, super.key});
  final BatchDownloadRequest request;
  @override
  ConsumerState<BatchDownloadDialog> createState() =>
      _BatchDownloadDialogState();
}

enum _BatchCount { all, first }

class _BatchDownloadDialogState extends ConsumerState<BatchDownloadDialog> {
  bool _folderEdited = false;
  _BatchCount _count = _BatchCount.all;
  late int _limit;
  late final TextEditingController _folder;
  BatchDownload get _logic =>
      ref.read(batchDownloadProvider(widget.request).notifier);

  @override
  void initState() {
    super.initState();
    final initial = ref.read(batchDownloadProvider(widget.request));
    _limit = initial.limit;
    // Setup and fetching can close before the folder field is ever built.
    // Initialize here so dispose only releases resources, without reading ref.
    _folder = TextEditingController(text: initial.folder);
  }

  @override
  void dispose() {
    _folder.dispose();
    super.dispose();
  }

  void _enqueue(AsyncValue<BatchSaveLocation> location) {
    if (location.hasValue) unawaited(_logic.enqueue(location.requireValue));
  }

  void _viewDownloads() {
    final router = GoRouter.of(context);
    Navigator.pop(context, true);
    router.goNamed(AppRoute.downloads.name);
  }

  List<FrostDialogAction<bool>> _actions(
    BatchDownloadState state,
    AsyncValue<BatchSaveLocation> location,
  ) {
    final strings = t.batchDownload;
    return switch (state.phase) {
      BatchPhase.setup => [
        FrostDialogAction(
          label: t.generic.cancel,
          value: false,
          role: FrostButtonRole.cancel,
        ),
        FrostDialogAction(
          label: strings.start,
          isDefault: true,
          onPressed: () {
            unawaited(_logic.fetch(_limit));
            return false;
          },
        ),
      ],
      BatchPhase.fetching => [
        FrostDialogAction(
          label: strings.stop,
          onPressed: () {
            _logic.stopFetching();
            return false;
          },
        ),
      ],
      BatchPhase.ready => [
        FrostDialogAction(
          label: strings.enqueue(count: formatCount(state.selected)),
          isDefault: true,
          enabled:
              state.items.isNotEmpty &&
              validBatchFolder(state.folder) &&
              location.hasValue,
          onPressed: () {
            _enqueue(location);
            return false;
          },
        ),
      ],
      BatchPhase.enqueueing => [
        FrostDialogAction(
          label: strings.close,
          value: false,
          role: FrostButtonRole.cancel,
        ),
      ],
      BatchPhase.finished => [
        FrostDialogAction(
          label: strings.viewDownloads,
          onPressed: () {
            _viewDownloads();
            return false;
          },
        ),
        FrostDialogAction(label: strings.done, value: true, isDefault: true),
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(batchDownloadProvider(widget.request));
    final location = ref.watch(
      batchSaveLocationProvider(widget.request.key.sourceId),
    );
    final strings = t.batchDownload;
    final actions = _actions(state, location);
    final leading = state.phase == BatchPhase.ready
        ? FrostDialogAction<bool>(
            label: strings.back,
            onPressed: () {
              _count = _BatchCount.all;
              _folderEdited = false;
              _folder.clear();
              _logic.reset();
              return false;
            },
          )
        : null;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FrostText(
          [
            widget.request.sourceName,
            if (widget.request.query.isNotEmpty) widget.request.query,
          ].join(' · '),
          role: FrostTextRole.subheadline,
          tone: FrostTextTone.secondary,
        ),
        const SizedBox(height: FrostGap.section),
        ...switch (state.phase) {
          BatchPhase.setup => [
            FrostNumberField(
              value: _limit,
              min: 1,
              max: 1000000,
              label: strings.limitLabel,
              help: strings.limitHint,
              onChanged: (value) => setState(() => _limit = value.toInt()),
            ),
          ],
          BatchPhase.fetching => [
            Wrap(
              spacing: FrostGap.related,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FrostText(
                  formatCount(state.items.length),
                  role: FrostTextRole.value,
                  numeric: true,
                ),
                FrostText(
                  strings.fetchLimit(count: formatCount(state.limit)),
                  role: FrostTextRole.subheadline,
                  tone: FrostTextTone.secondary,
                  numeric: true,
                ),
              ],
            ),
            const SizedBox(height: FrostGap.group),
            FrostProgressBar(
              value: state.items.length / state.limit,
              semanticLabel: strings.fetching,
            ),
            const SizedBox(height: FrostGap.group),
            FrostText(
              strings.stopHint,
              role: FrostTextRole.footnote,
              tone: FrostTextTone.secondary,
            ),
          ],
          BatchPhase.ready => _ready(state, location),
          BatchPhase.enqueueing => [
            FrostStat(
              value: formatCount(state.enqueued),
              caption: strings.added,
            ),
            const SizedBox(height: FrostGap.group),
            FrostProgressBar(
              value: state.attemptTotal == 0
                  ? 0
                  : state.processed / state.attemptTotal,
              semanticLabel: strings.enqueueing,
            ),
            const SizedBox(height: FrostGap.related),
            FrostText(
              strings.preparing(
                current: formatCount(state.processed),
                total: formatCount(state.attemptTotal),
              ),
            ),
            const SizedBox(height: FrostGap.related),
            FrostText(
              strings.backgroundHint,
              role: FrostTextRole.footnote,
              tone: FrostTextTone.secondary,
            ),
          ],
          BatchPhase.finished => [
            Row(
              children: [
                const FrostStatusGlyph(
                  kind: FrostStatusGlyphKind.success,
                  size: 28,
                ),
                const SizedBox(width: FrostGap.group),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FrostText(
                        strings.addedCount(count: formatCount(state.enqueued)),
                        role: FrostTextRole.headline,
                        numeric: true,
                      ),
                      FrostLabeledContent(
                        label: strings.savedTo(folder: '').trim(),
                        content: FrostPathText(
                          state.folder,
                          role: FrostTextRole.subheadline,
                          tone: FrostTextTone.secondary,
                          selectable: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (state.failed.isNotEmpty) ...[
              const SizedBox(height: FrostGap.section),
              FrostInlineBanner(
                tone: FrostBannerTone.caution,
                message: strings.failedHint(
                  count: formatCount(state.failed.length),
                ),
                actionLabel: strings.retryFailed,
                onAction: () => unawaited(_logic.retryEnqueue()),
              ),
              if (state.error case final error?)
                FrostErrorDetails(details: _failureMessage(error)),
            ],
          ],
        },
        if (state.error is DownloadPermissionDenied)
          FrostInlineBanner(
            tone: FrostBannerTone.caution,
            message: strings.permissionDenied,
            actionLabel: t.ugoira.openSettings,
            onAction: () =>
                unawaited(NativeDownloadPermissionGuard.openAppSettings()),
          ),
      ],
    );
    return FrostDialog(
      title: strings.title,
      showsCloseButton: true,
      content: content,
      leadingAction: leading,
      actions: actions,
    );
  }

  List<Widget> _ready(
    BatchDownloadState state,
    AsyncValue<BatchSaveLocation> location,
  ) => [
    Wrap(
      spacing: FrostGap.related,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FrostText(
          formatCount(state.items.length),
          role: FrostTextRole.value,
          numeric: true,
        ),
        FrostText(
          t.batchDownload.found,
          role: FrostTextRole.subheadline,
          tone: FrostTextTone.secondary,
        ),
      ],
    ),
    if (state.items.isEmpty) ...[
      const SizedBox(height: FrostGap.related),
      FrostText(t.batchDownload.empty, tone: FrostTextTone.secondary),
    ],
    if (state.error case final error?) ...[
      const SizedBox(height: FrostGap.group),
      FrostText(switch (error) {
        BatchFetchIssue.stalled => t.batchDownload.stalled,
        BatchFetchIssue.sessionChanged => t.batchDownload.sessionChanged,
        _ => '${t.batchDownload.fetchFailed}\n${_failureMessage(error)}',
      }, tone: FrostTextTone.negative),
      if (error != BatchFetchIssue.sessionChanged)
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FrostButton(
            label: t.generic.retry,
            onPressed: () => unawaited(_logic.retryFetch()),
          ),
        ),
    ],
    if (state.items.isNotEmpty) ...[
      const SizedBox(height: FrostGap.section),
      FrostText(
        t.batchDownload.countLabel,
        role: FrostTextRole.footnote,
        tone: FrostTextTone.secondary,
      ),
      const SizedBox(height: FrostGap.inline),
      FrostPicker.segmented(
        label: t.batchDownload.countLabel,
        value: _count,
        options: [
          FrostPickerOption(value: _BatchCount.all, label: t.batchDownload.all),
          FrostPickerOption(
            value: _BatchCount.first,
            label: t.batchDownload.first,
          ),
        ],
        onChanged: (value) {
          setState(() => _count = value);
          if (value == _BatchCount.all) _logic.select(state.items.length);
        },
      ),
      FrostPresence(
        visible: _count == _BatchCount.first,
        effect: FrostPresenceEffect.expand,
        child: Padding(
          padding: const EdgeInsets.only(top: FrostGap.related),
          child: FrostNumberField(
            value: state.selected,
            min: 1,
            max: state.items.length,
            label: t.batchDownload.countLabel,
            help: t.batchDownload.orderHint,
            onChanged: (value) => _logic.select(value.toInt()),
          ),
        ),
      ),
      const SizedBox(height: FrostGap.group),
      FrostTextField(
        controller: _folder,
        label: ref.watch(downloadPlatformProvider) == DownloadPlatform.ios
            ? t.ugoira.albumName
            : t.batchDownload.folderLabel,
        help: t.batchDownload.folderHelp,
        error: !_folderEdited || validBatchFolder(state.folder)
            ? null
            : t.batchDownload.invalidFolder,
        onChanged: (value) {
          _folderEdited = true;
          _logic.setFolder(value);
        },
      ),
      const SizedBox(height: FrostGap.related),
      switch (location) {
        AsyncData() => const SizedBox.shrink(),
        AsyncError() => FrostButton(
          label: t.batchDownload.locationFailed,
          icon: FrostIconSet.of(context).refresh,
          onPressed: () => ref.invalidate(
            batchSaveLocationProvider(widget.request.key.sourceId),
          ),
        ),
        // A resolved location adds no content; do not invent a loading block.
        _ => const SizedBox.shrink(),
      },
      if (location.value?.target.type == SaveTargetType.photos)
        FrostText(t.batchDownload.photosHint, role: FrostTextRole.footnote),
    ],
  ];
}

String _failureMessage(Object? error) => switch (error) {
  DownloadException(cause: PlatformException(:final code))
      when code == 'permission_denied' ||
          code == 'permission_denied_permanent' ||
          code == 'permission_unavailable' =>
    t.batchDownload.permissionDenied,
  DownloadException() => t.batchDownload.enqueueFailed,
  _ => describeBooruError(error, includeDiagnostics: false),
};
