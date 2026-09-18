// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'master_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Contact {

 String get id; String get name;/// A type this build does not know reads as `null`, like `ProductType`.
@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) ContactType? get type;@JsonKey(name: 'company_name') String? get companyName; String? get email; String? get phone;
/// Create a copy of Contact
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContactCopyWith<Contact> get copyWith => _$ContactCopyWithImpl<Contact>(this as Contact, _$identity);

  /// Serializes this Contact to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Contact;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Contact&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.companyName, _this.companyName) || other.companyName == _this.companyName)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.phone, _this.phone) || other.phone == _this.phone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Contact;
  return Object.hash(runtimeType,_this.id,_this.name,_this.type,_this.companyName,_this.email,_this.phone);
}

@override
String toString() {
  final _this = this as Contact;
  return 'Contact(id: ${_this.id}, name: ${_this.name}, type: ${_this.type}, companyName: ${_this.companyName}, email: ${_this.email}, phone: ${_this.phone})';
}


}

/// @nodoc
abstract mixin class $ContactCopyWith<$Res>  {
  factory $ContactCopyWith(Contact value, $Res Function(Contact) _then) = _$ContactCopyWithImpl;
@useResult
$Res call({
 String id, String name,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) ContactType? type,@JsonKey(name: 'company_name') String? companyName, String? email, String? phone
});




}
/// @nodoc
class _$ContactCopyWithImpl<$Res>
    implements $ContactCopyWith<$Res> {
  _$ContactCopyWithImpl(this._self, this._then);

  final Contact _self;
  final $Res Function(Contact) _then;

/// Create a copy of Contact
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = freezed,Object? companyName = freezed,Object? email = freezed,Object? phone = freezed,}) {
  return _then(Contact(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ContactType?,companyName: freezed == companyName ? _self.companyName : companyName // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Contact].
extension ContactPatterns on Contact {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Contact value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Contact() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Contact value)  $default,){
final _that = this;
switch (_that) {
case _Contact():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Contact value)?  $default,){
final _that = this;
switch (_that) {
case _Contact() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  ContactType? type, @JsonKey(name: 'company_name')  String? companyName,  String? email,  String? phone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Contact() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.companyName,_that.email,_that.phone);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  ContactType? type, @JsonKey(name: 'company_name')  String? companyName,  String? email,  String? phone)  $default,) {final _that = this;
switch (_that) {
case _Contact():
return $default(_that.id,_that.name,_that.type,_that.companyName,_that.email,_that.phone);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  ContactType? type, @JsonKey(name: 'company_name')  String? companyName,  String? email,  String? phone)?  $default,) {final _that = this;
switch (_that) {
case _Contact() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.companyName,_that.email,_that.phone);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Contact implements Contact {
  const _Contact({required this.id, required this.name, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) this.type, @JsonKey(name: 'company_name') this.companyName, this.email, this.phone});
  factory _Contact.fromJson(Map<String, dynamic> json) => _$ContactFromJson(json);

@override final  String id;
@override final  String name;
/// A type this build does not know reads as `null`, like `ProductType`.
@override@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) final  ContactType? type;
@override@JsonKey(name: 'company_name') final  String? companyName;
@override final  String? email;
@override final  String? phone;

/// Create a copy of Contact
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContactCopyWith<_Contact> get copyWith => __$ContactCopyWithImpl<_Contact>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ContactToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Contact&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.companyName, companyName) || other.companyName == companyName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,type,companyName,email,phone);
}

@override
String toString() {
    return 'Contact(id: $id, name: $name, type: $type, companyName: $companyName, email: $email, phone: $phone)';
}


}

