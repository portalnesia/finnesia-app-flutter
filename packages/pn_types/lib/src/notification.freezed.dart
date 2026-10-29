// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NotificationItemRef {

 String get type; String get id;
/// Create a copy of NotificationItemRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationItemRefCopyWith<NotificationItemRef> get copyWith => _$NotificationItemRefCopyWithImpl<NotificationItemRef>(this as NotificationItemRef, _$identity);

  /// Serializes this NotificationItemRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NotificationItemRef;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationItemRef&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.id, _this.id) || other.id == _this.id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NotificationItemRef;
  return Object.hash(runtimeType,_this.type,_this.id);
}

@override
String toString() {
  final _this = this as NotificationItemRef;
  return 'NotificationItemRef(type: ${_this.type}, id: ${_this.id})';
}


}

/// @nodoc
abstract mixin class $NotificationItemRefCopyWith<$Res>  {
  factory $NotificationItemRefCopyWith(NotificationItemRef value, $Res Function(NotificationItemRef) _then) = _$NotificationItemRefCopyWithImpl;
@useResult
$Res call({
 String type, String id
});




}
/// @nodoc
class _$NotificationItemRefCopyWithImpl<$Res>
    implements $NotificationItemRefCopyWith<$Res> {
  _$NotificationItemRefCopyWithImpl(this._self, this._then);

  final NotificationItemRef _self;
  final $Res Function(NotificationItemRef) _then;

/// Create a copy of NotificationItemRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? id = null,}) {
  return _then(NotificationItemRef(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationItemRef].
extension NotificationItemRefPatterns on NotificationItemRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationItemRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationItemRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationItemRef value)  $default,){
final _that = this;
switch (_that) {
case _NotificationItemRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationItemRef value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationItemRef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  String id)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationItemRef() when $default != null:
return $default(_that.type,_that.id);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  String id)  $default,) {final _that = this;
switch (_that) {
case _NotificationItemRef():
return $default(_that.type,_that.id);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  String id)?  $default,) {final _that = this;
switch (_that) {
case _NotificationItemRef() when $default != null:
return $default(_that.type,_that.id);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationItemRef implements NotificationItemRef {
  const _NotificationItemRef({required this.type, required this.id});
  factory _NotificationItemRef.fromJson(Map<String, dynamic> json) => _$NotificationItemRefFromJson(json);

@override final  String type;
@override final  String id;

/// Create a copy of NotificationItemRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationItemRefCopyWith<_NotificationItemRef> get copyWith => __$NotificationItemRefCopyWithImpl<_NotificationItemRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationItemRefToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationItemRef&&(identical(other.type, type) || other.type == type)&&(identical(other.id, id) || other.id == id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,id);
}

@override
String toString() {
    return 'NotificationItemRef(type: $type, id: $id)';
}


}

/// @nodoc
abstract mixin class _$NotificationItemRefCopyWith<$Res> implements $NotificationItemRefCopyWith<$Res> {
  factory _$NotificationItemRefCopyWith(_NotificationItemRef value, $Res Function(_NotificationItemRef) _then) = __$NotificationItemRefCopyWithImpl;
@override @useResult
$Res call({
 String type, String id
});




}
/// @nodoc
class __$NotificationItemRefCopyWithImpl<$Res>
    implements _$NotificationItemRefCopyWith<$Res> {
  __$NotificationItemRefCopyWithImpl(this._self, this._then);

  final _NotificationItemRef _self;
  final $Res Function(_NotificationItemRef) _then;

/// Create a copy of NotificationItemRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? id = null,}) {
  return _then(_NotificationItemRef(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$NotificationItemActor {

 String get id; String get name; String? get picture;
/// Create a copy of NotificationItemActor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationItemActorCopyWith<NotificationItemActor> get copyWith => _$NotificationItemActorCopyWithImpl<NotificationItemActor>(this as NotificationItemActor, _$identity);

  /// Serializes this NotificationItemActor to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NotificationItemActor;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationItemActor&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.picture, _this.picture) || other.picture == _this.picture));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NotificationItemActor;
  return Object.hash(runtimeType,_this.id,_this.name,_this.picture);
}

@override
String toString() {
  final _this = this as NotificationItemActor;
  return 'NotificationItemActor(id: ${_this.id}, name: ${_this.name}, picture: ${_this.picture})';
}


}

/// @nodoc
abstract mixin class $NotificationItemActorCopyWith<$Res>  {
  factory $NotificationItemActorCopyWith(NotificationItemActor value, $Res Function(NotificationItemActor) _then) = _$NotificationItemActorCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? picture
});




}
/// @nodoc
class _$NotificationItemActorCopyWithImpl<$Res>
    implements $NotificationItemActorCopyWith<$Res> {
  _$NotificationItemActorCopyWithImpl(this._self, this._then);

  final NotificationItemActor _self;
  final $Res Function(NotificationItemActor) _then;

/// Create a copy of NotificationItemActor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? picture = freezed,}) {
  return _then(NotificationItemActor(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,picture: freezed == picture ? _self.picture : picture // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationItemActor].
extension NotificationItemActorPatterns on NotificationItemActor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationItemActor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationItemActor() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationItemActor value)  $default,){
final _that = this;
switch (_that) {
case _NotificationItemActor():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationItemActor value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationItemActor() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? picture)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationItemActor() when $default != null:
return $default(_that.id,_that.name,_that.picture);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? picture)  $default,) {final _that = this;
switch (_that) {
case _NotificationItemActor():
return $default(_that.id,_that.name,_that.picture);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? picture)?  $default,) {final _that = this;
switch (_that) {
case _NotificationItemActor() when $default != null:
return $default(_that.id,_that.name,_that.picture);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationItemActor implements NotificationItemActor {
  const _NotificationItemActor({required this.id, required this.name, this.picture});
  factory _NotificationItemActor.fromJson(Map<String, dynamic> json) => _$NotificationItemActorFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? picture;

/// Create a copy of NotificationItemActor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationItemActorCopyWith<_NotificationItemActor> get copyWith => __$NotificationItemActorCopyWithImpl<_NotificationItemActor>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationItemActorToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationItemActor&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.picture, picture) || other.picture == picture));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,picture);
}

@override
String toString() {
    return 'NotificationItemActor(id: $id, name: $name, picture: $picture)';
}


}

/// @nodoc
abstract mixin class _$NotificationItemActorCopyWith<$Res> implements $NotificationItemActorCopyWith<$Res> {
  factory _$NotificationItemActorCopyWith(_NotificationItemActor value, $Res Function(_NotificationItemActor) _then) = __$NotificationItemActorCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? picture
});




}
/// @nodoc
class __$NotificationItemActorCopyWithImpl<$Res>
    implements _$NotificationItemActorCopyWith<$Res> {
  __$NotificationItemActorCopyWithImpl(this._self, this._then);

  final _NotificationItemActor _self;
  final $Res Function(_NotificationItemActor) _then;

/// Create a copy of NotificationItemActor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? picture = freezed,}) {
  return _then(_NotificationItemActor(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,picture: freezed == picture ? _self.picture : picture // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$NotificationItemIcon {

 String get type; String get value; String? get fallback;
/// Create a copy of NotificationItemIcon
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationItemIconCopyWith<NotificationItemIcon> get copyWith => _$NotificationItemIconCopyWithImpl<NotificationItemIcon>(this as NotificationItemIcon, _$identity);

  /// Serializes this NotificationItemIcon to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NotificationItemIcon;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationItemIcon&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.value, _this.value) || other.value == _this.value)&&(identical(other.fallback, _this.fallback) || other.fallback == _this.fallback));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NotificationItemIcon;
  return Object.hash(runtimeType,_this.type,_this.value,_this.fallback);
}

@override
String toString() {
  final _this = this as NotificationItemIcon;
  return 'NotificationItemIcon(type: ${_this.type}, value: ${_this.value}, fallback: ${_this.fallback})';
}


}

/// @nodoc
abstract mixin class $NotificationItemIconCopyWith<$Res>  {
  factory $NotificationItemIconCopyWith(NotificationItemIcon value, $Res Function(NotificationItemIcon) _then) = _$NotificationItemIconCopyWithImpl;
@useResult
$Res call({
 String type, String value, String? fallback
});




}
/// @nodoc
class _$NotificationItemIconCopyWithImpl<$Res>
    implements $NotificationItemIconCopyWith<$Res> {
  _$NotificationItemIconCopyWithImpl(this._self, this._then);

  final NotificationItemIcon _self;
  final $Res Function(NotificationItemIcon) _then;

/// Create a copy of NotificationItemIcon
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? value = null,Object? fallback = freezed,}) {
  return _then(NotificationItemIcon(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,fallback: freezed == fallback ? _self.fallback : fallback // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationItemIcon].
extension NotificationItemIconPatterns on NotificationItemIcon {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationItemIcon value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationItemIcon() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationItemIcon value)  $default,){
final _that = this;
switch (_that) {
case _NotificationItemIcon():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationItemIcon value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationItemIcon() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  String value,  String? fallback)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationItemIcon() when $default != null:
return $default(_that.type,_that.value,_that.fallback);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  String value,  String? fallback)  $default,) {final _that = this;
switch (_that) {
case _NotificationItemIcon():
return $default(_that.type,_that.value,_that.fallback);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  String value,  String? fallback)?  $default,) {final _that = this;
switch (_that) {
case _NotificationItemIcon() when $default != null:
return $default(_that.type,_that.value,_that.fallback);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationItemIcon implements NotificationItemIcon {
  const _NotificationItemIcon({required this.type, required this.value, this.fallback});
  factory _NotificationItemIcon.fromJson(Map<String, dynamic> json) => _$NotificationItemIconFromJson(json);

@override final  String type;
@override final  String value;
@override final  String? fallback;

/// Create a copy of NotificationItemIcon
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationItemIconCopyWith<_NotificationItemIcon> get copyWith => __$NotificationItemIconCopyWithImpl<_NotificationItemIcon>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationItemIconToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationItemIcon&&(identical(other.type, type) || other.type == type)&&(identical(other.value, value) || other.value == value)&&(identical(other.fallback, fallback) || other.fallback == fallback));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,value,fallback);
}

@override
String toString() {
    return 'NotificationItemIcon(type: $type, value: $value, fallback: $fallback)';
}


}

