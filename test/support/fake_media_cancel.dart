import 'package:booruflow/src/rust/api/booru_download.dart';

/// A [MediaCancel] that records its use without the native library.
class FakeMediaCancel implements MediaCancel {
  bool cancelled = false;
  bool disposed = false;

  @override
  void cancel() => cancelled = true;

  @override
  void dispose() => disposed = true;

  @override
  bool get isDisposed => disposed;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
