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

/// Whitespace inside a quoted source expression remains part of that expression.
List<String> parseQueryInput(String text) {
  final result = <String>[];
  var token = StringBuffer();
  String? quote;
  var braces = 0;
  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    if (quote != null) {
      token.write(char);
      if (char == quote) quote = null;
    } else if (char == '"' || char == "'") {
      quote = char;
      token.write(char);
    } else if (char == '{') {
      braces++;
      token.write(char);
    } else if (char == '}') {
      if (braces > 0) braces--;
      token.write(char);
    } else if (char.trim().isEmpty && braces == 0) {
      if (token.isNotEmpty) {
        result.add(token.toString());
        token = StringBuffer();
      }
    } else {
      token.write(char);
    }
  }
  if (token.isNotEmpty) result.add(token.toString());
  return result;
}
