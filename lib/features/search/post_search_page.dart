import 'dart:async';
import 'package:booruflow/features/search/common_tags_sheet.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:booruflow/features/booru/booru_service.dart';
import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/features/discovery/widgets/discovery_toolbar.dart';
import 'package:booruflow/shared/widgets/tag_label.dart';
import 'package:booruflow/shared/widgets/auto_scaffold.dart';
import 'package:booruflow/features/search/tag_suggestion_repository.dart';
import 'package:booruflow/features/search/user_tags_page.dart';
import 'package:booruflow/features/search/query.dart';
export 'package:booruflow/features/search/query.dart' show parseQueryInput;
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/shared/widgets/form_controls.dart';
import 'package:booruflow/shared/widgets/interaction_controls.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';

class PostSearchPage extends StatefulWidget {
  const PostSearchPage({
    super.key,
    this.sourceId,
    this.initialTags,
    this.initialQuery,
    this.isQueryEditor = false,
    this.onSubmit,
    this.repository,
    this.invalidQuery = false,
  });
  final String? sourceId;
  final List<String>? initialTags;
  final String? initialQuery;
  final bool isQueryEditor;
  final void Function(String sourceId, List<String> tags)? onSubmit;
  final TagSuggestionRepository? repository;
  final bool invalidQuery;
  @override
  State<PostSearchPage> createState() => _PostSearchPageState();
}

class _PostSearchPageState extends State<PostSearchPage> {
  final _input = TextEditingController();
  final _suggestionScroll = ScrollController();
  final _overlay = OverlayPortalController()..show();
  final _selected = <String>[];
  final _verified = <String>{};
  final _labels = <String, String>{};
  late final _repository =
      widget.repository ?? TagSuggestionRepository.instance;
  late String _source;
  String _locale = '';
  Timer? _debounce;
  int _generation = 0;
  int _commonGeneration = 0;
  int _highlight = -1;
  bool _busy = false;
  bool _commonBusy = false;
  bool _ready = false;
  bool _dismissed = false;
  bool _invalidSource = false;
  Object? _error;
  Object? _commonError;
  List<TagSuggestion> _suggestions = [];
  List<TagSuggestion> _common = [];
  bool get _composing =>
      _input.value.composing.isValid && !_input.value.composing.isCollapsed;
  bool get _canSubmit =>
      !_composing && (_selected.isNotEmpty || _input.text.trim().isNotEmpty);
  @override
  void initState() {
    super.initState();
    _source = widget.sourceId ?? BooruService.instance.selectedSource.value;
    if (!BooruService.instance.sources.any(
      (source) => source.sourceId == _source,
    )) {
      _invalidSource = true;
      _source = BooruService.instance.selectedSource.value;
    }
    _selected.addAll(widget.initialTags ?? []);
    final query = widget.initialQuery ?? '';
    _input.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    _input.addListener(_changed);
    BooruService.instance.selectedSource.addListener(_globalSourceChanged);
    BooruService.instance.revision.addListener(_networkChanged);
    _initialize();
  }

  @override
  void didUpdateWidget(covariant PostSearchPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final source = widget.sourceId;
    if (source != oldWidget.sourceId &&
        source != null &&
        BooruService.instance.sources.any((item) => item.sourceId == source)) {
      _switchSource(source);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).toLanguageTag();
    if (_locale != locale) {
      _locale = locale;
      if (_ready) {
        _changed();
        _loadCommon();
      }
    }
  }

  Future<void> _initialize() async {
    try {
      await _repository.initialize();
      if (!mounted) return;
      _ready = true;
      _changed();
      _loadCommon();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _globalSourceChanged() {
    if (widget.onSubmit == null) {
      _switchSource(BooruService.instance.selectedSource.value);
    }
  }

  void _networkChanged() {
    _verified.clear();
    _changed();
    _loadCommon();
  }

  void _switchSource(String source) {
    if (_source == source) return;
    setState(() {
      _source = source;
      _verified.clear();
      _suggestions = [];
      _common = [];
    });
    if (widget.onSubmit == null) BooruService.instance.selectSource(source);
    _changed();
    _loadCommon();
  }

  void _changed() {
    _debounce?.cancel();
    final generation = ++_generation;
    _highlight = -1;
    _dismissed = false;
    final term = QueryTerm.parse(parseQueryInput(_input.text).lastOrNull ?? '');
    final text = term.value;
    setState(() {
      _error = null;
      _busy = false;
      _suggestions = !_ready || _composing || text.isEmpty
          ? []
          : _repository.local(_source, _locale, text);
    });
    if (!_ready || _composing || text.isEmpty) return;
    final source = _source;
    final locale = _locale;
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      if (!mounted || generation != _generation) return;
      setState(() => _busy = true);
      try {
        final remote = await _repository.remote(source, locale, text);
        if (!mounted || generation != _generation) return;
        setState(
          () => _suggestions = _repository.merge(source, locale, text, [
            ...remote,
            ..._suggestions,
          ]),
        );
      } catch (e) {
        if (mounted && generation == _generation) setState(() => _error = e);
      } finally {
        if (mounted && generation == _generation) setState(() => _busy = false);
      }
    });
  }

