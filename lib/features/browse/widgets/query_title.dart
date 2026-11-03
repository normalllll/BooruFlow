import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';

/// A query painted by token with the search field's rules: excluded words in
/// the negative tone, meta words neutral. The field's controller does the
/// painting, so the title and the field cannot disagree.
class QueryTitle extends StatefulWidget {
  const QueryTitle(this.tags, {super.key});
  final List<String> tags;

  @override
  State<QueryTitle> createState() => _QueryTitleState();
}

class _QueryTitleState extends State<QueryTitle> {
  // Tokens are painted once they are followed by a space.
  static String _text(List<String> tags) => '${tags.join(' ')} ';

  late final _controller = FrostTokenEditingController(
    text: _text(widget.tags),
    rules: [
      FrostTokenRule(pattern: RegExp(r'^-'), tone: FrostTokenTone.negative),
      FrostTokenRule(pattern: RegExp(r':'), tone: FrostTokenTone.neutral),
    ],
  );

  @override
  void didUpdateWidget(QueryTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.text = _text(widget.tags);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FrostText.rich(
    _controller.buildTextSpan(context: context, withComposing: false),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}
