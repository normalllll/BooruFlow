import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/search/logic.dart';
import 'package:booruflow/features/search/search_suggestions.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';

/// The query and focus of the title bar search, owned by the shell so its
/// shortcut can reach the field wherever the keyboard focus is.
class TitleBarSearchController {
  final text = FrostTokenEditingController();
  final node = FocusNode(debugLabel: 'Title bar search');

  void focus() => node.requestFocus();

  void dispose() {
    text.dispose();
    node.dispose();
  }
}

/// Search in the title row (sidebar layouts). A submitted query opens the
/// result list of the selected source. While a results page is in front the
/// field shows its query; elsewhere it holds what was typed.
class TitleBarSearch extends ConsumerStatefulWidget {
  const TitleBarSearch({
    required this.controller,
    required this.location,
    super.key,
  });
  final TitleBarSearchController controller;

  /// The current location of the app's router.
  final Uri location;

  @override
  ConsumerState<TitleBarSearch> createState() => _TitleBarSearchState();
}

class _TitleBarSearchState extends ConsumerState<TitleBarSearch> {
  SearchBox? _box;
  String? _locale;
  bool _showingResults = false;

  bool get _onResults => widget.location.path == AppRoute.results.path;

  @override
  void initState() {
    super.initState();
    widget.controller.text.addListener(_rebuild);
    _syncResults();
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
        controller: widget.controller.text,
        focus: widget.controller.node,
        locale: locale,
      );
    } else if (_locale != locale) {
      Future.microtask(() {
        if (mounted) _box!.setLocale(locale);
      });
    }
    _locale = locale;
  }

  @override
  void didUpdateWidget(TitleBarSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) _syncResults();
  }

  /// Shows the query of the results page in front, and empties the field once
  /// that page is left. Editing the controller waits for the frame to end.
  void _syncResults() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final query = _onResults ? ResultsQuery.parse(widget.location) : null;
      final controller = widget.controller.text;
      if (query != null && query.valid && query.tags.isNotEmpty) {
        final text = '${query.tags.join(' ')} ';
        if (controller.text != text) {
          controller.value = TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          );
        }
        _showingResults = true;
      } else if (_showingResults) {
        controller.clear();
        _showingResults = false;
      }
    });
  }

  void _take(SearchTextRequest request) {
    ref.read(pendingSearchProvider.notifier).clear(request);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _box!.append(request.text);
      _box!.focusAtEnd();
    });
  }

  @override
  void dispose() {
    widget.controller.text.removeListener(_rebuild);
    _box?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final box = _box!;
    // While hidden, a request belongs to the Tags page's inline search.
    final inCaption = FrostShell.titleContentInCaptionOf(context);
    ref.listen(pendingSearchProvider, (_, request) {
      if (request != null && inCaption) _take(request);
    });
    final state = ref.watch(searchProvider(box.session));
    final source = ref
        .watch(booruSourcesProvider)
        .where((item) => item.sourceId == state.sourceId)
        .firstOrNull;
    final content = box.suggestions(context);
    return FrostCaptionSearch(
      controller: widget.controller.text,
      focusNode: widget.controller.node,
      placeholder: t.discovery.searchSource(
        source: source?.displayName ?? state.sourceId,
      ),
      // AppShell binds this shortcut to TitleBarSearchController.focus.
      hint: const FrostShortcut(
        LogicalKeyboardKey.keyK,
        primary: true,
      ).hintLabel(context),
      content: content,
      onSubmitted: (_) => box.submit(context, replace: _onResults),
    );
  }
}
