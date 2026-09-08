// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booru_download.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DownloadEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DownloadEvent()';
}


}

/// @nodoc
class $DownloadEventCopyWith<$Res>  {
$DownloadEventCopyWith(DownloadEvent _, $Res Function(DownloadEvent) __);
}


/// Adds pattern-matching-related methods to [DownloadEvent].
extension DownloadEventPatterns on DownloadEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DownloadEvent_Progress value)?  progress,TResult Function( DownloadEvent_Done value)?  done,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DownloadEvent_Progress() when progress != null:
return progress(_that);case DownloadEvent_Done() when done != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DownloadEvent_Progress value)  progress,required TResult Function( DownloadEvent_Done value)  done,}){
final _that = this;
switch (_that) {
case DownloadEvent_Progress():
return progress(_that);case DownloadEvent_Done():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DownloadEvent_Progress value)?  progress,TResult? Function( DownloadEvent_Done value)?  done,}){
final _that = this;
switch (_that) {
case DownloadEvent_Progress() when progress != null:
return progress(_that);case DownloadEvent_Done() when done != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String receivedBytesDecimal,  String? totalBytesDecimal,  double progress)?  progress,TResult Function( String path)?  done,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DownloadEvent_Progress() when progress != null:
return progress(_that.receivedBytesDecimal,_that.totalBytesDecimal,_that.progress);case DownloadEvent_Done() when done != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String receivedBytesDecimal,  String? totalBytesDecimal,  double progress)  progress,required TResult Function( String path)  done,}) {final _that = this;
switch (_that) {
case DownloadEvent_Progress():
return progress(_that.receivedBytesDecimal,_that.totalBytesDecimal,_that.progress);case DownloadEvent_Done():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String receivedBytesDecimal,  String? totalBytesDecimal,  double progress)?  progress,TResult? Function( String path)?  done,}) {final _that = this;
switch (_that) {
case DownloadEvent_Progress() when progress != null:
return progress(_that.receivedBytesDecimal,_that.totalBytesDecimal,_that.progress);case DownloadEvent_Done() when done != null:
return done(_that.path);case _:
  return null;

}
}

}

/// @nodoc


class DownloadEvent_Progress extends DownloadEvent {
  const DownloadEvent_Progress({required this.receivedBytesDecimal, this.totalBytesDecimal, required this.progress}): super._();


 final  String receivedBytesDecimal;
 final  String? totalBytesDecimal;
 final  double progress;

/// Create a copy of DownloadEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DownloadEvent_ProgressCopyWith<DownloadEvent_Progress> get copyWith => _$DownloadEvent_ProgressCopyWithImpl<DownloadEvent_Progress>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadEvent_Progress&&(identical(other.receivedBytesDecimal, receivedBytesDecimal) || other.receivedBytesDecimal == receivedBytesDecimal)&&(identical(other.totalBytesDecimal, totalBytesDecimal) || other.totalBytesDecimal == totalBytesDecimal)&&(identical(other.progress, progress) || other.progress == progress));
}


@override
int get hashCode => Object.hash(runtimeType,receivedBytesDecimal,totalBytesDecimal,progress);

@override
String toString() {
  return 'DownloadEvent.progress(receivedBytesDecimal: $receivedBytesDecimal, totalBytesDecimal: $totalBytesDecimal, progress: $progress)';
}


}

