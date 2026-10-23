import 'dart:convert';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/downloads/downloads_page.dart';
import 'package:booruflow/features/home/home_page.dart';
import 'package:booruflow/features/image_viewer/image_zoom_page.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/post_detail_page.dart';
import 'package:booruflow/features/posts/post_list_page.dart';
import 'package:booruflow/features/posts/post_reference_page.dart';
import 'package:booruflow/features/search/post_search_page.dart';
import 'package:booruflow/features/search/user_tags_page.dart';
import 'package:booruflow/features/settings/settings_page.dart';
import 'package:booruflow/features/shell/app_shell.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';
import 'frost_config.dart';
import 'media_viewer_page.dart';
import 'stage_page.dart';

class AppRouter {
  const AppRouter._();

  static final rootNavigatorKey = GlobalKey<NavigatorState>();
  static final rightNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoute.posts.path,
    routes: [
      ShellRoute(
        navigatorKey: rightNavigatorKey,
        builder: (context, state, child) {
          return AppShell(
            selectedIndex: appDestinationIndexForPath(
              state.extra is _ContentPageArgs
                  ? (state.extra as _ContentPageArgs).parentPath
                  : state.uri.path,
            ),
            atDestinationRoot: isPrimaryNavigationPath(state.uri.path),
            onBack: popRightNavigator,
            onDestinationSelected: (index) =>
                router.go(appDestinations[index].route.path),
            onResetRightNavigator: popRightNavigatorToRoot,
            child: child,
          );
        },
        routes: [
          StatefulShellRoute.indexedStack(
            // Destination branches are retained page infrastructure, not a
            // detail transition. Removing/reinstating them during a deep-link
            // return must not keep a second keyed shell in an outgoing route.
            pageBuilder: (context, state, navigationShell) {
              return NoTransitionPage<void>(
                key: state.pageKey,
                child: FrostShellDestination(child: navigationShell),
              );
            },
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoute.posts.path,
                    name: AppRoute.posts.name,
                    pageBuilder: (context, state) =>
                        _primaryPage(state, const HomePage()),
                    routes: [
                      GoRoute(
                        parentNavigatorKey: rightNavigatorKey,
                        path: 'content',
                        pageBuilder: (context, state) =>
                            _contentPage(state, switch (state.extra) {
                              _ContentPageArgs(:final child) => child,
                              _ => const _MissingRouteDataPage(),
                            }),
                      ),
                      GoRoute(
                        parentNavigatorKey: rightNavigatorKey,
                        path: 'posts/:id',
                        name: AppRoute.postDetail.name,
                        pageBuilder: (context, state) {
                          final post = state.extra;
                          return _mediaPage(state, switch (post) {
                            PostDetailRouteArgs() => PostDetailPage(args: post),
                            Post() => PostDetailPage(
                              args: PostDetailRouteArgs(post: post),
                            ),
                            _ => PostReferencePage(
                              sourceId: state.uri.queryParameters['source'],
                              postId: state.pathParameters['id']!,
                            ),
                          });
                        },
                      ),
                    ],
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
                    routes: [
                      GoRoute(
                        parentNavigatorKey: rightNavigatorKey,
                        path: 'posts',
                        name: AppRoute.taggedPosts.name,
                        pageBuilder: (context, state) {
                          final sourceId =
                              state.uri.queryParameters['source'] ??
                              BooruService.instance.selectedSourceId;
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
                              tags = parseQueryInput(
                                state.uri.queryParameters['q'] ?? '',
                              );
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
                        parentNavigatorKey: rightNavigatorKey,
                        path: 'edit',
                        name: AppRoute.searchEditor.name,
                        pageBuilder: (context, state) {
                          final source = state.uri.queryParameters['source'];
                          var tags = <String>[];
                          var valid = BooruService.instance.sources.any(
                            (item) => item.sourceId == source,
                          );
                          try {
                            tags =
                                (jsonDecode(
                                          state.uri.queryParameters['tags'] ??
                                              '[]',
                                        )
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
                              autofocus:
                                  state.uri.queryParameters['focus'] != 'false',
                              invalidQuery: !valid,
                              onSubmit: (source, tags) => context.pop(
                                SearchQuery(sourceId: source, tags: tags),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoute.downloads.path,
                    name: AppRoute.downloads.name,
                    pageBuilder: (context, state) => _primaryPage(
                      state,
                      DownloadsPage(
                        taskId: state.uri.queryParameters['task'],
                        revealRequest: state.uri.queryParameters['reveal'],
                      ),
                    ),
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
                    routes: [
                      GoRoute(
                        parentNavigatorKey: rightNavigatorKey,
                        path: 'custom-tags',
                        name: AppRoute.userTags.name,
                        pageBuilder: (context, state) => _contentPage(
                          state,
                          UserTagsPage(
                            sourceId: state.uri.queryParameters['source'],
                          ),
                        ),
                      ),
                      GoRoute(
                        parentNavigatorKey: rightNavigatorKey,
                        path: ':section',
                        name: AppRoute.settingsSection.name,
                        pageBuilder: (context, state) {
                          final section = SettingsSection.fromPath(
                            state.pathParameters['section'],
                          );
                          return _contentPage(state, switch (section) {
                            null => const _MissingRouteDataPage(),
                            _ => SettingsPage(
                              section: section,
                              sourceId: state.uri.queryParameters['source'],
                            ),
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoute.about.path,
            name: AppRoute.about.name,
            redirect: (_, _) => '/settings/about',
          ),
        ],
      ),
      GoRoute(
        path: AppRoute.imageViewer.path,
        name: AppRoute.imageViewer.name,
        pageBuilder: (context, state) {
          final args = state.extra;
          return MediaViewerPage(
            key: state.pageKey,
            child: switch (args) {
              ImageViewerRouteArgs() => ImageZoomPage(args: args),
              _ => const _MissingRouteDataPage(),
            },
          );
        },
      ),
    ],
  );

  // The delegate has no matches until initial parsing completes. Thereafter
  // its state includes imperative pushes, unlike the route-information URI.
  static Uri get currentUri =>
      router.routerDelegate.currentConfiguration.isEmpty
      ? router.routeInformationProvider.value.uri
      : router.state.uri;

  /// Secondary content shares the declarative route state and retained shell.
  /// Unlike a raw Navigator push, this immediately updates Back and root nav.
  static Future<T?> pushContent<T>(BuildContext context, Widget child) =>
      router.push<T>(
        '/content',
        extra: _ContentPageArgs(child: child, parentPath: currentUri.path),
      );

  static void popRightNavigator() {
    if (router.canPop()) {
      router.pop();
    } else {
      // A deep-linked secondary page still has a logical destination parent.
      final destination = appDestinationIndexForPath(currentUri.path) ?? 0;
      router.go(appDestinations[destination].route.path);
    }
  }

  static void popRightNavigatorToRoot() {
    rightNavigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  static Page<void> _primaryPage(GoRouterState state, Widget child) {
    return NoTransitionPage<void>(key: state.pageKey, child: child);
  }

  static Page<void> _mediaPage(GoRouterState state, Widget child) =>
      FrostDetailPage<void>.media(key: state.pageKey, child: child);

  static Page<void> _contentPage(
    GoRouterState state,
    Widget child, {
    bool opaque = true,
  }) {
    return FrostDetailPage<void>(
      key: state.pageKey,
      opaque: opaque,
      child: child,
    );
  }
}

class _MissingRouteDataPage extends StatelessWidget {
  const _MissingRouteDataPage();

  @override
  Widget build(BuildContext context) {
    return StagePage(
      title: t.generic.notFound,
      child: FrostEmptyState(icon: appIcons.error, title: t.generic.notFound),
    );
  }
}

class _ContentPageArgs {
  const _ContentPageArgs({required this.child, required this.parentPath});
  final Widget child;
  final String parentPath;
}
