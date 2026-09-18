// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'printer_port.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PrinterDevice {

/// The printer's stable identity: its MAC address on Android. This is what gets saved, so
/// a reconnect after a restart does not depend on the printer still advertising a name.
 String get address;/// What the Menu shows, so a cashier can tell which printer is configured without
/// walking over to read its label. May be empty.
 String get name;
/// Create a copy of PrinterDevice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PrinterDeviceCopyWith<PrinterDevice> get copyWith => _$PrinterDeviceCopyWithImpl<PrinterDevice>(this as PrinterDevice, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PrinterDevice;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PrinterDevice&&(identical(other.address, _this.address) || other.address == _this.address)&&(identical(other.name, _this.name) || other.name == _this.name));
}


@override
int get hashCode {
  final _this = this as PrinterDevice;
  return Object.hash(runtimeType,_this.address,_this.name);
}

@override
String toString() {
  final _this = this as PrinterDevice;
  return 'PrinterDevice(address: ${_this.address}, name: ${_this.name})';
}


}

/// @nodoc
abstract mixin class $PrinterDeviceCopyWith<$Res>  {
  factory $PrinterDeviceCopyWith(PrinterDevice value, $Res Function(PrinterDevice) _then) = _$PrinterDeviceCopyWithImpl;
@useResult
$Res call({
 String address, String name
});




}
/// @nodoc
class _$PrinterDeviceCopyWithImpl<$Res>
    implements $PrinterDeviceCopyWith<$Res> {
  _$PrinterDeviceCopyWithImpl(this._self, this._then);

  final PrinterDevice _self;
  final $Res Function(PrinterDevice) _then;

/// Create a copy of PrinterDevice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? address = null,Object? name = null,}) {
  return _then(PrinterDevice(
address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PrinterDevice].
extension PrinterDevicePatterns on PrinterDevice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PrinterDevice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PrinterDevice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PrinterDevice value)  $default,){
final _that = this;
switch (_that) {
case _PrinterDevice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PrinterDevice value)?  $default,){
final _that = this;
switch (_that) {
case _PrinterDevice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String address,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PrinterDevice() when $default != null:
return $default(_that.address,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String address,  String name)  $default,) {final _that = this;
switch (_that) {
case _PrinterDevice():
return $default(_that.address,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String address,  String name)?  $default,) {final _that = this;
switch (_that) {
case _PrinterDevice() when $default != null:
return $default(_that.address,_that.name);case _:
  return null;

}
}

}

/// @nodoc


class _PrinterDevice implements PrinterDevice {
  const _PrinterDevice({required this.address, required this.name});
  

/// The printer's stable identity: its MAC address on Android. This is what gets saved, so
/// a reconnect after a restart does not depend on the printer still advertising a name.
@override final  String address;
/// What the Menu shows, so a cashier can tell which printer is configured without
/// walking over to read its label. May be empty.
@override final  String name;

/// Create a copy of PrinterDevice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PrinterDeviceCopyWith<_PrinterDevice> get copyWith => __$PrinterDeviceCopyWithImpl<_PrinterDevice>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PrinterDevice&&(identical(other.address, address) || other.address == address)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode {
    return Object.hash(runtimeType,address,name);
}

@override
String toString() {
    return 'PrinterDevice(address: $address, name: $name)';
}


}

/// @nodoc
abstract mixin class _$PrinterDeviceCopyWith<$Res> implements $PrinterDeviceCopyWith<$Res> {
  factory _$PrinterDeviceCopyWith(_PrinterDevice value, $Res Function(_PrinterDevice) _then) = __$PrinterDeviceCopyWithImpl;
@override @useResult
$Res call({
 String address, String name
});




}
/// @nodoc
class __$PrinterDeviceCopyWithImpl<$Res>
    implements _$PrinterDeviceCopyWith<$Res> {
  __$PrinterDeviceCopyWithImpl(this._self, this._then);

  final _PrinterDevice _self;
  final $Res Function(_PrinterDevice) _then;

/// Create a copy of PrinterDevice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? address = null,Object? name = null,}) {
  return _then(_PrinterDevice(
address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
