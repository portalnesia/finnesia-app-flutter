// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transport.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TransportRequest {

 HttpMethod get method; String get path; Map<String, String> get headers;/// Already encoded (JSON text). The client sets `Content-Type`.
 String? get body;
/// Create a copy of TransportRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransportRequestCopyWith<TransportRequest> get copyWith => _$TransportRequestCopyWithImpl<TransportRequest>(this as TransportRequest, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TransportRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransportRequest&&(identical(other.method, _this.method) || other.method == _this.method)&&(identical(other.path, _this.path) || other.path == _this.path)&&const DeepCollectionEquality().equals(other.headers, _this.headers)&&(identical(other.body, _this.body) || other.body == _this.body));
}


@override
int get hashCode {
  final _this = this as TransportRequest;
  return Object.hash(runtimeType,_this.method,_this.path,const DeepCollectionEquality().hash(_this.headers),_this.body);
}

@override
String toString() {
  final _this = this as TransportRequest;
  return 'TransportRequest(method: ${_this.method}, path: ${_this.path}, headers: ${_this.headers}, body: ${_this.body})';
}


}

/// @nodoc
abstract mixin class $TransportRequestCopyWith<$Res>  {
  factory $TransportRequestCopyWith(TransportRequest value, $Res Function(TransportRequest) _then) = _$TransportRequestCopyWithImpl;
@useResult
$Res call({
 HttpMethod method, String path, Map<String, String> headers, String? body
});




}
/// @nodoc
class _$TransportRequestCopyWithImpl<$Res>
    implements $TransportRequestCopyWith<$Res> {
  _$TransportRequestCopyWithImpl(this._self, this._then);

  final TransportRequest _self;
  final $Res Function(TransportRequest) _then;

/// Create a copy of TransportRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? method = null,Object? path = null,Object? headers = null,Object? body = freezed,}) {
  return _then(TransportRequest(
method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as HttpMethod,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,headers: null == headers ? _self.headers : headers // ignore: cast_nullable_to_non_nullable
as Map<String, String>,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TransportRequest].
extension TransportRequestPatterns on TransportRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransportRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransportRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransportRequest value)  $default,){
final _that = this;
switch (_that) {
case _TransportRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransportRequest value)?  $default,){
final _that = this;
switch (_that) {
case _TransportRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( HttpMethod method,  String path,  Map<String, String> headers,  String? body)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransportRequest() when $default != null:
return $default(_that.method,_that.path,_that.headers,_that.body);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( HttpMethod method,  String path,  Map<String, String> headers,  String? body)  $default,) {final _that = this;
switch (_that) {
case _TransportRequest():
return $default(_that.method,_that.path,_that.headers,_that.body);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( HttpMethod method,  String path,  Map<String, String> headers,  String? body)?  $default,) {final _that = this;
switch (_that) {
case _TransportRequest() when $default != null:
return $default(_that.method,_that.path,_that.headers,_that.body);case _:
  return null;

}
}

}

/// @nodoc


class _TransportRequest implements TransportRequest {
  const _TransportRequest({required this.method, required this.path,  Map<String, String> headers = const <String, String>{}, this.body}): _headers = headers;
  

@override final  HttpMethod method;
@override final  String path;
 final  Map<String, String> _headers;
@override@JsonKey() Map<String, String> get headers {
  if (_headers is EqualUnmodifiableMapView) return _headers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_headers);
}

/// Already encoded (JSON text). The client sets `Content-Type`.
@override final  String? body;

/// Create a copy of TransportRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransportRequestCopyWith<_TransportRequest> get copyWith => __$TransportRequestCopyWithImpl<_TransportRequest>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransportRequest&&(identical(other.method, method) || other.method == method)&&(identical(other.path, path) || other.path == path)&&const DeepCollectionEquality().equals(other.headers, _headers)&&(identical(other.body, body) || other.body == body));
}


@override
int get hashCode {
    return Object.hash(runtimeType,method,path,const DeepCollectionEquality().hash(_headers),body);
}

@override
String toString() {
    return 'TransportRequest(method: $method, path: $path, headers: $headers, body: $body)';
}


}

/// @nodoc
abstract mixin class _$TransportRequestCopyWith<$Res> implements $TransportRequestCopyWith<$Res> {
  factory _$TransportRequestCopyWith(_TransportRequest value, $Res Function(_TransportRequest) _then) = __$TransportRequestCopyWithImpl;
@override @useResult
$Res call({
 HttpMethod method, String path, Map<String, String> headers, String? body
});




}
/// @nodoc
class __$TransportRequestCopyWithImpl<$Res>
    implements _$TransportRequestCopyWith<$Res> {
  __$TransportRequestCopyWithImpl(this._self, this._then);

  final _TransportRequest _self;
  final $Res Function(_TransportRequest) _then;

/// Create a copy of TransportRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? method = null,Object? path = null,Object? headers = null,Object? body = freezed,}) {
  return _then(_TransportRequest(
method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as HttpMethod,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,headers: null == headers ? _self._headers : headers // ignore: cast_nullable_to_non_nullable
as Map<String, String>,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
