import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:go_router/go_router.dart';
import 'package:yande_gui/global.dart';
import 'package:yande_gui/i18n.dart';
import 'package:yande_gui/router/app_navigation.dart';
import 'package:yande_gui/services/dns_service.dart';
import 'package:yande_gui/services/settings_service.dart';
import 'package:yande_gui/services/updater_service.dart';
import 'package:yande_gui/src/rust/api/yande_client.dart';
import 'package:yande_gui/themes.dart';
import 'package:yande_gui/widgets/auto_scaffold/auto_scaffold.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({
    required this.selectedIndex,
    required this.showMobileNavigation,
    required this.canPopListenable,
    required this.onBack,
    required this.onResetRightNavigator,
    required this.child,
    super.key,
  });

  final int? selectedIndex;
  final bool showMobileNavigation;
  final ValueListenable<bool> canPopListenable;
  final VoidCallback onBack;
  final VoidCallback onResetRightNavigator;
  final Widget child;

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  bool _initialized = !SettingsService.prefetchDns;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration.zero, _initialize);
  }

  Future<void> _initialize() async {
    if (!_initialized) {
      YandeClient instance;
      try {
        final dns = await DnsService.fetchDns();
        realIps = dns;
        instance = YandeClient(
          ips: dns != null ? StringArray3(dns) : null,
          forLargeFile: false,
        );
      } catch (_) {
        instance = YandeClient(ips: null, forLargeFile: false);
      }

      setYandeClient(instance);
      if (!mounted) return;
      setState(() => _initialized = true);
    }

    try {
      final result = await UpdaterService.checkForUpdate();
      if (result != null) {
        EasyLoading.showToast(
          i18n.update.newVersionFound(version: result.$1),
          toastPosition: EasyLoadingToastPosition.bottom,
          duration: const Duration(seconds: 6),
        );
      }
    } catch (_) {
      EasyLoading.showToast(i18n.update.checkUpdateFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing...'),
            ],
          ),
        ),
      );
    }

    final useDesktopShell = shouldUseDesktopShell(context);

    return Scaffold(
      body: Row(
        children: [
          if (useDesktopShell)
            _DesktopSidebar(
              destinations: appDestinations,
              selectedIndex: widget.selectedIndex,
              canPopListenable: widget.canPopListenable,
              onBack: widget.onBack,
              onDestinationSelected: _selectDestination,
            ),
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: !useDesktopShell && widget.showMobileNavigation
          ? _MobileNavigationBar(
              destinations: appDestinations,
              selectedIndex: widget.selectedIndex ?? 0,
              onDestinationSelected: _selectDestination,
            )
          : null,
    );
  }

  void _selectDestination(int index) {
    widget.onResetRightNavigator();
    context.go(appDestinations[index].route.path);
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.destinations,
    required this.selectedIndex,
    required this.canPopListenable,
    required this.onBack,
    required this.onDestinationSelected,
  });

  static const width = 96.0;

  final List<AppDestination> destinations;
  final int? selectedIndex;
  final ValueListenable<bool> canPopListenable;
  final VoidCallback onBack;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);

    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surface,
          border: BorderDirectional(
            end: BorderSide(color: tokens.line.withValues(alpha: 0.40)),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 82),
            child: Column(
              children: [
                _SidebarBackButton(
                  canPopListenable: canPopListenable,
                  onBack: onBack,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: destinations.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) => _NavigationItem(
                      destination: destinations[index],
                      selected: selectedIndex == index,
                      onTap: () => onDestinationSelected(index),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarBackButton extends StatelessWidget {
  const _SidebarBackButton({
    required this.canPopListenable,
    required this.onBack,
  });

  final ValueListenable<bool> canPopListenable;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<bool>(
      valueListenable: canPopListenable,
      builder: (context, canPop, child) {
        return Tooltip(
          message: MaterialLocalizations.of(context).backButtonTooltip,
          child: Semantics(
            button: true,
            enabled: canPop,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: canPop ? onBack : null,
              child: SizedBox(
                height: 48,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutCubic,
                    width: 52,
                    height: 46,
                    decoration: BoxDecoration(
                      color: canPop
                          ? tokens.brand
                          : colorScheme.surfaceContainerHighest.withValues(
                              alpha: 0.56,
                            ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: canPop
                            ? tokens.brand
                            : tokens.line.withValues(alpha: 0.60),
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: canPop
                          ? Colors.white
                          : colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.42,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final AppDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final accent = tokens.brand;
    final label = appDestinationLabel(destination);

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
            decoration: BoxDecoration(
              color: selected
                  ? Color.alphaBlend(
                      accent.withValues(alpha: 0.11),
                      tokens.surfaceRaised,
                    )
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? accent.withValues(alpha: 0.28)
                    : Colors.transparent,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  width: 32,
                  height: 30,
                  decoration: BoxDecoration(
                    color: selected ? accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    size: 20,
                    color: selected
                        ? Colors.white
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: selected ? accent : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileNavigationBar extends StatelessWidget {
  const _MobileNavigationBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<AppDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);

    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surface,
          border: Border(
            top: BorderSide(color: tokens.line.withValues(alpha: 0.56)),
          ),
        ),
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              for (var index = 0; index < destinations.length; index++)
                Expanded(
                  child: _MobileNavigationItem(
                    destination: destinations[index],
                    selected: selectedIndex == index,
                    onTap: () => onDestinationSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileNavigationItem extends StatelessWidget {
  const _MobileNavigationItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final AppDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = AppThemeTokens.of(context).brand;
    final label = appDestinationLabel(destination);

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  size: 22,
                  color: selected
                      ? accent
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.78),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    height: 1,
                    color: selected
                        ? accent
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
