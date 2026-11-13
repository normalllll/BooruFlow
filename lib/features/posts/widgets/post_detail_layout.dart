import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

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

/// The height of a stacked stage in [space]: its width over [aspectRatio], up to
/// the part of the page a long image may take.
double postStackedStageHeight(Size space, double aspectRatio) => math.min(
  space.width / aspectRatio,
  math.max(_minimumStageHeight, space.height * _stageHeightFraction),
);

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

/// The same information as one box, for a place that cross-fades it as a whole.
class PostInformationBox extends StatelessWidget {
  const PostInformationBox({
    required this.primary,
    this.actions,
    this.sections = const [],
    super.key,
  });
  final Widget primary;
  final Widget? actions;
  final List<Widget> sections;

  Widget _block(Widget child, double gap) => RepaintBoundary(
    key: child.key == null ? null : ValueKey(child.key),
    child: Padding(
      padding: EdgeInsets.only(top: gap),
      child: child,
    ),
  );

  @override
  Widget build(BuildContext context) => FrostContentColumn(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: FrostGap.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _block(primary, 0),
          if (actions case final actions?) _block(actions, _actionsGap),
          for (final section in sections) _block(section, _blockGap),
        ],
      ),
    ),
  );
}

/// A post with a single stage: the media edge to edge at the top, scrolling
/// away with its information.
class PostStackedScroll extends StatelessWidget {
  const PostStackedScroll({
    required this.stage,
    required this.information,
    super.key,
  });
  final Widget stage;
  final Widget information;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => CustomScrollView(
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
              child: stage,
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
  );
}

/// The stacked post detail: one vertical scroll whose first part is the stage
/// area, a row of stages that pages sideways with the finger, then the
/// information of the post the pages last settled on.
///
/// The stage area is as high as the stage in front of it; while pages move it
/// is the blend of the two stages either side of the fractional page, so the
/// information below follows the image continuously. [onSettled] hears the
/// page the row comes to rest on; the information and everything else that
/// belongs to a post changes then, not midway.
class PostStackedLayout extends StatefulWidget {
  const PostStackedLayout({
    required this.pages,
    required this.itemCount,
    required this.stageBuilder,
    required this.ratioOf,
    required this.information,
    required this.informationIdentity,
    this.ratios,
    this.menu = const [],
    this.onSettled,
    super.key,
  });
  final PageController pages;
  final int itemCount;
  final IndexedWidgetBuilder stageBuilder;

  /// The aspect ratio the stage at an index presents right now.
  final double Function(int index) ratioOf;

  /// Notifies when any [ratioOf] value changes.
  final Listenable? ratios;
  final Widget information;

  /// What the information is of; a new one cross-fades in.
  final Object informationIdentity;
  final List<FrostMenuEntry> menu;
  final ValueChanged<int>? onSettled;

  @override
  State<PostStackedLayout> createState() => _PostStackedLayoutState();
}

class _PostStackedLayoutState extends State<PostStackedLayout> {
  final _scroll = ScrollController();
  late final _past = _PastStage(_isPastStage);
  late Listenable _heights;
  Size _space = Size.zero;
  double _header = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_past.refresh);
    _bind();
  }

  void _bind() {
    _heights = Listenable.merge([widget.pages, ?widget.ratios])
      ..addListener(_past.refresh);
  }

  @override
  void didUpdateWidget(PostStackedLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pages != widget.pages || oldWidget.ratios != widget.ratios) {
      _heights.removeListener(_past.refresh);
      _bind();
    }
  }

  @override
  void dispose() {
    _heights.removeListener(_past.refresh);
    _scroll.dispose();
    _past.dispose();
    super.dispose();
  }

  /// The stage area's height: the blend of the stages either side of the page.
  double _stageHeight() {
    final count = widget.itemCount;
    if (count == 0 || _space.isEmpty) return 0;
    final pages = widget.pages;
    final shown = pages.hasClients ? pages.page : null;
    final page = (shown ?? pages.initialPage.toDouble()).clamp(
      0.0,
      count - 1.0,
    );
    final before = page.floor(), after = math.min(before + 1, count - 1);
    double height(int index) =>
        postStackedStageHeight(_space, widget.ratioOf(index));
    return lerpDouble(height(before), height(after), page - before)!;
  }

  /// Whether the stage has scrolled out from under the header.
  bool _isPastStage() =>
      _scroll.hasClients && _scroll.offset >= _stageHeight() - _header;

  bool _pageScrolled(ScrollNotification notification) {
    if (notification is ScrollEndNotification &&
        notification.depth == 0 &&
        notification.metrics.axis == Axis.horizontal &&
        notification.metrics is PageMetrics) {
      final page = (notification.metrics as PageMetrics).page;
      if (page != null && (page - page.round()).abs() < .001) {
        widget.onSettled?.call(page.round());
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    _header =
        MediaQuery.paddingOf(context).top + FrostPageHeader.verticalHeight;
    final pages = NotificationListener<ScrollNotification>(
      onNotification: _pageScrolled,
      child: PageView.builder(
        key: const ValueKey('post-detail-pages'),
        controller: widget.pages,
        // The pages beside the one shown are built ahead, so a neighbour's
        // image is already on its way when it slides into view.
        allowImplicitScrolling: true,
        itemCount: widget.itemCount,
        itemBuilder: widget.stageBuilder,
      ),
    );
    return LayoutBuilder(
      builder: (context, box) {
        _space = box.biggest;
        return Stack(
          fit: StackFit.expand,
          children: [
            CustomScrollView(
              controller: _scroll,
              slivers: [
                SliverToBoxAdapter(
                  child: MediaQuery.removePadding(
                    context: context,
                    removeBottom: true,
                    child: AnimatedBuilder(
                      animation: _heights,
                      child: pages,
                      builder: (context, child) =>
                          SizedBox(height: _stageHeight(), child: child),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: FrostLayoutCrossfade(
                      layoutIdentity: widget.informationIdentity,
                      child: widget.information,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(height: MediaQuery.paddingOf(context).bottom),
                ),
              ],
            ),
            PostMediaHeader(pastStage: _past, menu: widget.menu),
          ],
        );
      },
    );
  }
}

/// Whether the stage is behind the header: read from the scroll whenever it is
/// asked, and announced only when it changes.
class _PastStage extends ChangeNotifier implements ValueListenable<bool> {
  _PastStage(this._read);
  final bool Function() _read;
  bool _announced = false;

  @override
  bool get value => _read();

  void refresh() {
    final now = _read();
    if (now == _announced) return;
    _announced = now;
    notifyListeners();
  }
}

/// A stage beside a column of information that scrolls on its own.
class PostWideLayout extends StatelessWidget {
  const PostWideLayout({
    required this.stage,
    required this.information,
    this.title,
    this.stageKey,
    super.key,
  });
  final Widget stage;
  final Widget information;

  /// The page title the shell's title row shows; the header itself only keeps
  /// it for screen readers there.
  final String? title;
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
                  chrome: title == null
                      ? const SizedBox.shrink()
                      : FrostPageHeader(title: FrostText(title!)),
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
