import 'package:booruflow/src/rust/api/booru_auth.dart';

// Keep the persisted field whitelist at the authentication boundary. Old
// records included null optional fields; they are absent values, not corruption.
const _storedAuthFields = {
  'username',
  'userId',
  'apiKey',
  'cookieHeader',
  'userAgent',
};
Map<String, String>? decodeStoredAuth(Object? value) {
  if (value is! Map ||
      value.entries.any(
        (entry) =>
            !_storedAuthFields.contains(entry.key) ||
            entry.value != null && entry.value is! String,
      )) {
    return null;
  }
  return {
    for (final entry in value.entries)
      if (entry.value case final String text) entry.key as String: text,
  };
}

Map<String, String> encodeStoredCredentials(SourceCredentials credentials) => {
  'username': ?credentials.username,
  'userId': ?credentials.userId,
  'apiKey': ?credentials.apiKey,
};
