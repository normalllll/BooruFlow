import 'package:booruflow/core/app_runtime.dart';
import 'package:booruflow/core/settings/logic.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/ui/custom/download_flight.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';

// App-specific shell widths; all item geometry remains owned by FrostShell.
const _navigationMetrics = FrostNavigationMetrics(
  railWidth: 56,
  expandedWidth: 220,
  expandableMinWidth: 900,
  mobileMaxWidth: 600,
);

class AppShell extends ConsumerWidget {
  const AppShell({
    required this.selectedIndex,
    required this.atDestinationRoot,
    required this.onBack,
    required this.onDestinationSelected,
    required this.onResetRightNavigator,
    required this.child,
    super.key,
  });
  final int? selectedIndex;
  final bool atDestinationRoot;
  final VoidCallback onBack, onResetRightNavigator;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final activity = ref.watch(downloadActivityProvider);
    return FrostShell(
      destinations: [
        for (final destination in appDestinations)
          FrostNavDestination(
            label: appDestinationLabel(destination),
            builder: destination.route == AppRoute.downloads
                ? (context, child) => DownloadFlightTarget(child: child)
                : null,
            icon: destination.icon,
            badge: destination.route == AppRoute.downloads ? activity.count : 0,
            progress: destination.route == AppRoute.downloads
                ? activity.progress
                : null,
          ),
      ],
      selectedIndex: selectedIndex,
      atDestinationRoot: atDestinationRoot,
      onDestinationSelected: (index) {
        onResetRightNavigator();
        onDestinationSelected(index);
      },
      canGoBack: !atDestinationRoot,
      onBack: onBack,
      showsMobileNavigation: true,
      sidebarStyle: const FrostSidebarStyle.inset(),
      metrics: _navigationMetrics,
      initiallyExpanded: settings.sidebarExpanded,
      onExpandedChanged: ref.read(settingsProvider.notifier).setSidebarExpanded,
      brand: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/app-icon.png',
            width: FrostControlSize.regular.iconSize,
            height: FrostControlSize.regular.iconSize,
            excludeFromSemantics: true,
          ),
          const SizedBox(width: FrostGap.related),
          const Flexible(
            child: FrostText(
              AppInfo.name,
              role: FrostTextRole.callout,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      child: child,
    );
  }
}
