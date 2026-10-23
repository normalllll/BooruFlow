class DownloadException implements Exception {
  const DownloadException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() {
    final cause = this.cause;
    if (cause == null) {
      return message;
    }
    return '$message: $cause';
  }
}

final class DuplicateDownloadException extends DownloadException {
  const DuplicateDownloadException()
    : super('This image is already queued or downloading.');
}

final class DownloadPermissionDenied extends DownloadException {
  const DownloadPermissionDenied(super.message, [super.cause]);
}
