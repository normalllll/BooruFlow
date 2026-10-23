import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/core/settings/logic.dart';
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';

const _ratingPanelMaxWidth = 300.0;

Future<void> showRatingFilterSheet(BuildContext context) =>
    showFrostSheet<void>(
      context: context,
      title: t.discovery.ratingsTitle,
      detents: const [FrostSheetDetent.fitted],
      builder: (_) => const _RatingChoices(),
    );

/// One source of controls and live settings for both panel presentations.
class RatingFilterButton extends ConsumerWidget {
  const RatingFilterButton({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final active = ref.watch(
      settingsProvider.select((s) => s.ratings.isNotEmpty),
    );
    Widget button(
      BuildContext context,
      FocusNode? focus,
      VoidCallback toggle,
    ) => Focus(
      focusNode: focus,
      skipTraversal: true,
      child: FrostButton.icon(
        label: t.discovery.filters,
        icon: appIcons.filter,
        size: FrostControlSize.compact,
        selected: active,
        onPressed: toggle,
      ).frostBadge(active ? 1 : 0),
    );
    return FrostPopover(
      maxWidth: _ratingPanelMaxWidth,
      title: t.discovery.ratingsTitle,
      builder: button,
      contentBuilder: (_, _) => const _RatingChoices(),
    );
  }
}

class _RatingChoices extends ConsumerWidget {
  const _RatingChoices();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final ratings = ref.watch(settingsProvider).ratings;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final rating in SettingsService.configurableRatings)
          FrostCheckboxRow(
            title: rating.displayLabel,
            value: ratings.contains(rating),
            onChanged: (selected) {
              final next = ref.read(settingsProvider).ratings.toSet();
              if (selected == true) {
                next.add(rating);
              } else {
                next.remove(rating);
              }
              ref.read(settingsProvider.notifier).setRatings(next.toList());
            },
          ),
        const SizedBox(height: FrostGap.related),
        FrostText(
          t.discovery.defaultRatingsHint,
          role: FrostTextRole.footnote,
          tone: FrostTextTone.secondary,
        ),
        const SizedBox(height: FrostGap.group),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: FrostButton.quiet(
            label: t.discovery.resetFilters,
            size: FrostControlSize.compact,
            onPressed: () => ref.read(settingsProvider.notifier).setRatings([]),
          ),
        ),
      ],
    );
  }
}

class RatingConditions extends ConsumerStatefulWidget {
  const RatingConditions({this.showsReset = true, super.key});
  final bool showsReset;
  @override
  ConsumerState<RatingConditions> createState() => _RatingConditionsState();
}

class _RatingConditionsState extends ConsumerState<RatingConditions> {
  List<String> _last = const [];
  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final ratings = ref.watch(settingsProvider).ratings;
    if (ratings.isNotEmpty) _last = ratings.map((r) => r.displayLabel).toList();
    void reset() => ref.read(settingsProvider.notifier).setRatings([]);
    return FrostPresence(
      visible: ratings.isNotEmpty,
      effect: FrostPresenceEffect.expand,
      child: Wrap(
        spacing: FrostGap.related,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          FrostFilterChip(
            label: t.discovery.ratingLabel,
            value: _last.join(t.discovery.ratingSeparator),
            onClear: reset,
          ),
          if (widget.showsReset)
            FrostButton.quiet(
              label: t.discovery.resetFilters,
              size: FrostControlSize.compact,
              onPressed: reset,
            ),
        ],
      ),
    );
  }
}
