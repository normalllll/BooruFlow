import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/widgets/interaction_controls.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/material.dart';

import 'discovery_toolbar.dart';

/// Browsing navigation, separate from the search query editor and results header.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.sourceId,
    required this.kind,
    required this.modes,
    required this.modeLabel,
    required this.onSource,
    required this.onMode,
    this.details,
    this.onRetryProbe,
  });
  final String sourceId;
  final FeedKind kind;
  final List<FeedKind> modes;
  final String Function(FeedKind) modeLabel;
  final ValueChanged<String> onSource;
  final ValueChanged<FeedKind> onMode;
  final VoidCallback? onRetryProbe;
  final Widget? details;

  @override
  Widget build(BuildContext context) {
    return DiscoveryToolbar(
      sourceId: sourceId,
      onSource: onSource,
      controls: [
        if (onRetryProbe != null)
          AppIconButton(
            tooltip: t.generic.retry,
            icon: const Icon(Icons.cloud_off_outlined),
            onPressed: onRetryProbe,
          ),
        const SizedBox(width: 8),
        for (final mode in modes)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Semantics(
              selected: kind == mode,
              child: AppButton(
                label: modeLabel(mode),
                compact: true,
                kind: kind == mode
                    ? AppButtonKind.primary
                    : AppButtonKind.ghost,
                onPressed: () => onMode(mode),
              ),
            ),
          ),
        if (details != null)
          Padding(padding: const EdgeInsets.only(left: 8), child: details!),
      ],
    );
  }
}
