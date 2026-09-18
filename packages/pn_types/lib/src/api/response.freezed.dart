// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PaginationMeta {

@JsonKey(name: 'next_cursor') String? get nextCursor;@JsonKey(name: 'prev_cursor') String? get prevCursor;@JsonKey(name: 'page_size') int? get pageSize; int? get page; int? get total;
/// Create a copy of PaginationMeta
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaginationMetaCopyWith<PaginationMeta> get copyWith => _$PaginationMetaCopyWithImpl<PaginationMeta>(this as PaginationMeta, _$identity);

  /// Serializes this PaginationMeta to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PaginationMeta;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaginationMeta&&(identical(other.nextCursor, _this.nextCursor) || other.nextCursor == _this.nextCursor)&&(identical(other.prevCursor, _this.prevCursor) || other.prevCursor == _this.prevCursor)&&(identical(other.pageSize, _this.pageSize) || other.pageSize == _this.pageSize)&&(identical(other.page, _this.page) || other.page == _this.page)&&(identical(other.total, _this.total) || other.total == _this.total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PaginationMeta;
  return Object.hash(runtimeType,_this.nextCursor,_this.prevCursor,_this.pageSize,_this.page,_this.total);
}

@override
String toString() {
  final _this = this as PaginationMeta;
  return 'PaginationMeta(nextCursor: ${_this.nextCursor}, prevCursor: ${_this.prevCursor}, pageSize: ${_this.pageSize}, page: ${_this.page}, total: ${_this.total})';
}


}

/// @nodoc
abstract mixin class $PaginationMetaCopyWith<$Res>  {
  factory $PaginationMetaCopyWith(PaginationMeta value, $Res Function(PaginationMeta) _then) = _$PaginationMetaCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'next_cursor') String? nextCursor,@JsonKey(name: 'prev_cursor') String? prevCursor,@JsonKey(name: 'page_size') int? pageSize, int? page, int? total
});




}
/// @nodoc
class _$PaginationMetaCopyWithImpl<$Res>
    implements $PaginationMetaCopyWith<$Res> {
  _$PaginationMetaCopyWithImpl(this._self, this._then);

  final PaginationMeta _self;
  final $Res Function(PaginationMeta) _then;

/// Create a copy of PaginationMeta
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? nextCursor = freezed,Object? prevCursor = freezed,Object? pageSize = freezed,Object? page = freezed,Object? total = freezed,}) {
  return _then(PaginationMeta(
nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,prevCursor: freezed == prevCursor ? _self.prevCursor : prevCursor // ignore: cast_nullable_to_non_nullable
as String?,pageSize: freezed == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int?,page: freezed == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int?,total: freezed == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [PaginationMeta].
extension PaginationMetaPatterns on PaginationMeta {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaginationMeta value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaginationMeta() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaginationMeta value)  $default,){
final _that = this;
switch (_that) {
case _PaginationMeta():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaginationMeta value)?  $default,){
final _that = this;
switch (_that) {
case _PaginationMeta() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'next_cursor')  String? nextCursor, @JsonKey(name: 'prev_cursor')  String? prevCursor, @JsonKey(name: 'page_size')  int? pageSize,  int? page,  int? total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaginationMeta() when $default != null:
return $default(_that.nextCursor,_that.prevCursor,_that.pageSize,_that.page,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'next_cursor')  String? nextCursor, @JsonKey(name: 'prev_cursor')  String? prevCursor, @JsonKey(name: 'page_size')  int? pageSize,  int? page,  int? total)  $default,) {final _that = this;
switch (_that) {
case _PaginationMeta():
return $default(_that.nextCursor,_that.prevCursor,_that.pageSize,_that.page,_that.total);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'next_cursor')  String? nextCursor, @JsonKey(name: 'prev_cursor')  String? prevCursor, @JsonKey(name: 'page_size')  int? pageSize,  int? page,  int? total)?  $default,) {final _that = this;
switch (_that) {
case _PaginationMeta() when $default != null:
return $default(_that.nextCursor,_that.prevCursor,_that.pageSize,_that.page,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaginationMeta implements PaginationMeta {
  const _PaginationMeta({@JsonKey(name: 'next_cursor') this.nextCursor, @JsonKey(name: 'prev_cursor') this.prevCursor, @JsonKey(name: 'page_size') this.pageSize, this.page, this.total});
  factory _PaginationMeta.fromJson(Map<String, dynamic> json) => _$PaginationMetaFromJson(json);

@override@JsonKey(name: 'next_cursor') final  String? nextCursor;
@override@JsonKey(name: 'prev_cursor') final  String? prevCursor;
@override@JsonKey(name: 'page_size') final  int? pageSize;
@override final  int? page;
@override final  int? total;

/// Create a copy of PaginationMeta
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaginationMetaCopyWith<_PaginationMeta> get copyWith => __$PaginationMetaCopyWithImpl<_PaginationMeta>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaginationMetaToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaginationMeta&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.prevCursor, prevCursor) || other.prevCursor == prevCursor)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.page, page) || other.page == page)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,nextCursor,prevCursor,pageSize,page,total);
}