/// @nodoc
abstract mixin class _$NotificationItemIconCopyWith<$Res> implements $NotificationItemIconCopyWith<$Res> {
  factory _$NotificationItemIconCopyWith(_NotificationItemIcon value, $Res Function(_NotificationItemIcon) _then) = __$NotificationItemIconCopyWithImpl;
@override @useResult
$Res call({
 String type, String value, String? fallback
});




}
/// @nodoc
class __$NotificationItemIconCopyWithImpl<$Res>
    implements _$NotificationItemIconCopyWith<$Res> {
  __$NotificationItemIconCopyWithImpl(this._self, this._then);

  final _NotificationItemIcon _self;
  final $Res Function(_NotificationItemIcon) _then;

/// Create a copy of NotificationItemIcon
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? value = null,Object? fallback = freezed,}) {
  return _then(_NotificationItemIcon(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,fallback: freezed == fallback ? _self.fallback : fallback // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$NotificationItemButton {

 String get label; String get link; String get style;
/// Create a copy of NotificationItemButton
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationItemButtonCopyWith<NotificationItemButton> get copyWith => _$NotificationItemButtonCopyWithImpl<NotificationItemButton>(this as NotificationItemButton, _$identity);

  /// Serializes this NotificationItemButton to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NotificationItemButton;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationItemButton&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.link, _this.link) || other.link == _this.link)&&(identical(other.style, _this.style) || other.style == _this.style));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NotificationItemButton;
  return Object.hash(runtimeType,_this.label,_this.link,_this.style);
}

@override
String toString() {
  final _this = this as NotificationItemButton;
  return 'NotificationItemButton(label: ${_this.label}, link: ${_this.link}, style: ${_this.style})';
}


}

/// @nodoc
abstract mixin class $NotificationItemButtonCopyWith<$Res>  {
  factory $NotificationItemButtonCopyWith(NotificationItemButton value, $Res Function(NotificationItemButton) _then) = _$NotificationItemButtonCopyWithImpl;
@useResult
$Res call({
 String label, String link, String style
});




}
/// @nodoc
class _$NotificationItemButtonCopyWithImpl<$Res>
    implements $NotificationItemButtonCopyWith<$Res> {
  _$NotificationItemButtonCopyWithImpl(this._self, this._then);

  final NotificationItemButton _self;
  final $Res Function(NotificationItemButton) _then;

/// Create a copy of NotificationItemButton
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? link = null,Object? style = null,}) {
  return _then(NotificationItemButton(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,link: null == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String,style: null == style ? _self.style : style // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationItemButton].
extension NotificationItemButtonPatterns on NotificationItemButton {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationItemButton value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationItemButton() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationItemButton value)  $default,){
final _that = this;
switch (_that) {
case _NotificationItemButton():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationItemButton value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationItemButton() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  String link,  String style)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationItemButton() when $default != null:
return $default(_that.label,_that.link,_that.style);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  String link,  String style)  $default,) {final _that = this;
switch (_that) {
case _NotificationItemButton():
return $default(_that.label,_that.link,_that.style);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  String link,  String style)?  $default,) {final _that = this;
switch (_that) {
case _NotificationItemButton() when $default != null:
return $default(_that.label,_that.link,_that.style);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationItemButton implements NotificationItemButton {
  const _NotificationItemButton({required this.label, required this.link, required this.style});
  factory _NotificationItemButton.fromJson(Map<String, dynamic> json) => _$NotificationItemButtonFromJson(json);

@override final  String label;
@override final  String link;
@override final  String style;

/// Create a copy of NotificationItemButton
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationItemButtonCopyWith<_NotificationItemButton> get copyWith => __$NotificationItemButtonCopyWithImpl<_NotificationItemButton>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationItemButtonToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationItemButton&&(identical(other.label, label) || other.label == label)&&(identical(other.link, link) || other.link == link)&&(identical(other.style, style) || other.style == style));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,label,link,style);
}

@override
String toString() {
    return 'NotificationItemButton(label: $label, link: $link, style: $style)';
}


}

