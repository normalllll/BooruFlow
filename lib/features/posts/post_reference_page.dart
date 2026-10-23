import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/app/stage_page.dart';
import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/posts/logic.dart';
import 'package:booruflow/features/posts/post_detail_page.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/src/rust/booru/error.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';

/// Restored downloads and deep links have a source/post reference, rather than
/// a retained feed snapshot. Resolve that reference through the detail cache.
class PostReferencePage extends ConsumerWidget {
  const PostReferencePage({
    required this.sourceId,
    required this.postId,
    super.key,
  });
  final String? sourceId;
  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourceId = this.sourceId;
    final knownSource = ref
        .watch(booruSourcesProvider)
        .any((s) => s.sourceId == sourceId);
    final key = (sourceId: sourceId ?? '', postId: postId);
    final detail =
        sourceId == null || sourceId.isEmpty || postId.isEmpty || !knownSource
        ? null
        : ref.watch(postAttributionDetailProvider(key));
    if (detail?.asData?.value case final post?) {
      return PostDetailPage(args: PostDetailRouteArgs(post: post));
    }
    final error = detail?.error;
    final cause = switch (error) {
      BooruReadableException(:final cause) => cause,
      BooruError value => value,
      _ => null,
    };
    final missing =
        detail == null || cause?.httpStatus == 404 || cause?.httpStatus == 410;
    final title = missing
        ? t.postDetail.notFound
        : t.postDetail.titleWithId(id: postId);
    final Widget body;
    if (missing) {
      body = FrostEmptyState(
        icon: appIcons.error,
        title: t.postDetail.notFound,
      );
    } else if (error != null) {
      body = FrostErrorContent(
        message: describeBooruError(error, includeDiagnostics: false),
        details: booruErrorDetails(error),
        onRetry: () => ref.invalidate(postAttributionDetailProvider(key)),
      );
    } else {
      // A reference has not supplied media geometry yet; reserve a square
      // stage and the same information row outline rather than a page spinner.
      body = FrostDetailLayout(
        stage: FrostMediaFrame.skeleton(aspectRatio: 1),
        primary: FrostListRow.skeleton(
          title: '#$postId',
          icon: false,
          subtitle: null,
          value: null,
        ),
      );
    }
    return FrostWindowTitleContribution(
      path: '/posts/$postId',
      page: FrostPageTitle(id: (sourceId, postId), title: title),
      child: StagePage(
        title: missing ? '' : title,
        onBack: () => Navigator.of(context).maybePop(),
        child: body,
      ),
    );
  }
}
