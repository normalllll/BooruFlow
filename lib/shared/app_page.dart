import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';

/// A page header pinned over one scrolling column.
///
/// [filterBar] scrolls with the content. [empty] takes the space below the
/// header while [isEmpty] holds, in place of [slivers].
class AppPage extends StatelessWidget {
  const AppPage({
    required this.header,
    required this.slivers,
    this.filterBar,
    this.empty,
    this.isEmpty = false,
    this.maxWidth = double.infinity,
    super.key,
  });
  final Widget header;
  final List<Widget> slivers;
  final Widget? filterBar, empty;
  final bool isEmpty;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => FrostPinnedChrome(
    chrome: FrostContentColumn(maxWidth: maxWidth, child: header),
    body: FrostLayoutCrossfade(
      // A new primary controller owns another offset: only the viewport changes.
      key: ObjectKey(PrimaryScrollController.maybeOf(context)),
      layoutIdentity: isEmpty,
      child: FrostLoadingScrollView(
        slivers: _pageSlivers(
          maxWidth: maxWidth,
          filterBar: filterBar,
          empty: isEmpty ? empty : null,
          slivers: slivers,
        ),
      ),
    ),
  );
}

List<Widget> _pageSlivers({
  required double maxWidth,
  required List<Widget> slivers,
  Widget? filterBar,
  Widget? refreshHeader,
  Widget? empty,
}) => [
  const FrostChromeSpacer(),
  if (filterBar != null)
    FrostSliverContentColumn(
      maxWidth: maxWidth,
      sliver: SliverToBoxAdapter(child: filterBar),
    ),
  if (refreshHeader != null)
    FrostSliverContentColumn(maxWidth: maxWidth, sliver: refreshHeader),
  FrostSliverContentColumn(
    maxWidth: maxWidth,
    sliver: empty != null
        ? SliverFillRemaining(hasScrollBody: false, child: Center(child: empty))
        : SliverMainAxisGroup(slivers: slivers),
  ),
];

/// One section's body in an [AppSectionPage].
class AppSection {
  const AppSection({required this.slivers, this.filterBar, this.onRefresh});
  final List<Widget> slivers;
  final Widget? filterBar;
  final FrostRefreshAction? onRefresh;
}

/// A page header and section tabs pinned over one body per section, each with
/// its own scroll position. Sections are built when first shown and then kept.
///
/// The section on screen answers the system's scroll to top; the others keep
/// their positions without it.
class AppSectionPage extends StatefulWidget {
  const AppSectionPage({
    required this.header,
    required this.tabs,
    required this.controller,
    required this.sectionBuilder,
    this.trailing,
    this.maxWidth = double.infinity,
    super.key,
  });

  final Widget header;
  final Widget tabs;

  /// A control of the selected section, after the tabs.
  final Widget? trailing;
  final FrostTabController controller;
  final AppSection Function(BuildContext context, int index) sectionBuilder;
  final double maxWidth;

  @override
  State<AppSectionPage> createState() => _AppSectionPageState();
}

class _AppSectionPageState extends State<AppSectionPage> {
  late int _active = widget.controller.index;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_selectionChanged);
  }

  @override
  void didUpdateWidget(AppSectionPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_selectionChanged);
    widget.controller.addListener(_selectionChanged);
    _active = widget.controller.index;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_selectionChanged);
    super.dispose();
  }

  void _selectionChanged() {
    final index = widget.controller.index;
    if (index != _active) setState(() => _active = index);
  }

  Widget _section(BuildContext context, int index, ScrollController? primary) {
    final section = widget.sectionBuilder(context, index);
    Widget view(Widget? refreshHeader) => FrostLoadingScrollView(
      slivers: _pageSlivers(
        maxWidth: widget.maxWidth,
        filterBar: section.filterBar,
        refreshHeader: refreshHeader,
        slivers: section.slivers,
      ),
    );
    final onRefresh = section.onRefresh;
    return onRefresh == null
        ? view(null)
        : FrostRefreshView(
            onRefresh: onRefresh,
            scrollController: primary,
            builder: (context, physics, locators) =>
                view(locators.sliverHeader),
          );
  }

  @override
  Widget build(BuildContext context) {
    final primary = PrimaryScrollController.maybeOf(context);
    return FrostPinnedChrome(
      chrome: FrostContentColumn(
        maxWidth: widget.maxWidth,
        child: FrostHeaderSections(
          header: widget.header,
          tabs: widget.tabs,
          trailing: switch (widget.trailing) {
            // A long label truncates rather than pushing the tabs out.
            final trailing? => LayoutBuilder(
              builder: (context, box) => ConstrainedBox(
                constraints: BoxConstraints(maxWidth: box.maxWidth * .6),
                child: trailing,
              ),
            ),
            null => null,
          },
        ),
      ),
      // Mouse and trackpad change sections by the tabs, not by dragging.
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: const {
            PointerDeviceKind.touch,
            PointerDeviceKind.stylus,
            PointerDeviceKind.invertedStylus,
            PointerDeviceKind.unknown,
          },
        ),
        child: FrostTabView(
          controller: widget.controller,
          children: [
            for (var index = 0; index < widget.controller.length; index++)
              FrostKeepAlive(
                key: ValueKey(index),
                child: FrostChromeActiveBody(
                  active: index == _active,
                  child: ExcludeFocus(
                    excluding: index != _active,
                    child: Builder(
                      builder: (context) {
                        final owned = index == _active ? primary : null;
                        final section = _section(context, index, owned);
                        return owned == null
                            ? PrimaryScrollController.none(child: section)
                            : PrimaryScrollController(
                                controller: owned,
                                child: section,
                              );
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
