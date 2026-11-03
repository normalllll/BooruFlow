import 'dart:async';
import 'dart:math' as math;

import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/features/posts/widgets/post_detail_controls.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';

const _informationWidth = 380.0;
const _minimumStageWidth = 240.0;
const _blockGap = FrostGap.section;
const _actionsGap = FrostGap.group;

/// A long image stops at this part of the page, so the information still shows
/// below it; the viewer is where it is seen whole.
const _stageHeightFraction = .75;
const _minimumStageHeight = 240.0;

/// A narrow or portrait space is one column of media and information.
bool postDetailStacked(BuildContext context, Size space) =>
    space.width < FrostSizeClass.medium.minimumWidth ||
    !isHorizontalSize(space, pointer: FrostDensity.of(context).usesPointer);

/// The corners of a stage: a stacked one meets the screen edges.
double postStageRadius({required bool stacked}) => stacked ? 0 : FrostRadius.lg;

/// The window around the media: its artwork where there is some, else the page.
class PostDetailBackdrop extends StatelessWidget {
  const PostDetailBackdrop({required this.image, this.stageKey, super.key});
  final ImageProvider? image;

  /// The stage the artwork's light is centred on.
  final GlobalKey? stageKey;
  @override
  Widget build(BuildContext context) {
    if (image case final image?) {
      return FrostAmbientBackdrop.fromImage(
        image: image,
        stageKey: stageKey,
        child: const SizedBox.expand(),
      );
    }
    final tokens = FrostThemeTokens.of(context);
    return ColoredBox(color: tokens.isDark ? tokens.canvas : tokens.surface);
  }
}

/// One post's information as a sliver in the page's content column.
class PostInformationSliver extends StatelessWidget {
  const PostInformationSliver({
    required this.primary,
    this.actions,
    this.sections = const [],
    super.key,
  });
  final Widget primary;
  final Widget? actions;
  final List<Widget> sections;

  Widget _block(Widget child, double gap) => KeepAlive(
    key: child.key == null ? null : ValueKey(child.key),
    keepAlive: true,
    child: RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.only(top: gap),
        child: child,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => FrostSliverContentColumn(
    sliver: SliverPadding(
      padding: const EdgeInsets.symmetric(vertical: FrostGap.section),
      sliver: SliverList(
        // Visited blocks keep their State; blocks further down wait to be built.
        delegate: SliverChildListDelegate(
          [
            _block(primary, 0),
            if (actions case final actions?) _block(actions, _actionsGap),
            for (final section in sections) _block(section, _blockGap),
          ],
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: false,
          addSemanticIndexes: false,
        ),
      ),
    ),
  );
}

/// One post in a stacked page: the media edge to edge at the top, scrolling
/// away with its information. [onMetrics] hears each change of its position.
class PostStackedScroll extends StatelessWidget {
  const PostStackedScroll({
    required this.stage,
    required this.information,
    this.stageKey,
    this.onMetrics,
    super.key,
  });
  final Widget stage;
  final Widget information;
  final GlobalKey? stageKey;
  final ValueChanged<ScrollMetrics>? onMetrics;

