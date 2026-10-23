import 'dart:convert';
import 'package:booruflow/app/icons.g.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/stage_image_presentation.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

enum AppRoute {
  posts('/'),
  search('/search'),
  about('/about'),
  downloads('/downloads'),
  settings('/settings'),
  settingsSection('/settings/:section'),
  userTags('/settings/custom-tags'),
  taggedPosts('/search/posts'),
  searchEditor('/search/edit'),
  postDetail('/posts/:id'),
  imageViewer('/image-viewer');

  const AppRoute(this.path);

  final String path;
}

class AppDestination {
  const AppDestination({required this.route, required this.icon});
  final AppRoute route;
  final FrostIconData icon;
}

const appDestinations = <AppDestination>[
  AppDestination(
    route: AppRoute.posts,
    icon: FrostIconData.glyph(BooruFlowIcons.compass),
  ),
  AppDestination(
    route: AppRoute.search,
    icon: FrostIconData.glyph(BooruFlowIcons.search),
  ),
  AppDestination(
    route: AppRoute.downloads,
    icon: FrostIconData.glyph(BooruFlowIcons.download),
  ),
  AppDestination(
    route: AppRoute.settings,
    icon: FrostIconData.glyph(BooruFlowIcons.settings),
  ),
];

String appDestinationLabel(AppDestination destination) =>
    switch (destination.route) {
      AppRoute.posts => t.navigation.browse,
      AppRoute.search => t.navigation.search,
      AppRoute.downloads => t.navigation.downloads,
      AppRoute.settings => t.navigation.settings,
      _ => '',
    };

int? appDestinationIndexForPath(String path) {
  for (var index = 0; index < appDestinations.length; index++) {
    if (appDestinations[index].route.path == path) return index;
  }
  if (path.startsWith('/posts/')) return 0;
  if (path == AppRoute.userTags.path) return 1;
  if (path.startsWith('${AppRoute.search.path}/')) return 1;
  if (path.startsWith('${AppRoute.downloads.path}/')) return 2;
  if (path == AppRoute.about.path ||
      path.startsWith('${AppRoute.settings.path}/')) {
    return appDestinations.indexWhere(
      (destination) => destination.route == AppRoute.settings,
    );
  }
  return null;
}

bool isPrimaryNavigationPath(String path) {
  return appDestinations.any((destination) => destination.route.path == path);
}

/// One opened card occurrence and a snapshot of the collection it came from.
class PostDetailRouteArgs {
  PostDetailRouteArgs({
    required Post post,
    List<Post>? collection,
    this.initialIndex = 0,
    this.heroTag,
    this.preview,
  }) : collection = List.unmodifiable(collection ?? [post]) {
    assert(initialIndex >= 0 && initialIndex < this.collection.length);
    assert(this.collection[initialIndex].postKey == post.postKey);
  }
  final List<Post> collection;
  final int initialIndex;
  final FrostMediaHeroTag? heroTag;
  final ImageProvider? preview;
  Post get post => collection[initialIndex];
}

class ImageViewerRouteArgs {
  ImageViewerRouteArgs({
    required List<Post> collection,
    required this.initialIndex,
    this.preview,
    this.presentation,
    this.onIndexChanged,
    this.videoPosition,
    this.videoMuted = false,
  }) : collection = List.unmodifiable(collection) {
    assert(collection.isNotEmpty);
    assert(initialIndex >= 0 && initialIndex < collection.length);
  }
  final List<Post> collection;
  final int initialIndex;
  final ImageProvider? preview;
  final StageImagePresentation? presentation;
  final ValueChanged<int>? onIndexChanged;
  final Duration? videoPosition;
  final bool videoMuted;
}

class SearchQuery {
  SearchQuery({required this.sourceId, required Iterable<String> tags})
    : tags = List.unmodifiable(tags);
  final String sourceId;
  final List<String> tags;
}

extension AppNavigation on BuildContext {
  Future<SearchQuery?> editSearch(
    List<String> tags, {
    required String sourceId,
    bool autofocus = true,
  }) => pushNamed<SearchQuery>(
    AppRoute.searchEditor.name,
    queryParameters: {
      'source': sourceId,
      'tags': jsonEncode(tags),
      if (!autofocus) 'focus': 'false',
    },
  );

  Future<T?> pushUserTags<T>({String? sourceId}) => pushNamed<T>(
    AppRoute.userTags.name,
    queryParameters: {'source': ?sourceId},
  );

  Future<T?> pushPost<T>(
    Post post, {
    List<Post>? collection,
    int initialIndex = 0,
    FrostMediaHeroTag? heroTag,
    ImageProvider? preview,
  }) => pushNamed<T>(
    AppRoute.postDetail.name,
    pathParameters: {'id': post.id},
    queryParameters: {'source': post.sourceId},
    extra: PostDetailRouteArgs(
      post: post,
      collection: collection,
      initialIndex: initialIndex,
      heroTag: heroTag,
      preview: preview,
    ),
  );

  Future<T?> pushTaggedPosts<T>(List<String> tags, {required String sourceId}) {
    return pushNamed<T>(
      AppRoute.taggedPosts.name,
      queryParameters: {'tags': jsonEncode(tags), 'source': sourceId},
    );
  }

  void replaceTaggedPosts(List<String> tags, {required String sourceId}) {
    replaceNamed(
      AppRoute.taggedPosts.name,
      queryParameters: {'tags': jsonEncode(tags), 'source': sourceId},
    );
  }

  Future<T?> pushSearch<T>({required String sourceId}) =>
      pushNamed<T>(AppRoute.search.name, queryParameters: {'source': sourceId});

  Future<T?> pushImageViewer<T>(ImageViewerRouteArgs args) =>
      pushNamed<T>(AppRoute.imageViewer.name, extra: args);
}
