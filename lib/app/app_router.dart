import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:booruflow/features/booru/booru_service.dart';
import 'package:go_router/go_router.dart';
import 'package:booruflow/app/navigator_stack_observer.dart';
import 'package:booruflow/features/about/about_page.dart';
import 'package:booruflow/features/downloads/widgets/download_floating_window.dart';
import 'package:booruflow/features/image_viewer/image_zoom_page.dart';
import 'package:booruflow/features/posts/post_detail_page.dart';
import 'package:booruflow/features/posts/post_list_page.dart';
import 'package:booruflow/features/home/home_page.dart';
import 'package:booruflow/features/search/post_search_page.dart';
import 'package:booruflow/features/search/user_tags_page.dart';
import 'package:booruflow/features/settings/settings_page.dart';
import 'package:booruflow/features/shell/app_shell.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/shared/widgets/auto_scaffold.dart';

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
            onTaskTap: _openPost,
            child: AppShell(
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
                        _primaryPage(state, const HomePage()),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoute.search.path,
                    name: AppRoute.search.name,
                    pageBuilder: (context, state) => _primaryPage(
                      state,
                      PostSearchPage(
                        sourceId: state.uri.queryParameters['source'],
                      ),
                    ),
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
            path: AppRoute.searchEditor.path,
            name: AppRoute.searchEditor.name,
            pageBuilder: (context, state) {
              final source = state.uri.queryParameters['source'];
              var tags = <String>[];
              var valid = BooruService.instance.sources.any(
                (item) => item.sourceId == source,
              );
              try {
                tags =
                    (jsonDecode(state.uri.queryParameters['tags'] ?? '[]')
                            as List)
                        .cast<String>();
              } catch (_) {
                valid = false;
              }
              return NoTransitionPage<void>(
                key: state.pageKey,
                child: PostSearchPage(
                  sourceId: valid ? source : null,
                  initialQuery: tags.join(' '),
                  isQueryEditor: true,
                  invalidQuery: !valid,
                  onSubmit: (source, tags) =>
                      context.pop(SearchQuery(sourceId: source, tags: tags)),
                ),
              );
            },
          ),
          GoRoute(
            path: AppRoute.userTags.path,
            name: AppRoute.userTags.name,
            pageBuilder: (context, state) => _contentPage(
              state,
              UserTagsPage(sourceId: state.uri.queryParameters['source']),
            ),
          ),
          GoRoute(
            path: AppRoute.settingsSection.path,
            name: AppRoute.settingsSection.name,
            pageBuilder: (context, state) {
              final section = SettingsSection.fromPath(
                state.pathParameters['section'],
              );
              return _contentPage(
                state,
                section == null
                    ? const _MissingRouteDataPage()
                    : SettingsPage(section: section),
              );
            },
          ),
          GoRoute(
            path: AppRoute.taggedPosts.path,
            name: AppRoute.taggedPosts.name,
            pageBuilder: (context, state) {
              final sourceId =
                  state.uri.queryParameters['source'] ??
                  BooruService.instance.selectedSource.value;
              var tags = <String>[];
              var valid = BooruService.instance.sources.any(
                (source) => source.sourceId == sourceId,
              );
              try {
                final encoded = state.uri.queryParameters['tags'];
                if (encoded != null) {
                  tags = (jsonDecode(encoded) as List)
                      .cast<String>()
                      .map((tag) => tag.trim())
                      .where((tag) => tag.isNotEmpty)
                      .toList();
                } else {
                  tags = parseQueryInput(state.uri.queryParameters['q'] ?? '');
                }
              } catch (_) {
                valid = false;
              }
              return NoTransitionPage<void>(
                key: state.pageKey,
                child: !valid || tags.isEmpty
                    ? PostSearchPage(
                        initialTags: tags,
                        sourceId: valid ? sourceId : null,
                        invalidQuery: !valid,
                      )
                    : PostListPage(
                        tags: List<String>.unmodifiable(tags),
                        sourceId: sourceId,
                      ),
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
                        sourceId: args.sourceId,
                        postId: args.postId,
                      )
                    : const _MissingRouteDataPage(),
              );
            },
          ),
        ],
      ),
    ],
  );

  static Future<T?> _openPost<T>(Post post) {
    return router.pushNamed<T>(
      AppRoute.postDetail.name,
      pathParameters: {'id': post.id},
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
