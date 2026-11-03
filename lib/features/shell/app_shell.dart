import 'package:booruflow/app/icons.g.dart';
import 'package:booruflow/core/app_runtime.dart';
import 'package:booruflow/core/settings/logic.dart';
import 'package:booruflow/features/downloads/download_entry.dart';
import 'package:booruflow/features/search/title_bar_search.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';

/// The window frame: destinations, Back, the title bar and its search. All
/// geometry (sidebar or bottom bar, widths, the title row) is Frost's.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({
    required this.selectedIndex,
    required this.atDestinationRoot,
    required this.routeDepth,
    required this.location,
    required this.onBack,
    required this.onBackToFirst,
    required this.onDestinationSelected,
    required this.onResetRightNavigator,
    required this.child,
    super.key,
  });
  final int? selectedIndex;
  final bool atDestinationRoot;

  /// The router's current location; the title bar search follows its query.
  final Uri location;

  /// Pages above the selected destination's root page.
  final int routeDepth;
  final VoidCallback onBack, onBackToFirst, onResetRightNavigator;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final _search = TitleBarSearchController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final shell = CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            _search.focus,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
            _search.focus,
      },
      // The title bar search sits outside the page navigators: when it lets go
      // of focus, focus falls back to its nearest scope. This scope keeps that
      // inside the shortcuts, so Ctrl+K works again after the first search.
      child: FocusScope(
        child: FrostShell(
          destinations: [
            for (final destination in appDestinations)
              FrostNavDestination(
                label: appDestinationLabel(destination),
                icon: destination.icon,
              ),
          ],
          selectedIndex: widget.selectedIndex,
          atDestinationRoot: widget.atDestinationRoot,
          onDestinationSelected: (index) {
            widget.onResetRightNavigator();
            widget.onDestinationSelected(index);
          },
          canGoBack: !widget.atDestinationRoot,
          onBack: widget.onBack,
          showsMobileNavigation: true,
          initiallyExpanded: settings.sidebarExpanded,
          onExpandedChanged: ref
              .read(settingsProvider.notifier)
              .setSidebarExpanded,
          brand: FrostShellBrand(
            expanded: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/app-icon.png',
                  width: 24,
                  height: 24,
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
            icon: Image.asset(
              'assets/images/app-icon.png',
              width: 24,
              height: 24,
              excludeFromSemantics: true,
            ),
            label: AppInfo.name,
          ),
          routeDepth: widget.routeDepth,
          backToFirst: FrostShellBackToFirst(
            label: t.navigation.backToFirst,
            icon: const FrostIconData.glyph(BooruFlowIcons.house),
            onPressed: widget.onBackToFirst,
          ),
          // Frost shows the search in the title row when it fits; otherwise the
          // pages that offer a search carry it in their header (InlineSearch).
          titleBarSearch: TitleBarSearch(
            controller: _search,
            location: widget.location,
          ),
          titleBarSearchPlacement: FrostCaptionSearchPlacement.end,
          taskEntry: appDownloadTaskEntry(
            position: settings.downloadEntryPosition,
            onPositionChanged: ref
                .read(settingsProvider.notifier)
                .setDownloadEntryPosition,
          ),
          child: widget.child,
        ),
      ),
    );
    // An Escape nothing inside the shell took goes back one page. It has its own
    // intent: the Scaffolds around the pages map DismissIntent to their drawers
    // and would swallow it.
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): _PageBackIntent(),
      },
      child: Actions(
        actions: {
          _PageBackIntent: _PageBackAction(
            enabled: !widget.atDestinationRoot,
            onBack: widget.onBack,
          ),
        },
        child: shell,
      ),
    );
  }
}

class _PageBackIntent extends Intent {
  const _PageBackIntent();
}

class _PageBackAction extends Action<_PageBackIntent> {
  _PageBackAction({required this.enabled, required this.onBack});
  final bool enabled;
  final VoidCallback onBack;

  @override
  bool isEnabled(_PageBackIntent intent) => enabled;

  @override
  Object? invoke(_PageBackIntent intent) {
    onBack();
    return null;
  }
}