  Future<void> _loadCommon({bool refresh = false}) async {
    if (!_ready) return;
    final generation = ++_commonGeneration;
    setState(() {
      _commonBusy = true;
      _commonError = null;
    });
    try {
      final values = await _repository.common(
        _source,
        _locale,
        refresh: refresh,
      );
      if (mounted && generation == _commonGeneration) {
        setState(() => _common = values);
      }
    } catch (e) {
      if (mounted && generation == _commonGeneration) {
        setState(() => _commonError = e);
      }
    } finally {
      if (mounted && generation == _commonGeneration) {
        setState(() => _commonBusy = false);
      }
    }
  }

  String _displayName(String raw, [String? fallback]) =>
      _repository.displayName(_source, _locale, QueryTerm.parse(raw).value) ??
      _labels['$_source:$raw'] ??
      fallback ??
      raw;

  void _add(TagSuggestion tag, {bool replaceTerm = false}) {
    final terms = parseQueryInput(_input.text);
    final operator = replaceTerm && terms.isNotEmpty
        ? QueryTerm.parse(terms.removeLast()).operator
        : QueryOperator.include;
    final value = QueryTerm(
      tag.value,
      operator == QueryOperator.metatag ? QueryOperator.include : operator,
    ).raw;
    setState(() {
      for (final term in [...terms, value]) {
        if (!_selected.contains(term)) _selected.add(term);
      }
      if (tag.verified) _verified.add(value);
      if (tag.displayName != null) {
        _labels['$_source:$value'] = tag.displayName!;
      }
    });
    _input.clear();
  }