  bool _report(ScrollMetrics metrics, int depth) {
    if (depth == 0 && metrics.axis == Axis.vertical) onMetrics?.call(metrics);
    return false;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) => _report(n.metrics, n.depth),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) => _report(n.metrics, n.depth),
        child: CustomScrollView(
          primary: false,
          slivers: [
            SliverToBoxAdapter(
              child: MediaQuery.removePadding(
                context: context,
                removeBottom: true,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: math.max(
                      _minimumStageHeight,
                      box.maxHeight * _stageHeightFraction,
                    ),
                  ),
                  child: KeyedSubtree(key: stageKey, child: stage),
                ),
              ),
            ),
            MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: information,
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.paddingOf(context).bottom),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A stage beside a column of information that scrolls on its own.
class PostWideLayout extends StatelessWidget {
  const PostWideLayout({
    required this.stage,
    required this.information,
    this.stageKey,
    super.key,
  });
  final Widget stage;
  final Widget information;
  final GlobalKey? stageKey;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final rtl = Directionality.of(context) == TextDirection.rtl;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeLeft: rtl,
              removeRight: !rtl,
              child: KeyedSubtree(key: stageKey, child: stage),
            ),
          ),
          SizedBox(
            width: math.min(
              _informationWidth,
              math.max(0, box.maxWidth - _minimumStageWidth),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                FrostPinnedChrome(
                  chrome: const SizedBox.shrink(),
                  body: CustomScrollView(
                    slivers: [
                      const FrostChromeSpacer(),
                      information,
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: MediaQuery.paddingOf(context).bottom,
                        ),
                      ),
                    ],
                  ),
                ),
                const PositionedDirectional(
                  start: 0,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: FrostDivider(axis: Axis.vertical),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

/// Back and More over stacked media, on the system-bar protection. They stay
/// put while the pages move under them. Once [pastStage] holds there is no
/// media below them, and they become an ordinary glass page header.
class PostMediaHeader extends StatelessWidget {
  const PostMediaHeader({
    required this.pastStage,
    this.menu = const [],
    super.key,
  });
  final ValueListenable<bool> pastStage;
  final List<FrostMenuEntry> menu;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context);
    final consumed = EdgeInsets.fromLTRB(inset.left, inset.top, inset.right, 0);
    return ValueListenableBuilder<bool>(
      valueListenable: pastStage,
      builder: (context, past, _) => Stack(
        children: [
          FrostMediaSystemChrome(active: !past, child: const SizedBox.shrink()),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: past
                ? _glass(context, consumed)
                : _onMedia(context, consumed),
          ),
        ],
      ),
    );
  }

  Widget _glass(BuildContext context, EdgeInsets consumed) =>
      FrostPinnedChromeGlass(
        opacity: 1,
        child: Padding(
          padding: consumed,
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            removeLeft: true,
            removeRight: true,
            child: FrostContentColumn(
              child: FrostPageHeader(
                actions: [if (menu.isNotEmpty) postMoreAction(context, menu)],
              ),
            ),
          ),
        ),
      );

  Widget _onMedia(BuildContext context, EdgeInsets consumed) {
    // While another page moves over this one, Back stays so it fades with the
    // page, but it no longer takes taps or focus.
    final inert = ModalRoute.isCurrentOf(context) != true;
    return Padding(
      padding: consumed.add(const EdgeInsets.all(FrostGap.inline)),
      child: Row(
        children: [
          if (FrostPageHeader.leadingFor(context) != null)
            IgnorePointer(
              ignoring: inert,
              child: ExcludeFocus(
                excluding: inert,
                child: FrostButton.iconOnMedia(
                  label: t.frost.back,
                  icon: appIcons.back,
                  onPressed: () => _back(context),
                ),
              ),
            ),
          const Spacer(),
          if (menu.isNotEmpty) _More(menu),
        ],
      ),
    );
  }
}

/// The way back that a page header's own Back button takes.
void _back(BuildContext context) {
  final shell = FrostShellNavigationScope.maybeOf(context);
  if (shell?.canGoBack ?? false) {
    shell!.goBack();
  } else {
    unawaited(Navigator.maybeOf(context)?.maybePop());
  }
}

class _More extends StatelessWidget {
  const _More(this.entries);
  final List<FrostMenuEntry> entries;
  @override
  Widget build(BuildContext context) => FrostMenuAnchor(
    entries: entries,
    builder: (context, focus, toggle) => Focus(
      focusNode: focus,
      canRequestFocus: false,
      child: FrostButton.iconOnMedia(
        label: t.frost.more,
        icon: appIcons.more,
        onPressed: toggle,
      ),
    ),
  );
}