/// @nodoc
abstract mixin class _$NotificationItemButtonCopyWith<$Res> implements $NotificationItemButtonCopyWith<$Res> {
  factory _$NotificationItemButtonCopyWith(_NotificationItemButton value, $Res Function(_NotificationItemButton) _then) = __$NotificationItemButtonCopyWithImpl;
@override @useResult
$Res call({
 String label, String link, String style
});




}
/// @nodoc
class __$NotificationItemButtonCopyWithImpl<$Res>
    implements _$NotificationItemButtonCopyWith<$Res> {
  __$NotificationItemButtonCopyWithImpl(this._self, this._then);

  final _NotificationItemButton _self;
  final $Res Function(_NotificationItemButton) _then;

/// Create a copy of NotificationItemButton
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? link = null,Object? style = null,}) {
  return _then(_NotificationItemButton(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,link: null == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String,style: null == style ? _self.style : style // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$NotificationItem {

 String get id;@JsonKey(name: 'notification_id') String get notificationId; String get type; String get category; String get title; String get body; String? get link; NotificationItemRef? get ref;@JsonKey(name: 'company_id') String? get companyId; NotificationItemActor? get actor; NotificationItemIcon? get icon; String? get image;@JsonKey(name: 'image_ratio') String? get imageRatio; List<NotificationItemButton> get buttons;@JsonKey(name: 'read_at') DateTime? get readAt;@JsonKey(name: 'created_at') DateTime get createdAt;
/// Create a copy of NotificationItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationItemCopyWith<NotificationItem> get copyWith => _$NotificationItemCopyWithImpl<NotificationItem>(this as NotificationItem, _$identity);

  /// Serializes this NotificationItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NotificationItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationItem&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.notificationId, _this.notificationId) || other.notificationId == _this.notificationId)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.body, _this.body) || other.body == _this.body)&&(identical(other.link, _this.link) || other.link == _this.link)&&(identical(other.ref, _this.ref) || other.ref == _this.ref)&&(identical(other.companyId, _this.companyId) || other.companyId == _this.companyId)&&(identical(other.actor, _this.actor) || other.actor == _this.actor)&&(identical(other.icon, _this.icon) || other.icon == _this.icon)&&(identical(other.image, _this.image) || other.image == _this.image)&&(identical(other.imageRatio, _this.imageRatio) || other.imageRatio == _this.imageRatio)&&const DeepCollectionEquality().equals(other.buttons, _this.buttons)&&(identical(other.readAt, _this.readAt) || other.readAt == _this.readAt)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NotificationItem;
  return Object.hash(runtimeType,_this.id,_this.notificationId,_this.type,_this.category,_this.title,_this.body,_this.link,_this.ref,_this.companyId,_this.actor,_this.icon,_this.image,_this.imageRatio,const DeepCollectionEquality().hash(_this.buttons),_this.readAt,_this.createdAt);
}

@override
String toString() {
  final _this = this as NotificationItem;
  return 'NotificationItem(id: ${_this.id}, notificationId: ${_this.notificationId}, type: ${_this.type}, category: ${_this.category}, title: ${_this.title}, body: ${_this.body}, link: ${_this.link}, ref: ${_this.ref}, companyId: ${_this.companyId}, actor: ${_this.actor}, icon: ${_this.icon}, image: ${_this.image}, imageRatio: ${_this.imageRatio}, buttons: ${_this.buttons}, readAt: ${_this.readAt}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $NotificationItemCopyWith<$Res>  {
  factory $NotificationItemCopyWith(NotificationItem value, $Res Function(NotificationItem) _then) = _$NotificationItemCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'notification_id') String notificationId, String type, String category, String title, String body, String? link, NotificationItemRef? ref,@JsonKey(name: 'company_id') String? companyId, NotificationItemActor? actor, NotificationItemIcon? icon, String? image,@JsonKey(name: 'image_ratio') String? imageRatio, List<NotificationItemButton> buttons,@JsonKey(name: 'read_at') DateTime? readAt,@JsonKey(name: 'created_at') DateTime createdAt
});


$NotificationItemRefCopyWith<$Res>? get ref;$NotificationItemActorCopyWith<$Res>? get actor;$NotificationItemIconCopyWith<$Res>? get icon;

}
/// @nodoc
class _$NotificationItemCopyWithImpl<$Res>
    implements $NotificationItemCopyWith<$Res> {
  _$NotificationItemCopyWithImpl(this._self, this._then);

  final NotificationItem _self;
  final $Res Function(NotificationItem) _then;

/// Create a copy of NotificationItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? notificationId = null,Object? type = null,Object? category = null,Object? title = null,Object? body = null,Object? link = freezed,Object? ref = freezed,Object? companyId = freezed,Object? actor = freezed,Object? icon = freezed,Object? image = freezed,Object? imageRatio = freezed,Object? buttons = null,Object? readAt = freezed,Object? createdAt = null,}) {
  return _then(NotificationItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,notificationId: null == notificationId ? _self.notificationId : notificationId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,link: freezed == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String?,ref: freezed == ref ? _self.ref : ref // ignore: cast_nullable_to_non_nullable
as NotificationItemRef?,companyId: freezed == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String?,actor: freezed == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as NotificationItemActor?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as NotificationItemIcon?,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String?,imageRatio: freezed == imageRatio ? _self.imageRatio : imageRatio // ignore: cast_nullable_to_non_nullable
as String?,buttons: null == buttons ? _self.buttons : buttons // ignore: cast_nullable_to_non_nullable
as List<NotificationItemButton>,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of NotificationItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationItemRefCopyWith<$Res>? get ref {
    if (_self.ref == null) {
    return null;
  }

  return $NotificationItemRefCopyWith<$Res>(_self.ref!, (value) {
    return _then(_self.copyWith(ref: value));
  });
}/// Create a copy of NotificationItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationItemActorCopyWith<$Res>? get actor {
    if (_self.actor == null) {
    return null;
  }

  return $NotificationItemActorCopyWith<$Res>(_self.actor!, (value) {
    return _then(_self.copyWith(actor: value));
  });
}/// Create a copy of NotificationItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationItemIconCopyWith<$Res>? get icon {
    if (_self.icon == null) {
    return null;
  }

  return $NotificationItemIconCopyWith<$Res>(_self.icon!, (value) {
    return _then(_self.copyWith(icon: value));
  });
}
}