  void _submit() {
    if (!_canSubmit) return;
    _dismissSuggestions();
    final tags = <String>{
      ..._selected,
      ...parseQueryInput(_input.text),
    }.toList();
    if (tags.isEmpty) return;
    unawaited(_repository.remember(_source, tags));
    if (widget.onSubmit != null) {
      widget.onSubmit!(_source, List.unmodifiable(tags));
    } else {
      context.pushTaggedPosts(tags, sourceId: _source);
    }
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (_composing || event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      setState(() {
        _dismissed = true;
        _highlight = -1;
      });
      return KeyEventResult.handled;
    }
    if (!_dismissed && _suggestions.isNotEmpty) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(
          () => _highlight =
              (_highlight +
                      (event.logicalKey == LogicalKeyboardKey.arrowDown
                          ? 1
                          : -1))
                  .clamp(0, _suggestions.length - 1),
        );
        if (_suggestionScroll.hasClients) {
          _suggestionScroll.animateTo(
            (_highlight * 72.0).clamp(
              0,
              _suggestionScroll.position.maxScrollExtent,
            ),
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
        return KeyEventResult.handled;
      }
      if (_highlight >= 0 &&
          (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.tab)) {
        _add(_suggestions[_highlight], replaceTerm: true);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  Future<void> _manageAliases() async {
    _dismissSuggestions();
    FocusScope.of(context).unfocus();
    await context.pushUserTags<void>(sourceId: _source);
    if (mounted) _changed();
  }

  Future<void> _manageSelected() async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          children: [
            for (final tag in _selected)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: InputChip(
                    label: TagLabel(value: tag, translation: _displayName(tag)),
                    onDeleted: () {
                      setState(() => _selected.remove(tag));
                      update(() {});
                    },
                    deleteIcon: const Icon(Icons.close),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _moreCommon() async {
    final source = _source;
    final tag = await showModalBottomSheet<TagSuggestion>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => CommonTagsSheet(
        repository: _repository,
        source: source,
        locale: _locale,
        initialTags: _common,
      ),
    );
    if (mounted && tag != null && source == _source) _add(tag);
  }

  Future<void> _addAlias() async {
    final alias = await editUserTag(
      context,
      source: _source,
      locale: _locale,
      value: QueryTerm.parse(
        parseQueryInput(_input.text).lastOrNull ?? '',
      ).value,
    );
    if (!mounted || alias == null) return;
    _add(
      TagSuggestion(
        value: alias.value,
        displayName: alias.displayName,
        origin: SuggestionOrigin.userAlias,
      ),
    );
  }

  @override
  void dispose() {
    _generation++;
    _commonGeneration++;
    _debounce?.cancel();
    _input.removeListener(_changed);
    _input.dispose();
    _suggestionScroll.dispose();
    BooruService.instance.selectedSource.removeListener(_globalSourceChanged);
    BooruService.instance.revision.removeListener(_networkChanged);
    super.dispose();
  }

  void _dismissSuggestions() {
    if (!_dismissed) setState(() => _dismissed = true);
  }

  Widget _queryField() => OverlayPortal.overlayChildLayoutBuilder(
    controller: _overlay,
    overlayChildBuilder: (context, info) {
      if (_dismissed || _composing || _input.text.trim().isEmpty) {
        return const SizedBox.shrink();
      }
      final anchor = MatrixUtils.transformRect(
        info.childPaintTransform,
        Offset.zero & info.childSize,
      );
      // The overlay may already end above the keyboard (a resized Scaffold).
      final media = MediaQuery.of(context);
      final keyboardTop = media.size.height - media.viewInsets.bottom;
      final bottom = math.min(info.overlaySize.height, keyboardTop) - 8;
      final below = math.max(0.0, bottom - anchor.bottom - 4);
      final above = math.max(0.0, anchor.top - media.padding.top - 4);
      final openAbove = below < 120 && above > below;
      final height = math.min(360.0, openAbove ? above : below);
      return Positioned(
        left: anchor.left,
        width: anchor.width,
        top: openAbove ? null : anchor.bottom + 4,
        bottom: openAbove ? info.overlaySize.height - anchor.top + 4 : null,
        child: TextFieldTapRegion(
          child: Material(
            key: const ValueKey('search-suggestions'),
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: height),
              child: ListView(
                controller: _suggestionScroll,
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  if (_busy) const LinearProgressIndicator(),
                  for (var index = 0; index < _suggestions.length; index++)
                    _suggestionRow(_suggestions[index], index),
                  if (!_busy && _suggestions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(t.discovery.noSuggestions),
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        '${t.discovery.localFallback}\n${describeBooruError(_error)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  if (!_suggestions.any(
                    (tag) =>
                        tag.value ==
                        QueryTerm.parse(
                          parseQueryInput(_input.text).lastOrNull ?? '',
                        ).value,
                  ))
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: AppButton(
                        label: t.discovery.addCustomTag,
                        kind: AppButtonKind.ghost,
                        onPressed: _addAlias,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    },
    child: Focus(
      onKeyEvent: _key,
      child: AppTextField(
        height: appFieldHeight(context),
        autofocus: widget.isQueryEditor,
        controller: _input,
        hintText: t.discovery.queryHint,
        textInputAction: TextInputAction.search,
        onTap: () => setState(() => _dismissed = false),
        onTapOutside: (_) => _dismissSuggestions(),
        // Preserve composition until the IME commits it.
        onEditingComplete: () {},
        onSubmitted: (_) => _submit(),
        trailing: AppIconButton(
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          padding: const EdgeInsets.all(6),
          tooltip: t.postSearch.title,
          icon: const Icon(Icons.search),
          onPressed: _canSubmit ? _submit : null,
        ),
      ),
    ),
  );

  Widget _suggestionRow(TagSuggestion tag, int index) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      key: ValueKey('suggestion-row-$index'),
      color: index == _highlight
          ? colors.primaryContainer
          : index.isEven
          ? colors.surface
          : colors.surfaceContainerHighest,
      child: InkWell(
        onTap: () => _add(tag, replaceTerm: true),
        onLongPress: () => showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: TagLabel(value: tag.value, translation: tag.displayName),
            content: Text(
              '${tag.value}\n${tag.verified ? t.discovery.verifiedTag : t.discovery.unverifiedTag}',
            ),
            actions: [
              AppButton(
                label: t.generic.ok,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TagLabel(value: tag.value, translation: tag.displayName),
                    Text(
                      categoryLabel(tag.category),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (tag.count != null) ...[
                const SizedBox(width: 12),
                SizedBox(
                  width: 64,
                  child: Text(
                    compactCount(tag.count!),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Material(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final showBack =
            widget.isQueryEditor && !shouldUseDesktopShell(context);
        return CustomScrollView(
          key: const ValueKey('search-tags-scroll'),
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              snap: false,
              automaticallyImplyLeading: false,
              toolbarHeight: appFieldHeight(context) + 20 + (showBack ? 48 : 0),
              flexibleSpace: Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFieldTapRegion(
                      child: DiscoveryToolbar(
                        sourceId: _source,
                        onSource: _switchSource,
                        query: _queryField(),
                      ),
                    ),
                    if (showBack)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: BackButton(),
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.invalidQuery || _invalidSource)
                      Text(t.booruError.invalidRequest),
                    if (!_ready && _error != null)
                      Text(describeBooruError(_error)),
                    if (_selected.isNotEmpty) ...[
                      SelectedTags(
                        tags: _selected,
                        displayName: _displayName,
                        onRemove: (tag) =>
                            setState(() => _selected.remove(tag)),
                        onMore: _manageSelected,
                      ),
                      if (_selected.any((tag) => !_verified.contains(tag)))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            t.discovery.unverifiedTag,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      const SizedBox(height: 8),
                    ],
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          t.discovery.commonTags,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        AppButton(
                          label: t.discovery.manageTags,
                          icon: Icons.sell_outlined,
                          compact: true,
                          kind: AppButtonKind.ghost,
                          onPressed: _manageAliases,
                        ),
                        if (_common.isNotEmpty)
                          AppButton(
                            label: t.discovery.moreTags,
                            compact: true,
                            kind: AppButtonKind.ghost,
                            onPressed: _moreCommon,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_common.isNotEmpty) ...[
                      Wrap(
                        key: const ValueKey('common-tags'),
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final tag in _common.take(40))
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: math.min(
                                  240,
                                  constraints.maxWidth - 24,
                                ),
                              ),
                              child: AppButton(
                                compact: true,
                                label: TagLabel.text(
                                  tag.value,
                                  _displayName(tag.value, tag.displayName),
                                ),
                                labelWidget: TagLabel(
                                  value: tag.value,
                                  translation: _displayName(
                                    tag.value,
                                    tag.displayName,
                                  ),
                                ),
                                onPressed: () => _add(tag),
                              ),
                            ),
                        ],
                      ),
                    ],
                    if (_commonBusy && _common.isEmpty)
                      const LinearProgressIndicator(),
                    if (_commonError != null)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: AppButton(
                          label: t.discovery.retryTags,
                          kind: AppButtonKind.ghost,
                          onPressed: () => _loadCommon(refresh: true),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

String compactCount(String count) {
  final number = int.tryParse(count);
  if (number == null) return count;
  if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}m';
  if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}k';
  return count;
}

String categoryLabel(TagCategory category) => switch (category) {
  TagCategory.artist => t.discovery.artist,
  TagCategory.character => t.discovery.character,
  TagCategory.copyright => t.discovery.copyright,
  TagCategory.meta => t.discovery.meta,
  TagCategory.general => t.discovery.general,
};

class SelectedTags extends StatelessWidget {
  const SelectedTags({
    super.key,
    required this.tags,
    required this.displayName,
    required this.onRemove,
    required this.onMore,
  });
  final List<String> tags;
  final String Function(String) displayName;
  final ValueChanged<String> onRemove;
  final VoidCallback onMore;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final style = Theme.of(context).textTheme.labelLarge!;
      double textWidth(String text) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();
        final width = painter.width;
        painter.dispose();
        return width;
      }

      final widths = tags
          .map(
            (tag) => math.min(
              math.min(240.0, constraints.maxWidth),
              textWidth(TagLabel.text(tag, displayName(tag))) + 64,
            ),
          )
          .toList();
      final rows = <List<int>>[[], []];
      final used = [0.0, 0.0];
      var row = 0;
      var visible = 0;
      for (var i = 0; i < tags.length; i++) {
        final gap = rows[row].isEmpty ? 0.0 : 8.0;
        if (used[row] + gap + widths[i] > constraints.maxWidth &&
            rows[row].isNotEmpty) {
          row++;
        }
        if (row >= 2) break;
        used[row] += (rows[row].isEmpty ? 0 : 8) + widths[i];
        rows[row].add(i);
        visible++;
      }
      final moreWidth = math.min(
        constraints.maxWidth,
        textWidth('+${tags.length}') + 48,
      );
      if (visible < tags.length) {
        while (rows[1].isNotEmpty &&
            used[1] + 8 + moreWidth > constraints.maxWidth) {
          used[1] -= widths[rows[1].removeLast()] + (rows[1].isEmpty ? 0 : 8);
          visible--;
        }
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var r = 0; r < 2; r++)
            if (rows[r].isNotEmpty || r == 1 && visible < tags.length)
              Padding(
                padding: EdgeInsets.only(top: r == 0 ? 0 : 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < rows[r].length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      SizedBox(
                        width: widths[rows[r][i]],
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: InputChip(
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            label: TagLabel(
                              value: tags[rows[r][i]],
                              translation: displayName(tags[rows[r][i]]),
                              style: style,
                            ),
                            onDeleted: () => onRemove(tags[rows[r][i]]),
                            deleteButtonTooltipMessage: t.generic.clear,
                          ),
                        ),
                      ),
                    ],
                    if (r == 1 && visible < tags.length) ...[
                      if (rows[r].isNotEmpty) const SizedBox(width: 8),
                      SizedBox(
                        width: moreWidth,
                        child: ActionChip(
                          label: Text(
                            '+${tags.length - visible}',
                            style: style,
                            maxLines: 1,
                          ),
                          onPressed: onMore,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
        ],
      );
    },
  );
}
