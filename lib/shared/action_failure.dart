/// Preserves an operation's localized summary alongside its structured cause.
/// The shared FrostErrorPresenter decides which safe diagnostics may be shown.
final class AppActionFailure {
  const AppActionFailure(this.message, [this.cause]);
  final String message;
  final Object? cause;
}
