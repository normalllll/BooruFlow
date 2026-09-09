import 'dart:async';
import 'dart:math' as math;

import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/features/discovery/widgets/discovery_toolbar.dart';
import 'package:booruflow/features/search/logic.dart';
import 'package:booruflow/features/search/query.dart';
import 'package:booruflow/features/search/services/tag_suggestion_repository.dart';
import 'package:booruflow/features/search/user_tags_page.dart';
import 'package:booruflow/features/search/widgets/common_tags_sheet.dart';
import 'package:booruflow/features/search/widgets/search_tag_widgets.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/shared/widgets/auto_scaffold.dart';
import 'package:booruflow/shared/widgets/form_controls.dart';
import 'package:booruflow/shared/widgets/interaction_controls.dart';
import 'package:booruflow/shared/widgets/tag_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:booruflow/features/search/query.dart' show parseQueryInput;
export 'package:booruflow/features/search/widgets/search_tag_widgets.dart'
    show SelectedTags, compactCount, categoryLabel;

class PostSearchPage extends ConsumerStatefulWidget {
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
  ConsumerState<PostSearchPage> createState() => _PostSearchPageState();
}

class _PostSearchPageState extends ConsumerState<PostSearchPage> {
  final _input = TextEditingController();
  final _suggestionScroll = ScrollController();
  final _overlay = OverlayPortalController()..show();
  SearchSession? _session;
  SearchState get _state => ref.read(searchProvider(_session!));
  Search get _controller => ref.read(searchProvider(_session!).notifier);
  TagSuggestionRepository get _repository => _controller.repository;
  String get _source => _state.sourceId;
  String get _locale => _state.locale;
  List<String> get _selected => _state.selected;
  Set<String> get _verified => _state.verified;
  List<TagSuggestion> get _suggestions => _state.suggestions.value;
  List<TagSuggestion> get _common => _state.common.value;
  bool get _busy => _state.suggestions.isLoading;
  bool get _commonBusy => _state.common.isLoading;
  bool get _ready => _state.ready;
  bool get _invalidSource => _state.invalidSource;
  Object? get _error => _state.initialization.error ?? _state.suggestions.error;
  Object? get _commonError => _state.common.error;
  int _highlight = -1;
  bool _dismissed = false;
  bool get _composing =>
      _input.value.composing.isValid && !_input.value.composing.isCollapsed;
  bool get _canSubmit =>
      !_composing && (_selected.isNotEmpty || _input.text.trim().isNotEmpty);

  @override
  void initState() {
    super.initState();
    final query = widget.initialQuery ?? '';
    _input.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    _input.addListener(_changed);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).toLanguageTag();
    if (_session == null) {
      _session = SearchSession(
        locale: locale,
        followSource: widget.onSubmit == null,
        sourceId: widget.sourceId,
        initialTags: widget.initialTags ?? const [],
        initialQuery: widget.initialQuery ?? '',
        repository: widget.repository,
      );
    } else {
      Future.microtask(() {
        if (mounted) _controller.setLocale(locale);
      });
    }
  }

  @override
  void didUpdateWidget(covariant PostSearchPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sourceId case final source? when source != oldWidget.sourceId) {
      Future.microtask(() {
        if (mounted) _switchSource(source);
      });
    }
  }

  void _switchSource(String source) => _controller.switchSource(source);
  void _changed() {
    if (_session == null) return;
    setState(() {
      _highlight = -1;
      _dismissed = false;
    });
    _controller.queryChanged(_input.text, composing: _composing);
  }

  Future<void> _loadCommon({bool refresh = false}) =>
      _controller.loadCommon(refresh: refresh);
  String _displayName(String raw, [String? fallback]) =>
      _controller.displayName(raw, fallback);
  void _add(TagSuggestion tag, {bool replaceTerm = false}) {
    _controller.add(tag, _input.text, replaceTerm: replaceTerm);
    _input.clear();
  }

  void _submit() {
    if (!_canSubmit) return;
    _dismissSuggestions();
    final tags = _controller.submittedTags(_input.text);
    if (tags.isEmpty) return;
    unawaited(_controller.remember(tags));
    if (widget.onSubmit case final submit?) {
      submit(_source, List.unmodifiable(tags));
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
      builder: (context) => Consumer(
        builder: (context, ref, _) => ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          children: [
            for (final tag in ref.watch(searchProvider(_session!)).selected)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: InputChip(
                    label: TagLabel(value: tag, translation: _displayName(tag)),
                    onDeleted: () {
                      _controller.remove(tag);
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
    _input.removeListener(_changed);
    _input.dispose();
    _suggestionScroll.dispose();
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
      color: switch (index) {
        _ when index == _highlight => colors.primaryContainer,
        _ when index.isEven => colors.surface,
        _ => colors.surfaceContainerHighest,
      },
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
  Widget build(BuildContext context) {
    ref.watch(searchProvider(_session!));
    return Material(
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
                toolbarHeight:
                    appFieldHeight(context) + 20 + (showBack ? 48 : 0),
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
                          onRemove: (tag) => _controller.remove(tag),
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
}
