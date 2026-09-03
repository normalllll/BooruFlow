import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yande_gui/components/download_floating_window/download_floating_window.dart';
import 'package:yande_gui/intl/translations.g.dart';
import 'package:yande_gui/pages/about/about_page.dart';
import 'package:yande_gui/pages/image_zoom_page/image_zoom_page.dart';
import 'package:yande_gui/pages/index/index_page.dart';
import 'package:yande_gui/pages/post_detail/post_detail_page.dart';
import 'package:yande_gui/pages/post_list/post_list_page.dart';
import 'package:yande_gui/pages/post_search/post_search_page.dart';
import 'package:yande_gui/pages/settings/settings_page.dart';
import 'package:yande_gui/router/app_navigation.dart';
import 'package:yande_gui/router/navigator_stack_observer.dart';
import 'package:yande_gui/src/rust/yande/model/post.dart';
import 'package:yande_gui/widgets/auto_scaffold/auto_scaffold.dart';

class ImageViewerRouteArgs {
  const ImageViewerRouteArgs({
    required this.url,
    required this.width,
    required this.height,
  });

  final String url;
  final double width;
  final double height;
}

class AppRouter {
  const AppRouter._();

  static final rootNavigatorKey = GlobalKey<NavigatorState>();
  static final rightNavigatorKey = GlobalKey<NavigatorState>();
  static final rightNavigatorCanPop = ValueNotifier<bool>(false);
  static final _rightNavigatorObserver = NavigatorStackObserver(
    _refreshRightNavigatorCanPop,
  );

  static final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoute.posts.path,
    routes: [
      ShellRoute(
        navigatorKey: rightNavigatorKey,
        observers: [_rightNavigatorObserver],
        builder: (context, state, child) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _refreshRightNavigatorCanPop(),
          );
          return DownloadFloatingWindow(
            onTaskTap: openPost,
            child: IndexPage(
              selectedIndex: appDestinationIndexForPath(state.uri.path),
              showMobileNavigation: isPrimaryNavigationPath(state.uri.path),
              canPopListenable: rightNavigatorCanPop,
              onBack: _popRightNavigator,
              onResetRightNavigator: _popRightNavigatorToRoot,
              child: child,
            ),
          );
        },
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) => navigationShell,
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoute.posts.path,
                    name: AppRoute.posts.name,
                    pageBuilder: (context, state) =>
                        _primaryPage(state, const PostListPage()),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoute.search.path,
                    name: AppRoute.search.name,
                    pageBuilder: (context, state) =>
                        _primaryPage(state, const PostSearchPage()),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoute.about.path,
                    name: AppRoute.about.name,
                    pageBuilder: (context, state) =>
                        _primaryPage(state, const AboutPage()),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoute.settings.path,
                    name: AppRoute.settings.name,
                    pageBuilder: (context, state) =>
                        _primaryPage(state, const SettingsPage()),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoute.taggedPosts.path,
            name: AppRoute.taggedPosts.name,
            pageBuilder: (context, state) {
              final query = state.uri.queryParameters['q'] ?? '';
              final tags = query
                  .trim()
                  .split(RegExp(r'\s+'))
                  .where((tag) => tag.isNotEmpty)
                  .toList(growable: false);
              return NoTransitionPage<void>(
                key: state.pageKey,
                child: PostListPage(tags: List<String>.unmodifiable(tags)),
              );
            },
          ),
          GoRoute(
            path: AppRoute.postDetail.path,
            name: AppRoute.postDetail.name,
            pageBuilder: (context, state) {
              final post = state.extra;
              return _contentPage(
                state,
                post is Post
                    ? PostDetailPage(post: post)
                    : const _MissingRouteDataPage(),
              );
            },
          ),
          GoRoute(
            path: AppRoute.imageViewer.path,
            name: AppRoute.imageViewer.name,
            pageBuilder: (context, state) {
              final args = state.extra;
              return _contentPage(
                state,
                args is ImageViewerRouteArgs
                    ? ImageZoomPage(
                        url: args.url,
                        width: args.width,
                        height: args.height,
                      )
                    : const _MissingRouteDataPage(),
              );
            },
          ),
        ],
      ),
    ],
  );

  static Future<T?> pushPost<T>(BuildContext context, Post post) {
    return context.pushNamed<T>(
      AppRoute.postDetail.name,
      pathParameters: {'id': '${post.id}'},
      extra: post,
    );
  }

  static Future<T?> pushTaggedPosts<T>(
    BuildContext context,
    List<String> tags,
  ) {
    return context.pushNamed<T>(
      AppRoute.taggedPosts.name,
      queryParameters: {'q': tags.join(' ')},
    );
  }

  static Future<T?> pushImageViewer<T>(
    BuildContext context, {
    required String url,
    required double width,
    required double height,
  }) {
    return context.pushNamed<T>(
      AppRoute.imageViewer.name,
      extra: ImageViewerRouteArgs(url: url, width: width, height: height),
    );
  }

  static Future<T?> openPost<T>(Post post) {
    return router.pushNamed<T>(
      AppRoute.postDetail.name,
      pathParameters: {'id': '${post.id}'},
      extra: post,
    );
  }

  static void _popRightNavigator() {
    rightNavigatorKey.currentState?.maybePop();
  }

  static void _popRightNavigatorToRoot() {
    rightNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    _refreshRightNavigatorCanPop();
  }

  static void _refreshRightNavigatorCanPop() {
    final canPop = _rightNavigatorObserver.canPopPageRoute;
    if (rightNavigatorCanPop.value != canPop) {
      rightNavigatorCanPop.value = canPop;
    }
  }

  static Page<void> _primaryPage(GoRouterState state, Widget child) {
    return NoTransitionPage<void>(key: state.pageKey, child: child);
  }

  static Page<void> _contentPage(GoRouterState state, Widget child) {
    return MaterialPage<void>(key: state.pageKey, child: child);
  }
}

class _MissingRouteDataPage extends StatelessWidget {
  const _MissingRouteDataPage();

  @override
  Widget build(BuildContext context) {
    return AutoScaffold(
      titleWidget: Text(t.generic.notFound),
      builder: (context, horizontal) => Center(child: Text(t.generic.notFound)),
    );
  }
}
