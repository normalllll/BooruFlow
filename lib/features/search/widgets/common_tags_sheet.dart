import 'package:booruflow/features/search/logic.dart';
import 'package:booruflow/features/search/services/tag_suggestion_repository.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/widgets/tag_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The common tags and this paginated list share the same source tag cache.
class CommonTagsSheet extends ConsumerStatefulWidget {
  const CommonTagsSheet({
    super.key,
    required this.repository,
    required this.source,
    required this.locale,
    required this.initialTags,
  });
  final TagSuggestionRepository repository;
  final String source;
  final String locale;
  final List<TagSuggestion> initialTags;
  @override
  ConsumerState<CommonTagsSheet> createState() => _CommonTagsSheetState();
}

class _CommonTagsSheetState extends ConsumerState<CommonTagsSheet> {
  late final _request = CommonTagsRequest(
    source: widget.source,
    locale: widget.locale,
    repository: widget.repository,
    initialTags: widget.initialTags,
  );
  Future<void> _loadMore() =>
      ref.read(commonTagsProvider(_request).notifier).loadMore();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(commonTagsProvider(_request));
    final tags = state.tags;
    return FractionallySizedBox(
      heightFactor: .75,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: tags.length + 2,
        itemBuilder: (context, index) {
          final colors = Theme.of(context).colorScheme;
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Text(t.discovery.commonTags),
            );
          }
          if (index == tags.length + 1) {
            if (state.loading.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!state.hasMore) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: TextButton(
                onPressed: _loadMore,
                child: Text(
                  state.loading.hasError
                      ? t.generic.retry
                      : t.discovery.loadMore,
                ),
              ),
            );
          }
          final tag = tags[index - 1];
          final odd = (index - 1).isOdd;
          return Material(
            color: odd ? colors.surfaceContainer : colors.surface,
            child: InkWell(
              onTap: () => Navigator.pop(context, tag),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: TagLabel(
                  value: tag.value,
                  translation:
                      widget.repository.displayName(
                        widget.source,
                        widget.locale,
                        tag.value,
                      ) ??
                      tag.displayName,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
