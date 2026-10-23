import 'package:booruflow/app/icons.g.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:flutter/widgets.dart';

import 'package:frost_ui/frost_ui.dart';

import 'frost_config.dart';

/// Reads translations inside the mounted route, so language changes do not
/// depend on GoRouter recreating a cached Page.
class PrimaryStagePage extends StatelessWidget {
  const PrimaryStagePage({required this.destination, super.key});
  final AppRoute destination;
  @override
  Widget build(BuildContext context) {
    final labels = Translations.of(context).navigation;
    final (title, message, icon) = switch (destination) {
      AppRoute.posts => (labels.browse, labels.browseEmpty, appIcons.image),
      AppRoute.search => (labels.search, labels.searchEmpty, appIcons.search),
      AppRoute.downloads => (
        labels.downloads,
        labels.downloadsEmpty,
        appIcons.download,
      ),
      AppRoute.settings => (
        labels.settings,
        labels.settingsEmpty,
        const FrostIconData.glyph(BooruFlowIcons.settings),
      ),
      _ => throw ArgumentError.value(destination, 'destination'),
    };
    return FrostWindowTitleContribution(
      path: destination.path,
      page: FrostPageTitle(id: destination, title: title),
      child: StagePage(
        title: title,
        child: FrostEmptyState(icon: icon, title: message),
      ),
    );
  }
}

/// Shared fallback/loading page shell. Pinned chrome owns the system top/side
/// insets; SafeArea consumes its measured content budget and the gesture inset.
class StagePage extends StatelessWidget {
  const StagePage({
    required this.title,
    required this.child,
    this.onBack,
    super.key,
  });
  final String title;
  final Widget child;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) => FrostPinnedChrome(
    chrome: FrostPageHeader(
      title: FrostText(title, role: FrostTextRole.headline),
      onBack: onBack,
    ),
    body: SafeArea(child: child),
  );
}