/// @nodoc
abstract mixin class $DownloadEvent_ProgressCopyWith<$Res> implements $DownloadEventCopyWith<$Res> {
  factory $DownloadEvent_ProgressCopyWith(DownloadEvent_Progress value, $Res Function(DownloadEvent_Progress) _then) = _$DownloadEvent_ProgressCopyWithImpl;
@useResult
$Res call({
 String receivedBytesDecimal, String? totalBytesDecimal, double progress
});




}
/// @nodoc
class _$DownloadEvent_ProgressCopyWithImpl<$Res>
    implements $DownloadEvent_ProgressCopyWith<$Res> {
  _$DownloadEvent_ProgressCopyWithImpl(this._self, this._then);

  final DownloadEvent_Progress _self;
  final $Res Function(DownloadEvent_Progress) _then;

/// Create a copy of DownloadEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? receivedBytesDecimal = null,Object? totalBytesDecimal = freezed,Object? progress = null,}) {
  return _then(DownloadEvent_Progress(
receivedBytesDecimal: null == receivedBytesDecimal ? _self.receivedBytesDecimal : receivedBytesDecimal // ignore: cast_nullable_to_non_nullable
as String,totalBytesDecimal: freezed == totalBytesDecimal ? _self.totalBytesDecimal : totalBytesDecimal // ignore: cast_nullable_to_non_nullable
as String?,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class DownloadEvent_Done extends DownloadEvent {
  const DownloadEvent_Done({required this.path}): super._();


 final  String path;

/// Create a copy of DownloadEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DownloadEvent_DoneCopyWith<DownloadEvent_Done> get copyWith => _$DownloadEvent_DoneCopyWithImpl<DownloadEvent_Done>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadEvent_Done&&(identical(other.path, path) || other.path == path));
}


@override
int get hashCode => Object.hash(runtimeType,path);

@override
String toString() {
  return 'DownloadEvent.done(path: $path)';
}


}

/// @nodoc
abstract mixin class $DownloadEvent_DoneCopyWith<$Res> implements $DownloadEventCopyWith<$Res> {
  factory $DownloadEvent_DoneCopyWith(DownloadEvent_Done value, $Res Function(DownloadEvent_Done) _then) = _$DownloadEvent_DoneCopyWithImpl;
@useResult
$Res call({
 String path
});




}
/// @nodoc
class _$DownloadEvent_DoneCopyWithImpl<$Res>
    implements $DownloadEvent_DoneCopyWith<$Res> {
  _$DownloadEvent_DoneCopyWithImpl(this._self, this._then);

  final DownloadEvent_Done _self;
  final $Res Function(DownloadEvent_Done) _then;

/// Create a copy of DownloadEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? path = null,}) {
  return _then(DownloadEvent_Done(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$MediaFetchEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MediaFetchEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MediaFetchEvent()';
}


}

/// @nodoc
class $MediaFetchEventCopyWith<$Res>  {
$MediaFetchEventCopyWith(MediaFetchEvent _, $Res Function(MediaFetchEvent) __);
}


/// Adds pattern-matching-related methods to [MediaFetchEvent].
extension MediaFetchEventPatterns on MediaFetchEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( MediaFetchEvent_Failed value)?  failed,TResult Function( MediaFetchEvent_Chunk value)?  chunk,required TResult orElse(),}){
final _that = this;
switch (_that) {
case MediaFetchEvent_Failed() when failed != null:
return failed(_that);case MediaFetchEvent_Chunk() when chunk != null:
return chunk(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( MediaFetchEvent_Failed value)  failed,required TResult Function( MediaFetchEvent_Chunk value)  chunk,}){
final _that = this;
switch (_that) {
case MediaFetchEvent_Failed():
return failed(_that);case MediaFetchEvent_Chunk():
return chunk(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( MediaFetchEvent_Failed value)?  failed,TResult? Function( MediaFetchEvent_Chunk value)?  chunk,}){
final _that = this;
switch (_that) {
case MediaFetchEvent_Failed() when failed != null:
return failed(_that);case MediaFetchEvent_Chunk() when chunk != null:
return chunk(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( BooruError error)?  failed,TResult Function( Uint8List bytes,  String receivedBytesDecimal,  String? totalBytesDecimal)?  chunk,required TResult orElse(),}) {final _that = this;
switch (_that) {
case MediaFetchEvent_Failed() when failed != null:
return failed(_that.error);case MediaFetchEvent_Chunk() when chunk != null:
return chunk(_that.bytes,_that.receivedBytesDecimal,_that.totalBytesDecimal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( BooruError error)  failed,required TResult Function( Uint8List bytes,  String receivedBytesDecimal,  String? totalBytesDecimal)  chunk,}) {final _that = this;
switch (_that) {
case MediaFetchEvent_Failed():
return failed(_that.error);case MediaFetchEvent_Chunk():
return chunk(_that.bytes,_that.receivedBytesDecimal,_that.totalBytesDecimal);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( BooruError error)?  failed,TResult? Function( Uint8List bytes,  String receivedBytesDecimal,  String? totalBytesDecimal)?  chunk,}) {final _that = this;
switch (_that) {
case MediaFetchEvent_Failed() when failed != null:
return failed(_that.error);case MediaFetchEvent_Chunk() when chunk != null:
return chunk(_that.bytes,_that.receivedBytesDecimal,_that.totalBytesDecimal);case _:
  return null;

}
}

}

/// @nodoc


class MediaFetchEvent_Failed extends MediaFetchEvent {
  const MediaFetchEvent_Failed({required this.error}): super._();


 final  BooruError error;

/// Create a copy of MediaFetchEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MediaFetchEvent_FailedCopyWith<MediaFetchEvent_Failed> get copyWith => _$MediaFetchEvent_FailedCopyWithImpl<MediaFetchEvent_Failed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MediaFetchEvent_Failed&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,error);

@override
String toString() {
  return 'MediaFetchEvent.failed(error: $error)';
}


}

/// @nodoc
abstract mixin class $MediaFetchEvent_FailedCopyWith<$Res> implements $MediaFetchEventCopyWith<$Res> {
  factory $MediaFetchEvent_FailedCopyWith(MediaFetchEvent_Failed value, $Res Function(MediaFetchEvent_Failed) _then) = _$MediaFetchEvent_FailedCopyWithImpl;
@useResult
$Res call({
 BooruError error
});




}
/// @nodoc
class _$MediaFetchEvent_FailedCopyWithImpl<$Res>
    implements $MediaFetchEvent_FailedCopyWith<$Res> {
  _$MediaFetchEvent_FailedCopyWithImpl(this._self, this._then);

  final MediaFetchEvent_Failed _self;
  final $Res Function(MediaFetchEvent_Failed) _then;

/// Create a copy of MediaFetchEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(MediaFetchEvent_Failed(
error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as BooruError,
  ));
}


}

/// @nodoc


class MediaFetchEvent_Chunk extends MediaFetchEvent {
  const MediaFetchEvent_Chunk({required this.bytes, required this.receivedBytesDecimal, this.totalBytesDecimal}): super._();


 final  Uint8List bytes;
 final  String receivedBytesDecimal;
 final  String? totalBytesDecimal;

/// Create a copy of MediaFetchEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MediaFetchEvent_ChunkCopyWith<MediaFetchEvent_Chunk> get copyWith => _$MediaFetchEvent_ChunkCopyWithImpl<MediaFetchEvent_Chunk>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MediaFetchEvent_Chunk&&const DeepCollectionEquality().equals(other.bytes, bytes)&&(identical(other.receivedBytesDecimal, receivedBytesDecimal) || other.receivedBytesDecimal == receivedBytesDecimal)&&(identical(other.totalBytesDecimal, totalBytesDecimal) || other.totalBytesDecimal == totalBytesDecimal));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(bytes),receivedBytesDecimal,totalBytesDecimal);

@override
String toString() {
  return 'MediaFetchEvent.chunk(bytes: $bytes, receivedBytesDecimal: $receivedBytesDecimal, totalBytesDecimal: $totalBytesDecimal)';
}


}

/// @nodoc
abstract mixin class $MediaFetchEvent_ChunkCopyWith<$Res> implements $MediaFetchEventCopyWith<$Res> {
  factory $MediaFetchEvent_ChunkCopyWith(MediaFetchEvent_Chunk value, $Res Function(MediaFetchEvent_Chunk) _then) = _$MediaFetchEvent_ChunkCopyWithImpl;
@useResult
$Res call({
 Uint8List bytes, String receivedBytesDecimal, String? totalBytesDecimal
});




}
/// @nodoc
class _$MediaFetchEvent_ChunkCopyWithImpl<$Res>
    implements $MediaFetchEvent_ChunkCopyWith<$Res> {
  _$MediaFetchEvent_ChunkCopyWithImpl(this._self, this._then);

  final MediaFetchEvent_Chunk _self;
  final $Res Function(MediaFetchEvent_Chunk) _then;

/// Create a copy of MediaFetchEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? bytes = null,Object? receivedBytesDecimal = null,Object? totalBytesDecimal = freezed,}) {
  return _then(MediaFetchEvent_Chunk(
bytes: null == bytes ? _self.bytes : bytes // ignore: cast_nullable_to_non_nullable
as Uint8List,receivedBytesDecimal: null == receivedBytesDecimal ? _self.receivedBytesDecimal : receivedBytesDecimal // ignore: cast_nullable_to_non_nullable
as String,totalBytesDecimal: freezed == totalBytesDecimal ? _self.totalBytesDecimal : totalBytesDecimal // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
