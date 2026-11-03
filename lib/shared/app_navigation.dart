import 'dart:async';
import 'dart:convert';
import 'package:booruflow/app/icons.g.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/stage_image_presentation.dart';
import 'package:booruflow/features/search/logic.dart';
import 'package:booruflow/features/search/query.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

enum AppRoute {
  posts('/'),
  tags('/tags'),
  about('/about'),
  downloads('/downloads'),
  settings('/settings'),
  settingsSection('/settings/:section'),
  settingsSource('/settings/sources/:source'),
  userTags('/tags/mine'),
  commonTags('/tags/common'),
  results('/results'),
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
    route: AppRoute.tags,
    icon: FrostIconData.glyph(BooruFlowIcons.tags),
  ),
  AppDestination(
    route: AppRoute.settings,
    icon: FrostIconData.glyph(BooruFlowIcons.settings),
  ),
];

String appDestinationLabel(AppDestination destination) =>
    switch (destination.route) {
      AppRoute.posts => t.navigation.browse,
      AppRoute.tags => t.navigation.tags,
      AppRoute.settings => t.navigation.settings,
      _ => '',
    };

/// The destination a location belongs to by its path alone. Null for pages
/// any destination can open (a post, a result list): those are highlighted by
/// the destination that opened them, see [AppRouter.destinationIndexFor].
int? appDestinationIndexForPath(String path) {
  for (var index = 0; index < appDestinations.length; index++) {
    if (appDestinations[index].route.path == path) return index;
  }
  if (path.startsWith('${AppRoute.tags.path}/')) return 1;
  if (path == AppRoute.about.path ||
      path.startsWith('${AppRoute.settings.path}/')) {
    return appDestinations.indexWhere(
      (destination) => destination.route == AppRoute.settings,
    );
  }
  return null;
}

/// The downloads page, opened on [taskId] when given. [reveal] tells a page
/// that is already open to reveal the task again.
String downloadsLocation({String? taskId, String? reveal}) => Uri(
  path: AppRoute.downloads.path,
  queryParameters: {'task': ?taskId, 'reveal': ?reveal},
).toString();

bool isPrimaryNavigationPath(String path) {
  return appDestinations.any((destination) => destination.route.path == path);
}

/// Pages the collection a detail or viewer was opened from, so paging goes on
/// past the items loaded when it opened.
class PostPaging {
  const PostPaging({required this.hasMore, required this.loadMore});

  /// Whether another page may exist.
  final bool Function() hasMore;

  /// Loads the next page and returns the whole list after it; throws when the
  /// load fails, and may be called again to retry.
  final Future<List<Post>> Function() loadMore;
}

/// One opened card occurrence and a snapshot of the collection it came from.
class PostDetailRouteArgs {
  PostDetailRouteArgs({
    required Post post,
    List<Post>? collection,
    this.initialIndex = 0,
    this.heroTag,
    this.preview,
    this.onIndexChanged,
    this.paging,
    this.query = const [],
  }) : collection = List.unmodifiable(collection ?? [post]) {
    assert(initialIndex >= 0 && initialIndex < this.collection.length);
    assert(this.collection[initialIndex].postKey == post.postKey);
  }
  final List<Post> collection;
  final int initialIndex;
  final FrostMediaHeroTag? heroTag;
  final ImageProvider? preview;

  /// Reports every collection position the detail page moves to, so the grid
  /// that opened it can follow. System back carries no result to return it.
  final ValueChanged<int>? onIndexChanged;
  final PostPaging? paging;

  /// The tags of the search this post was listed in, which tag actions refine.
  final List<String> query;
  Post get post => collection[initialIndex];
}

class ImageViewerRouteArgs {
  ImageViewerRouteArgs({
    required List<Post> collection,
    required this.initialIndex,
    this.preview,
    this.presentation,
    this.onIndexChanged,
    this.paging,
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
  final PostPaging? paging;
  final Duration? videoPosition;
  final bool videoMuted;
}

/// What a results location asks for. [valid] is false for an unknown source or
/// a tag list that cannot be read; [tags] is empty when it asks for nothing.
class ResultsQuery {
  const ResultsQuery({
    required this.sourceId,
    required this.tags,
    required this.valid,
  });
  final String sourceId;
  final List<String> tags;
  final bool valid;

  factory ResultsQuery.parse(Uri uri) {
    final sourceId =
        uri.queryParameters['source'] ?? BooruService.instance.selectedSourceId;
    var valid = BooruService.instance.sources.any(
      (source) => source.sourceId == sourceId,
    );
    var tags = <String>[];
    try {
      final encoded = uri.queryParameters['tags'];
      tags = encoded == null
          ? parseQueryInput(uri.queryParameters['q'] ?? '')
          : [
              for (final tag in (jsonDecode(encoded) as List).cast<String>())
                if (tag.trim().isNotEmpty) tag.trim(),
            ];
    } catch (_) {
      valid = false;
    }
    return ResultsQuery(
      sourceId: sourceId,
      tags: List.unmodifiable(tags),
      valid: valid,
    );
  }
}

extension AppNavigation on BuildContext {
  /// Puts [text] into the search box: the title bar's while it is in the title
  /// row, otherwise the Tags page's inline search, opened. From any other page
  /// of the inline layout it opens the results for [text] instead.
  void openSearch(String text, {required String sourceId}) {
    final container = ProviderScope.containerOf(this);
    if (container.read(booruSessionProvider).sourceId != sourceId) {
      container.read(booruSessionProvider.notifier).selectSource(sourceId);
    }
    final inline = !FrostShell.titleContentInCaptionOf(this);
    final router = GoRouter.of(this);
    // Away from the Tags page the post stays reachable: the results header
    // holds the editable query and Back returns to where it was added.
    if (inline && router.state.uri.path != AppRoute.tags.path) {
      unawaited(pushTaggedPosts([text], sourceId: sourceId));
      return;
    }
    container.read(pendingSearchProvider.notifier).request(text);
    if (inline) router.go(AppRoute.tags.path);
  }

  void goToTags() => GoRouter.of(this).go(AppRoute.tags.path);

  Future<T?> pushUserTags<T>({String? sourceId}) => pushNamed<T>(
    AppRoute.userTags.name,
    queryParameters: {'source': ?sourceId},
  );

  Future<T?> pushCommonTags<T>({required String sourceId}) => pushNamed<T>(
    AppRoute.commonTags.name,
    queryParameters: {'source': sourceId},
  );

  Future<T?> pushPost<T>(
    Post post, {
    List<Post>? collection,
    int initialIndex = 0,
    FrostMediaHeroTag? heroTag,
    ImageProvider? preview,
    ValueChanged<int>? onIndexChanged,
    PostPaging? paging,
    List<String> query = const [],
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
      onIndexChanged: onIndexChanged,
      paging: paging,
      query: query,
    ),
  );

  Future<T?> pushTaggedPosts<T>(List<String> tags, {required String sourceId}) {
    return pushNamed<T>(
      AppRoute.results.name,
      queryParameters: {'tags': jsonEncode(tags), 'source': sourceId},
    );
  }

  void replaceTaggedPosts(List<String> tags, {required String sourceId}) {
    replaceNamed(
      AppRoute.results.name,
      queryParameters: {'tags': jsonEncode(tags), 'source': sourceId},
    );
  }

  Future<T?> pushImageViewer<T>(ImageViewerRouteArgs args) =>
      pushNamed<T>(AppRoute.imageViewer.name, extra: args);
}
