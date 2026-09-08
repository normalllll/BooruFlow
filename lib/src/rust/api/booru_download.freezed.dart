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
mixin _$DownloadEventDto {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadEventDto);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DownloadEventDto()';
}


}

/// @nodoc
class $DownloadEventDtoCopyWith<$Res>  {
$DownloadEventDtoCopyWith(DownloadEventDto _, $Res Function(DownloadEventDto) __);
}


/// Adds pattern-matching-related methods to [DownloadEventDto].
extension DownloadEventDtoPatterns on DownloadEventDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DownloadEventDto_Progress value)?  progress,TResult Function( DownloadEventDto_Done value)?  done,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DownloadEventDto_Progress() when progress != null:
return progress(_that);case DownloadEventDto_Done() when done != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DownloadEventDto_Progress value)  progress,required TResult Function( DownloadEventDto_Done value)  done,}){
final _that = this;
switch (_that) {
case DownloadEventDto_Progress():
return progress(_that);case DownloadEventDto_Done():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DownloadEventDto_Progress value)?  progress,TResult? Function( DownloadEventDto_Done value)?  done,}){
final _that = this;
switch (_that) {
case DownloadEventDto_Progress() when progress != null:
return progress(_that);case DownloadEventDto_Done() when done != null:
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
case DownloadEventDto_Progress() when progress != null:
return progress(_that.receivedBytesDecimal,_that.totalBytesDecimal,_that.progress);case DownloadEventDto_Done() when done != null:
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
case DownloadEventDto_Progress():
return progress(_that.receivedBytesDecimal,_that.totalBytesDecimal,_that.progress);case DownloadEventDto_Done():
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
case DownloadEventDto_Progress() when progress != null:
return progress(_that.receivedBytesDecimal,_that.totalBytesDecimal,_that.progress);case DownloadEventDto_Done() when done != null:
return done(_that.path);case _:
  return null;

}
}

}

/// @nodoc


class DownloadEventDto_Progress extends DownloadEventDto {
  const DownloadEventDto_Progress({required this.receivedBytesDecimal, this.totalBytesDecimal, required this.progress}): super._();


 final  String receivedBytesDecimal;
 final  String? totalBytesDecimal;
 final  double progress;

/// Create a copy of DownloadEventDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DownloadEventDto_ProgressCopyWith<DownloadEventDto_Progress> get copyWith => _$DownloadEventDto_ProgressCopyWithImpl<DownloadEventDto_Progress>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadEventDto_Progress&&(identical(other.receivedBytesDecimal, receivedBytesDecimal) || other.receivedBytesDecimal == receivedBytesDecimal)&&(identical(other.totalBytesDecimal, totalBytesDecimal) || other.totalBytesDecimal == totalBytesDecimal)&&(identical(other.progress, progress) || other.progress == progress));
}


@override
int get hashCode => Object.hash(runtimeType,receivedBytesDecimal,totalBytesDecimal,progress);

@override
String toString() {
  return 'DownloadEventDto.progress(receivedBytesDecimal: $receivedBytesDecimal, totalBytesDecimal: $totalBytesDecimal, progress: $progress)';
}


}

