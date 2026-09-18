// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api_error.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ApiErrorDetail {

/// The form field the message belongs to. Unset when the error names a record.
 String? get field;/// The document the detail points at, when the error names a blocking record rather
/// than a form field. A `document_settled` rejection lists the payments and returns
/// that already settled the document, so the message carries a document number the
/// user can open. Plain validation errors leave it unset and stay plain text.
 String? get id; String get message;
/// Create a copy of ApiErrorDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiErrorDetailCopyWith<ApiErrorDetail> get copyWith => _$ApiErrorDetailCopyWithImpl<ApiErrorDetail>(this as ApiErrorDetail, _$identity);

  /// Serializes this ApiErrorDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ApiErrorDetail;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiErrorDetail&&(identical(other.field, _this.field) || other.field == _this.field)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.message, _this.message) || other.message == _this.message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ApiErrorDetail;
  return Object.hash(runtimeType,_this.field,_this.id,_this.message);
}

@override
String toString() {
  final _this = this as ApiErrorDetail;
  return 'ApiErrorDetail(field: ${_this.field}, id: ${_this.id}, message: ${_this.message})';
}


}

/// @nodoc
abstract mixin class $ApiErrorDetailCopyWith<$Res>  {
  factory $ApiErrorDetailCopyWith(ApiErrorDetail value, $Res Function(ApiErrorDetail) _then) = _$ApiErrorDetailCopyWithImpl;
@useResult
$Res call({
 String? field, String? id, String message
});




}
/// @nodoc
class _$ApiErrorDetailCopyWithImpl<$Res>
    implements $ApiErrorDetailCopyWith<$Res> {
  _$ApiErrorDetailCopyWithImpl(this._self, this._then);

  final ApiErrorDetail _self;
  final $Res Function(ApiErrorDetail) _then;

/// Create a copy of ApiErrorDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? field = freezed,Object? id = freezed,Object? message = null,}) {
  return _then(ApiErrorDetail(
field: freezed == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as String?,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ApiErrorDetail].
extension ApiErrorDetailPatterns on ApiErrorDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ApiErrorDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ApiErrorDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ApiErrorDetail value)  $default,){
final _that = this;
switch (_that) {
case _ApiErrorDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ApiErrorDetail value)?  $default,){
final _that = this;
switch (_that) {
case _ApiErrorDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? field,  String? id,  String message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ApiErrorDetail() when $default != null:
return $default(_that.field,_that.id,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? field,  String? id,  String message)  $default,) {final _that = this;
switch (_that) {
case _ApiErrorDetail():
return $default(_that.field,_that.id,_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? field,  String? id,  String message)?  $default,) {final _that = this;
switch (_that) {
case _ApiErrorDetail() when $default != null:
return $default(_that.field,_that.id,_that.message);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ApiErrorDetail implements ApiErrorDetail {
  const _ApiErrorDetail({this.field, this.id, required this.message});
  factory _ApiErrorDetail.fromJson(Map<String, dynamic> json) => _$ApiErrorDetailFromJson(json);

/// The form field the message belongs to. Unset when the error names a record.
@override final  String? field;
/// The document the detail points at, when the error names a blocking record rather
/// than a form field. A `document_settled` rejection lists the payments and returns
/// that already settled the document, so the message carries a document number the
/// user can open. Plain validation errors leave it unset and stay plain text.
@override final  String? id;
@override final  String message;

/// Create a copy of ApiErrorDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApiErrorDetailCopyWith<_ApiErrorDetail> get copyWith => __$ApiErrorDetailCopyWithImpl<_ApiErrorDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ApiErrorDetailToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApiErrorDetail&&(identical(other.field, field) || other.field == field)&&(identical(other.id, id) || other.id == id)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,field,id,message);
}

@override
String toString() {
    return 'ApiErrorDetail(field: $field, id: $id, message: $message)';
}


}

/// @nodoc
abstract mixin class _$ApiErrorDetailCopyWith<$Res> implements $ApiErrorDetailCopyWith<$Res> {
  factory _$ApiErrorDetailCopyWith(_ApiErrorDetail value, $Res Function(_ApiErrorDetail) _then) = __$ApiErrorDetailCopyWithImpl;
@override @useResult
$Res call({
 String? field, String? id, String message
});




}
/// @nodoc
class __$ApiErrorDetailCopyWithImpl<$Res>
    implements _$ApiErrorDetailCopyWith<$Res> {
  __$ApiErrorDetailCopyWithImpl(this._self, this._then);

  final _ApiErrorDetail _self;
  final $Res Function(_ApiErrorDetail) _then;

/// Create a copy of ApiErrorDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? field = freezed,Object? id = freezed,Object? message = null,}) {
  return _then(_ApiErrorDetail(
field: freezed == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as String?,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ApiErrorTypes {

 String? get name; int? get code; String? get message; String? get description; List<ApiErrorDetail>? get details;/// The i18n key the server used to build [description], e.g. `pos_device_unregistered`.
///
/// The one machine-readable part of an error. [code] cannot stand in for it: 422/720 is
/// shared by the device limit and six unrelated Postgres conditions.
///
/// Absent against a backend that predates it — see `plan/pos-device-registry/`
/// `02-kebutuhan-error-key.md`.
 String? get key;/// The values interpolated into [description], e.g. `{'limit': 10}`.
 Map<String, dynamic>? get params;
/// Create a copy of ApiErrorTypes
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiErrorTypesCopyWith<ApiErrorTypes> get copyWith => _$ApiErrorTypesCopyWithImpl<ApiErrorTypes>(this as ApiErrorTypes, _$identity);

  /// Serializes this ApiErrorTypes to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ApiErrorTypes;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiErrorTypes&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.code, _this.code) || other.code == _this.code)&&(identical(other.message, _this.message) || other.message == _this.message)&&(identical(other.description, _this.description) || other.description == _this.description)&&const DeepCollectionEquality().equals(other.details, _this.details)&&(identical(other.key, _this.key) || other.key == _this.key)&&const DeepCollectionEquality().equals(other.params, _this.params));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ApiErrorTypes;
  return Object.hash(runtimeType,_this.name,_this.code,_this.message,_this.description,const DeepCollectionEquality().hash(_this.details),_this.key,const DeepCollectionEquality().hash(_this.params));
}

@override
String toString() {
  final _this = this as ApiErrorTypes;
  return 'ApiErrorTypes(name: ${_this.name}, code: ${_this.code}, message: ${_this.message}, description: ${_this.description}, details: ${_this.details}, key: ${_this.key}, params: ${_this.params})';
}


}

/// @nodoc
abstract mixin class $ApiErrorTypesCopyWith<$Res>  {
  factory $ApiErrorTypesCopyWith(ApiErrorTypes value, $Res Function(ApiErrorTypes) _then) = _$ApiErrorTypesCopyWithImpl;
@useResult
$Res call({
 String? name, int? code, String? message, String? description, List<ApiErrorDetail>? details, String? key, Map<String, dynamic>? params
});




}
/// @nodoc
class _$ApiErrorTypesCopyWithImpl<$Res>
    implements $ApiErrorTypesCopyWith<$Res> {
  _$ApiErrorTypesCopyWithImpl(this._self, this._then);

  final ApiErrorTypes _self;
  final $Res Function(ApiErrorTypes) _then;

/// Create a copy of ApiErrorTypes
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = freezed,Object? code = freezed,Object? message = freezed,Object? description = freezed,Object? details = freezed,Object? key = freezed,Object? params = freezed,}) {
  return _then(ApiErrorTypes(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as List<ApiErrorDetail>?,key: freezed == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String?,params: freezed == params ? _self.params : params // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [ApiErrorTypes].
extension ApiErrorTypesPatterns on ApiErrorTypes {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ApiErrorTypes value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ApiErrorTypes() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ApiErrorTypes value)  $default,){
final _that = this;
switch (_that) {
case _ApiErrorTypes():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ApiErrorTypes value)?  $default,){
final _that = this;
switch (_that) {
case _ApiErrorTypes() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? name,  int? code,  String? message,  String? description,  List<ApiErrorDetail>? details,  String? key,  Map<String, dynamic>? params)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ApiErrorTypes() when $default != null:
return $default(_that.name,_that.code,_that.message,_that.description,_that.details,_that.key,_that.params);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? name,  int? code,  String? message,  String? description,  List<ApiErrorDetail>? details,  String? key,  Map<String, dynamic>? params)  $default,) {final _that = this;
switch (_that) {
case _ApiErrorTypes():
return $default(_that.name,_that.code,_that.message,_that.description,_that.details,_that.key,_that.params);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? name,  int? code,  String? message,  String? description,  List<ApiErrorDetail>? details,  String? key,  Map<String, dynamic>? params)?  $default,) {final _that = this;
switch (_that) {
case _ApiErrorTypes() when $default != null:
return $default(_that.name,_that.code,_that.message,_that.description,_that.details,_that.key,_that.params);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ApiErrorTypes implements ApiErrorTypes {
  const _ApiErrorTypes({this.name, this.code, this.message, this.description,  List<ApiErrorDetail>? details, this.key,  Map<String, dynamic>? params}): _details = details,_params = params;
  factory _ApiErrorTypes.fromJson(Map<String, dynamic> json) => _$ApiErrorTypesFromJson(json);

@override final  String? name;
@override final  int? code;
@override final  String? message;
@override final  String? description;
 final  List<ApiErrorDetail>? _details;
@override List<ApiErrorDetail>? get details {
  final value = _details;
  if (value == null) return null;
  if (_details is EqualUnmodifiableListView) return _details;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// The i18n key the server used to build [description], e.g. `pos_device_unregistered`.
///
/// The one machine-readable part of an error. [code] cannot stand in for it: 422/720 is
/// shared by the device limit and six unrelated Postgres conditions.
///
/// Absent against a backend that predates it — see `plan/pos-device-registry/`
/// `02-kebutuhan-error-key.md`.
@override final  String? key;
/// The values interpolated into [description], e.g. `{'limit': 10}`.
 final  Map<String, dynamic>? _params;
/// The values interpolated into [description], e.g. `{'limit': 10}`.
@override Map<String, dynamic>? get params {
  final value = _params;
  if (value == null) return null;
  if (_params is EqualUnmodifiableMapView) return _params;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of ApiErrorTypes
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApiErrorTypesCopyWith<_ApiErrorTypes> get copyWith => __$ApiErrorTypesCopyWithImpl<_ApiErrorTypes>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ApiErrorTypesToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApiErrorTypes&&(identical(other.name, name) || other.name == name)&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.details, _details)&&(identical(other.key, key) || other.key == key)&&const DeepCollectionEquality().equals(other.params, _params));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,code,message,description,const DeepCollectionEquality().hash(_details),key,const DeepCollectionEquality().hash(_params));
}

@override
String toString() {
    return 'ApiErrorTypes(name: $name, code: $code, message: $message, description: $description, details: $details, key: $key, params: $params)';
}


}

/// @nodoc
abstract mixin class _$ApiErrorTypesCopyWith<$Res> implements $ApiErrorTypesCopyWith<$Res> {
  factory _$ApiErrorTypesCopyWith(_ApiErrorTypes value, $Res Function(_ApiErrorTypes) _then) = __$ApiErrorTypesCopyWithImpl;
@override @useResult
$Res call({
 String? name, int? code, String? message, String? description, List<ApiErrorDetail>? details, String? key, Map<String, dynamic>? params
});




}
/// @nodoc
class __$ApiErrorTypesCopyWithImpl<$Res>
    implements _$ApiErrorTypesCopyWith<$Res> {
  __$ApiErrorTypesCopyWithImpl(this._self, this._then);

  final _ApiErrorTypes _self;
  final $Res Function(_ApiErrorTypes) _then;

/// Create a copy of ApiErrorTypes
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = freezed,Object? code = freezed,Object? message = freezed,Object? description = freezed,Object? details = freezed,Object? key = freezed,Object? params = freezed,}) {
  return _then(_ApiErrorTypes(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,details: freezed == details ? _self._details : details // ignore: cast_nullable_to_non_nullable
as List<ApiErrorDetail>?,key: freezed == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String?,params: freezed == params ? _self._params : params // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
