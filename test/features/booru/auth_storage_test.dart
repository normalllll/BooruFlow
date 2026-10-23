import 'package:booruflow/features/booru/services/auth_storage.dart';
import 'package:booruflow/src/rust/api/booru_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('legacy nullable optional fields preserve configured credentials', () {
    expect(
      decodeStoredAuth({
        'username': 'Alice',
        'userId': null,
        'apiKey': 'example',
      }),
      {'username': 'Alice', 'apiKey': 'example'},
    );
    expect(
      decodeStoredAuth({'username': null, 'userId': '42', 'apiKey': 'example'}),
      {'userId': '42', 'apiKey': 'example'},
    );
    expect(
      decodeStoredAuth({
        'cookieHeader': 'session=example',
        'userAgent': 'Agent',
      }),
      {'cookieHeader': 'session=example', 'userAgent': 'Agent'},
    );
  });
  test(
    'new records omit missing fields and round trip without invalidating an account',
    () {
      final record = encodeStoredCredentials(
        const SourceCredentials(username: 'Alice', apiKey: 'example'),
      );
      expect(record, {'username': 'Alice', 'apiKey': 'example'});
      expect(decodeStoredAuth(record), record);
      expect(
        decodeStoredAuth(
          encodeStoredCredentials(const SourceCredentials(apiKey: 'example')),
        ),
        {'apiKey': 'example'},
      );
    },
  );
  test('unrecognized and corrupted fields remain invalid', () {
    for (final value in [
      null,
      'broken',
      {'username': 7},
      {'unrecognized': 'value'},
      {7: 'value'},
      {
        'apiKey': ['unexpected'],
      },
    ]) {
      expect(decodeStoredAuth(value), isNull);
    }
  });
}
