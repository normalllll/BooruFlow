import 'package:booruflow/features/booru/models/web_challenge_failure.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/booru/error.dart';

String describeBooruError(Object? error) {
  final booruError = switch (error) {
    BooruReadableException(:final cause) => cause,
    BooruError value => value,
    _ => null,
  };
  if (booruError == null) return error?.toString() ?? t.generic.loadFailed;

  final primary = switch (booruError.code) {
    _ when booruError.userMessageKey.startsWith('webChallenge.') =>
      webChallengeMessage(
        booruError.userMessageKey.substring('webChallenge.'.length),
      ),
    _ when booruError.userMessageKey == 'booru.error.routeUnavailable' =>
      t.booruError.routeUnavailable,
    BooruErrorCode.invalidRequest => t.booruError.invalidRequest,
    BooruErrorCode.unsupportedCapability => t.booruError.unsupportedCapability,
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
    BooruErrorCode.mediaValidationFailed => t.booruError.mediaValidationFailed,
    BooruErrorCode.cancelled => t.booruError.cancelled,
    BooruErrorCode.internal => t.booruError.internal,
  };
  final context = <String>[
    if (booruError.sourceId case final source?) 'source=$source',
    'code=${booruError.code.name}',
    if (booruError.httpStatus case final status?) 'HTTP=$status',
    if (booruError.retryAfterSeconds case final seconds?)
      'retryAfter=${seconds}s',
    if (booruError.action case final action?) 'action=${action.name}',
  ];
  return '$primary\n${context.join(' · ')}\n'
      'message=${booruError.userMessageKey} · id=${booruError.diagnosticId}';
}

Object makeBooruErrorReadable(Object error) => switch (error) {
  BooruReadableException() => error,
  BooruError value => BooruReadableException(value),
  _ => error,
};

final class BooruReadableException implements Exception {
  const BooruReadableException(this.cause);

  final BooruError cause;

  @override
  String toString() => describeBooruError(cause);
}
