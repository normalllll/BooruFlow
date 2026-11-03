import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/browse/browse_page.dart';
import 'package:booruflow/features/browse/results_page.dart';
import 'package:booruflow/features/downloads/downloads_page.dart';
import 'package:booruflow/features/image_viewer/image_zoom_page.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/post_detail_page.dart';
import 'package:booruflow/features/posts/post_reference_page.dart';
import 'package:booruflow/features/settings/settings_page.dart';
import 'package:booruflow/features/shell/app_shell.dart';
import 'package:booruflow/features/tags/common_tags_page.dart';
import 'package:booruflow/features/tags/my_tags_page.dart';
import 'package:booruflow/features/tags/tags_page.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

import 'media_viewer_page.dart';
import 'not_found_page.dart';

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
            selectedIndex: destinationIndexFor(state.uri.path),
            atDestinationRoot: isPrimaryNavigationPath(state.uri.path),
            routeDepth: rightNavigatorDepth,
            location: state.uri,
            onBack: popRightNavigator,
            onBackToFirst: popRightNavigatorToRoot,
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
                        _primaryPage(state, const BrowsePage()),
                    routes: [
                      GoRoute(
                        parentNavigatorKey: rightNavigatorKey,
                        path: 'content',
                        pageBuilder: (context, state) =>
                            _contentPage(state, switch (state.extra) {
                              _ContentPageArgs(:final child) => child,
                              _ => const NotFoundPage(),
                            }),
                      ),
                      // Downloads is the shell's task entry, not a destination:
                      // a content page any destination pushes, and a deep link
                      // to it has Browse below.
                      GoRoute(
                        parentNavigatorKey: rightNavigatorKey,
                        path: 'downloads',
                        name: AppRoute.downloads.name,
                        pageBuilder: (context, state) => _contentPage(
                          state,
                          DownloadsPage(
                            taskId: state.uri.queryParameters['task'],
                            revealRequest: state.uri.queryParameters['reveal'],
                          ),
                        ),
                      ),
                      GoRoute(
                        parentNavigatorKey: rightNavigatorKey,
                        path: 'results',
                        name: AppRoute.results.name,
                        redirect: (context, state) {
                          final query = ResultsQuery.parse(state.uri);
                          return query.valid && query.tags.isEmpty
                              ? AppRoute.tags.path
                              : null;
                        },
                        pageBuilder: (context, state) {
                          final query = ResultsQuery.parse(state.uri);
                          return _contentPage(
                            state,
                            query.valid
                                ? ResultsPage(
                                    tags: query.tags,
                                    sourceId: query.sourceId,
                                  )
                                : const TagsPage(invalidQuery: true),
                          );
                        },
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
                    path: AppRoute.tags.path,
                    name: AppRoute.tags.name,
                    pageBuilder: (context, state) =>
                        _primaryPage(state, const TagsPage()),
                    routes: [
                      GoRoute(
                        parentNavigatorKey: rightNavigatorKey,
                        path: 'mine',
                        name: AppRoute.userTags.name,
                        pageBuilder: (context, state) => _contentPage(
                          state,
                          MyTagsPage(
                            sourceId: state.uri.queryParameters['source'],
                          ),
                        ),
                      ),
                      GoRoute(
                        parentNavigatorKey: rightNavigatorKey,
                        path: 'common',
                        name: AppRoute.commonTags.name,
                        pageBuilder: (context, state) => _contentPage(
                          state,
                          AllCommonTagsPage(
                            sourceId:
                                state.uri.queryParameters['source'] ??
                                BooruService.instance.selectedSourceId,
                          ),
                        ),
                      ),
                    ],
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
                        path: ':section',
                        name: AppRoute.settingsSection.name,
                        pageBuilder: (context, state) {
                          final section = SettingsSection.fromPath(
                            state.pathParameters['section'],
                          );
                          return _contentPage(state, switch (section) {
                            null => const NotFoundPage(),
                            _ => SettingsPage(section: section),
                          });
                        },
                        routes: [
                          GoRoute(
                            parentNavigatorKey: rightNavigatorKey,
                            path: ':source',
                            name: AppRoute.settingsSource.name,
                            pageBuilder: (context, state) => _contentPage(
                              state,
                              state.pathParameters['section'] ==
                                      SettingsSection.sources.pathSegment
                                  ? SettingsPage(
                                      section: SettingsSection.sources,
                                      sourceId: state.pathParameters['source'],
                                    )
                                  : const NotFoundPage(),
                            ),
                          ),
                        ],
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
              _ => const NotFoundPage(),
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

  /// The destination that opened the content pages above a destination's root
  /// page. Pages any destination can open (a post, a result list) keep the
  /// highlight of the destination they were opened from.
  static int? _opener;

  /// The destination to highlight for [path].
  static int? destinationIndexFor(String path) {
    final byPath = appDestinationIndexForPath(path);
    if (byPath == null) return _opener ?? 0;
    if (isPrimaryNavigationPath(path)) _opener = byPath;
    return byPath;
  }

  /// How many pages the right navigator holds above the destination's root.
  static int get rightNavigatorDepth {
    for (final match in router.routerDelegate.currentConfiguration.matches) {
      if (match is ShellRouteMatch && match.navigatorKey == rightNavigatorKey) {
        return match.matches.length - 1;
      }
    }
    return 0;
  }

  /// Secondary content shares the declarative route state and retained shell.
  /// Unlike a raw Navigator push, this immediately updates Back and root nav.
  static Future<T?> pushContent<T>(BuildContext context, Widget child) =>
      router.push<T>('/content', extra: _ContentPageArgs(child));

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

class _ContentPageArgs {
  const _ContentPageArgs(this.child);
  final Widget child;
}