@override
String toString() {
    return 'PaginationMeta(nextCursor: $nextCursor, prevCursor: $prevCursor, pageSize: $pageSize, page: $page, total: $total)';
}


}

/// @nodoc
abstract mixin class _$PaginationMetaCopyWith<$Res> implements $PaginationMetaCopyWith<$Res> {
  factory _$PaginationMetaCopyWith(_PaginationMeta value, $Res Function(_PaginationMeta) _then) = __$PaginationMetaCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'next_cursor') String? nextCursor,@JsonKey(name: 'prev_cursor') String? prevCursor,@JsonKey(name: 'page_size') int? pageSize, int? page, int? total
});




}
/// @nodoc
class __$PaginationMetaCopyWithImpl<$Res>
    implements _$PaginationMetaCopyWith<$Res> {
  __$PaginationMetaCopyWithImpl(this._self, this._then);

  final _PaginationMeta _self;
  final $Res Function(_PaginationMeta) _then;

/// Create a copy of PaginationMeta
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? nextCursor = freezed,Object? prevCursor = freezed,Object? pageSize = freezed,Object? page = freezed,Object? total = freezed,}) {
  return _then(_PaginationMeta(
nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,prevCursor: freezed == prevCursor ? _self.prevCursor : prevCursor // ignore: cast_nullable_to_non_nullable
as String?,pageSize: freezed == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int?,page: freezed == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int?,total: freezed == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$ResponseData<R> {

 R get data; ApiErrorTypes? get error; String? get message; PaginationMeta? get meta;
/// Create a copy of ResponseData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResponseDataCopyWith<R, ResponseData<R>> get copyWith => _$ResponseDataCopyWithImpl<R, ResponseData<R>>(this as ResponseData<R>, _$identity);

  /// Serializes this ResponseData to a JSON map.
  Map<String, dynamic> toJson(Object? Function(R) toJsonR);


@override
bool operator ==(Object other) {
  final _this = this as ResponseData<R>;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResponseData<R>&&const DeepCollectionEquality().equals(other.data, _this.data)&&(identical(other.error, _this.error) || other.error == _this.error)&&(identical(other.message, _this.message) || other.message == _this.message)&&(identical(other.meta, _this.meta) || other.meta == _this.meta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ResponseData<R>;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.data),_this.error,_this.message,_this.meta);
}

@override
String toString() {
  final _this = this as ResponseData<R>;
  return 'ResponseData<$R>(data: ${_this.data}, error: ${_this.error}, message: ${_this.message}, meta: ${_this.meta})';
}


}

/// @nodoc
abstract mixin class $ResponseDataCopyWith<R,$Res>  {
  factory $ResponseDataCopyWith(ResponseData<R> value, $Res Function(ResponseData<R>) _then) = _$ResponseDataCopyWithImpl;
@useResult
$Res call({
 R data, ApiErrorTypes? error, String? message, PaginationMeta? meta
});


$ApiErrorTypesCopyWith<$Res>? get error;$PaginationMetaCopyWith<$Res>? get meta;

}
/// @nodoc
class _$ResponseDataCopyWithImpl<R,$Res>
    implements $ResponseDataCopyWith<R, $Res> {
  _$ResponseDataCopyWithImpl(this._self, this._then);

  final ResponseData<R> _self;
  final $Res Function(ResponseData<R>) _then;

/// Create a copy of ResponseData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? data = freezed,Object? error = freezed,Object? message = freezed,Object? meta = freezed,}) {
  return _then(ResponseData(
data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as R,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as ApiErrorTypes?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,meta: freezed == meta ? _self.meta : meta // ignore: cast_nullable_to_non_nullable
as PaginationMeta?,
  ));
}
/// Create a copy of ResponseData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ApiErrorTypesCopyWith<$Res>? get error {
    if (_self.error == null) {
    return null;
  }

  return $ApiErrorTypesCopyWith<$Res>(_self.error!, (value) {
    return _then(_self.copyWith(error: value));
  });
}/// Create a copy of ResponseData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaginationMetaCopyWith<$Res>? get meta {
    if (_self.meta == null) {
    return null;
  }

  return $PaginationMetaCopyWith<$Res>(_self.meta!, (value) {
    return _then(_self.copyWith(meta: value));
  });
}
}


