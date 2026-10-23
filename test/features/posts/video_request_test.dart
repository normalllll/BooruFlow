import 'package:booruflow/features/posts/video_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HTTP proxy is handed to mpv; SOCKS is bypassed explicitly', () {
    for (final scheme in ['http', 'https']) {
      final url = '$scheme://user:password@127.0.0.1:7890';
      final proxy = VideoProxy.fromUrl(url);
      expect(proxy.httpProxy, url);
      expect(proxy.bypassesSocks, false);
    }
    for (final scheme in ['socks5', 'socks5h', 'socks4', 'socks4a']) {
      final proxy = VideoProxy.fromUrl('$scheme://127.0.0.1:7890');
      expect(proxy.httpProxy, isNull);
      expect(proxy.bypassesSocks, true);
    }
    expect(VideoProxy.fromUrl(null).httpProxy, isNull);
    expect(VideoProxy.fromUrl(null).bypassesSocks, false);
  });
  test('decoder failures never reveal header values or URL credentials', () {
    final message = redactVideoFailure(
      'HTTP failure https://user:password@example.test/video.mp4?token=secret Cookie: sid=private',
      ['sid=private'],
    );
    expect(message, contains('example.test/video.mp4'));
    for (final secret in [
      'password',
      'user:',
      'token',
      'secret',
      'sid=private',
    ]) {
      expect(message, isNot(contains(secret)));
    }
  });
}
