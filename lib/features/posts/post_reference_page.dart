import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/posts/logic.dart';
import 'package:booruflow/features/posts/post_detail_page.dart';
import 'package:booruflow/features/posts/widgets/post_detail_layout.dart';
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
    Widget Function(bool stacked) stage;
    final Widget primary;
    if (missing) {
      stage = (stacked) => _BelowHeader(
        stacked: stacked,
        child: FrostEmptyState(
          icon: appIcons.error,
          title: t.postDetail.notFound,
        ),
      );
      primary = _ReferenceTitle(postId);
    } else if (error != null) {
      stage = (stacked) => _BelowHeader(
        stacked: stacked,
        child: FrostErrorContent(
          message: describeBooruError(error, includeDiagnostics: false),
          details: booruErrorDetails(error),
          onRetry: () => ref.invalidate(postAttributionDetailProvider(key)),
        ),
      );
      primary = _ReferenceTitle(postId);
    } else {
      // A reference has not supplied media geometry yet; reserve a square
      // stage and the same information row outline rather than a page spinner.
      stage = (stacked) => FrostMediaFrame.skeleton(
        aspectRatio: 1,
        radius: postStageRadius(stacked: stacked),
      );
      primary = FrostListRow.skeleton(
        title: '#$postId',
        icon: false,
        subtitle: null,
        value: null,
      );
    }
    return FrostWindowTitleContribution(
      path: '/posts/$postId',
      page: FrostPageTitle(id: (sourceId, postId), title: title),
      child: LayoutBuilder(
        builder: (context, box) {
          final stacked = postDetailStacked(context, box.biggest);
          final information = PostInformationSliver(primary: primary);
          return Stack(
            key: const ValueKey('post-detail-layout'),
            fit: StackFit.expand,
            children: [
              const PostDetailBackdrop(image: null),
              if (stacked) ...[
                PostStackedScroll(
                  stage: stage(stacked),
                  information: information,
                ),
                // Narrow media is edge to edge and carries Back.
                const PostMediaHeader(pastStage: AlwaysStoppedAnimation(false)),
              ] else
                PostWideLayout(stage: stage(stacked), information: information),
            ],
          );
        },
      ),
    );
  }
}

class _ReferenceTitle extends StatelessWidget {
  const _ReferenceTitle(this.postId);
  final String postId;
  @override
  Widget build(BuildContext context) => FrostText(
    '#$postId',
    role: FrostTextRole.title2,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}

/// A message in a stacked stage sits below the header that overlays it and
/// inside the safe areas, which edge-to-edge media does not use.
class _BelowHeader extends StatelessWidget {
  const _BelowHeader({required this.stacked, required this.child});
  final bool stacked;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (!stacked) return child;
    final inset = MediaQuery.paddingOf(context);
    return Padding(
      padding: inset.copyWith(top: inset.top + FrostPageHeader.verticalHeight),
      child: child,
    );
  }
}
