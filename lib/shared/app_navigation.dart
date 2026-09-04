import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/features/posts/models/post.dart';

enum AppRoute {
  posts('/'),
  search('/search'),
  about('/about'),
  settings('/settings'),
  settingsSection('/settings/:section'),
  taggedPosts('/search/posts'),
  postDetail('/posts/:id'),
  imageViewer('/image-viewer');

  const AppRoute(this.path);

  final String path;
}

class AppDestination {
  const AppDestination({
    required this.route,
    required this.icon,
    required this.selectedIcon,
  });

  final AppRoute route;
  final IconData icon;
  final IconData selectedIcon;
}

const appDestinations = <AppDestination>[
  AppDestination(
    route: AppRoute.posts,
    icon: Icons.list_alt_outlined,
    selectedIcon: Icons.list_alt,
  ),
  AppDestination(
    route: AppRoute.search,
    icon: Icons.search_outlined,
    selectedIcon: Icons.search,
  ),
  AppDestination(
    route: AppRoute.about,
    icon: Icons.info_outline,
    selectedIcon: Icons.info,
  ),
  AppDestination(
    route: AppRoute.settings,
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
  ),
];

String appDestinationLabel(AppDestination destination) {
  return switch (destination.route) {
    AppRoute.posts => t.postList.short,
    AppRoute.search => t.postSearch.title,
    AppRoute.about => t.about.title,
    AppRoute.settings => t.settings.title,
    _ => '',
  };
}

int? appDestinationIndexForPath(String path) {
  for (var index = 0; index < appDestinations.length; index++) {
    if (appDestinations[index].route.path == path) return index;
  }
  if (path.startsWith('${AppRoute.settings.path}/')) {
    return appDestinations.indexWhere(
      (destination) => destination.route == AppRoute.settings,
    );
  }
  return null;
}

bool isPrimaryNavigationPath(String path) {
  return appDestinations.any((destination) => destination.route.path == path);
}

class ImageViewerRouteArgs {
  const ImageViewerRouteArgs({
    required this.url,
    required this.width,
    required this.height,
    required this.sourceId,
    required this.postId,
  });

  final String url;
  final double width;
  final double height;
  final String sourceId;
  final String postId;
}

extension AppNavigation on BuildContext {
  Future<T?> pushPost<T>(Post post) {
    return pushNamed<T>(
      AppRoute.postDetail.name,
      pathParameters: {'id': post.id},
      extra: post,
    );
  }

  Future<T?> pushTaggedPosts<T>(List<String> tags) {
    return pushNamed<T>(
      AppRoute.taggedPosts.name,
      queryParameters: {'q': tags.join(' ')},
    );
  }

  Future<T?> pushImageViewer<T>({
    required String url,
    required double width,
    required double height,
    required String sourceId,
    required String postId,
  }) {
    return pushNamed<T>(
      AppRoute.imageViewer.name,
      extra: ImageViewerRouteArgs(
        url: url,
        width: width,
        height: height,
        sourceId: sourceId,
        postId: postId,
      ),
    );
  }
}