/// Adds pattern-matching-related methods to [NotificationItem].
extension NotificationItemPatterns on NotificationItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationItem value)  $default,){
final _that = this;
switch (_that) {
case _NotificationItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationItem value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'notification_id')  String notificationId,  String type,  String category,  String title,  String body,  String? link,  NotificationItemRef? ref, @JsonKey(name: 'company_id')  String? companyId,  NotificationItemActor? actor,  NotificationItemIcon? icon,  String? image, @JsonKey(name: 'image_ratio')  String? imageRatio,  List<NotificationItemButton> buttons, @JsonKey(name: 'read_at')  DateTime? readAt, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationItem() when $default != null:
return $default(_that.id,_that.notificationId,_that.type,_that.category,_that.title,_that.body,_that.link,_that.ref,_that.companyId,_that.actor,_that.icon,_that.image,_that.imageRatio,_that.buttons,_that.readAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'notification_id')  String notificationId,  String type,  String category,  String title,  String body,  String? link,  NotificationItemRef? ref, @JsonKey(name: 'company_id')  String? companyId,  NotificationItemActor? actor,  NotificationItemIcon? icon,  String? image, @JsonKey(name: 'image_ratio')  String? imageRatio,  List<NotificationItemButton> buttons, @JsonKey(name: 'read_at')  DateTime? readAt, @JsonKey(name: 'created_at')  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _NotificationItem():
return $default(_that.id,_that.notificationId,_that.type,_that.category,_that.title,_that.body,_that.link,_that.ref,_that.companyId,_that.actor,_that.icon,_that.image,_that.imageRatio,_that.buttons,_that.readAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'notification_id')  String notificationId,  String type,  String category,  String title,  String body,  String? link,  NotificationItemRef? ref, @JsonKey(name: 'company_id')  String? companyId,  NotificationItemActor? actor,  NotificationItemIcon? icon,  String? image, @JsonKey(name: 'image_ratio')  String? imageRatio,  List<NotificationItemButton> buttons, @JsonKey(name: 'read_at')  DateTime? readAt, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _NotificationItem() when $default != null:
return $default(_that.id,_that.notificationId,_that.type,_that.category,_that.title,_that.body,_that.link,_that.ref,_that.companyId,_that.actor,_that.icon,_that.image,_that.imageRatio,_that.buttons,_that.readAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationItem implements NotificationItem {
  const _NotificationItem({required this.id, @JsonKey(name: 'notification_id') required this.notificationId, required this.type, required this.category, required this.title, required this.body, this.link, this.ref, @JsonKey(name: 'company_id') this.companyId, this.actor, this.icon, this.image, @JsonKey(name: 'image_ratio') this.imageRatio,  List<NotificationItemButton> buttons = const <NotificationItemButton>[], @JsonKey(name: 'read_at') this.readAt, @JsonKey(name: 'created_at') required this.createdAt}): _buttons = buttons;
  factory _NotificationItem.fromJson(Map<String, dynamic> json) => _$NotificationItemFromJson(json);

@override final  String id;
@override@JsonKey(name: 'notification_id') final  String notificationId;
@override final  String type;
@override final  String category;
@override final  String title;
@override final  String body;
@override final  String? link;
@override final  NotificationItemRef? ref;
@override@JsonKey(name: 'company_id') final  String? companyId;
@override final  NotificationItemActor? actor;
@override final  NotificationItemIcon? icon;
@override final  String? image;
@override@JsonKey(name: 'image_ratio') final  String? imageRatio;
 final  List<NotificationItemButton> _buttons;
@override@JsonKey() List<NotificationItemButton> get buttons {
  if (_buttons is EqualUnmodifiableListView) return _buttons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_buttons);
}

@override@JsonKey(name: 'read_at') final  DateTime? readAt;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;

/// Create a copy of NotificationItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationItemCopyWith<_NotificationItem> get copyWith => __$NotificationItemCopyWithImpl<_NotificationItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationItem&&(identical(other.id, id) || other.id == id)&&(identical(other.notificationId, notificationId) || other.notificationId == notificationId)&&(identical(other.type, type) || other.type == type)&&(identical(other.category, category) || other.category == category)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.link, link) || other.link == link)&&(identical(other.ref, ref) || other.ref == ref)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.actor, actor) || other.actor == actor)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.image, image) || other.image == image)&&(identical(other.imageRatio, imageRatio) || other.imageRatio == imageRatio)&&const DeepCollectionEquality().equals(other.buttons, _buttons)&&(identical(other.readAt, readAt) || other.readAt == readAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,notificationId,type,category,title,body,link,ref,companyId,actor,icon,image,imageRatio,const DeepCollectionEquality().hash(_buttons),readAt,createdAt);
}

@override
String toString() {
    return 'NotificationItem(id: $id, notificationId: $notificationId, type: $type, category: $category, title: $title, body: $body, link: $link, ref: $ref, companyId: $companyId, actor: $actor, icon: $icon, image: $image, imageRatio: $imageRatio, buttons: $buttons, readAt: $readAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$NotificationItemCopyWith<$Res> implements $NotificationItemCopyWith<$Res> {
  factory _$NotificationItemCopyWith(_NotificationItem value, $Res Function(_NotificationItem) _then) = __$NotificationItemCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'notification_id') String notificationId, String type, String category, String title, String body, String? link, NotificationItemRef? ref,@JsonKey(name: 'company_id') String? companyId, NotificationItemActor? actor, NotificationItemIcon? icon, String? image,@JsonKey(name: 'image_ratio') String? imageRatio, List<NotificationItemButton> buttons,@JsonKey(name: 'read_at') DateTime? readAt,@JsonKey(name: 'created_at') DateTime createdAt
});


@override $NotificationItemRefCopyWith<$Res>? get ref;@override $NotificationItemActorCopyWith<$Res>? get actor;@override $NotificationItemIconCopyWith<$Res>? get icon;

}
/// @nodoc
class __$NotificationItemCopyWithImpl<$Res>
    implements _$NotificationItemCopyWith<$Res> {
  __$NotificationItemCopyWithImpl(this._self, this._then);

  final _NotificationItem _self;
  final $Res Function(_NotificationItem) _then;

/// Create a copy of NotificationItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? notificationId = null,Object? type = null,Object? category = null,Object? title = null,Object? body = null,Object? link = freezed,Object? ref = freezed,Object? companyId = freezed,Object? actor = freezed,Object? icon = freezed,Object? image = freezed,Object? imageRatio = freezed,Object? buttons = null,Object? readAt = freezed,Object? createdAt = null,}) {
  return _then(_NotificationItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,notificationId: null == notificationId ? _self.notificationId : notificationId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,link: freezed == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String?,ref: freezed == ref ? _self.ref : ref // ignore: cast_nullable_to_non_nullable
as NotificationItemRef?,companyId: freezed == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String?,actor: freezed == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as NotificationItemActor?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as NotificationItemIcon?,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String?,imageRatio: freezed == imageRatio ? _self.imageRatio : imageRatio // ignore: cast_nullable_to_non_nullable
as String?,buttons: null == buttons ? _self._buttons : buttons // ignore: cast_nullable_to_non_nullable
as List<NotificationItemButton>,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of NotificationItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationItemRefCopyWith<$Res>? get ref {
    if (_self.ref == null) {
    return null;
  }

  return $NotificationItemRefCopyWith<$Res>(_self.ref!, (value) {
    return _then(_self.copyWith(ref: value));
  });
}/// Create a copy of NotificationItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationItemActorCopyWith<$Res>? get actor {
    if (_self.actor == null) {
    return null;
  }

  return $NotificationItemActorCopyWith<$Res>(_self.actor!, (value) {
    return _then(_self.copyWith(actor: value));
  });
}/// Create a copy of NotificationItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationItemIconCopyWith<$Res>? get icon {
    if (_self.icon == null) {
    return null;
  }

  return $NotificationItemIconCopyWith<$Res>(_self.icon!, (value) {
    return _then(_self.copyWith(icon: value));
  });
}
}


