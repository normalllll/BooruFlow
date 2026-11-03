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
        // A form section lines the marks up with the title and the hint.
        FrostFormSection(
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
          ],
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

/// The conditions bar: shown only while a rating filter is in effect.
class RatingConditions extends ConsumerStatefulWidget {
  const RatingConditions({super.key});
  @override
  ConsumerState<RatingConditions> createState() => _RatingConditionsState();
}

class _RatingConditionsState extends ConsumerState<RatingConditions> {
  // Kept while the bar collapses, after the filter has been cleared.
  String _last = '';

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final ratings = ref.watch(settingsProvider).ratings;
    if (ratings.isNotEmpty) {
      _last = ratings
          .map((rating) => rating.displayLabel)
          .join(t.discovery.ratingSeparator);
    }
    void reset() => ref.read(settingsProvider.notifier).setRatings([]);
    return FrostPresence(
      visible: ratings.isNotEmpty,
      effect: FrostPresenceEffect.expand,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: FrostGap.related),
        child: FrostFilterBar(
          chips: [
            FrostFilterChip(
              label: t.discovery.ratingLabel,
              value: _last,
              onPressed: () => showRatingFilterSheet(context),
              onClear: reset,
            ),
          ],
          onClearAll: reset,
        ),
      ),
    );
  }
}
