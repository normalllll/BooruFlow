import 'dart:async';

import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/core/media/image_clipboard.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import 'displayed_media_frame.dart';

/// Shared source-aware actions. Media bytes still pass through Rust's request,
/// authentication and cache path; the UI never fetches an upstream URL itself.
List<FrostMenuEntry> postMenuEntries({
  required BuildContext context,
  required Post post,
  required VoidCallback download,
}) {
  final labels = Translations.of(context);
  final webUrl = post.webUrl;
  // Upstream author is an uploader username, not necessarily the creator.
  // Artist search follows the source's canonical artist tag instead.
  final artist = post.data.tags
      .where((tag) => tag.category == TagCategory.artist)
      .firstOrNull
      ?.name;
  // Grid menus intentionally do not copy a thumbnail as a full artwork.
  // Detail and viewer copy the decoded pixels they actually present.
  Future<void> perform(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (context.mounted) {
        FrostToast.fromError(context, error);
      }
    }
  }

  return [
    FrostMenuAction(
      labels.postDetail.download,
      icon: appIcons.download,
      onSelected: download,
    ),
    FrostMenuAction(
      labels.discovery.copyLink,
      icon: appIcons.link,
      enabled: webUrl != null,
      onSelected: webUrl == null
          ? null
          : () => perform(() async {
              await Clipboard.setData(ClipboardData(text: webUrl));
              if (context.mounted) {
                FrostToast.copied(labels.verificationPage.linkCopied);
              }
            }),
    ),
    FrostMenuAction(
      labels.frost.openInBrowser,
      icon: appIcons.externalLink,
      enabled: webUrl != null,
      onSelected: webUrl == null
          ? null
          : () => perform(() async {
              if (!await launchUrl(
                Uri.parse(webUrl),
                mode: LaunchMode.externalApplication,
              )) {
                throw StateError(labels.generic.loadFailed);
              }
            }),
    ),
    const FrostMenuDivider(),
    FrostMenuAction(
      labels.discovery.searchAuthor,
      icon: appIcons.search,
      enabled: artist != null,
      onSelected: artist == null
          ? null
          : () => context.pushTaggedPosts([artist], sourceId: post.sourceId),
    ),
  ];
}

bool isPostWebUrl(String value) {
  final uri = Uri.tryParse(value);
  return uri != null &&
      const {'http', 'https'}.contains(uri.scheme) &&
      uri.host.isNotEmpty;
}

/// Prefer the Pixiv deep link, then use the shared external URL launcher.
Future<bool> openPostUrl(String url) async {
  var target = url;
  if (url.startsWith('https://i.pximg.net/')) {
    target =
        'https://www.pixiv.net/artworks/${url.split('/').last.split('_').first}';
  }
  Future<bool> open(String value) async {
    try {
      return await launchUrl(
        Uri.parse(value),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }

  final uri = Uri.tryParse(target);
  if (uri != null && const {'www.pixiv.net', 'pixiv.net'}.contains(uri.host)) {
    final parts = uri.pathSegments;
    if (parts.length >= 2) {
      final scheme = switch (parts.first) {
        'artworks' => 'pixiv://illusts/${parts[1]}',
        'users' => 'pixiv://users/${parts[1]}',
        _ => null,
      };
      if (scheme != null && await open(scheme)) return true;
    }
  }
  return open(target);
}

Future<void> performPostAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (error) {
    if (context.mounted) {
      FrostToast.fromError(context, error);
    }
  }
}

Future<void> copyPostValue(BuildContext context, String value) async {
  await Clipboard.setData(ClipboardData(text: value));
  if (context.mounted) {
    FrostToast.success(Translations.of(context).frost.copied);
  }
}

/// Both the detail and viewer copy the same click-time pixels. Slow copies
/// have an ordinary cancellable progress dialog; fast copies need no modal.
Future<void> copyDisplayedPostImage(
  BuildContext context,
  DisplayedMediaFrame frame,
  String identity, {
  required ImageClipboard clipboard,
}) async {
  var finished = false;
  BuildContext? progressContext;
  final pending = Timer(const Duration(milliseconds: 300), () {
    if (!context.mounted || finished) return;
    unawaited(
      showFrostDialog<void>(
        context: context,
        builder: (context) {
          progressContext = context;
          return FrostDialog(
            title: t.discovery.copyImage,
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FrostActivityIndicator(semanticLabel: t.generic.loading),
                const SizedBox(width: FrostGap.related),
                FrostText(t.generic.loading),
              ],
            ),
            actions: [
              FrostDialogAction(
                label: t.frost.cancel,
                role: FrostButtonRole.cancel,
                onPressed: () {
                  frame.cancelCopy();
                  return true;
                },
              ),
            ],
          );
        },
      ).then((_) {
        if (!finished) frame.cancelCopy();
      }),
    );
  });
  try {
    final copied = await frame.copy(identity, write: clipboard.write);
    if (copied && context.mounted) FrostToast.copied(t.frost.copied);
  } finally {
    finished = true;
    pending.cancel();
    final dialog = progressContext;
    if (dialog != null && dialog.mounted) {
      final route = ModalRoute.of(dialog)!;
      if (route.isCurrent) {
        Navigator.of(dialog).pop();
      } else if (route.isActive) {
        route.navigator?.removeRoute(route);
      }
    }
  }
}