/// @nodoc
mixin _$NotificationListResponse {

 List<NotificationItem> get items;@JsonKey(name: 'next_cursor') String get nextCursor;
/// Create a copy of NotificationListResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationListResponseCopyWith<NotificationListResponse> get copyWith => _$NotificationListResponseCopyWithImpl<NotificationListResponse>(this as NotificationListResponse, _$identity);

  /// Serializes this NotificationListResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NotificationListResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationListResponse&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.nextCursor, _this.nextCursor) || other.nextCursor == _this.nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NotificationListResponse;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.nextCursor);
}

@override
String toString() {
  final _this = this as NotificationListResponse;
  return 'NotificationListResponse(items: ${_this.items}, nextCursor: ${_this.nextCursor})';
}


}

/// @nodoc
abstract mixin class $NotificationListResponseCopyWith<$Res>  {
  factory $NotificationListResponseCopyWith(NotificationListResponse value, $Res Function(NotificationListResponse) _then) = _$NotificationListResponseCopyWithImpl;
@useResult
$Res call({
 List<NotificationItem> items,@JsonKey(name: 'next_cursor') String nextCursor
});




}
/// @nodoc
class _$NotificationListResponseCopyWithImpl<$Res>
    implements $NotificationListResponseCopyWith<$Res> {
  _$NotificationListResponseCopyWithImpl(this._self, this._then);

  final NotificationListResponse _self;
  final $Res Function(NotificationListResponse) _then;

/// Create a copy of NotificationListResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = null,}) {
  return _then(NotificationListResponse(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<NotificationItem>,nextCursor: null == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationListResponse].
extension NotificationListResponsePatterns on NotificationListResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationListResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationListResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationListResponse value)  $default,){
final _that = this;
switch (_that) {
case _NotificationListResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationListResponse value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationListResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<NotificationItem> items, @JsonKey(name: 'next_cursor')  String nextCursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationListResponse() when $default != null:
return $default(_that.items,_that.nextCursor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<NotificationItem> items, @JsonKey(name: 'next_cursor')  String nextCursor)  $default,) {final _that = this;
switch (_that) {
case _NotificationListResponse():
return $default(_that.items,_that.nextCursor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<NotificationItem> items, @JsonKey(name: 'next_cursor')  String nextCursor)?  $default,) {final _that = this;
switch (_that) {
case _NotificationListResponse() when $default != null:
return $default(_that.items,_that.nextCursor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationListResponse implements NotificationListResponse {
  const _NotificationListResponse({ List<NotificationItem> items = const <NotificationItem>[], @JsonKey(name: 'next_cursor') required this.nextCursor}): _items = items;
  factory _NotificationListResponse.fromJson(Map<String, dynamic> json) => _$NotificationListResponseFromJson(json);

 final  List<NotificationItem> _items;
@override@JsonKey() List<NotificationItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey(name: 'next_cursor') final  String nextCursor;

/// Create a copy of NotificationListResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationListResponseCopyWith<_NotificationListResponse> get copyWith => __$NotificationListResponseCopyWithImpl<_NotificationListResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationListResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationListResponse&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor);
}

@override
String toString() {
    return 'NotificationListResponse(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class _$NotificationListResponseCopyWith<$Res> implements $NotificationListResponseCopyWith<$Res> {
  factory _$NotificationListResponseCopyWith(_NotificationListResponse value, $Res Function(_NotificationListResponse) _then) = __$NotificationListResponseCopyWithImpl;
@override @useResult
$Res call({
 List<NotificationItem> items,@JsonKey(name: 'next_cursor') String nextCursor
});




}
/// @nodoc
class __$NotificationListResponseCopyWithImpl<$Res>
    implements _$NotificationListResponseCopyWith<$Res> {
  __$NotificationListResponseCopyWithImpl(this._self, this._then);

  final _NotificationListResponse _self;
  final $Res Function(_NotificationListResponse) _then;

/// Create a copy of NotificationListResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = null,}) {
  return _then(_NotificationListResponse(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<NotificationItem>,nextCursor: null == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$NotificationUnreadCountResponse {

 int get total;
/// Create a copy of NotificationUnreadCountResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationUnreadCountResponseCopyWith<NotificationUnreadCountResponse> get copyWith => _$NotificationUnreadCountResponseCopyWithImpl<NotificationUnreadCountResponse>(this as NotificationUnreadCountResponse, _$identity);

  /// Serializes this NotificationUnreadCountResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NotificationUnreadCountResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationUnreadCountResponse&&(identical(other.total, _this.total) || other.total == _this.total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NotificationUnreadCountResponse;
  return Object.hash(runtimeType,_this.total);
}

@override
String toString() {
  final _this = this as NotificationUnreadCountResponse;
  return 'NotificationUnreadCountResponse(total: ${_this.total})';
}


}

/// @nodoc
abstract mixin class $NotificationUnreadCountResponseCopyWith<$Res>  {
  factory $NotificationUnreadCountResponseCopyWith(NotificationUnreadCountResponse value, $Res Function(NotificationUnreadCountResponse) _then) = _$NotificationUnreadCountResponseCopyWithImpl;
@useResult
$Res call({
 int total
});




}
/// @nodoc
class _$NotificationUnreadCountResponseCopyWithImpl<$Res>
    implements $NotificationUnreadCountResponseCopyWith<$Res> {
  _$NotificationUnreadCountResponseCopyWithImpl(this._self, this._then);

  final NotificationUnreadCountResponse _self;
  final $Res Function(NotificationUnreadCountResponse) _then;

/// Create a copy of NotificationUnreadCountResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? total = null,}) {
  return _then(NotificationUnreadCountResponse(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationUnreadCountResponse].
extension NotificationUnreadCountResponsePatterns on NotificationUnreadCountResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationUnreadCountResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationUnreadCountResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationUnreadCountResponse value)  $default,){
final _that = this;
switch (_that) {
case _NotificationUnreadCountResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationUnreadCountResponse value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationUnreadCountResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationUnreadCountResponse() when $default != null:
return $default(_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int total)  $default,) {final _that = this;
switch (_that) {
case _NotificationUnreadCountResponse():
return $default(_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int total)?  $default,) {final _that = this;
switch (_that) {
case _NotificationUnreadCountResponse() when $default != null:
return $default(_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationUnreadCountResponse implements NotificationUnreadCountResponse {
  const _NotificationUnreadCountResponse({required this.total});
  factory _NotificationUnreadCountResponse.fromJson(Map<String, dynamic> json) => _$NotificationUnreadCountResponseFromJson(json);

@override final  int total;

/// Create a copy of NotificationUnreadCountResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationUnreadCountResponseCopyWith<_NotificationUnreadCountResponse> get copyWith => __$NotificationUnreadCountResponseCopyWithImpl<_NotificationUnreadCountResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationUnreadCountResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationUnreadCountResponse&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,total);
}

@override
String toString() {
    return 'NotificationUnreadCountResponse(total: $total)';
}


}

/// @nodoc
abstract mixin class _$NotificationUnreadCountResponseCopyWith<$Res> implements $NotificationUnreadCountResponseCopyWith<$Res> {
  factory _$NotificationUnreadCountResponseCopyWith(_NotificationUnreadCountResponse value, $Res Function(_NotificationUnreadCountResponse) _then) = __$NotificationUnreadCountResponseCopyWithImpl;
@override @useResult
$Res call({
 int total
});




}
/// @nodoc
class __$NotificationUnreadCountResponseCopyWithImpl<$Res>
    implements _$NotificationUnreadCountResponseCopyWith<$Res> {
  __$NotificationUnreadCountResponseCopyWithImpl(this._self, this._then);

  final _NotificationUnreadCountResponse _self;
  final $Res Function(_NotificationUnreadCountResponse) _then;

/// Create a copy of NotificationUnreadCountResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? total = null,}) {
  return _then(_NotificationUnreadCountResponse(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$NotificationMarkReadRequest {

 List<String> get ids; bool get all;
/// Create a copy of NotificationMarkReadRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationMarkReadRequestCopyWith<NotificationMarkReadRequest> get copyWith => _$NotificationMarkReadRequestCopyWithImpl<NotificationMarkReadRequest>(this as NotificationMarkReadRequest, _$identity);

  /// Serializes this NotificationMarkReadRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NotificationMarkReadRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationMarkReadRequest&&const DeepCollectionEquality().equals(other.ids, _this.ids)&&(identical(other.all, _this.all) || other.all == _this.all));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NotificationMarkReadRequest;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.ids),_this.all);
}

@override
String toString() {
  final _this = this as NotificationMarkReadRequest;
  return 'NotificationMarkReadRequest(ids: ${_this.ids}, all: ${_this.all})';
}


}

/// @nodoc
abstract mixin class $NotificationMarkReadRequestCopyWith<$Res>  {
  factory $NotificationMarkReadRequestCopyWith(NotificationMarkReadRequest value, $Res Function(NotificationMarkReadRequest) _then) = _$NotificationMarkReadRequestCopyWithImpl;
@useResult
$Res call({
 List<String> ids, bool all
});




}
/// @nodoc
class _$NotificationMarkReadRequestCopyWithImpl<$Res>
    implements $NotificationMarkReadRequestCopyWith<$Res> {
  _$NotificationMarkReadRequestCopyWithImpl(this._self, this._then);

  final NotificationMarkReadRequest _self;
  final $Res Function(NotificationMarkReadRequest) _then;

/// Create a copy of NotificationMarkReadRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ids = null,Object? all = null,}) {
  return _then(NotificationMarkReadRequest(
ids: null == ids ? _self.ids : ids // ignore: cast_nullable_to_non_nullable
as List<String>,all: null == all ? _self.all : all // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationMarkReadRequest].
extension NotificationMarkReadRequestPatterns on NotificationMarkReadRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationMarkReadRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationMarkReadRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationMarkReadRequest value)  $default,){
final _that = this;
switch (_that) {
case _NotificationMarkReadRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationMarkReadRequest value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationMarkReadRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> ids,  bool all)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationMarkReadRequest() when $default != null:
return $default(_that.ids,_that.all);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> ids,  bool all)  $default,) {final _that = this;
switch (_that) {
case _NotificationMarkReadRequest():
return $default(_that.ids,_that.all);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> ids,  bool all)?  $default,) {final _that = this;
switch (_that) {
case _NotificationMarkReadRequest() when $default != null:
return $default(_that.ids,_that.all);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationMarkReadRequest implements NotificationMarkReadRequest {
  const _NotificationMarkReadRequest({ List<String> ids = const <String>[], this.all = false}): _ids = ids;
  factory _NotificationMarkReadRequest.fromJson(Map<String, dynamic> json) => _$NotificationMarkReadRequestFromJson(json);

 final  List<String> _ids;
@override@JsonKey() List<String> get ids {
  if (_ids is EqualUnmodifiableListView) return _ids;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ids);
}

@override@JsonKey() final  bool all;

/// Create a copy of NotificationMarkReadRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationMarkReadRequestCopyWith<_NotificationMarkReadRequest> get copyWith => __$NotificationMarkReadRequestCopyWithImpl<_NotificationMarkReadRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationMarkReadRequestToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationMarkReadRequest&&const DeepCollectionEquality().equals(other.ids, _ids)&&(identical(other.all, all) || other.all == all));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_ids),all);
}

@override
String toString() {
    return 'NotificationMarkReadRequest(ids: $ids, all: $all)';
}


}

/// @nodoc
abstract mixin class _$NotificationMarkReadRequestCopyWith<$Res> implements $NotificationMarkReadRequestCopyWith<$Res> {
  factory _$NotificationMarkReadRequestCopyWith(_NotificationMarkReadRequest value, $Res Function(_NotificationMarkReadRequest) _then) = __$NotificationMarkReadRequestCopyWithImpl;
@override @useResult
$Res call({
 List<String> ids, bool all
});




}
/// @nodoc
class __$NotificationMarkReadRequestCopyWithImpl<$Res>
    implements _$NotificationMarkReadRequestCopyWith<$Res> {
  __$NotificationMarkReadRequestCopyWithImpl(this._self, this._then);

  final _NotificationMarkReadRequest _self;
  final $Res Function(_NotificationMarkReadRequest) _then;

/// Create a copy of NotificationMarkReadRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ids = null,Object? all = null,}) {
  return _then(_NotificationMarkReadRequest(
ids: null == ids ? _self._ids : ids // ignore: cast_nullable_to_non_nullable
as List<String>,all: null == all ? _self.all : all // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$NotificationMarkReadResponse {

 int get updated;
/// Create a copy of NotificationMarkReadResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationMarkReadResponseCopyWith<NotificationMarkReadResponse> get copyWith => _$NotificationMarkReadResponseCopyWithImpl<NotificationMarkReadResponse>(this as NotificationMarkReadResponse, _$identity);

  /// Serializes this NotificationMarkReadResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NotificationMarkReadResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationMarkReadResponse&&(identical(other.updated, _this.updated) || other.updated == _this.updated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NotificationMarkReadResponse;
  return Object.hash(runtimeType,_this.updated);
}

@override
String toString() {
  final _this = this as NotificationMarkReadResponse;
  return 'NotificationMarkReadResponse(updated: ${_this.updated})';
}


}

/// @nodoc
abstract mixin class $NotificationMarkReadResponseCopyWith<$Res>  {
  factory $NotificationMarkReadResponseCopyWith(NotificationMarkReadResponse value, $Res Function(NotificationMarkReadResponse) _then) = _$NotificationMarkReadResponseCopyWithImpl;
@useResult
$Res call({
 int updated
});




}
/// @nodoc
class _$NotificationMarkReadResponseCopyWithImpl<$Res>
    implements $NotificationMarkReadResponseCopyWith<$Res> {
  _$NotificationMarkReadResponseCopyWithImpl(this._self, this._then);

  final NotificationMarkReadResponse _self;
  final $Res Function(NotificationMarkReadResponse) _then;

/// Create a copy of NotificationMarkReadResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? updated = null,}) {
  return _then(NotificationMarkReadResponse(
updated: null == updated ? _self.updated : updated // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationMarkReadResponse].
extension NotificationMarkReadResponsePatterns on NotificationMarkReadResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationMarkReadResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationMarkReadResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationMarkReadResponse value)  $default,){
final _that = this;
switch (_that) {
case _NotificationMarkReadResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationMarkReadResponse value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationMarkReadResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int updated)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationMarkReadResponse() when $default != null:
return $default(_that.updated);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int updated)  $default,) {final _that = this;
switch (_that) {
case _NotificationMarkReadResponse():
return $default(_that.updated);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int updated)?  $default,) {final _that = this;
switch (_that) {
case _NotificationMarkReadResponse() when $default != null:
return $default(_that.updated);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationMarkReadResponse implements NotificationMarkReadResponse {
  const _NotificationMarkReadResponse({required this.updated});
  factory _NotificationMarkReadResponse.fromJson(Map<String, dynamic> json) => _$NotificationMarkReadResponseFromJson(json);

@override final  int updated;

/// Create a copy of NotificationMarkReadResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationMarkReadResponseCopyWith<_NotificationMarkReadResponse> get copyWith => __$NotificationMarkReadResponseCopyWithImpl<_NotificationMarkReadResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationMarkReadResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationMarkReadResponse&&(identical(other.updated, updated) || other.updated == updated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,updated);
}

@override
String toString() {
    return 'NotificationMarkReadResponse(updated: $updated)';
}


}

/// @nodoc
abstract mixin class _$NotificationMarkReadResponseCopyWith<$Res> implements $NotificationMarkReadResponseCopyWith<$Res> {
  factory _$NotificationMarkReadResponseCopyWith(_NotificationMarkReadResponse value, $Res Function(_NotificationMarkReadResponse) _then) = __$NotificationMarkReadResponseCopyWithImpl;
@override @useResult
$Res call({
 int updated
});




}
/// @nodoc
class __$NotificationMarkReadResponseCopyWithImpl<$Res>
    implements _$NotificationMarkReadResponseCopyWith<$Res> {
  __$NotificationMarkReadResponseCopyWithImpl(this._self, this._then);

  final _NotificationMarkReadResponse _self;
  final $Res Function(_NotificationMarkReadResponse) _then;

/// Create a copy of NotificationMarkReadResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? updated = null,}) {
  return _then(_NotificationMarkReadResponse(
updated: null == updated ? _self.updated : updated // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$NotificationOpenRequest {

@JsonKey(name: 'notification_id') String get notificationId;@JsonKey(name: 'company_id') String? get companyId;
/// Create a copy of NotificationOpenRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationOpenRequestCopyWith<NotificationOpenRequest> get copyWith => _$NotificationOpenRequestCopyWithImpl<NotificationOpenRequest>(this as NotificationOpenRequest, _$identity);

  /// Serializes this NotificationOpenRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NotificationOpenRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationOpenRequest&&(identical(other.notificationId, _this.notificationId) || other.notificationId == _this.notificationId)&&(identical(other.companyId, _this.companyId) || other.companyId == _this.companyId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NotificationOpenRequest;
  return Object.hash(runtimeType,_this.notificationId,_this.companyId);
}

@override
String toString() {
  final _this = this as NotificationOpenRequest;
  return 'NotificationOpenRequest(notificationId: ${_this.notificationId}, companyId: ${_this.companyId})';
}


}

/// @nodoc
abstract mixin class $NotificationOpenRequestCopyWith<$Res>  {
  factory $NotificationOpenRequestCopyWith(NotificationOpenRequest value, $Res Function(NotificationOpenRequest) _then) = _$NotificationOpenRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'notification_id') String notificationId,@JsonKey(name: 'company_id') String? companyId
});




}
/// @nodoc
class _$NotificationOpenRequestCopyWithImpl<$Res>
    implements $NotificationOpenRequestCopyWith<$Res> {
  _$NotificationOpenRequestCopyWithImpl(this._self, this._then);

  final NotificationOpenRequest _self;
  final $Res Function(NotificationOpenRequest) _then;

/// Create a copy of NotificationOpenRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? notificationId = null,Object? companyId = freezed,}) {
  return _then(NotificationOpenRequest(
notificationId: null == notificationId ? _self.notificationId : notificationId // ignore: cast_nullable_to_non_nullable
as String,companyId: freezed == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationOpenRequest].
extension NotificationOpenRequestPatterns on NotificationOpenRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationOpenRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationOpenRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationOpenRequest value)  $default,){
final _that = this;
switch (_that) {
case _NotificationOpenRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationOpenRequest value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationOpenRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'notification_id')  String notificationId, @JsonKey(name: 'company_id')  String? companyId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationOpenRequest() when $default != null:
return $default(_that.notificationId,_that.companyId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'notification_id')  String notificationId, @JsonKey(name: 'company_id')  String? companyId)  $default,) {final _that = this;
switch (_that) {
case _NotificationOpenRequest():
return $default(_that.notificationId,_that.companyId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'notification_id')  String notificationId, @JsonKey(name: 'company_id')  String? companyId)?  $default,) {final _that = this;
switch (_that) {
case _NotificationOpenRequest() when $default != null:
return $default(_that.notificationId,_that.companyId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationOpenRequest implements NotificationOpenRequest {
  const _NotificationOpenRequest({@JsonKey(name: 'notification_id') required this.notificationId, @JsonKey(name: 'company_id') this.companyId});
  factory _NotificationOpenRequest.fromJson(Map<String, dynamic> json) => _$NotificationOpenRequestFromJson(json);

@override@JsonKey(name: 'notification_id') final  String notificationId;
@override@JsonKey(name: 'company_id') final  String? companyId;

/// Create a copy of NotificationOpenRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationOpenRequestCopyWith<_NotificationOpenRequest> get copyWith => __$NotificationOpenRequestCopyWithImpl<_NotificationOpenRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationOpenRequestToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationOpenRequest&&(identical(other.notificationId, notificationId) || other.notificationId == notificationId)&&(identical(other.companyId, companyId) || other.companyId == companyId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,notificationId,companyId);
}

@override
String toString() {
    return 'NotificationOpenRequest(notificationId: $notificationId, companyId: $companyId)';
}


}

/// @nodoc
abstract mixin class _$NotificationOpenRequestCopyWith<$Res> implements $NotificationOpenRequestCopyWith<$Res> {
  factory _$NotificationOpenRequestCopyWith(_NotificationOpenRequest value, $Res Function(_NotificationOpenRequest) _then) = __$NotificationOpenRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'notification_id') String notificationId,@JsonKey(name: 'company_id') String? companyId
});




}
/// @nodoc
class __$NotificationOpenRequestCopyWithImpl<$Res>
    implements _$NotificationOpenRequestCopyWith<$Res> {
  __$NotificationOpenRequestCopyWithImpl(this._self, this._then);

  final _NotificationOpenRequest _self;
  final $Res Function(_NotificationOpenRequest) _then;

/// Create a copy of NotificationOpenRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? notificationId = null,Object? companyId = freezed,}) {
  return _then(_NotificationOpenRequest(
notificationId: null == notificationId ? _self.notificationId : notificationId // ignore: cast_nullable_to_non_nullable
as String,companyId: freezed == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$NotificationOpenResponse {

@JsonKey(name: 'company_id') String? get companyId; String get link; NotificationItem? get item;
/// Create a copy of NotificationOpenResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationOpenResponseCopyWith<NotificationOpenResponse> get copyWith => _$NotificationOpenResponseCopyWithImpl<NotificationOpenResponse>(this as NotificationOpenResponse, _$identity);

  /// Serializes this NotificationOpenResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NotificationOpenResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationOpenResponse&&(identical(other.companyId, _this.companyId) || other.companyId == _this.companyId)&&(identical(other.link, _this.link) || other.link == _this.link)&&(identical(other.item, _this.item) || other.item == _this.item));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NotificationOpenResponse;
  return Object.hash(runtimeType,_this.companyId,_this.link,_this.item);
}

@override
String toString() {
  final _this = this as NotificationOpenResponse;
  return 'NotificationOpenResponse(companyId: ${_this.companyId}, link: ${_this.link}, item: ${_this.item})';
}


}

/// @nodoc
abstract mixin class $NotificationOpenResponseCopyWith<$Res>  {
  factory $NotificationOpenResponseCopyWith(NotificationOpenResponse value, $Res Function(NotificationOpenResponse) _then) = _$NotificationOpenResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'company_id') String? companyId, String link, NotificationItem? item
});


$NotificationItemCopyWith<$Res>? get item;

}
/// @nodoc
class _$NotificationOpenResponseCopyWithImpl<$Res>
    implements $NotificationOpenResponseCopyWith<$Res> {
  _$NotificationOpenResponseCopyWithImpl(this._self, this._then);

  final NotificationOpenResponse _self;
  final $Res Function(NotificationOpenResponse) _then;

/// Create a copy of NotificationOpenResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? companyId = freezed,Object? link = null,Object? item = freezed,}) {
  return _then(NotificationOpenResponse(
companyId: freezed == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String?,link: null == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String,item: freezed == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as NotificationItem?,
  ));
}
/// Create a copy of NotificationOpenResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationItemCopyWith<$Res>? get item {
    if (_self.item == null) {
    return null;
  }

  return $NotificationItemCopyWith<$Res>(_self.item!, (value) {
    return _then(_self.copyWith(item: value));
  });
}
}


/// Adds pattern-matching-related methods to [NotificationOpenResponse].
extension NotificationOpenResponsePatterns on NotificationOpenResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationOpenResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationOpenResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationOpenResponse value)  $default,){
final _that = this;
switch (_that) {
case _NotificationOpenResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationOpenResponse value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationOpenResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'company_id')  String? companyId,  String link,  NotificationItem? item)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationOpenResponse() when $default != null:
return $default(_that.companyId,_that.link,_that.item);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'company_id')  String? companyId,  String link,  NotificationItem? item)  $default,) {final _that = this;
switch (_that) {
case _NotificationOpenResponse():
return $default(_that.companyId,_that.link,_that.item);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'company_id')  String? companyId,  String link,  NotificationItem? item)?  $default,) {final _that = this;
switch (_that) {
case _NotificationOpenResponse() when $default != null:
return $default(_that.companyId,_that.link,_that.item);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationOpenResponse implements NotificationOpenResponse {
  const _NotificationOpenResponse({@JsonKey(name: 'company_id') this.companyId, required this.link, this.item});
  factory _NotificationOpenResponse.fromJson(Map<String, dynamic> json) => _$NotificationOpenResponseFromJson(json);

@override@JsonKey(name: 'company_id') final  String? companyId;
@override final  String link;
@override final  NotificationItem? item;

/// Create a copy of NotificationOpenResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationOpenResponseCopyWith<_NotificationOpenResponse> get copyWith => __$NotificationOpenResponseCopyWithImpl<_NotificationOpenResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationOpenResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationOpenResponse&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.link, link) || other.link == link)&&(identical(other.item, item) || other.item == item));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,companyId,link,item);
}

@override
String toString() {
    return 'NotificationOpenResponse(companyId: $companyId, link: $link, item: $item)';
}


}

/// @nodoc
abstract mixin class _$NotificationOpenResponseCopyWith<$Res> implements $NotificationOpenResponseCopyWith<$Res> {
  factory _$NotificationOpenResponseCopyWith(_NotificationOpenResponse value, $Res Function(_NotificationOpenResponse) _then) = __$NotificationOpenResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'company_id') String? companyId, String link, NotificationItem? item
});


@override $NotificationItemCopyWith<$Res>? get item;

}
/// @nodoc
class __$NotificationOpenResponseCopyWithImpl<$Res>
    implements _$NotificationOpenResponseCopyWith<$Res> {
  __$NotificationOpenResponseCopyWithImpl(this._self, this._then);

  final _NotificationOpenResponse _self;
  final $Res Function(_NotificationOpenResponse) _then;

/// Create a copy of NotificationOpenResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? companyId = freezed,Object? link = null,Object? item = freezed,}) {
  return _then(_NotificationOpenResponse(
companyId: freezed == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String?,link: null == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String,item: freezed == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as NotificationItem?,
  ));
}

/// Create a copy of NotificationOpenResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationItemCopyWith<$Res>? get item {
    if (_self.item == null) {
    return null;
  }

  return $NotificationItemCopyWith<$Res>(_self.item!, (value) {
    return _then(_self.copyWith(item: value));
  });
}
}

// dart format on
