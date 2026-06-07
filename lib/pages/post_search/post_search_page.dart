import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:yande_gui/i18n.dart';
import 'package:yande_gui/pages/post_list/post_list_page.dart';
import 'package:yande_gui/services/custom_tags_service.dart';
import 'package:yande_gui/services/tag_translations_service.dart';
import 'package:yande_gui/widgets/auto_scaffold/auto_scaffold.dart';

class PostSearchPage extends StatefulWidget {
  const PostSearchPage({super.key});

  @override
  State<PostSearchPage> createState() => _PostSearchPageState();
}

class _PostSearchPageState extends State<PostSearchPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _textScrollController = ScrollController();
  bool _hasTextContent = false;
  List<String> _customTags = const [];
  final Set<String> _enteringCustomTags = <String>{};
  final Set<String> _removingCustomTags = <String>{};

  static final _knownTags = TagTranslationsService.knowTags;
  static final Duration _customTagEnterDuration = 240.ms;
  static final Duration _customTagExitDuration = 180.ms;

  @override
  void initState() {
    super.initState();
    _customTags = CustomTagsService.tags;
    _loadCustomTags();
  }

  @override
  void dispose() {
    _textController.dispose();
    _textScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomTags() async {
    await CustomTagsService.initialize();
    if (!mounted) {
      return;
    }
    setState(() {
      _customTags = CustomTagsService.tags;
      _enteringCustomTags.removeWhere((tag) => !_customTags.contains(tag));
      _removingCustomTags.removeWhere((tag) => !_customTags.contains(tag));
    });
  }

  List<String> _parseSearchTags(String text) {
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .where((tag) => tag.isNotEmpty)
        .toList(growable: true);
  }

  void _openPostList(String text) {
    final tags = _parseSearchTags(text);
    if (tags.isEmpty) {
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => PostListPage(tags: tags)));
  }

  void _appendTag(String tag) {
    final tags = _parseSearchTags(_textController.text);
    if (tags.contains(tag)) {
      return;
    }

    tags.add(tag);
    _textController.text = tags.join(' ');
    if (!_hasTextContent) {
      setState(() {
        _hasTextContent = true;
      });
    }
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: _textController.text.length),
    );
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _textScrollController.hasClients) {
        _textScrollController.jumpTo(
          _textScrollController.position.maxScrollExtent,
        );
      }
    });
  }

  String? _validateCustomTag(String tag) {
    final normalizedTag = tag.trim();
    if (normalizedTag.isEmpty) {
      return 'Tag is required';
    }
    if (normalizedTag.contains(RegExp(r'\s'))) {
      return 'Only one tag can be added at a time';
    }
    if (_knownTags.contains(normalizedTag)) {
      return 'Tag already exists in known tags';
    }
    if (CustomTagsService.contains(normalizedTag) ||
        _customTags.contains(normalizedTag)) {
      return 'Tag already exists';
    }
    return null;
  }

  Future<void> _showAddTagDialog() async {
    await CustomTagsService.initialize();
    if (!mounted) {
      return;
    }
    setState(() {
      _customTags = CustomTagsService.tags;
    });

    final tagController = TextEditingController();
    final translationController = TextEditingController();
    final input = await showDialog<({String tag, String? translation})>(
      context: context,
      builder: (context) {
        String? tagError;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            void submit() {
              final tag = tagController.text.trim();
              final error = _validateCustomTag(tag);
              if (error != null) {
                setDialogState(() {
                  tagError = error;
                });
                return;
              }

              final translation = translationController.text.trim();
              Navigator.of(context).pop((
                tag: tag,
                translation: translation.isEmpty ? null : translation,
              ));
            }

            return AlertDialog(
              title: const Text('Add tag'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: tagController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Tag',
                      hintText: 'tag_name',
                      errorText: tagError,
                    ),
                    onChanged: (_) {
                      if (tagError != null) {
                        setDialogState(() {
                          tagError = null;
                        });
                      }
                    },
                    onSubmitted: (_) {
                      submit();
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: translationController,
                    decoration: const InputDecoration(
                      labelText: 'Translation',
                      hintText: 'Optional',
                    ),
                    onSubmitted: (_) {
                      submit();
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(i18n.generic.cancel),
                ),
                TextButton(
                  onPressed: submit,
                  child: Text(i18n.generic.confirm),
                ),
              ],
            );
          },
        );
      },
    );
    tagController.dispose();
    translationController.dispose();

    if (input == null) {
      return;
    }

    final changed = await CustomTagsService.add(
      input.tag,
      translation: input.translation,
    );
    if (!mounted || !changed) {
      return;
    }
    setState(() {
      _customTags = CustomTagsService.tags;
      _enteringCustomTags.add(input.tag);
    });
    Future<void>.delayed(_customTagEnterDuration, () {
      if (!mounted || !_enteringCustomTags.contains(input.tag)) {
        return;
      }
      setState(() {
        _enteringCustomTags.remove(input.tag);
      });
    });
  }

  Future<void> _removeCustomTag(String tag) async {
    if (_removingCustomTags.contains(tag)) {
      return;
    }
    setState(() {
      _enteringCustomTags.remove(tag);
      _removingCustomTags.add(tag);
    });

    await Future<void>.delayed(_customTagExitDuration);
    final changed = await CustomTagsService.remove(tag);
    if (!mounted) {
      return;
    }
    setState(() {
      _removingCustomTags.remove(tag);
      _customTags = CustomTagsService.tags;
      if (!changed && _customTags.contains(tag)) {
        _enteringCustomTags.add(tag);
      }
    });
  }

  Widget _buildAddTagButton() {
    return ActionChip(
      avatar: const Icon(Icons.add, size: 18),
      label: const Text('Tag'),
      onPressed: _showAddTagDialog,
    );
  }

  Widget _buildTag(String tag, {required bool isCustom}) {
    final colorScheme = Theme.of(context).colorScheme;
    final translation = isCustom
        ? CustomTagsService.translate(tag)
        : TagTranslationsService.translate(tag);
    final backgroundColor = isCustom
        ? colorScheme.tertiaryContainer.withAlpha(150)
        : colorScheme.secondaryContainer.withAlpha(150);
    final translationColor = isCustom
        ? colorScheme.tertiary
        : colorScheme.primary;
    final tagStyle = TextStyle(
      fontSize: 16,
      color: colorScheme.onSurface,
      fontWeight: FontWeight.w600,
    );
    final translationStyle = tagStyle.copyWith(color: translationColor);
    final isRemoving = isCustom && _removingCustomTags.contains(tag);

    final tagChip = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: isRemoving ? null : () => _appendTag(tag),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: backgroundColor,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            RichText(
              strutStyle: const StrutStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                forceStrutHeight: true,
              ),
              text: TextSpan(
                children: [
                  TextSpan(text: tag, style: tagStyle),
                  if (translation != null)
                    TextSpan(text: ' #$translation', style: translationStyle),
                ],
              ),
            ),
            if (isCustom)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: isRemoving ? null : () => _removeCustomTag(tag),
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (!isCustom) {
      return tagChip;
    }

    return _buildAnimatedCustomTag(tag, tagChip);
  }

  Widget _buildAnimatedCustomTag(String tag, Widget child) {
    final isEntering = _enteringCustomTags.contains(tag);
    final isRemoving = _removingCustomTags.contains(tag);
    final isAnimating = isEntering || isRemoving;
    final animationState = isRemoving
        ? 'removing'
        : isEntering
        ? 'entering'
        : 'stable';
    final widthBegin = isRemoving ? 1.0 : 0.0;
    final widthEnd = isRemoving ? 0.0 : 1.0;
    final scaleBegin = isRemoving ? 1.0 : 0.86;
    final scaleEnd = isRemoving ? 0.92 : 1.0;
    final slideBegin = isRemoving ? 0.0 : 0.24;
    final slideEnd = isRemoving ? -0.08 : 0.0;
    final duration = isRemoving
        ? _customTagExitDuration
        : _customTagEnterDuration;

    return IgnorePointer(ignoring: isRemoving, child: child)
        .animate(
          key: ValueKey('custom-tag-$animationState-$tag'),
          autoPlay: isAnimating,
          value: isAnimating ? null : 1,
        )
        .custom(
          duration: duration,
          curve: isRemoving ? Curves.easeInCubic : Curves.easeOutCubic,
          begin: widthBegin,
          end: widthEnd,
          builder: (context, value, child) {
            return ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: value,
                heightFactor: value,
                child: child,
              ),
            );
          },
        )
        .fade(
          duration: duration,
          curve: isRemoving ? Curves.easeOut : Curves.easeOutCubic,
          begin: widthBegin,
          end: widthEnd,
        )
        .scaleXY(
          duration: duration,
          curve: isRemoving ? Curves.easeInCubic : Curves.easeOutBack,
          begin: scaleBegin,
          end: scaleEnd,
        )
        .slideY(
          duration: duration,
          curve: isRemoving ? Curves.easeInCubic : Curves.easeOutCubic,
          begin: slideBegin,
          end: slideEnd,
        );
  }

  Widget _buildSearchField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _textController,
            scrollController: _textScrollController,
            onChanged: (text) {
              if (text.isEmpty == _hasTextContent) {
                setState(() {
                  _hasTextContent = text.isNotEmpty;
                });
              }
            },
            onSubmitted: (value) {
              _openPostList(value);
            },
            decoration: InputDecoration(
              filled: true,
              hintText: i18n.postSearch.title,
              prefixIcon: Icon(
                Icons.search,
                color: Theme.of(context).inputDecorationTheme.hintStyle?.color,
              ),
              suffixIcon: _hasTextContent
                  ? IconButton(
                      icon: Icon(
                        Icons.cancel,
                        color: Theme.of(
                          context,
                        ).inputDecorationTheme.hintStyle?.color,
                      ),
                      onPressed: () {
                        _textController.clear();
                        setState(() {
                          _hasTextContent = false;
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(8),
            ),
          ),
        ),
        if (_hasTextContent)
          IconButton(
            onPressed: () {
              _openPostList(_textController.text);
            },
            icon: const Icon(Icons.search),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final customTagSet = _customTags.toSet();

    return AutoScaffold(
      builder: (context, horizontal) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: _buildSearchField(),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Wrap(
                    runSpacing: 6,
                    spacing: 6,
                    children: [
                      _buildAddTagButton(),
                      for (final tag in _knownTags)
                        if (!customTagSet.contains(tag))
                          _buildTag(tag, isCustom: false),
                      for (final tag in _customTags)
                        _buildTag(tag, isCustom: true),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
