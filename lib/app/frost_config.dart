import 'package:booruflow/app/icons.g.dart';
import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/features/booru/web_challenge_logic.dart';
import 'package:booruflow/features/discovery/collection_logic.dart'
    show NoSupportedRatings;
import 'package:booruflow/intl/number_format.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/action_failure.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';

// Search and result-query headers share one upper bound; allocation remains
// continuous inside the shared Toolbar after reserving the trailing actions.
const appSearchMiddleMaxWidth = 640.0;

const appIcons = FrostIconSet(
  back: FrostIconData.glyph(BooruFlowIcons.arrowLeft),
  forward: FrostIconData.glyph(BooruFlowIcons.arrowRight),
  close: FrostIconData.glyph(BooruFlowIcons.x),
  more: FrostIconData.glyph(BooruFlowIcons.ellipsis),
  chevronLeft: FrostIconData.glyph(BooruFlowIcons.chevronLeft),
  chevronRight: FrostIconData.glyph(BooruFlowIcons.chevronRight),
  chevronUp: FrostIconData.glyph(BooruFlowIcons.chevronUp),
  chevronDown: FrostIconData.glyph(BooruFlowIcons.chevronDown),
  arrowDown: FrostIconData.glyph(BooruFlowIcons.arrowDown),
  chevronUpDown: FrostIconData.glyph(BooruFlowIcons.chevronsUpDown),
  expand: FrostIconData.glyph(BooruFlowIcons.chevronDown),
  collapse: FrostIconData.glyph(BooruFlowIcons.chevronUp),
  sidebarExpand: FrostIconData.glyph(BooruFlowIcons.panelLeftOpen),
  sidebarCollapse: FrostIconData.glyph(BooruFlowIcons.panelLeftClose),
  externalLink: FrostIconData.glyph(BooruFlowIcons.externalLink),
  link: FrostIconData.glyph(BooruFlowIcons.link),
  search: FrostIconData.glyph(BooruFlowIcons.search),
  refresh: FrostIconData.glyph(BooruFlowIcons.refreshCw),
  copy: FrostIconData.glyph(BooruFlowIcons.copy),
  share: FrostIconData.glyph(BooruFlowIcons.share2),
  download: FrostIconData.glyph(BooruFlowIcons.download),
  upload: FrostIconData.glyph(BooruFlowIcons.upload),
  delete: FrostIconData.glyph(BooruFlowIcons.trash),
  edit: FrostIconData.glyph(BooruFlowIcons.squarePen),
  add: FrostIconData.glyph(BooruFlowIcons.plus),
  remove: FrostIconData.glyph(BooruFlowIcons.minus),
  filter: FrostIconData.glyph(BooruFlowIcons.listFilter),
  sort: FrostIconData.glyph(BooruFlowIcons.arrowDownUp),
  check: FrostIconData.glyph(BooruFlowIcons.check),
  dragHandle: FrostIconData.glyph(BooruFlowIcons.gripVertical),
  success: FrostIconData.glyph(BooruFlowIcons.circleCheck),
  info: FrostIconData.glyph(BooruFlowIcons.info),
  error: FrostIconData.glyph(BooruFlowIcons.circleAlert),
  empty: FrostIconData.glyph(BooruFlowIcons.inbox),
  play: FrostIconData.glyph(BooruFlowIcons.play),
  pause: FrostIconData.glyph(BooruFlowIcons.pause),
  repeat: FrostIconData.glyph(BooruFlowIcons.repeat),
  volumeOn: FrostIconData.glyph(BooruFlowIcons.volume2),
  volumeOff: FrostIconData.glyph(BooruFlowIcons.volumeX),
  fullscreen: FrostIconData.glyph(BooruFlowIcons.maximize),
  exitFullscreen: FrostIconData.glyph(BooruFlowIcons.minimize),
  zoomIn: FrostIconData.glyph(BooruFlowIcons.zoomIn),
  zoomOut: FrostIconData.glyph(BooruFlowIcons.zoomOut),
  image: FrostIconData.glyph(BooruFlowIcons.image),
  imageError: FrostIconData.glyph(BooruFlowIcons.imageOff),
  multiPage: FrostIconData.glyph(BooruFlowIcons.images),
  minimize: FrostIconData.glyph(BooruFlowIcons.minus),
  maximize: FrostIconData.glyph(BooruFlowIcons.square),
  restore: FrostIconData.glyph(BooruFlowIcons.copy),
  calendar: FrostIconData.glyph(BooruFlowIcons.calendarDays),
  clock: FrostIconData.glyph(BooruFlowIcons.clock),
  folder: FrostIconData.glyph(BooruFlowIcons.folder),
  eye: FrostIconData.glyph(BooruFlowIcons.eye),
  eyeOff: FrostIconData.glyph(BooruFlowIcons.eyeOff),
  user: FrostIconData.glyph(BooruFlowIcons.userRound),
  send: FrostIconData.glyph(BooruFlowIcons.send),
  attach: FrostIconData.glyph(BooruFlowIcons.paperclip),
  textFormat: FrostIconData.glyph(BooruFlowIcons.type),
);

