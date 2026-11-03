import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/search/logic.dart';
import 'package:booruflow/features/search/search_suggestions.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';

/// The search field of a page header in the bottom-bar layout. Frost expands
/// it over the header row when it takes focus and lists the suggestions in the
/// page body. A submitted query opens its results ([replace] swaps the current
/// results page for them) and collapses the header through [controller].
class InlineSearch extends ConsumerStatefulWidget {
  const InlineSearch({
    required this.sourceId,
    this.query = const [],
    this.replace = false,
    this.acceptsRequests = false,
    this.controller,
    super.key,
  });
  final String sourceId;

  /// The query the field starts with, and shows again when it changes.
  final List<String> query;
  final bool replace;

  /// Takes the text of [AppNavigation.openSearch] and expands for it.
  final bool acceptsRequests;
  final FrostPageHeaderSearchController? controller;

  @override
  ConsumerState<InlineSearch> createState() => _InlineSearchState();
}

class _InlineSearchState extends ConsumerState<InlineSearch> {
  final _controller = FrostTokenEditingController();
  final _focus = FocusNode(debugLabel: 'Inline search');
  SearchBox? _box;
  String? _locale;
  bool _awaitingReturn = false;

  String _text(List<String> query) =>
      query.isEmpty ? '' : '${query.join(' ')} ';

  @override
  void initState() {
    super.initState();
    _controller.text = _text(widget.query);
    _controller.addListener(_rebuild);
    if (widget.acceptsRequests && ref.read(pendingSearchProvider) != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _take(ref.read(pendingSearchProvider)),
      );
    }
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).toLanguageTag();
    if (_box == null) {
      _box = SearchBox(
        ref: ref,
        controller: _controller,
        focus: _focus,
        locale: locale,
        sourceId: widget.sourceId,
      );
    } else if (_locale != locale) {
      Future.microtask(() {
        if (mounted) _box!.setLocale(locale);
      });
    }
    _locale = locale;
    // The submitted query now lives on the results page it opened. Back on
    // this page the field holds [InlineSearch.query] again, as the list does.
    if (_awaitingReturn && (ModalRoute.isCurrentOf(context) ?? true)) {
      _awaitingReturn = false;
      final text = _text(widget.query);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.text = text;
      });
    }
  }

  @override
  void didUpdateWidget(InlineSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sourceId != oldWidget.sourceId) {
      Future.microtask(() {
        if (mounted) _box!.switchSource(widget.sourceId);
      });
    }
    if (!listEquals(widget.query, oldWidget.query)) {
      final text = _text(widget.query);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.text = text;
      });
    }
  }

  void _take(SearchTextRequest? request) {
    if (!mounted || request == null) return;
    ref.read(pendingSearchProvider.notifier).clear(request);
    _box!.append(request.text);
    _box!.focusAtEnd();
  }

  @override
  void dispose() {
    _box?.dispose();
    _controller.removeListener(_rebuild);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final box = _box!;
    if (widget.acceptsRequests) {
      ref.listen(pendingSearchProvider, (_, request) {
        if (request == null) return;
        WidgetsBinding.instance.addPostFrameCallback((_) => _take(request));
      });
    }
    final state = ref.watch(searchProvider(box.session));
    final source = ref
        .watch(booruSourcesProvider)
        .where((item) => item.sourceId == state.sourceId)
        .firstOrNull;
    final content = box.suggestions(context);
    return FrostSearchInput.suggesting(
      controller: _controller,
      focusNode: _focus,
      placeholder: t.discovery.searchSource(
        source: source?.displayName ?? state.sourceId,
      ),
      leadingIcon: true,
      appearance: FrostFieldAppearance.subtle,
      onSubmitted: (_) {
        _awaitingReturn =
            box.submit(context, replace: widget.replace) && !widget.replace;
        widget.controller?.collapse();
      },
      content: content,
    );
  }
}