/// Adds pattern-matching-related methods to [ResponseData].
extension ResponseDataPatterns<R> on ResponseData<R> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResponseData<R> value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResponseData() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResponseData<R> value)  $default,){
final _that = this;
switch (_that) {
case _ResponseData():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResponseData<R> value)?  $default,){
final _that = this;
switch (_that) {
case _ResponseData() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( R data,  ApiErrorTypes? error,  String? message,  PaginationMeta? meta)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResponseData() when $default != null:
return $default(_that.data,_that.error,_that.message,_that.meta);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( R data,  ApiErrorTypes? error,  String? message,  PaginationMeta? meta)  $default,) {final _that = this;
switch (_that) {
case _ResponseData():
return $default(_that.data,_that.error,_that.message,_that.meta);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( R data,  ApiErrorTypes? error,  String? message,  PaginationMeta? meta)?  $default,) {final _that = this;
switch (_that) {
case _ResponseData() when $default != null:
return $default(_that.data,_that.error,_that.message,_that.meta);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(genericArgumentFactories: true)

class _ResponseData<R> implements ResponseData<R> {
  const _ResponseData({required this.data, this.error, this.message, this.meta});
  factory _ResponseData.fromJson(Map<String, dynamic> json,R Function(Object?) fromJsonR) => _$ResponseDataFromJson(json,fromJsonR);

@override final  R data;
@override final  ApiErrorTypes? error;
@override final  String? message;
@override final  PaginationMeta? meta;

/// Create a copy of ResponseData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResponseDataCopyWith<R, _ResponseData<R>> get copyWith => __$ResponseDataCopyWithImpl<R, _ResponseData<R>>(this, _$identity);

@override
Map<String, dynamic> toJson(Object? Function(R) toJsonR) {
  return _$ResponseDataToJson<R>(this, toJsonR);
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResponseData<R>&&const DeepCollectionEquality().equals(other.data, data)&&(identical(other.error, error) || other.error == error)&&(identical(other.message, message) || other.message == message)&&(identical(other.meta, meta) || other.meta == meta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(data),error,message,meta);
}

@override
String toString() {
    return 'ResponseData<$R>(data: $data, error: $error, message: $message, meta: $meta)';
}


}

/// @nodoc
abstract mixin class _$ResponseDataCopyWith<R,$Res> implements $ResponseDataCopyWith<R, $Res> {
  factory _$ResponseDataCopyWith(_ResponseData<R> value, $Res Function(_ResponseData<R>) _then) = __$ResponseDataCopyWithImpl;
@override @useResult
$Res call({
 R data, ApiErrorTypes? error, String? message, PaginationMeta? meta
});


@override $ApiErrorTypesCopyWith<$Res>? get error;@override $PaginationMetaCopyWith<$Res>? get meta;

}
/// @nodoc
class __$ResponseDataCopyWithImpl<R,$Res>
    implements _$ResponseDataCopyWith<R, $Res> {
  __$ResponseDataCopyWithImpl(this._self, this._then);

  final _ResponseData<R> _self;
  final $Res Function(_ResponseData<R>) _then;

/// Create a copy of ResponseData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? data = freezed,Object? error = freezed,Object? message = freezed,Object? meta = freezed,}) {
  return _then(_ResponseData<R>(
data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as R,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as ApiErrorTypes?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,meta: freezed == meta ? _self.meta : meta // ignore: cast_nullable_to_non_nullable
as PaginationMeta?,
  ));
}

/// Create a copy of ResponseData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ApiErrorTypesCopyWith<$Res>? get error {
    if (_self.error == null) {
    return null;
  }

  return $ApiErrorTypesCopyWith<$Res>(_self.error!, (value) {
    return _then(_self.copyWith(error: value));
  });
}/// Create a copy of ResponseData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaginationMetaCopyWith<$Res>? get meta {
    if (_self.meta == null) {
    return null;
  }

  return $PaginationMetaCopyWith<$Res>(_self.meta!, (value) {
    return _then(_self.copyWith(meta: value));
  });
}
}

// dart format on