/// @nodoc
abstract mixin class $DownloadEventDto_ProgressCopyWith<$Res> implements $DownloadEventDtoCopyWith<$Res> {
  factory $DownloadEventDto_ProgressCopyWith(DownloadEventDto_Progress value, $Res Function(DownloadEventDto_Progress) _then) = _$DownloadEventDto_ProgressCopyWithImpl;
@useResult
$Res call({
 String receivedBytesDecimal, String? totalBytesDecimal, double progress
});




}
/// @nodoc
class _$DownloadEventDto_ProgressCopyWithImpl<$Res>
    implements $DownloadEventDto_ProgressCopyWith<$Res> {
  _$DownloadEventDto_ProgressCopyWithImpl(this._self, this._then);

  final DownloadEventDto_Progress _self;
  final $Res Function(DownloadEventDto_Progress) _then;

/// Create a copy of DownloadEventDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? receivedBytesDecimal = null,Object? totalBytesDecimal = freezed,Object? progress = null,}) {
  return _then(DownloadEventDto_Progress(
receivedBytesDecimal: null == receivedBytesDecimal ? _self.receivedBytesDecimal : receivedBytesDecimal // ignore: cast_nullable_to_non_nullable
as String,totalBytesDecimal: freezed == totalBytesDecimal ? _self.totalBytesDecimal : totalBytesDecimal // ignore: cast_nullable_to_non_nullable
as String?,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class DownloadEventDto_Done extends DownloadEventDto {
  const DownloadEventDto_Done({required this.path}): super._();


 final  String path;

/// Create a copy of DownloadEventDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DownloadEventDto_DoneCopyWith<DownloadEventDto_Done> get copyWith => _$DownloadEventDto_DoneCopyWithImpl<DownloadEventDto_Done>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadEventDto_Done&&(identical(other.path, path) || other.path == path));
}


@override
int get hashCode => Object.hash(runtimeType,path);

@override
String toString() {
  return 'DownloadEventDto.done(path: $path)';
}


}

/// @nodoc
abstract mixin class $DownloadEventDto_DoneCopyWith<$Res> implements $DownloadEventDtoCopyWith<$Res> {
  factory $DownloadEventDto_DoneCopyWith(DownloadEventDto_Done value, $Res Function(DownloadEventDto_Done) _then) = _$DownloadEventDto_DoneCopyWithImpl;
@useResult
$Res call({
 String path
});




}
/// @nodoc
class _$DownloadEventDto_DoneCopyWithImpl<$Res>
    implements $DownloadEventDto_DoneCopyWith<$Res> {
  _$DownloadEventDto_DoneCopyWithImpl(this._self, this._then);

  final DownloadEventDto_Done _self;
  final $Res Function(DownloadEventDto_Done) _then;

/// Create a copy of DownloadEventDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? path = null,}) {
  return _then(DownloadEventDto_Done(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$MediaFetchEventDto {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MediaFetchEventDto);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MediaFetchEventDto()';
}


}

/// @nodoc
class $MediaFetchEventDtoCopyWith<$Res>  {
$MediaFetchEventDtoCopyWith(MediaFetchEventDto _, $Res Function(MediaFetchEventDto) __);
}


/// Adds pattern-matching-related methods to [MediaFetchEventDto].
extension MediaFetchEventDtoPatterns on MediaFetchEventDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( MediaFetchEventDto_Failed value)?  failed,TResult Function( MediaFetchEventDto_Chunk value)?  chunk,required TResult orElse(),}){
final _that = this;
switch (_that) {
case MediaFetchEventDto_Failed() when failed != null:
return failed(_that);case MediaFetchEventDto_Chunk() when chunk != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( MediaFetchEventDto_Failed value)  failed,required TResult Function( MediaFetchEventDto_Chunk value)  chunk,}){
final _that = this;
switch (_that) {
case MediaFetchEventDto_Failed():
return failed(_that);case MediaFetchEventDto_Chunk():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( MediaFetchEventDto_Failed value)?  failed,TResult? Function( MediaFetchEventDto_Chunk value)?  chunk,}){
final _that = this;
switch (_that) {
case MediaFetchEventDto_Failed() when failed != null:
return failed(_that);case MediaFetchEventDto_Chunk() when chunk != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( BooruErrorDto error)?  failed,TResult Function( Uint8List bytes,  String receivedBytesDecimal,  String? totalBytesDecimal)?  chunk,required TResult orElse(),}) {final _that = this;
switch (_that) {
case MediaFetchEventDto_Failed() when failed != null:
return failed(_that.error);case MediaFetchEventDto_Chunk() when chunk != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( BooruErrorDto error)  failed,required TResult Function( Uint8List bytes,  String receivedBytesDecimal,  String? totalBytesDecimal)  chunk,}) {final _that = this;
switch (_that) {
case MediaFetchEventDto_Failed():
return failed(_that.error);case MediaFetchEventDto_Chunk():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( BooruErrorDto error)?  failed,TResult? Function( Uint8List bytes,  String receivedBytesDecimal,  String? totalBytesDecimal)?  chunk,}) {final _that = this;
switch (_that) {
case MediaFetchEventDto_Failed() when failed != null:
return failed(_that.error);case MediaFetchEventDto_Chunk() when chunk != null:
return chunk(_that.bytes,_that.receivedBytesDecimal,_that.totalBytesDecimal);case _:
  return null;

}
}

}

/// @nodoc


class MediaFetchEventDto_Failed extends MediaFetchEventDto {
  const MediaFetchEventDto_Failed({required this.error}): super._();


