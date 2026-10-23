enum QueryOperator { include, exclude, optional, metatag }

/// Keeps operators separate without changing the source's raw query spelling.
class QueryTerm {
  const QueryTerm(this.value, this.operator);
  final String value;
  final QueryOperator operator;
  factory QueryTerm.parse(String raw) {
    if (raw.startsWith('-')) {
      return QueryTerm(raw.substring(1), QueryOperator.exclude);
    }
    if (raw.startsWith('~')) {
      return QueryTerm(raw.substring(1), QueryOperator.optional);
    }
    return QueryTerm(
      raw,
      raw.contains(':') ? QueryOperator.metatag : QueryOperator.include,
    );
  }
  String get raw => switch (operator) {
    QueryOperator.exclude => '-$value',
    QueryOperator.optional => '~$value',
    _ => value,
  };
}

/// A UTF-16 range, matching Flutter's editing selection offsets.
class QuerySpan {
  const QuerySpan(this.raw, this.start, this.end);
  final String raw;
  final int start, end;
}

/// Whitespace inside quoted or braced source expressions stays in the term.
List<QuerySpan> querySpans(String text) {
  final result = <QuerySpan>[];
  int? start;
  String? quote;
  var braces = 0;
  for (var index = 0; index < text.length; index++) {
    final char = text[index];
    if (quote != null) {
      if (char == quote) quote = null;
    } else if (char == '"' || char == "'") {
      quote = char;
      start ??= index;
    } else if (char == '{') {
      braces++;
      start ??= index;
    } else if (char == '}') {
      if (braces > 0) braces--;
      start ??= index;
    } else if (char.trim().isEmpty && braces == 0) {
      if (start != null) {
        result.add(QuerySpan(text.substring(start, index), start, index));
      }
      start = null;
    } else {
      start ??= index;
    }
  }
  if (start != null) {
    result.add(QuerySpan(text.substring(start), start, text.length));
  }
  return result;
}

List<String> parseQueryInput(String text) => [
  for (final span in querySpans(text)) span.raw,
];

/// Completed trailing whitespace has no active term. Editing an earlier term
/// replaces only its range, preserving the rest of the query and its operators.
QuerySpan? querySpanAt(String text, int offset) => querySpans(
  text,
).where((span) => offset >= span.start && offset <= span.end).firstOrNull;
