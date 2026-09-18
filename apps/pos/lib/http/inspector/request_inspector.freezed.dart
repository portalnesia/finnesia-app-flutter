// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'request_inspector.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InspectedRequest {

 String get method; String get url; Map<String, String> get requestHeaders; Object? get requestBody; DateTime get at; int? get statusCode; Map<String, String>? get responseHeaders; Object? get responseBody; Duration? get duration;/// What went wrong, as a short code (`connectionTimeout`, `badResponse`). Not the
/// exception's own text: that can carry the URL, and a URL can carry a search term.
 String? get error;
/// Create a copy of InspectedRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InspectedRequestCopyWith<InspectedRequest> get copyWith => _$InspectedRequestCopyWithImpl<InspectedRequest>(this as InspectedRequest, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as InspectedRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InspectedRequest&&(identical(other.method, _this.method) || other.method == _this.method)&&(identical(other.url, _this.url) || other.url == _this.url)&&const DeepCollectionEquality().equals(other.requestHeaders, _this.requestHeaders)&&const DeepCollectionEquality().equals(other.requestBody, _this.requestBody)&&(identical(other.at, _this.at) || other.at == _this.at)&&(identical(other.statusCode, _this.statusCode) || other.statusCode == _this.statusCode)&&const DeepCollectionEquality().equals(other.responseHeaders, _this.responseHeaders)&&const DeepCollectionEquality().equals(other.responseBody, _this.responseBody)&&(identical(other.duration, _this.duration) || other.duration == _this.duration)&&(identical(other.error, _this.error) || other.error == _this.error));
}


@override
int get hashCode {
  final _this = this as InspectedRequest;
  return Object.hash(runtimeType,_this.method,_this.url,const DeepCollectionEquality().hash(_this.requestHeaders),const DeepCollectionEquality().hash(_this.requestBody),_this.at,_this.statusCode,const DeepCollectionEquality().hash(_this.responseHeaders),const DeepCollectionEquality().hash(_this.responseBody),_this.duration,_this.error);
}

@override
String toString() {
  final _this = this as InspectedRequest;
  return 'InspectedRequest(method: ${_this.method}, url: ${_this.url}, requestHeaders: ${_this.requestHeaders}, requestBody: ${_this.requestBody}, at: ${_this.at}, statusCode: ${_this.statusCode}, responseHeaders: ${_this.responseHeaders}, responseBody: ${_this.responseBody}, duration: ${_this.duration}, error: ${_this.error})';
}


}

