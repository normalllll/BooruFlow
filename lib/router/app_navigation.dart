import 'package:flutter/material.dart';
import 'package:yande_gui/intl/translations.g.dart';

enum AppRoute {
  posts('/'),
  search('/search'),
  about('/about'),
  settings('/settings'),
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
  return null;
}

bool isPrimaryNavigationPath(String path) {
  return appDestinationIndexForPath(path) != null;
}
