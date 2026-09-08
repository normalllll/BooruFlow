import 'package:booruflow/features/search/tag_suggestion_repository.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/widgets/tag_label.dart';
import 'package:flutter/material.dart';

/// The common tags and this paginated list share the same source tag cache.
class CommonTagsSheet extends StatefulWidget {
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
  State<CommonTagsSheet> createState() => _CommonTagsSheetState();
}

class _CommonTagsSheetState extends State<CommonTagsSheet> {
  late final _tags = [...widget.initialTags];
  late bool _hasMore = _tags.length == 50;
  bool _loading = false;
  bool _failed = false;
  int _page = 1;

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final items = await widget.repository.common(
        widget.source,
        widget.locale,
        page: _page + 1,
      );
      if (!mounted) return;
      setState(() {
        final seen = _tags.map((tag) => tag.value).toSet();
        _tags.addAll(items.where((tag) => seen.add(tag.value)));
        _hasMore = items.length == 50;
        _page++;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    heightFactor: .75,
    child: ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: _tags.length + 2,
      itemBuilder: (context, index) {
        final colors = Theme.of(context).colorScheme;
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Text(t.discovery.commonTags),
          );
        }
        if (index == _tags.length + 1) {
          if (_loading) return const Center(child: CircularProgressIndicator());
          if (!_hasMore) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: TextButton(
              onPressed: _loadMore,
              child: Text(_failed ? t.generic.retry : t.discovery.loadMore),
            ),
          );
        }
        final tag = _tags[index - 1];
        final odd = (index - 1).isOdd;
        return Material(
          color: odd ? colors.surfaceContainer : colors.surface,
          child: InkWell(
            onTap: () => Navigator.pop(context, tag),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
