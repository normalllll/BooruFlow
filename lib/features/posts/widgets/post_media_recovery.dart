import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/posts/media_presentation.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/post_actions.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/booru/error.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';
import 'rust_extended_network_image_provider.dart';

enum PostMediaRecoveryStyle { failure, unsupported, overlay, banner }

/// Recovery actions and error presentation, independent of image loading.
class PostMediaRecovery extends ConsumerWidget {
  const PostMediaRecovery({
    required this.post,
    required this.purpose,
    required this.style,
    required this.onRetry,
    this.error,
    this.retrying = false,
    this.onPlay,
    this.showsAuthenticationBadge = true,
    super.key,
  });
  final Post post;
  final PostMediaPurpose purpose;
  final PostMediaRecoveryStyle style;
  final Object? error;
  final bool retrying, showsAuthenticationBadge;
  final Future<void> Function() onRetry;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (style) {
    PostMediaRecoveryStyle.failure => _failure(context, ref, error!),
    PostMediaRecoveryStyle.unsupported => _unsupportedPlaceholder(context, ref),
    PostMediaRecoveryStyle.overlay => _overlay(context, ref),
    PostMediaRecoveryStyle.banner => _banner(),
  };
  Widget _recoveryControls(
    BuildContext context,
    WidgetRef ref,
    Object error, {
    bool labeled = false,
  }) {
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        if (labeled)
          FrostErrorActionButton(
            key: ValueKey(post.postKey),
            error: error,
            onResolved: onRetry,
            size: FrostControlSize.compact,
          )
        else
          FrostErrorActionButton.icon(
            key: ValueKey(post.postKey),
            error: error,
            onResolved: onRetry,
          ),
        if (labeled)
          FrostButton(
            label: t.generic.retry,
            icon: appIcons.refresh,
            size: FrostControlSize.compact,
            loading: retrying,
            onPressed: onRetry,
          )
        else
          FrostButton.icon(
            icon: appIcons.refresh,
            label: t.generic.retry,
            loading: retrying,
            onPressed: onRetry,
          ),
        if (labeled)
          FrostButton(
            label: t.mediaError.details,
            variant: FrostButtonVariant.plain,
            size: FrostControlSize.compact,
            onPressed: () => _showError(context, error),
          )
        else
          FrostButton.icon(
            icon: appIcons.info,
            label: t.mediaError.details,
            onPressed: () => _showError(context, error),
          ),
      ],
    );
  }

  Future<void> _showError(BuildContext context, Object error) =>
      showFrostDialog<void>(
        context: context,
        builder: (_) => FrostDialog(
          title: t.mediaError.title,
          showsCloseButton: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FrostText(describeBooruError(error, includeDiagnostics: false)),
              const SizedBox(height: FrostGap.group),
              FrostErrorDetails(
                details: booruErrorDetails(error) ?? error.toString(),
              ),
            ],
          ),
        ),
      );

  Widget _failure(BuildContext context, WidgetRef ref, Object error) {
    final cause = switch (error) {
      MediaImageException(:final cause) => cause,
      _ => error,
    };
    final authentication = postMediaRequiresAuthentication(cause);
    return ColoredBox(
      color: FrostThemeTokens.of(context).fillSubtle,
      child: Stack(
        children: [
          if (authentication && showsAuthenticationBadge)
            Align(
              alignment: AlignmentDirectional.topStart,
              child: FrostBadge(
                label: t.booruError.authenticationRequired,
                tone: FrostBadgeTone.onMedia,
                icon: appIcons.user,
              ),
            ),
          Center(child: _recoveryControls(context, ref, error)),
        ],
      ),
    );
  }

  Widget _unsupportedPlaceholder(BuildContext context, WidgetRef ref) =>
      LayoutBuilder(
        builder: (context, constraints) {
          final tiny =
              constraints.maxHeight <
              FrostControlSize.large.height(context) + FrostGap.section;
          return Center(
            child: FrostSurface(
              role: FrostSurfaceRole.module,
              borderRadius: FrostRadius.borderRadius(FrostRadius.lg),
              child: Padding(
                padding: const EdgeInsets.all(FrostGap.related),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FrostIcon(appIcons.imageError),
                    if (onPlay case final play?)
                      FrostButton.icon(
                        icon: appIcons.play,
                        label: t.frost.play,
                        style: FrostIconButtonStyle.onMedia,
                        onPressed: play,
                      ),
                    if (!tiny) ...[
                      const SizedBox(height: FrostGap.related),
                      FrostText(
                        t.mediaError.previewUnsupported,
                        role: FrostTextRole.footnote,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (purpose != PostMediaPurpose.thumbnail) ...[
                      const SizedBox(height: FrostGap.related),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: FrostGap.related,
                        runSpacing: FrostGap.inline,
                        children: [
                          FrostButton(
                            label: t.frost.openInBrowser,
                            icon: appIcons.externalLink,
                            size: FrostControlSize.compact,
                            onPressed: () =>
                                openPostMediaInBrowser(context, post),
                          ),
                          FrostButton(
                            label: t.mediaError.downloadOriginal,
                            icon: appIcons.download,
                            size: FrostControlSize.compact,
                            onPressed: () =>
                                ref.read(booruDownloadsProvider).add(post),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      );

  Widget _overlay(BuildContext context, WidgetRef ref) => Align(
    alignment: Alignment.center,
    child: Padding(
      padding: const EdgeInsets.all(FrostGap.related),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: SizedBox(
          width: double.infinity,
          child: FrostSurface(
            role: FrostSurfaceRole.onMediaChrome,
            borderRadius: FrostRadius.borderRadius(FrostRadius.lg),
            child: Padding(
              padding: const EdgeInsets.all(FrostGap.group + FrostGap.related),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FrostIcon(
                    appIcons.imageError,
                    size: FrostControlSize.large.iconSize,
                  ),
                  const SizedBox(height: FrostGap.related),
                  FrostText(
                    t.postDetail.originalFailed,
                    role: FrostTextRole.headline,
                  ),
                  const SizedBox(height: FrostGap.inline),
                  FrostText(
                    t.postDetail.previewShown,
                    role: FrostTextRole.footnote,
                    tone: FrostTextTone.secondary,
                  ),
                  const SizedBox(height: FrostGap.group),
                  _recoveryControls(context, ref, error!, labeled: true),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  Widget _banner() => Align(
    alignment: Alignment.bottomCenter,
    child: Padding(
      padding: const EdgeInsets.all(FrostGap.related),
      child: FrostInlineBanner(
        tone: FrostBannerTone.negative,
        message: t.postDetail.originalFailed,
        actionLabel: t.generic.retry,
        onAction: onRetry,
      ),
    ),
  );
}

// Both URL preparation and decoded-image failures retain the engine error.
bool postMediaRequiresAuthentication(Object error) {
  final cause = switch (error) {
    MediaImageException(:final cause) => cause,
    _ => error,
  };
  final underlying = switch (cause) {
    BooruReadableException(:final cause) => cause,
    _ => cause,
  };
  return underlying is BooruError &&
      underlying.code == BooruErrorCode.authenticationRequired;
}

Future<void> openPostMediaInBrowser(BuildContext context, Post post) =>
    performPostAction(context, () async {
      if (!await openPostUrl(post.webUrl ?? post.originalMedia.url)) {
        throw StateError(t.generic.loadFailed);
      }
    });
