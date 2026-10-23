import 'dart:async';

import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/search/logic.dart';
import 'package:booruflow/features/search/query.dart';
import 'package:booruflow/features/search/services/tag_suggestion_repository.dart';
import 'package:booruflow/features/search/user_tags_page.dart';
import 'package:booruflow/features/search/widgets/common_tags_sheet.dart';
import 'package:booruflow/features/search/widgets/search_landing_content.dart';
import 'package:booruflow/features/search/widgets/search_tag_widgets.dart';
import 'package:booruflow/features/tags/tag_presentation.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:intl/intl.dart';

export 'package:booruflow/features/search/query.dart' show parseQueryInput;
export 'package:booruflow/features/search/widgets/search_tag_widgets.dart'
    show compactCount, categoryLabel;

// The wide chooser keeps room for its title and the surrounding modal margin.
const _commonTagsViewportFraction = .7;

class PostSearchPage extends ConsumerStatefulWidget {
  const PostSearchPage({
    super.key,
    this.sourceId,
    this.initialTags,
    this.initialQuery,
    this.isQueryEditor = false,
    this.autofocus = true,
    this.onSubmit,
    this.repository,
    this.invalidQuery = false,
  });
  final String? sourceId, initialQuery;
  final List<String>? initialTags;
  final bool isQueryEditor, invalidQuery, autofocus;
  final void Function(String sourceId, List<String> tags)? onSubmit;
  final TagSuggestionRepository? repository;
  @override
  ConsumerState<PostSearchPage> createState() => _PostSearchPageState();
}

class _PostSearchPageState extends ConsumerState<PostSearchPage> {
  final _searchKey = GlobalKey();
  final _input = FrostTokenEditingController();
  final _focus = FocusNode();
  SearchSession? _session;
  TextEditingValue? _lastEditing;
  SearchState get _state => ref.read(searchProvider(_session!));
  Search get _logic => ref.read(searchProvider(_session!).notifier);
  TagSuggestionRepository get _repository => _logic.repository;
  bool get _composing =>
      _input.value.isComposingRangeValid && !_input.value.composing.isCollapsed;
  int get _caret => _input.selection.isValid
      ? _input.selection.extentOffset
      : _input.text.length;
  @override
  void initState() {
    super.initState();
    final query = [
      if (widget.initialTags?.isNotEmpty ?? false)
        widget.initialTags!.join(' '),
      if (widget.initialQuery?.isNotEmpty ?? false) widget.initialQuery!,
    ].join(' ');
    final initial =
        query.isNotEmpty && (widget.initialTags != null || widget.isQueryEditor)
        ? '$query '
        : query;
    _input.value = TextEditingValue(
      text: initial,
      selection: TextSelection.collapsed(offset: initial.length),
    );
    _lastEditing = _input.value;
    _input.rules = _rules(const {});
    _input.addListener(_changed);
  }