/// @nodoc
abstract mixin class _$ContactCopyWith<$Res> implements $ContactCopyWith<$Res> {
  factory _$ContactCopyWith(_Contact value, $Res Function(_Contact) _then) = __$ContactCopyWithImpl;
@override @useResult
$Res call({
 String id, String name,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) ContactType? type,@JsonKey(name: 'company_name') String? companyName, String? email, String? phone
});




}
/// @nodoc
class __$ContactCopyWithImpl<$Res>
    implements _$ContactCopyWith<$Res> {
  __$ContactCopyWithImpl(this._self, this._then);

  final _Contact _self;
  final $Res Function(_Contact) _then;

/// Create a copy of Contact
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = freezed,Object? companyName = freezed,Object? email = freezed,Object? phone = freezed,}) {
  return _then(_Contact(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ContactType?,companyName: freezed == companyName ? _self.companyName : companyName // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$CreateContactDTO {

 String get name; ContactType get type;@JsonKey(name: 'is_active') bool get isActive; String? get phone; String? get email;@JsonKey(name: 'company_name') String? get companyName; String? get address;
/// Create a copy of CreateContactDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateContactDTOCopyWith<CreateContactDTO> get copyWith => _$CreateContactDTOCopyWithImpl<CreateContactDTO>(this as CreateContactDTO, _$identity);

  /// Serializes this CreateContactDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CreateContactDTO;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateContactDTO&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.isActive, _this.isActive) || other.isActive == _this.isActive)&&(identical(other.phone, _this.phone) || other.phone == _this.phone)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.companyName, _this.companyName) || other.companyName == _this.companyName)&&(identical(other.address, _this.address) || other.address == _this.address));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CreateContactDTO;
  return Object.hash(runtimeType,_this.name,_this.type,_this.isActive,_this.phone,_this.email,_this.companyName,_this.address);
}

@override
String toString() {
  final _this = this as CreateContactDTO;
  return 'CreateContactDTO(name: ${_this.name}, type: ${_this.type}, isActive: ${_this.isActive}, phone: ${_this.phone}, email: ${_this.email}, companyName: ${_this.companyName}, address: ${_this.address})';
}


}

/// @nodoc
abstract mixin class $CreateContactDTOCopyWith<$Res>  {
  factory $CreateContactDTOCopyWith(CreateContactDTO value, $Res Function(CreateContactDTO) _then) = _$CreateContactDTOCopyWithImpl;
@useResult
$Res call({
 String name, ContactType type,@JsonKey(name: 'is_active') bool isActive, String? phone, String? email,@JsonKey(name: 'company_name') String? companyName, String? address
});




}
/// @nodoc
class _$CreateContactDTOCopyWithImpl<$Res>
    implements $CreateContactDTOCopyWith<$Res> {
  _$CreateContactDTOCopyWithImpl(this._self, this._then);

  final CreateContactDTO _self;
  final $Res Function(CreateContactDTO) _then;

/// Create a copy of CreateContactDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? type = null,Object? isActive = null,Object? phone = freezed,Object? email = freezed,Object? companyName = freezed,Object? address = freezed,}) {
  return _then(CreateContactDTO(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ContactType,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,companyName: freezed == companyName ? _self.companyName : companyName // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateContactDTO].
extension CreateContactDTOPatterns on CreateContactDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateContactDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateContactDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateContactDTO value)  $default,){
final _that = this;
switch (_that) {
case _CreateContactDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateContactDTO value)?  $default,){
final _that = this;
switch (_that) {
case _CreateContactDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  ContactType type, @JsonKey(name: 'is_active')  bool isActive,  String? phone,  String? email, @JsonKey(name: 'company_name')  String? companyName,  String? address)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateContactDTO() when $default != null:
return $default(_that.name,_that.type,_that.isActive,_that.phone,_that.email,_that.companyName,_that.address);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  ContactType type, @JsonKey(name: 'is_active')  bool isActive,  String? phone,  String? email, @JsonKey(name: 'company_name')  String? companyName,  String? address)  $default,) {final _that = this;
switch (_that) {
case _CreateContactDTO():
return $default(_that.name,_that.type,_that.isActive,_that.phone,_that.email,_that.companyName,_that.address);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  ContactType type, @JsonKey(name: 'is_active')  bool isActive,  String? phone,  String? email, @JsonKey(name: 'company_name')  String? companyName,  String? address)?  $default,) {final _that = this;
switch (_that) {
case _CreateContactDTO() when $default != null:
return $default(_that.name,_that.type,_that.isActive,_that.phone,_that.email,_that.companyName,_that.address);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(includeIfNull: false)
class _CreateContactDTO implements CreateContactDTO {
  const _CreateContactDTO({required this.name, required this.type, @JsonKey(name: 'is_active') this.isActive = true, this.phone, this.email, @JsonKey(name: 'company_name') this.companyName, this.address});
  factory _CreateContactDTO.fromJson(Map<String, dynamic> json) => _$CreateContactDTOFromJson(json);

@override final  String name;
@override final  ContactType type;
@override@JsonKey(name: 'is_active') final  bool isActive;
@override final  String? phone;
@override final  String? email;
@override@JsonKey(name: 'company_name') final  String? companyName;
@override final  String? address;

/// Create a copy of CreateContactDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateContactDTOCopyWith<_CreateContactDTO> get copyWith => __$CreateContactDTOCopyWithImpl<_CreateContactDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreateContactDTOToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateContactDTO&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.companyName, companyName) || other.companyName == companyName)&&(identical(other.address, address) || other.address == address));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,type,isActive,phone,email,companyName,address);
}

@override
String toString() {
    return 'CreateContactDTO(name: $name, type: $type, isActive: $isActive, phone: $phone, email: $email, companyName: $companyName, address: $address)';
}


}

/// @nodoc
abstract mixin class _$CreateContactDTOCopyWith<$Res> implements $CreateContactDTOCopyWith<$Res> {
  factory _$CreateContactDTOCopyWith(_CreateContactDTO value, $Res Function(_CreateContactDTO) _then) = __$CreateContactDTOCopyWithImpl;
@override @useResult
$Res call({
 String name, ContactType type,@JsonKey(name: 'is_active') bool isActive, String? phone, String? email,@JsonKey(name: 'company_name') String? companyName, String? address
});




}
/// @nodoc
class __$CreateContactDTOCopyWithImpl<$Res>
    implements _$CreateContactDTOCopyWith<$Res> {
  __$CreateContactDTOCopyWithImpl(this._self, this._then);

  final _CreateContactDTO _self;
  final $Res Function(_CreateContactDTO) _then;

/// Create a copy of CreateContactDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? type = null,Object? isActive = null,Object? phone = freezed,Object? email = freezed,Object? companyName = freezed,Object? address = freezed,}) {
  return _then(_CreateContactDTO(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ContactType,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,companyName: freezed == companyName ? _self.companyName : companyName // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ChartOfAccount {

 String get id; String get code; String get name;
/// Create a copy of ChartOfAccount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChartOfAccountCopyWith<ChartOfAccount> get copyWith => _$ChartOfAccountCopyWithImpl<ChartOfAccount>(this as ChartOfAccount, _$identity);

  /// Serializes this ChartOfAccount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ChartOfAccount;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChartOfAccount&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.code, _this.code) || other.code == _this.code)&&(identical(other.name, _this.name) || other.name == _this.name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ChartOfAccount;
  return Object.hash(runtimeType,_this.id,_this.code,_this.name);
}

@override
String toString() {
  final _this = this as ChartOfAccount;
  return 'ChartOfAccount(id: ${_this.id}, code: ${_this.code}, name: ${_this.name})';
}


}

/// @nodoc
abstract mixin class $ChartOfAccountCopyWith<$Res>  {
  factory $ChartOfAccountCopyWith(ChartOfAccount value, $Res Function(ChartOfAccount) _then) = _$ChartOfAccountCopyWithImpl;
@useResult
$Res call({
 String id, String code, String name
});




}
/// @nodoc
class _$ChartOfAccountCopyWithImpl<$Res>
    implements $ChartOfAccountCopyWith<$Res> {
  _$ChartOfAccountCopyWithImpl(this._self, this._then);

  final ChartOfAccount _self;
  final $Res Function(ChartOfAccount) _then;

/// Create a copy of ChartOfAccount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? name = null,}) {
  return _then(ChartOfAccount(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ChartOfAccount].
extension ChartOfAccountPatterns on ChartOfAccount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChartOfAccount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChartOfAccount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChartOfAccount value)  $default,){
final _that = this;
switch (_that) {
case _ChartOfAccount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChartOfAccount value)?  $default,){
final _that = this;
switch (_that) {
case _ChartOfAccount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String code,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChartOfAccount() when $default != null:
return $default(_that.id,_that.code,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String code,  String name)  $default,) {final _that = this;
switch (_that) {
case _ChartOfAccount():
return $default(_that.id,_that.code,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String code,  String name)?  $default,) {final _that = this;
switch (_that) {
case _ChartOfAccount() when $default != null:
return $default(_that.id,_that.code,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChartOfAccount implements ChartOfAccount {
  const _ChartOfAccount({required this.id, required this.code, required this.name});
  factory _ChartOfAccount.fromJson(Map<String, dynamic> json) => _$ChartOfAccountFromJson(json);

@override final  String id;
@override final  String code;
@override final  String name;

/// Create a copy of ChartOfAccount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChartOfAccountCopyWith<_ChartOfAccount> get copyWith => __$ChartOfAccountCopyWithImpl<_ChartOfAccount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChartOfAccountToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChartOfAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,code,name);
}

@override
String toString() {
    return 'ChartOfAccount(id: $id, code: $code, name: $name)';
}


}

/// @nodoc
abstract mixin class _$ChartOfAccountCopyWith<$Res> implements $ChartOfAccountCopyWith<$Res> {
  factory _$ChartOfAccountCopyWith(_ChartOfAccount value, $Res Function(_ChartOfAccount) _then) = __$ChartOfAccountCopyWithImpl;
@override @useResult
$Res call({
 String id, String code, String name
});




}
/// @nodoc
class __$ChartOfAccountCopyWithImpl<$Res>
    implements _$ChartOfAccountCopyWith<$Res> {
  __$ChartOfAccountCopyWithImpl(this._self, this._then);

  final _ChartOfAccount _self;
  final $Res Function(_ChartOfAccount) _then;

/// Create a copy of ChartOfAccount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? name = null,}) {
  return _then(_ChartOfAccount(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
