// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$downloaderHash() => r'be1a80cc02f6654b485ed5b6add5550d6038f8f8';

/// See also [Downloader].
@ProviderFor(Downloader)
final downloaderProvider =
    NotifierProvider<Downloader, DownloaderState>.internal(
  Downloader.new,
  name: r'downloaderProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$downloaderHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Downloader = Notifier<DownloaderState>;
String _$downloadTaskHash() => r'e8facf173da0afeca32692f87c517736b3ecd135';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$DownloadTask extends BuildlessNotifier<DownloadTaskState> {
  late final Post post;

  DownloadTaskState build({
    required Post post,
  });
}

/// See also [DownloadTask].
@ProviderFor(DownloadTask)
const downloadTaskProvider = DownloadTaskFamily();

/// See also [DownloadTask].
class DownloadTaskFamily extends Family<DownloadTaskState> {
  /// See also [DownloadTask].
  const DownloadTaskFamily();

  /// See also [DownloadTask].
  DownloadTaskProvider call({
    required Post post,
  }) {
    return DownloadTaskProvider(
      post: post,
    );
  }

  @override
  DownloadTaskProvider getProviderOverride(
    covariant DownloadTaskProvider provider,
  ) {
    return call(
      post: provider.post,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'downloadTaskProvider';
}

/// See also [DownloadTask].
class DownloadTaskProvider
    extends NotifierProviderImpl<DownloadTask, DownloadTaskState> {
  /// See also [DownloadTask].
  DownloadTaskProvider({
    required Post post,
  }) : this._internal(
          () => DownloadTask()..post = post,
          from: downloadTaskProvider,
          name: r'downloadTaskProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$downloadTaskHash,
          dependencies: DownloadTaskFamily._dependencies,
          allTransitiveDependencies:
              DownloadTaskFamily._allTransitiveDependencies,
          post: post,
        );

  DownloadTaskProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.post,
  }) : super.internal();

  final Post post;

  @override
  DownloadTaskState runNotifierBuild(
    covariant DownloadTask notifier,
  ) {
    return notifier.build(
      post: post,
    );
  }

  @override
  Override overrideWith(DownloadTask Function() create) {
    return ProviderOverride(
      origin: this,
      override: DownloadTaskProvider._internal(
        () => create()..post = post,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        post: post,
      ),
    );
  }

  @override
  NotifierProviderElement<DownloadTask, DownloadTaskState> createElement() {
    return _DownloadTaskProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DownloadTaskProvider && other.post == post;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, post.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin DownloadTaskRef on NotifierProviderRef<DownloadTaskState> {
  /// The parameter `post` of this provider.
  Post get post;
}

class _DownloadTaskProviderElement
    extends NotifierProviderElement<DownloadTask, DownloadTaskState>
    with DownloadTaskRef {
  _DownloadTaskProviderElement(super.provider);

  @override
  Post get post => (origin as DownloadTaskProvider).post;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