  List<FrostTokenRule> _rules(Set<String> verified) => [
    FrostTokenRule(pattern: RegExp(r'^-'), tone: FrostTokenTone.negative),
    FrostTokenRule(pattern: RegExp(r'^~'), tone: FrostTokenTone.accent),
    FrostTokenRule(pattern: RegExp(r':'), tone: FrostTokenTone.neutral),
    if (verified.isNotEmpty)
      FrostTokenRule(
        pattern: RegExp('^(?:${verified.map(RegExp.escape).join('|')})\$'),
        tone: FrostTokenTone.positive,
      ),
    FrostTokenRule(pattern: RegExp(r'.'), tone: FrostTokenTone.caution),
  ];
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).toLanguageTag();
    if (_session == null) {
      _session = SearchSession(
        locale: locale,
        sourceId: widget.sourceId,
        followSource: widget.onSubmit == null,
        initialQuery: _input.text,
        repository: widget.repository,
      );
    } else {
      Future.microtask(() {
        if (mounted) _logic.setLocale(locale);
      });
    }
  }

  @override
  void didUpdateWidget(PostSearchPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sourceId case final source? when source != oldWidget.sourceId) {
      Future.microtask(() {
        if (mounted) _logic.switchSource(source);
      });
    }
  }

  void _changed() {
    // Rule updates repaint but must not restart network debounce or alter IME.
    if (_session == null || _lastEditing == _input.value) return;
    _lastEditing = _input.value;
    _logic.queryChanged(
      _input.text,
      composing: _composing,
      caretOffset: _caret,
    );
  }

  void _setQuery(String text) {
    if (_composing) return;
    final next = text.trimRight();
    final query = next.isEmpty ? '' : '$next ';
    _input.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    // Inserting a query never opens the keyboard or steals editing focus.
  }

  void _add(TagSuggestion tag, {bool replaceTerm = false}) {
    if (_composing) return;
    final span = replaceTerm ? querySpanAt(_input.text, _caret) : null;
    final operator = span == null
        ? QueryOperator.include
        : QueryTerm.parse(span.raw).operator;
    final raw = QueryTerm(
      tag.value,
      operator == QueryOperator.metatag ? QueryOperator.include : operator,
    ).raw;
    _logic.recordTag(tag);
    if (span == null) {
      final prefix = _input.text.trimRight();
      _setQuery('${prefix.isEmpty ? '' : '$prefix '}$raw ');
    } else {
      final suffix = _input.text.substring(span.end);
      final separator = suffix.startsWith(RegExp(r'\s')) ? '' : ' ';
      _setQuery(
        _input.text.replaceRange(span.start, span.end, '$raw$separator'),
      );
    }
  }

  Future<void> _remember(List<String> tags) async {
    final repository = _repository, source = _state.sourceId;
    try {
      await _logic.remember(tags);
      if (mounted) ref.invalidate(searchHistoryProvider(repository, source));
    } catch (error) {
      if (mounted) FrostToast.fromError(context, error);
    }
  }

  void _submit(String _) {
    if (_composing) return;
    final tags = parseQueryInput(_input.text).toSet().toList();
    if (tags.isEmpty) return;
    unawaited(_remember(tags));
    _focus.unfocus();
    if (widget.onSubmit case final submit?) {
      submit(_state.sourceId, List.unmodifiable(tags));
    } else {
      context.pushTaggedPosts(tags, sourceId: _state.sourceId);
    }
  }

  Future<void> _manageAliases() async {
    _focus.unfocus();
    await context.pushUserTags<void>(sourceId: _state.sourceId);
  }

  Future<void> _addAlias() async {
    _focus.unfocus();
    final value = querySpanAt(_input.text, _caret)?.raw ?? _input.text.trim();
    await editUserTag(
      context,
      source: _state.sourceId,
      locale: _state.locale,
      value: QueryTerm.parse(value).value,
    );
  }

  Future<void> _moreCommon() async {
    _focus.unfocus();
    final source = _state.sourceId;
    final repository = _repository,
        locale = _state.locale,
        initialTags = _state.common.value;
    Widget panel() => CommonTagsSheet(
      repository: repository,
      source: source,
      locale: locale,
      initialTags: initialTags,
    );
    final tag = await showFrostAdaptiveDialog<TagSuggestion>(
      context: context,
      builder: (_) => FrostDialog(
        title: t.discovery.commonTags,
        size: FrostDialogSize.wide,
        showsCloseButton: true,
        scrollable: false,
        content: SizedBox(
          height:
              MediaQuery.sizeOf(context).height * _commonTagsViewportFraction,
          child: panel(),
        ),
      ),
    );
    if (mounted && tag != null && _state.sourceId == source) _add(tag);
  }

  @override
  void dispose() {
    _input.removeListener(_changed);
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  String? _suggestionCount(String? value) {
    if (value == null) return null;
    final count = int.tryParse(value);
    return count == null
        ? value
        : NumberFormat.decimalPattern(
            Localizations.localeOf(context).toLanguageTag(),
          ).format(count);
  }

  Widget _searchField(
    SearchState state, {
    Widget Function(BuildContext, Widget, Widget?)? layoutBuilder,
  }) {
    final active =
        !_composing &&
        (querySpanAt(_input.text, _caret)?.raw.isNotEmpty ?? false);
    final error = state.initialization.error ?? state.suggestions.error;
    final message = error != null
        ? describeBooruError(error, includeDiagnostics: false)
        : active &&
              state.ready &&
              !state.suggestions.isLoading &&
              state.suggestions.value.isEmpty
        ? t.discovery.noSuggestions
        : null;
    return FrostSearchInput(
      key: _searchKey,
      layoutBuilder: layoutBuilder,
      leadingIcon: true,
      controller: _input,
      focusNode: _focus,
      autofocus: widget.isQueryEditor && widget.autofocus,
      placeholder: t.discovery.queryHint,
      onSubmitted: _submit,
      loading: active && (!state.ready || state.suggestions.isLoading),
      message: message,
      suggestions: [
        FrostSearchSuggestionGroup(
          items: [
            for (final tag in state.suggestions.value)
              FrostSearchSuggestion(
                label: tag.value,
                detail:
                    _logic.displayName(tag.value, tag.displayName) == tag.value
                    ? null
                    : _logic.displayName(tag.value, tag.displayName),
                inlineDetail: true,
                dataColor: tag.category.colorIndex,
                value: _suggestionCount(tag.count),
                onSelected: () => _add(tag, replaceTerm: true),
              ),
          ],
        ),
      ],
    );
  }

  Widget _header(SearchState state, Widget field) {
    final sources = ref.watch(booruSourcesProvider);
    final source = sources
        .where((s) => s.sourceId == state.sourceId)
        .firstOrNull;
    final entries = [
      for (final s in sources)
        FrostMenuAction(
          s.displayName,
          checked: s.sourceId == state.sourceId,
          onSelected: () => _logic.switchSource(s.sourceId),
        ),
    ];
    final sourceMenu = FrostTitleMenu(
      title: source?.displayName ?? state.sourceId,
      entries: entries,
    );
    final more = <FrostMenuEntry>[
      FrostMenuAction(
        t.discovery.addCustomTag,
        icon: appIcons.add,
        onSelected: _input.text.trim().isEmpty ? null : _addAlias,
      ),
      FrostMenuAction(
        t.generic.clear,
        icon: appIcons.close,
        onSelected: _input.text.isEmpty ? null : () => _setQuery(''),
      ),
      FrostMenuAction(
        t.discovery.retryTags,
        icon: appIcons.refresh,
        onSelected: () => _logic.loadCommon(refresh: true),
      ),
    ];
    return FrostPageHeader(
      leading: [sourceMenu],
      middle: field,
      middleMaxWidth: appSearchMiddleMaxWidth,
      actions: [
        FrostToolbarItem.action(
          icon: appIcons.edit,
          label: t.discovery.manageTags,
          onPressed: _manageAliases,
        ),
        FrostToolbarItem.custom(
          minWidth: FrostDensity.of(context).targetHeight,
          priority: FrostToolbarPriority.low,
          overflowEntry: FrostMenuSection(entries: more),
          builder: (_) => FrostMenuAnchor(
            entries: more,
            builder: (context, focus, toggle) => Focus(
              focusNode: focus,
              canRequestFocus: false,
              child: FrostButton.icon(
                icon: appIcons.more,
                label: t.frost.more,
                size: FrostControlSize.compact,
                onPressed: toggle,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _layout(SearchState state, Widget field, Widget? suggestions) =>
      FrostPinnedChrome(
        chrome: FrostContentColumn(
          maxWidth: double.infinity,
          child: _header(state, field),
        ),
        body: suggestions == null
            ? CustomScrollView(
                key: const PageStorageKey('search-content'),
                slivers: [
                  const FrostChromeSpacer(),
                  FrostSliverContentColumn(
                    maxWidth: searchContentMaxWidth,
                    sliver: SliverToBoxAdapter(
                      child: SearchLandingContent(
                        state: state,
                        session: _session!,
                        invalidQuery: widget.invalidQuery,
                        onQuery: _setQuery,
                        onTag: _add,
                        onMoreCommon: _moreCommon,
                        onManageAliases: _manageAliases,
                        onAddAlias: _addAlias,
                      ),
                    ),
                  ),
                ],
              )
            : Builder(
                builder: (context) => Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.paddingOf(context).top,
                    bottom: MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: FrostColumnPlacement(
                    alignment: FrostColumnAlignment.start,
                    maxWidth: searchContentMaxWidth,
                    child: suggestions,
                  ),
                ),
              ),
      );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider(_session!));
    ref.listen(searchProvider(_session!), (previous, next) {
      if (previous?.verified != next.verified) {
        _input.rules = _rules(next.verified);
      }
    });
    return FrostWindowTitleContribution(
      path: widget.isQueryEditor
          ? AppRoute.searchEditor.path
          : AppRoute.search.path,
      page: FrostPageTitle(id: PostSearchPage, title: t.navigation.search),
      child: _searchField(
        state,
        layoutBuilder: (context, field, suggestions) =>
            _layout(state, field, suggestions),
      ),
    );
  }
}
