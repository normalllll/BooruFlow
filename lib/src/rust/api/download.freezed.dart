// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'download.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FrbDownloadFileEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FrbDownloadFileEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'FrbDownloadFileEvent()';
}


}

/// @nodoc
class $FrbDownloadFileEventCopyWith<$Res>  {
$FrbDownloadFileEventCopyWith(FrbDownloadFileEvent _, $Res Function(FrbDownloadFileEvent) __);
}


/// Adds pattern-matching-related methods to [FrbDownloadFileEvent].
extension FrbDownloadFileEventPatterns on FrbDownloadFileEvent {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( FrbDownloadFileEvent_Progress value)?  progress,TResult Function( FrbDownloadFileEvent_Done value)?  done,required TResult orElse(),}){
final _that = this;
switch (_that) {
case FrbDownloadFileEvent_Progress() when progress != null:
return progress(_that);case FrbDownloadFileEvent_Done() when done != null:
return done(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( FrbDownloadFileEvent_Progress value)  progress,required TResult Function( FrbDownloadFileEvent_Done value)  done,}){
final _that = this;
switch (_that) {
case FrbDownloadFileEvent_Progress():
return progress(_that);case FrbDownloadFileEvent_Done():
return done(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( FrbDownloadFileEvent_Progress value)?  progress,TResult? Function( FrbDownloadFileEvent_Done value)?  done,}){
final _that = this;
switch (_that) {
case FrbDownloadFileEvent_Progress() when progress != null:
return progress(_that);case FrbDownloadFileEvent_Done() when done != null:
return done(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int received,  int total)?  progress,TResult Function( String path)?  done,required TResult orElse(),}) {final _that = this;
switch (_that) {
case FrbDownloadFileEvent_Progress() when progress != null:
return progress(_that.received,_that.total);case FrbDownloadFileEvent_Done() when done != null:
return done(_that.path);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int received,  int total)  progress,required TResult Function( String path)  done,}) {final _that = this;
switch (_that) {
case FrbDownloadFileEvent_Progress():
return progress(_that.received,_that.total);case FrbDownloadFileEvent_Done():
return done(_that.path);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int received,  int total)?  progress,TResult? Function( String path)?  done,}) {final _that = this;
switch (_that) {
case FrbDownloadFileEvent_Progress() when progress != null:
return progress(_that.received,_that.total);case FrbDownloadFileEvent_Done() when done != null:
return done(_that.path);case _:
  return null;

}
}

}

/// @nodoc


class FrbDownloadFileEvent_Progress extends FrbDownloadFileEvent {
  const FrbDownloadFileEvent_Progress({required this.received, required this.total}): super._();


 final  int received;
 final  int total;

/// Create a copy of FrbDownloadFileEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FrbDownloadFileEvent_ProgressCopyWith<FrbDownloadFileEvent_Progress> get copyWith => _$FrbDownloadFileEvent_ProgressCopyWithImpl<FrbDownloadFileEvent_Progress>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FrbDownloadFileEvent_Progress&&(identical(other.received, received) || other.received == received)&&(identical(other.total, total) || other.total == total));
}


@override
int get hashCode => Object.hash(runtimeType,received,total);

@override
String toString() {
  return 'FrbDownloadFileEvent.progress(received: $received, total: $total)';
}


}

/// @nodoc
abstract mixin class $FrbDownloadFileEvent_ProgressCopyWith<$Res> implements $FrbDownloadFileEventCopyWith<$Res> {
  factory $FrbDownloadFileEvent_ProgressCopyWith(FrbDownloadFileEvent_Progress value, $Res Function(FrbDownloadFileEvent_Progress) _then) = _$FrbDownloadFileEvent_ProgressCopyWithImpl;
@useResult
$Res call({
 int received, int total
});




}
/// @nodoc
class _$FrbDownloadFileEvent_ProgressCopyWithImpl<$Res>
    implements $FrbDownloadFileEvent_ProgressCopyWith<$Res> {
  _$FrbDownloadFileEvent_ProgressCopyWithImpl(this._self, this._then);

  final FrbDownloadFileEvent_Progress _self;
  final $Res Function(FrbDownloadFileEvent_Progress) _then;

/// Create a copy of FrbDownloadFileEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? received = null,Object? total = null,}) {
  return _then(FrbDownloadFileEvent_Progress(
received: null == received ? _self.received : received // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class FrbDownloadFileEvent_Done extends FrbDownloadFileEvent {
  const FrbDownloadFileEvent_Done({required this.path}): super._();


 final  String path;

/// Create a copy of FrbDownloadFileEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FrbDownloadFileEvent_DoneCopyWith<FrbDownloadFileEvent_Done> get copyWith => _$FrbDownloadFileEvent_DoneCopyWithImpl<FrbDownloadFileEvent_Done>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FrbDownloadFileEvent_Done&&(identical(other.path, path) || other.path == path));
}


@override
int get hashCode => Object.hash(runtimeType,path);

@override
String toString() {
  return 'FrbDownloadFileEvent.done(path: $path)';
}


}

/// @nodoc
abstract mixin class $FrbDownloadFileEvent_DoneCopyWith<$Res> implements $FrbDownloadFileEventCopyWith<$Res> {
  factory $FrbDownloadFileEvent_DoneCopyWith(FrbDownloadFileEvent_Done value, $Res Function(FrbDownloadFileEvent_Done) _then) = _$FrbDownloadFileEvent_DoneCopyWithImpl;
@useResult
$Res call({
 String path
});




}
/// @nodoc
class _$FrbDownloadFileEvent_DoneCopyWithImpl<$Res>
    implements $FrbDownloadFileEvent_DoneCopyWith<$Res> {
  _$FrbDownloadFileEvent_DoneCopyWithImpl(this._self, this._then);

  final FrbDownloadFileEvent_Done _self;
  final $Res Function(FrbDownloadFileEvent_Done) _then;

/// Create a copy of FrbDownloadFileEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? path = null,}) {
  return _then(FrbDownloadFileEvent_Done(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
