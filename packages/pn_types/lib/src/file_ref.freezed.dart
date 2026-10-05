// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'file_ref.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FileRef {

@JsonKey(fromJson: _asString) String get id;@JsonKey(fromJson: _asNullableString) String? get name;/// One of `pending | attached | detached | deleting`, kept a plain string: an unknown
/// value from a newer API has to mean "do not render", not a parse failure.
@JsonKey(fromJson: _asString) String get status;@JsonKey(fromJson: _asString) String get url;
/// Create a copy of FileRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FileRefCopyWith<FileRef> get copyWith => _$FileRefCopyWithImpl<FileRef>(this as FileRef, _$identity);

  /// Serializes this FileRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as FileRef;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileRef&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.url, _this.url) || other.url == _this.url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FileRef;
  return Object.hash(runtimeType,_this.id,_this.name,_this.status,_this.url);
}

@override
String toString() {
  final _this = this as FileRef;
  return 'FileRef(id: ${_this.id}, name: ${_this.name}, status: ${_this.status}, url: ${_this.url})';
}


}

/// @nodoc
abstract mixin class $FileRefCopyWith<$Res>  {
  factory $FileRefCopyWith(FileRef value, $Res Function(FileRef) _then) = _$FileRefCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: _asString) String id,@JsonKey(fromJson: _asNullableString) String? name,@JsonKey(fromJson: _asString) String status,@JsonKey(fromJson: _asString) String url
});




}
/// @nodoc
class _$FileRefCopyWithImpl<$Res>
    implements $FileRefCopyWith<$Res> {
  _$FileRefCopyWithImpl(this._self, this._then);

  final FileRef _self;
  final $Res Function(FileRef) _then;

/// Create a copy of FileRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = freezed,Object? status = null,Object? url = null,}) {
  return _then(FileRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FileRef].
extension FileRefPatterns on FileRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FileRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FileRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FileRef value)  $default,){
final _that = this;
switch (_that) {
case _FileRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FileRef value)?  $default,){
final _that = this;
switch (_that) {
case _FileRef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: _asString)  String id, @JsonKey(fromJson: _asNullableString)  String? name, @JsonKey(fromJson: _asString)  String status, @JsonKey(fromJson: _asString)  String url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FileRef() when $default != null:
return $default(_that.id,_that.name,_that.status,_that.url);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: _asString)  String id, @JsonKey(fromJson: _asNullableString)  String? name, @JsonKey(fromJson: _asString)  String status, @JsonKey(fromJson: _asString)  String url)  $default,) {final _that = this;
switch (_that) {
case _FileRef():
return $default(_that.id,_that.name,_that.status,_that.url);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: _asString)  String id, @JsonKey(fromJson: _asNullableString)  String? name, @JsonKey(fromJson: _asString)  String status, @JsonKey(fromJson: _asString)  String url)?  $default,) {final _that = this;
switch (_that) {
case _FileRef() when $default != null:
return $default(_that.id,_that.name,_that.status,_that.url);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FileRef extends FileRef {
  const _FileRef({@JsonKey(fromJson: _asString) this.id = '', @JsonKey(fromJson: _asNullableString) this.name, @JsonKey(fromJson: _asString) this.status = '', @JsonKey(fromJson: _asString) this.url = ''}): super._();
  factory _FileRef.fromJson(Map<String, dynamic> json) => _$FileRefFromJson(json);

@override@JsonKey(fromJson: _asString) final  String id;
@override@JsonKey(fromJson: _asNullableString) final  String? name;
/// One of `pending | attached | detached | deleting`, kept a plain string: an unknown
/// value from a newer API has to mean "do not render", not a parse failure.
@override@JsonKey(fromJson: _asString) final  String status;
@override@JsonKey(fromJson: _asString) final  String url;

/// Create a copy of FileRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FileRefCopyWith<_FileRef> get copyWith => __$FileRefCopyWithImpl<_FileRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FileRefToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FileRef&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.status, status) || other.status == status)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,status,url);
}

@override
String toString() {
    return 'FileRef(id: $id, name: $name, status: $status, url: $url)';
}


}

/// @nodoc
abstract mixin class _$FileRefCopyWith<$Res> implements $FileRefCopyWith<$Res> {
  factory _$FileRefCopyWith(_FileRef value, $Res Function(_FileRef) _then) = __$FileRefCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: _asString) String id,@JsonKey(fromJson: _asNullableString) String? name,@JsonKey(fromJson: _asString) String status,@JsonKey(fromJson: _asString) String url
});




}
/// @nodoc
class __$FileRefCopyWithImpl<$Res>
    implements _$FileRefCopyWith<$Res> {
  __$FileRefCopyWithImpl(this._self, this._then);

  final _FileRef _self;
  final $Res Function(_FileRef) _then;

/// Create a copy of FileRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,Object? status = null,Object? url = null,}) {
  return _then(_FileRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
