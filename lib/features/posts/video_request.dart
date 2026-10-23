/// mpv/FFmpeg's HTTP input accepts HTTP(S) proxies, not SOCKS. This value is
/// session-local; proxy credentials must never be included in diagnostics.
class VideoProxy {
  const VideoProxy._(this.httpProxy, this.bypassesSocks);
  factory VideoProxy.fromUrl(String? value) {
    final uri = Uri.tryParse(value ?? '');
    return switch (uri?.scheme) {
      'http' || 'https' => VideoProxy._(value, false),
      'socks5' ||
      'socks5h' ||
      'socks4' ||
      'socks4a' => const VideoProxy._(null, true),
      _ => const VideoProxy._(null, false),
    };
  }
  final String? httpProxy;
  final bool bypassesSocks;
}

/// Decoder diagnostics may echo a URL or header. Keep credentials out of UI
/// errors as well as logs. The original request is never serialized to disk.
String redactVideoFailure(String message, Iterable<String> secrets) {
  var result = message;
  for (final secret in secrets) {
    if (secret.isNotEmpty) result = result.replaceAll(secret, '[redacted]');
  }
  return result.replaceAllMapped(RegExp(r'https?://[^\s\]\)]+'), (match) {
    final uri = Uri.tryParse(match.group(0)!);
    return uri?.replace(userInfo: '', query: '', fragment: '').toString() ??
        '[url]';
  });
}