 final  BooruErrorDto error;

/// Create a copy of MediaFetchEventDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MediaFetchEventDto_FailedCopyWith<MediaFetchEventDto_Failed> get copyWith => _$MediaFetchEventDto_FailedCopyWithImpl<MediaFetchEventDto_Failed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MediaFetchEventDto_Failed&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,error);

@override
String toString() {
  return 'MediaFetchEventDto.failed(error: $error)';
}


}

/// @nodoc
abstract mixin class $MediaFetchEventDto_FailedCopyWith<$Res> implements $MediaFetchEventDtoCopyWith<$Res> {
  factory $MediaFetchEventDto_FailedCopyWith(MediaFetchEventDto_Failed value, $Res Function(MediaFetchEventDto_Failed) _then) = _$MediaFetchEventDto_FailedCopyWithImpl;
@useResult
$Res call({
 BooruErrorDto error
});




}
/// @nodoc
class _$MediaFetchEventDto_FailedCopyWithImpl<$Res>
    implements $MediaFetchEventDto_FailedCopyWith<$Res> {
  _$MediaFetchEventDto_FailedCopyWithImpl(this._self, this._then);

  final MediaFetchEventDto_Failed _self;
  final $Res Function(MediaFetchEventDto_Failed) _then;

/// Create a copy of MediaFetchEventDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(MediaFetchEventDto_Failed(
error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as BooruErrorDto,
  ));
}


}

/// @nodoc


class MediaFetchEventDto_Chunk extends MediaFetchEventDto {
  const MediaFetchEventDto_Chunk({required this.bytes, required this.receivedBytesDecimal, this.totalBytesDecimal}): super._();


 final  Uint8List bytes;
 final  String receivedBytesDecimal;
 final  String? totalBytesDecimal;

/// Create a copy of MediaFetchEventDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MediaFetchEventDto_ChunkCopyWith<MediaFetchEventDto_Chunk> get copyWith => _$MediaFetchEventDto_ChunkCopyWithImpl<MediaFetchEventDto_Chunk>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MediaFetchEventDto_Chunk&&const DeepCollectionEquality().equals(other.bytes, bytes)&&(identical(other.receivedBytesDecimal, receivedBytesDecimal) || other.receivedBytesDecimal == receivedBytesDecimal)&&(identical(other.totalBytesDecimal, totalBytesDecimal) || other.totalBytesDecimal == totalBytesDecimal));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(bytes),receivedBytesDecimal,totalBytesDecimal);

@override
String toString() {
  return 'MediaFetchEventDto.chunk(bytes: $bytes, receivedBytesDecimal: $receivedBytesDecimal, totalBytesDecimal: $totalBytesDecimal)';
}


}

/// @nodoc
abstract mixin class $MediaFetchEventDto_ChunkCopyWith<$Res> implements $MediaFetchEventDtoCopyWith<$Res> {
  factory $MediaFetchEventDto_ChunkCopyWith(MediaFetchEventDto_Chunk value, $Res Function(MediaFetchEventDto_Chunk) _then) = _$MediaFetchEventDto_ChunkCopyWithImpl;
@useResult
$Res call({
 Uint8List bytes, String receivedBytesDecimal, String? totalBytesDecimal
});




}
/// @nodoc
class _$MediaFetchEventDto_ChunkCopyWithImpl<$Res>
    implements $MediaFetchEventDto_ChunkCopyWith<$Res> {
  _$MediaFetchEventDto_ChunkCopyWithImpl(this._self, this._then);

  final MediaFetchEventDto_Chunk _self;
  final $Res Function(MediaFetchEventDto_Chunk) _then;

/// Create a copy of MediaFetchEventDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? bytes = null,Object? receivedBytesDecimal = null,Object? totalBytesDecimal = freezed,}) {
  return _then(MediaFetchEventDto_Chunk(
bytes: null == bytes ? _self.bytes : bytes // ignore: cast_nullable_to_non_nullable
as Uint8List,receivedBytesDecimal: null == receivedBytesDecimal ? _self.receivedBytesDecimal : receivedBytesDecimal // ignore: cast_nullable_to_non_nullable
as String,totalBytesDecimal: freezed == totalBytesDecimal ? _self.totalBytesDecimal : totalBytesDecimal // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
