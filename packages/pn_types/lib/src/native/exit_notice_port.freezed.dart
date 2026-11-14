// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exit_notice_port.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ExitNotice {

 String get title; String get body;
/// Create a copy of ExitNotice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExitNoticeCopyWith<ExitNotice> get copyWith => _$ExitNoticeCopyWithImpl<ExitNotice>(this as ExitNotice, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ExitNotice;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExitNotice&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.body, _this.body) || other.body == _this.body));
}


@override
int get hashCode {
  final _this = this as ExitNotice;
  return Object.hash(runtimeType,_this.title,_this.body);
}

@override
String toString() {
  final _this = this as ExitNotice;
  return 'ExitNotice(title: ${_this.title}, body: ${_this.body})';
}


}

/// @nodoc
abstract mixin class $ExitNoticeCopyWith<$Res>  {
  factory $ExitNoticeCopyWith(ExitNotice value, $Res Function(ExitNotice) _then) = _$ExitNoticeCopyWithImpl;
@useResult
$Res call({
 String title, String body
});




}
/// @nodoc
class _$ExitNoticeCopyWithImpl<$Res>
    implements $ExitNoticeCopyWith<$Res> {
  _$ExitNoticeCopyWithImpl(this._self, this._then);

  final ExitNotice _self;
  final $Res Function(ExitNotice) _then;

/// Create a copy of ExitNotice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? body = null,}) {
  return _then(ExitNotice(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ExitNotice].
extension ExitNoticePatterns on ExitNotice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExitNotice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExitNotice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExitNotice value)  $default,){
final _that = this;
switch (_that) {
case _ExitNotice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExitNotice value)?  $default,){
final _that = this;
switch (_that) {
case _ExitNotice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String body)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExitNotice() when $default != null:
return $default(_that.title,_that.body);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String body)  $default,) {final _that = this;
switch (_that) {
case _ExitNotice():
return $default(_that.title,_that.body);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String body)?  $default,) {final _that = this;
switch (_that) {
case _ExitNotice() when $default != null:
return $default(_that.title,_that.body);case _:
  return null;

}
}

}

/// @nodoc


class _ExitNotice implements ExitNotice {
  const _ExitNotice({required this.title, required this.body});
  

@override final  String title;
@override final  String body;

/// Create a copy of ExitNotice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExitNoticeCopyWith<_ExitNotice> get copyWith => __$ExitNoticeCopyWithImpl<_ExitNotice>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExitNotice&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body));
}


@override
int get hashCode {
    return Object.hash(runtimeType,title,body);
}

@override
String toString() {
    return 'ExitNotice(title: $title, body: $body)';
}


}

/// @nodoc
abstract mixin class _$ExitNoticeCopyWith<$Res> implements $ExitNoticeCopyWith<$Res> {
  factory _$ExitNoticeCopyWith(_ExitNotice value, $Res Function(_ExitNotice) _then) = __$ExitNoticeCopyWithImpl;
@override @useResult
$Res call({
 String title, String body
});




}
/// @nodoc
class __$ExitNoticeCopyWithImpl<$Res>
    implements _$ExitNoticeCopyWith<$Res> {
  __$ExitNoticeCopyWithImpl(this._self, this._then);

  final _ExitNotice _self;
  final $Res Function(_ExitNotice) _then;

/// Create a copy of ExitNotice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? body = null,}) {
  return _then(_ExitNotice(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