/// @nodoc
abstract mixin class $InspectedRequestCopyWith<$Res>  {
  factory $InspectedRequestCopyWith(InspectedRequest value, $Res Function(InspectedRequest) _then) = _$InspectedRequestCopyWithImpl;
@useResult
$Res call({
 String method, String url, Map<String, String> requestHeaders, Object? requestBody, DateTime at, int? statusCode, Map<String, String>? responseHeaders, Object? responseBody, Duration? duration, String? error
});




}
/// @nodoc
class _$InspectedRequestCopyWithImpl<$Res>
    implements $InspectedRequestCopyWith<$Res> {
  _$InspectedRequestCopyWithImpl(this._self, this._then);

  final InspectedRequest _self;
  final $Res Function(InspectedRequest) _then;

/// Create a copy of InspectedRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? method = null,Object? url = null,Object? requestHeaders = null,Object? requestBody = freezed,Object? at = null,Object? statusCode = freezed,Object? responseHeaders = freezed,Object? responseBody = freezed,Object? duration = freezed,Object? error = freezed,}) {
  return _then(InspectedRequest(
method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,requestHeaders: null == requestHeaders ? _self.requestHeaders : requestHeaders // ignore: cast_nullable_to_non_nullable
as Map<String, String>,requestBody: freezed == requestBody ? _self.requestBody : requestBody ,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,statusCode: freezed == statusCode ? _self.statusCode : statusCode // ignore: cast_nullable_to_non_nullable
as int?,responseHeaders: freezed == responseHeaders ? _self.responseHeaders : responseHeaders // ignore: cast_nullable_to_non_nullable
as Map<String, String>?,responseBody: freezed == responseBody ? _self.responseBody : responseBody ,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [InspectedRequest].
extension InspectedRequestPatterns on InspectedRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InspectedRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InspectedRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InspectedRequest value)  $default,){
final _that = this;
switch (_that) {
case _InspectedRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InspectedRequest value)?  $default,){
final _that = this;
switch (_that) {
case _InspectedRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String method,  String url,  Map<String, String> requestHeaders,  Object? requestBody,  DateTime at,  int? statusCode,  Map<String, String>? responseHeaders,  Object? responseBody,  Duration? duration,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InspectedRequest() when $default != null:
return $default(_that.method,_that.url,_that.requestHeaders,_that.requestBody,_that.at,_that.statusCode,_that.responseHeaders,_that.responseBody,_that.duration,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String method,  String url,  Map<String, String> requestHeaders,  Object? requestBody,  DateTime at,  int? statusCode,  Map<String, String>? responseHeaders,  Object? responseBody,  Duration? duration,  String? error)  $default,) {final _that = this;
switch (_that) {
case _InspectedRequest():
return $default(_that.method,_that.url,_that.requestHeaders,_that.requestBody,_that.at,_that.statusCode,_that.responseHeaders,_that.responseBody,_that.duration,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String method,  String url,  Map<String, String> requestHeaders,  Object? requestBody,  DateTime at,  int? statusCode,  Map<String, String>? responseHeaders,  Object? responseBody,  Duration? duration,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _InspectedRequest() when $default != null:
return $default(_that.method,_that.url,_that.requestHeaders,_that.requestBody,_that.at,_that.statusCode,_that.responseHeaders,_that.responseBody,_that.duration,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _InspectedRequest implements InspectedRequest {
  const _InspectedRequest({required this.method, required this.url, required  Map<String, String> requestHeaders, required this.requestBody, required this.at, this.statusCode,  Map<String, String>? responseHeaders, this.responseBody, this.duration, this.error}): _requestHeaders = requestHeaders,_responseHeaders = responseHeaders;
  

@override final  String method;
@override final  String url;
 final  Map<String, String> _requestHeaders;
@override Map<String, String> get requestHeaders {
  if (_requestHeaders is EqualUnmodifiableMapView) return _requestHeaders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_requestHeaders);
}

@override final  Object? requestBody;
@override final  DateTime at;
@override final  int? statusCode;
 final  Map<String, String>? _responseHeaders;
@override Map<String, String>? get responseHeaders {
  final value = _responseHeaders;
  if (value == null) return null;
  if (_responseHeaders is EqualUnmodifiableMapView) return _responseHeaders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  Object? responseBody;
@override final  Duration? duration;
/// What went wrong, as a short code (`connectionTimeout`, `badResponse`). Not the
/// exception's own text: that can carry the URL, and a URL can carry a search term.
@override final  String? error;

/// Create a copy of InspectedRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InspectedRequestCopyWith<_InspectedRequest> get copyWith => __$InspectedRequestCopyWithImpl<_InspectedRequest>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InspectedRequest&&(identical(other.method, method) || other.method == method)&&(identical(other.url, url) || other.url == url)&&const DeepCollectionEquality().equals(other.requestHeaders, _requestHeaders)&&const DeepCollectionEquality().equals(other.requestBody, requestBody)&&(identical(other.at, at) || other.at == at)&&(identical(other.statusCode, statusCode) || other.statusCode == statusCode)&&const DeepCollectionEquality().equals(other.responseHeaders, _responseHeaders)&&const DeepCollectionEquality().equals(other.responseBody, responseBody)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode {
    return Object.hash(runtimeType,method,url,const DeepCollectionEquality().hash(_requestHeaders),const DeepCollectionEquality().hash(requestBody),at,statusCode,const DeepCollectionEquality().hash(_responseHeaders),const DeepCollectionEquality().hash(responseBody),duration,error);
}

@override
String toString() {
    return 'InspectedRequest(method: $method, url: $url, requestHeaders: $requestHeaders, requestBody: $requestBody, at: $at, statusCode: $statusCode, responseHeaders: $responseHeaders, responseBody: $responseBody, duration: $duration, error: $error)';
}


}

/// @nodoc
abstract mixin class _$InspectedRequestCopyWith<$Res> implements $InspectedRequestCopyWith<$Res> {
  factory _$InspectedRequestCopyWith(_InspectedRequest value, $Res Function(_InspectedRequest) _then) = __$InspectedRequestCopyWithImpl;
@override @useResult
$Res call({
 String method, String url, Map<String, String> requestHeaders, Object? requestBody, DateTime at, int? statusCode, Map<String, String>? responseHeaders, Object? responseBody, Duration? duration, String? error
});




}
/// @nodoc
class __$InspectedRequestCopyWithImpl<$Res>
    implements _$InspectedRequestCopyWith<$Res> {
  __$InspectedRequestCopyWithImpl(this._self, this._then);

  final _InspectedRequest _self;
  final $Res Function(_InspectedRequest) _then;

/// Create a copy of InspectedRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? method = null,Object? url = null,Object? requestHeaders = null,Object? requestBody = freezed,Object? at = null,Object? statusCode = freezed,Object? responseHeaders = freezed,Object? responseBody = freezed,Object? duration = freezed,Object? error = freezed,}) {
  return _then(_InspectedRequest(
method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,requestHeaders: null == requestHeaders ? _self._requestHeaders : requestHeaders // ignore: cast_nullable_to_non_nullable
as Map<String, String>,requestBody: freezed == requestBody ? _self.requestBody : requestBody ,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,statusCode: freezed == statusCode ? _self.statusCode : statusCode // ignore: cast_nullable_to_non_nullable
as int?,responseHeaders: freezed == responseHeaders ? _self._responseHeaders : responseHeaders // ignore: cast_nullable_to_non_nullable
as Map<String, String>?,responseBody: freezed == responseBody ? _self.responseBody : responseBody ,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
