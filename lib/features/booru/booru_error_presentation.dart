import 'package:booruflow/features/booru/models/web_challenge_failure.dart';
import 'package:booruflow/features/posts/widgets/rust_extended_network_image_provider.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/booru/error.dart';
import 'package:frost_ui/frost_ui.dart' show FrostRetryAfter;

String describeBooruError(Object? error, {bool includeDiagnostics = true}) {
  final booruError = switch (error) {
    BooruReadableException(:final cause) => cause,
    BooruError value => value,
    _ => null,
  };
  if (booruError == null) {
    return includeDiagnostics
        ? error?.toString() ?? t.generic.loadFailed
        : t.generic.loadFailed;
  }

  final animationError = switch (booruError.userMessageKey) {
    'booru.error.ugoiraInvalidArchive' => t.ugoira.ugoiraInvalidArchive,
    'booru.error.ugoiraMetadataMissing' => t.ugoira.ugoiraMetadataMissing,
    'booru.error.ugoiraInvalidMetadata' => t.ugoira.ugoiraInvalidMetadata,
    'booru.error.ugoiraFrameMissing' => t.ugoira.ugoiraFrameMissing,
    'booru.error.ugoiraFrameCorrupt' => t.ugoira.ugoiraFrameCorrupt,
    'booru.error.ugoiraFrameSizeMismatch' => t.ugoira.ugoiraFrameSizeMismatch,
    'booru.error.ugoiraFrameTooLarge' => t.ugoira.ugoiraFrameTooLarge,
    'booru.error.ugoiraEncodeFailed' => t.ugoira.ugoiraEncodeFailed,
    'booru.error.ugoiraOutputTooLarge' => t.ugoira.ugoiraOutputTooLarge,
    _ => null,
  };
  final primary =
      animationError ??
      switch (booruError.code) {
        _ when booruError.userMessageKey.startsWith('webChallenge.') =>
          webChallengeMessage(
            booruError.userMessageKey.substring('webChallenge.'.length),
          ),
        _ when booruError.userMessageKey == 'booru.error.routeUnavailable' =>
          t.booruError.routeUnavailable,
        BooruErrorCode.invalidRequest => t.booruError.invalidRequest,
        BooruErrorCode.unsupportedCapability =>
          t.booruError.unsupportedCapability,
        BooruErrorCode.authenticationRequired =>
          t.booruError.authenticationRequired,
        BooruErrorCode.authenticationRejected =>
          t.booruError.authenticationRejected,
        BooruErrorCode.permissionDenied => t.booruError.permissionDenied,
        BooruErrorCode.rateLimited => t.booruError.rateLimited,
        BooruErrorCode.challengeRequired => t.booruError.challengeRequired,
        BooruErrorCode.sourceUnavailable => t.booruError.sourceUnavailable,
        BooruErrorCode.network => t.booruError.network,
        BooruErrorCode.timeout => t.booruError.timeout,
        BooruErrorCode.invalidResponse => t.booruError.invalidResponse,
        BooruErrorCode.unsafeRedirect => t.booruError.unsafeRedirect,
        BooruErrorCode.mediaValidationFailed =>
          t.booruError.mediaValidationFailed,
        BooruErrorCode.cancelled => t.booruError.cancelled,
        BooruErrorCode.internal => t.booruError.internal,
      };
  if (!includeDiagnostics) return primary;
  return '$primary\n${_booruDiagnostics(booruError)}';
}

Object makeBooruErrorReadable(Object error) => switch (error) {
  BooruReadableException() => error,
  BooruError value => BooruReadableException(
    value,
    retryDeadline: DateTime.now().add(booruRetryDelay(value)),
  ),
  _ => error,
};

final class BooruReadableException implements Exception, FrostRetryAfter {
  const BooruReadableException(this.cause, {this.retryDeadline});
  final DateTime? retryDeadline;
  @override
  DateTime get retryAt =>
      retryDeadline ?? DateTime.fromMillisecondsSinceEpoch(0);

  final BooruError cause;

  @override
  String toString() => describeBooruError(cause);
}

String? booruErrorDetails(Object error) => switch (error) {
  MediaImageException() => _mediaDiagnostics(error),
  BooruError() => _booruDiagnostics(error),
  BooruReadableException(:final cause) => _booruDiagnostics(cause),
  _ => null,
};

String _mediaDiagnostics(MediaImageException error) {
  final request = error.request;
  final uri = Uri.tryParse(request.url);
  // Keep diagnostics free of headers, credentials and signed query parameters.
  final location = uri == null
      ? '(invalid URL)'
      : '${uri.scheme}://${uri.host}${uri.path}';
  final cause = (booruErrorDetails(error.cause) ?? error.cause.toString())
      .replaceAll(request.url, location);
  return 'source=${request.sourceId} · post=${request.postId} · variant=${request.variant.name}\n'
      'stage=${error.stage} · cache=${error.fromCache}${error.byteCount == null ? "" : " · bytes=${error.byteCount}"}\n'
      '$location\n$cause';
}

bool isBooruRateLimited(Object error) => switch (error) {
  BooruError(code: BooruErrorCode.rateLimited) => true,
  BooruReadableException(cause: BooruError(code: BooruErrorCode.rateLimited)) =>
    true,
  _ => false,
};

Duration booruRetryDelay(Object? error) {
  final value = switch (error) {
    BooruReadableException(:final cause) => cause,
    BooruError value => value,
    _ => null,
  };
  return Duration(
    seconds: value?.code == BooruErrorCode.rateLimited
        ? (value?.retryAfterSeconds ?? 60).clamp(0, 86400)
        : 0,
  );
}

BooruError? challengeError(Object? error) {
  if (error case MediaImageException(:final cause)) {
    return challengeError(cause);
  }
  final value = switch (error) {
    BooruReadableException(:final cause) => cause,
    BooruError value => value,
    _ => null,
  };
  return switch (value?.code) {
    BooruErrorCode.challengeRequired => value,
    _ => null,
  };
}

String _booruDiagnostics(BooruError booruError) {
  final context = <String>[
    if (booruError.sourceId case final source?) 'source=$source',
    'code=${booruError.code.name}',
    if (booruError.httpStatus case final status?) 'HTTP=$status',
    if (booruError.retryAfterSeconds case final seconds?)
      'retryAfter=${seconds}s',
    if (booruError.action case final action?) 'action=${action.name}',
  ];
  final details = booruError.details;
  return '${context.join(' · ')}\n'
      'message=${booruError.userMessageKey} · id=${booruError.diagnosticId}'
      '${details == null ? '' : '\n$details'}';
}
