import 'dart:async';

import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/app/icons.g.dart';
import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/features/search/logic.dart';
import 'package:booruflow/features/search/query.dart';
import 'package:booruflow/features/search/services/tag_suggestion_repository.dart';
import 'package:booruflow/features/tags/tag_presentation.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:intl/intl.dart';

const _recentLimit = 8;
const _commonLimit = 5;

/// Token colouring of a query: `-` negative, `~` emphasised, `:` neutral,
/// tags the source verified positive, anything else a hint.
List<FrostTokenRule> searchTokenRules(Set<String> verified) => [
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

/// The query editing and suggestions of one search field, shared by the title
/// bar search and the inline search. The owning state creates it, calls
/// [suggestions] from its build and [dispose] with itself, and rebuilds when
/// [controller] changes.
class SearchBox {
  SearchBox({
    required this.ref,
    required this.controller,
    required this.focus,
    required String locale,
    String? sourceId,
  }) : session = SearchSession(
         locale: locale,
         sourceId: sourceId,
         followSource: true,
         initialQuery: controller.text,
       ) {
    controller.rules = searchTokenRules(const {});
    _lastEditing = controller.value;
    controller.addListener(_changed);
  }

  final WidgetRef ref;
  final FrostTokenEditingController controller;
  final FocusNode focus;
  final SearchSession session;
  TextEditingValue? _lastEditing;

  SearchState get state => ref.read(searchProvider(session));
  Search get _logic => ref.read(searchProvider(session).notifier);
  bool get _composing =>
      controller.value.isComposingRangeValid &&
      !controller.value.composing.isCollapsed;
  int get _caret => controller.selection.isValid
      ? controller.selection.extentOffset
      : controller.text.length;

  void dispose() => controller.removeListener(_changed);

  void _changed() {
    // Rule updates repaint but must not restart network debounce or alter IME.
    if (_lastEditing == controller.value) return;
    _lastEditing = controller.value;
    _logic.queryChanged(
      controller.text,
      composing: _composing,
      caretOffset: _caret,
    );
  }

  void setLocale(String locale) => _logic.setLocale(locale);

  void switchSource(String sourceId) => _logic.switchSource(sourceId);

  /// Replaces the whole query; the caret goes to its end.
  void setText(String text) {
    if (_composing) return;
    final next = text.trimRight();
    final query = next.isEmpty ? '' : '$next ';
    controller.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
  }

  /// Focuses the field with the caret after its text; focusing alone selects
  /// all of it on desktop.
  void focusAtEnd() {
    focus.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
    });
  }

  /// Adds [raw] as a new term.
  void append(String raw) {
    final prefix = controller.text.trimRight();
    setText('${prefix.isEmpty ? '' : '$prefix '}$raw');
  }

  /// Adds a suggested tag as a new term and records its state.
  void _add(TagSuggestion tag) {
    _logic.recordTag(tag);
    append(tag.value);
  }

  /// Takes a suggestion for the word at the caret, keeping its operator.
  void _replaceWord(TagSuggestion tag) {
    if (_composing) return;
    final span = querySpanAt(controller.text, _caret);
    final operator = span == null
        ? QueryOperator.include
        : QueryTerm.parse(span.raw).operator;
    final raw = QueryTerm(
      tag.value,
      operator == QueryOperator.metatag ? QueryOperator.include : operator,
    ).raw;
    _logic.recordTag(tag);
    if (span == null) {
      append(raw);
    } else {
      final suffix = controller.text.substring(span.end);
      final separator = suffix.startsWith(RegExp(r'\s')) ? '' : ' ';
      setText(
        controller.text.replaceRange(span.start, span.end, '$raw$separator'),
      );
    }
  }

  /// Opens the results of the query, replacing the page when it is one.
  /// Opens the results of the typed query; false when there is nothing to open.
  bool submit(BuildContext context, {required bool replace}) {
    if (_composing) return false;
    final tags = parseQueryInput(controller.text).toSet().toList();
    if (tags.isEmpty) return false;
    final sourceId = state.sourceId;
    unawaited(_remember(context, tags));
    focus.unfocus();
    if (replace) {
      context.replaceTaggedPosts(tags, sourceId: sourceId);
    } else {
      context.pushTaggedPosts(tags, sourceId: sourceId);
    }
    return true;
  }

  Future<void> _remember(BuildContext context, List<String> tags) async {
    final logic = _logic, source = state.sourceId;
    final repository = logic.repository;
    try {
      await logic.remember(tags);
      if (context.mounted) {
        ref.invalidate(searchHistoryProvider(repository, source));
      }
    } catch (error) {
      if (context.mounted) FrostToast.fromError(context, error);
    }
  }

  String? _count(BuildContext context, String? value) {
    if (value == null) return null;
    final count = int.tryParse(value);
    return count == null
        ? value
        : NumberFormat.decimalPattern(
            Localizations.localeOf(context).toLanguageTag(),
          ).format(count);
  }

  /// The dropdown content for the current query, or null when there is nothing
  /// to show: matches for the word at the caret, or, with nothing typed,
  /// recent searches, my tags and common tags. Call from build: it watches the
  /// state it reads.
  Widget? suggestions(BuildContext context) {
    final state = ref.watch(searchProvider(session));
    final logic = _logic;
    final repository = logic.repository;
    ref.listen(searchProvider(session), (previous, next) {
      if (previous?.verified != next.verified) {
        controller.rules = searchTokenRules(next.verified);
      }
    });
    final active =
        !_composing &&
        (querySpanAt(controller.text, _caret)?.raw.isNotEmpty ?? false);
    final initialization = state.initialization.error;
    final error = initialization ?? state.suggestions.error;
    final message = error != null
        ? describeBooruError(error, includeDiagnostics: false)
        : active &&
              state.ready &&
              !state.suggestions.isLoading &&
              state.suggestions.value.isEmpty
        ? t.discovery.noSuggestions
        : null;
    final loading = active && (!state.ready || state.suggestions.isLoading);
    String? translation(TagSuggestion tag) {
      final name = logic.displayName(tag.value, tag.displayName);
      return name == tag.value ? null : name;
    }

    // A failure is a section of its own, with its retry in the title row.
    Widget failure({
      String? title,
      required Object error,
      required VoidCallback retry,
    }) => FrostSearchSection(
      title: title,
      actionLabel: t.generic.retry,
      onAction: retry,
      children: [
        FrostSearchSuggestionRow(
          label: describeBooruError(error, includeDiagnostics: false),
          icon: appIcons.error,
          keepsOpen: true,
          onSelected: retry,
        ),
      ],
    );
    final initializationFailure = initialization == null
        ? null
        : failure(
            error: initialization,
            retry: () => ref.invalidate(searchProvider(session)),
          );
    final status = initialization == null ? message : null;

    if (active) {
      final matches = state.suggestions.value;
      if (initializationFailure == null &&
          matches.isEmpty &&
          !loading &&
          status == null) {
        return null;
      }
      return _column([
        ?initializationFailure,
        if (matches.isNotEmpty)
          FrostSearchSection(
            children: [
              for (final tag in matches)
                FrostSearchSuggestionRow(
                  label: tag.value,
                  detail: translation(tag),
                  inlineDetail: true,
                  dataColor: tag.category.colorIndex,
                  value: _count(context, tag.count),
                  keepsOpen: true,
                  onSelected: () => _replaceWord(tag),
                ),
            ],
          ),
        if (loading || status != null)
          FrostSearchStatus(loading: loading, message: status),
      ]);
    }
    final history = ref.watch(
      searchHistoryProvider(repository, state.sourceId),
    );
    final recents = (history.value ?? const <String>[])
        .take(_recentLimit)
        .toList();
    final aliases = [
      for (final alias in ref.watch(userTagsProvider).value ?? <UserTagAlias>[])
        if (alias.appliesTo(state.sourceId)) alias,
    ];
    final common = state.common.value.take(_commonLimit).toList();
    final sections = <Widget>[
      ?initializationFailure,
      if (history.error case final historyError?)
        failure(
          title: t.discovery.recentSearches,
          error: historyError,
          retry: () =>
              ref.invalidate(searchHistoryProvider(repository, state.sourceId)),
        ),
      if (state.common.error case final commonError?)
        failure(
          title: t.discovery.commonTags,
          error: commonError,
          retry: () => logic.loadCommon(refresh: true),
        ),
      if (recents.isNotEmpty)
        FrostSearchSection(
          title: t.discovery.recentSearches,
          actionLabel: t.discovery.clearHistory,
          onAction: () => ref
              .read(searchHistoryProvider(repository, state.sourceId).notifier)
              .clearQueries(),
          children: [
            for (final query in recents)
              FrostSearchSuggestionRow(
                label: query,
                icon: appIcons.clock,
                keepsOpen: true,
                onSelected: () => setText(query),
                onRemove: () => ref
                    .read(
                      searchHistoryProvider(
                        repository,
                        state.sourceId,
                      ).notifier,
                    )
                    .removeQuery(query),
              ),
          ],
        ),
      if (aliases.isNotEmpty)
        FrostSearchSection(
          title: t.discovery.myTags,
          actionLabel: t.discovery.manageTagsAction,
          onAction: () {
            focus.unfocus();
            unawaited(context.pushUserTags<void>(sourceId: state.sourceId));
          },
          children: [
            for (final alias in aliases)
              FrostSearchSuggestionRow(
                label: alias.displayName ?? alias.value,
                detail: alias.displayName == null ? null : alias.value,
                inlineDetail: true,
                icon: const FrostIconData.glyph(BooruFlowIcons.tags),
                keepsOpen: true,
                onSelected: () => _add(
                  TagSuggestion(
                    value: alias.value,
                    displayName: alias.displayName,
                    origin: SuggestionOrigin.userAlias,
                  ),
                ),
              ),
          ],
        ),
      if (common.isNotEmpty)
        FrostSearchSection(
          title: t.discovery.commonTags,
          actionLabel: t.discovery.allTagsAction,
          onAction: () {
            focus.unfocus();
            context.goToTags();
          },
          children: [
            for (final tag in common)
              FrostSearchSuggestionRow(
                label: tag.value,
                detail: translation(tag),
                inlineDetail: true,
                dataColor: tag.category.colorIndex,
                keepsOpen: true,
                onSelected: () => _add(tag),
              ),
          ],
        ),
      if (status != null) FrostSearchStatus(message: status),
    ];
    return sections.isEmpty ? null : _column(sections);
  }

  /// A non-scrolling column; the dropdown scrolls it.
  Widget _column(List<Widget> children) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: children,
  );
}
