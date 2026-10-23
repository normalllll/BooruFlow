// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Account)
final accountProvider = AccountFamily._();

final class AccountProvider
    extends $AsyncNotifierProvider<Account, AccountData> {
  AccountProvider._({
    required AccountFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'accountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$accountHash();

  @override
  String toString() {
    return r'accountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  Account create() => Account();

  @override
  bool operator ==(Object other) {
    return other is AccountProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$accountHash() => r'2ad10d5f46a3a955709703eb8ee26c167f33560e';

final class AccountFamily extends $Family
    with
        $ClassFamilyOverride<
          Account,
          AsyncValue<AccountData>,
          AccountData,
          FutureOr<AccountData>,
          String
        > {
  AccountFamily._()
    : super(
        retry: null,
        name: r'accountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AccountProvider call(String sourceId) =>
      AccountProvider._(argument: sourceId, from: this);

  @override
  String toString() => r'accountProvider';
}

abstract class _$Account extends $AsyncNotifier<AccountData> {
  late final _$args = ref.$arg as String;
  String get sourceId => _$args;

  FutureOr<AccountData> build(String sourceId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AccountData>, AccountData>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AccountData>, AccountData>,
              AsyncValue<AccountData>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