final appFrostConfig = FrostConfig(
  palettes: FrostPalettes.pink,
  fonts: const FrostFonts(
    japanese: 'Noto Sans JP',
    simplifiedChinese: 'Noto Sans SC',
    defaultScript: FrostContentScript.japanese,
  ),
  icons: appIcons,
  labels: appFrostLabels,
  errors: FrostErrorPresenter(
    message: (context, error) => switch (error) {
      AppActionFailure(:final message) => message,
      NoSupportedRatings() => Translations.of(
        context,
      ).discovery.unsupportedRatings,
      _ => describeBooruError(error, includeDiagnostics: false),
    },
    details: (error) => switch (error) {
      AppActionFailure(cause: final cause?) => booruErrorDetails(cause),
      AppActionFailure() => null,
      _ => booruErrorDetails(error),
    },
    title: (context, error) => isBooruRateLimited(error)
        ? Translations.of(context).discovery.tooManyRequests
        : null,
    icon: (context, error) => isBooruRateLimited(error) ? appIcons.clock : null,
    action: (context, error) {
      final sourceId = challengeError(error)?.sourceId;
      if (sourceId == null) return null;
      return FrostErrorAction(
        label: Translations.of(context).webChallenge.open,
        icon: appIcons.user,
        onPressed: () async {
          try {
            final container = ProviderScope.containerOf(context, listen: false);
            final service = container.read(webChallengeServiceProvider);
            return await container
                .read(webChallengeSessionProvider(service).notifier)
                .resolve(context, sourceId);
          } catch (error) {
            if (context.mounted) {
              FrostToast.fromError(context, error);
            }
            return false;
          }
        },
      );
    },
  ),
);

FrostLabels appFrostLabels(BuildContext context) {
  final labels = Translations.of(context).frost;
  return FrostLabels(
    retry: labels.retry,
    retryAfter: (seconds) =>
        Translations.of(context).discovery.retryIn(seconds: seconds),
    error: labels.error,
    errorDetails: labels.errorDetails,
    copyDetails: labels.copyDetails,
    copied: labels.copied,
    loading: labels.loading,
    actionSucceeded: labels.actionSucceeded,
    actionFailed: labels.actionFailed,
    loadFailed: labels.loadFailed,
    noMoreItems: labels.noMoreItems,
    noItems: labels.noItems,
    pullToRefresh: labels.pullToRefresh,
    releaseToRefresh: labels.releaseToRefresh,
    refreshing: labels.refreshing,
    refreshComplete: labels.refreshComplete,
    refreshFailed: labels.refreshFailed,
    previous: labels.previous,
    next: labels.next,
    back: labels.back,
    more: labels.more,
    expandNavigation: labels.expandNavigation,
    collapseNavigation: labels.collapseNavigation,
    navigationStatus: (count, progressPercent) => [
      if (count > 0) labels.navigationCount(count: formatCount(count)),
      if (progressPercent != null)
        labels.navigationProgress(progress: formatCount(progressPercent)),
    ].join(labels.listSeparator),
    clearText: labels.clearText,
    search: labels.search,
    noResults: (query) => labels.noResults(query: query),
    clearSearch: labels.clearSearch,
    dismiss: labels.dismiss,
    expandText: labels.expandText,
    collapseText: labels.collapseText,
    showAll: labels.showAll,
    copy: labels.copy,
    clearAll: labels.clearAll,
    showPassword: labels.showPassword,
    hidePassword: labels.hidePassword,
    chooseDate: labels.chooseDate,
    chooseTime: labels.chooseTime,
    increment: labels.increment,
    decrement: labels.decrement,
    reorderHandle: labels.reorderHandle,
    sortAscending: labels.sortAscending,
    sortDescending: labels.sortDescending,
    play: labels.play,
    pause: labels.pause,
    loop: labels.loop,
    mute: labels.mute,
    unmute: labels.unmute,
    fullscreen: labels.fullscreen,
    exitFullscreen: labels.exitFullscreen,
    reload: labels.reload,
    openInBrowser: labels.openInBrowser,
    minimize: labels.minimize,
    maximize: labels.maximize,
    restore: labels.restore,
    close: labels.close,
    cancel: labels.cancel,
    apply: labels.apply,
    clear: labels.clear,
    choose: labels.choose,
    showInFolder: labels.showInFolder,
    selectedCount: (count) => labels.selectedCount(count: formatCount(count)),
    pageOf: (page, total) =>
        labels.pageOf(page: formatCount(page), total: formatCount(total)),
    selectAll: labels.selectAll,
    done: labels.done,
    itemPosition: (position, total) => labels.itemPosition(
      position: formatCount(position),
      total: formatCount(total),
    ),
    tableDimensions: (rows, columns) => labels.tableDimensions(
      rows: formatCount(rows),
      columns: formatCount(columns),
    ),
    taskQueued: labels.taskQueued,
    taskRunning: labels.taskRunning,
    taskPaused: labels.taskPaused,
    taskCompleted: labels.taskCompleted,
    taskFailed: labels.taskFailed,
    taskCancelled: labels.taskCancelled,
    remove: labels.remove,
    forward: labels.forward,
    stop: labels.stop,
    seek: labels.seek,
    send: labels.send,
    attach: labels.attach,
    readerSettings: labels.readerSettings,
    textSize: labels.textSize,
    lineSpacing: labels.lineSpacing,
    readingProgress: labels.readingProgress,
    showReplies: (count) => labels.showReplies(count: formatCount(count)),
    characterCount: (count, limit) => labels.characterCount(
      count: formatCount(count),
      limit: formatCount(limit),
    ),
    moreMedia: (count) => labels.moreMedia(count: formatCount(count)),
  );
}
