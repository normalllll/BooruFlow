import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';

/// A whole-window lightbox, still owned by GoRouter's declarative pages.
/// A ModalRoute (not PageRoute) avoids root Hero collection across the retained
/// branch and content navigators. TransitionRoute supplies predictive back;
/// the shared transition paints the same page motion as ordinary content.
class MediaViewerPage extends Page<void> {
  const MediaViewerPage({required this.child, super.key});
  final Widget child;

  /// The shared viewport has already painted the complete exit. Keep GoRouter's
  /// normal pop/history notification, without adding another route animation.
  static void completeViewportDismissal(BuildContext context) {
    final route = ModalRoute.of(context);
    assert(route is _MediaViewerRoute);
    if (route is _MediaViewerRoute) route.finishViewportDismissal();
  }

  @override
  Route<void> createRoute(BuildContext context) =>
      _MediaViewerRoute(this, context);
}

class _MediaViewerRoute extends ModalRoute<void> {
  _MediaViewerRoute(MediaViewerPage page, BuildContext context)
    // The desktop viewer fills the window: it appears and leaves at once.
    : _enter = frostUsesCustomTitleBar
          ? Duration.zero
          : FrostMotion.duration(context, FrostMotion.page),
      _exit = frostUsesCustomTitleBar
          ? Duration.zero
          : FrostMotion.duration(context, FrostMotion.exit),
      super(settings: page);
  final Duration _enter, _exit;
  bool _viewportDismissed = false;
  void finishViewportDismissal() {
    if (!isCurrent || _viewportDismissed) return;
    _viewportDismissed = true;
    controller!.reverseDuration = Duration.zero;
    navigator!.pop();
  }

  @override
  Duration get transitionDuration => _enter;
  @override
  Duration get reverseTransitionDuration => _exit;
  @override
  // The shared viewport paints an opaque media background at rest and fades
  // that background during pull-down. A transparent route exposes the detail
  // beneath it without reintroducing root PageRoute Hero collection. The
  // desktop viewer has no pull-down: it is opaque, so the shell's glass and
  // the pages below stop laying out, painting and blurring.
  bool get opaque => frostUsesCustomTitleBar;
  @override
  bool get maintainState => true;
  @override
  bool get barrierDismissible => false;
  @override
  Color? get barrierColor => null;
  @override
  String? get barrierLabel => null;
  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => (settings as MediaViewerPage).child;
  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _viewportDismissed
      ? child
      : frostPageTransition(context, animation, secondaryAnimation, child);
}
