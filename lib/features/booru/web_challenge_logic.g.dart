// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'web_challenge_logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(webChallengeService)
final webChallengeServiceProvider = WebChallengeServiceProvider._();

final class WebChallengeServiceProvider
    extends
        $FunctionalProvider<
          WebChallengeService,
          WebChallengeService,
          WebChallengeService
        >
    with $Provider<WebChallengeService> {
  WebChallengeServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'webChallengeServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$webChallengeServiceHash();

  @$internal
  @override
  $ProviderElement<WebChallengeService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WebChallengeService create(Ref ref) {
    return webChallengeService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WebChallengeService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WebChallengeService>(value),
    );
  }
}

String _$webChallengeServiceHash() =>
    r'e8e7fc0ef37b8b2bbe87fa3df6b2a61902e8cd25';

@ProviderFor(WebChallengeSession)
final webChallengeSessionProvider = WebChallengeSessionFamily._();

final class WebChallengeSessionProvider
    extends $NotifierProvider<WebChallengeSession, WebChallengeSessionState> {
  WebChallengeSessionProvider._({
    required WebChallengeSessionFamily super.from,
    required WebChallengeService super.argument,
  }) : super(
         retry: null,
         name: r'webChallengeSessionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$webChallengeSessionHash();

  @override
  String toString() {
    return r'webChallengeSessionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  WebChallengeSession create() => WebChallengeSession();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WebChallengeSessionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WebChallengeSessionState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WebChallengeSessionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$webChallengeSessionHash() =>
    r'6261e03c9b8acf514e97d948be851c282ce3cf8a';

final class WebChallengeSessionFamily extends $Family
    with
        $ClassFamilyOverride<
          WebChallengeSession,
          WebChallengeSessionState,
          WebChallengeSessionState,
          WebChallengeSessionState,
          WebChallengeService
        > {
  WebChallengeSessionFamily._()
    : super(
        retry: null,
        name: r'webChallengeSessionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WebChallengeSessionProvider call(WebChallengeService service) =>
      WebChallengeSessionProvider._(argument: service, from: this);

  @override
  String toString() => r'webChallengeSessionProvider';
}

abstract class _$WebChallengeSession
    extends $Notifier<WebChallengeSessionState> {
  late final _$args = ref.$arg as WebChallengeService;
  WebChallengeService get service => _$args;

  WebChallengeSessionState build(WebChallengeService service);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<WebChallengeSessionState, WebChallengeSessionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WebChallengeSessionState, WebChallengeSessionState>,
              WebChallengeSessionState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(webChallengeData)
final webChallengeDataProvider = WebChallengeDataFamily._();

final class WebChallengeDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<WebChallengeState>,
          WebChallengeState,
          FutureOr<WebChallengeState>
        >
    with
        $FutureModifier<WebChallengeState>,
        $FutureProvider<WebChallengeState> {
  WebChallengeDataProvider._({
    required WebChallengeDataFamily super.from,
    required WebDataRequest super.argument,
  }) : super(
         retry: null,
         name: r'webChallengeDataProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$webChallengeDataHash();

  @override
  String toString() {
    return r'webChallengeDataProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<WebChallengeState> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WebChallengeState> create(Ref ref) {
    final argument = this.argument as WebDataRequest;
    return webChallengeData(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WebChallengeDataProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$webChallengeDataHash() => r'ccf895202444d21d69bafe48e94d8d9185b82763';

final class WebChallengeDataFamily extends $Family
    with
        $FunctionalFamilyOverride<FutureOr<WebChallengeState>, WebDataRequest> {
  WebChallengeDataFamily._()
    : super(
        retry: null,
        name: r'webChallengeDataProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WebChallengeDataProvider call(WebDataRequest request) =>
      WebChallengeDataProvider._(argument: request, from: this);

  @override
  String toString() => r'webChallengeDataProvider';
}
