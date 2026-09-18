// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tenant.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserCompany {

 String get id;@JsonKey(name: 'user_id') String get userId;/// The company this membership belongs to. The till compares it with the company
/// pairing locked (`session.companyId`) to pick the membership that counts.
@JsonKey(name: 'company_id') String get companyId;@JsonKey(name: 'role_id') String? get roleId;@JsonKey(name: 'branch_id') String? get branchId;@JsonKey(name: 'warehouse_id') String? get warehouseId;@JsonKey(name: 'outlet_id') String? get outletId;/// A plain string, not an enum: the source's union ends in `| string` because tenants
/// can define their own roles, and an enum would throw on the first one.
 String get role;@JsonKey(name: 'is_active') bool get isActive;
/// Create a copy of UserCompany
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserCompanyCopyWith<UserCompany> get copyWith => _$UserCompanyCopyWithImpl<UserCompany>(this as UserCompany, _$identity);

  /// Serializes this UserCompany to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as UserCompany;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserCompany&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.companyId, _this.companyId) || other.companyId == _this.companyId)&&(identical(other.roleId, _this.roleId) || other.roleId == _this.roleId)&&(identical(other.branchId, _this.branchId) || other.branchId == _this.branchId)&&(identical(other.warehouseId, _this.warehouseId) || other.warehouseId == _this.warehouseId)&&(identical(other.outletId, _this.outletId) || other.outletId == _this.outletId)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.isActive, _this.isActive) || other.isActive == _this.isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as UserCompany;
  return Object.hash(runtimeType,_this.id,_this.userId,_this.companyId,_this.roleId,_this.branchId,_this.warehouseId,_this.outletId,_this.role,_this.isActive);
}

@override
String toString() {
  final _this = this as UserCompany;
  return 'UserCompany(id: ${_this.id}, userId: ${_this.userId}, companyId: ${_this.companyId}, roleId: ${_this.roleId}, branchId: ${_this.branchId}, warehouseId: ${_this.warehouseId}, outletId: ${_this.outletId}, role: ${_this.role}, isActive: ${_this.isActive})';
}


}

/// @nodoc
abstract mixin class $UserCompanyCopyWith<$Res>  {
  factory $UserCompanyCopyWith(UserCompany value, $Res Function(UserCompany) _then) = _$UserCompanyCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'company_id') String companyId,@JsonKey(name: 'role_id') String? roleId,@JsonKey(name: 'branch_id') String? branchId,@JsonKey(name: 'warehouse_id') String? warehouseId,@JsonKey(name: 'outlet_id') String? outletId, String role,@JsonKey(name: 'is_active') bool isActive
});




}
/// @nodoc
class _$UserCompanyCopyWithImpl<$Res>
    implements $UserCompanyCopyWith<$Res> {
  _$UserCompanyCopyWithImpl(this._self, this._then);

  final UserCompany _self;
  final $Res Function(UserCompany) _then;

/// Create a copy of UserCompany
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? companyId = null,Object? roleId = freezed,Object? branchId = freezed,Object? warehouseId = freezed,Object? outletId = freezed,Object? role = null,Object? isActive = null,}) {
  return _then(UserCompany(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,roleId: freezed == roleId ? _self.roleId : roleId // ignore: cast_nullable_to_non_nullable
as String?,branchId: freezed == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String?,warehouseId: freezed == warehouseId ? _self.warehouseId : warehouseId // ignore: cast_nullable_to_non_nullable
as String?,outletId: freezed == outletId ? _self.outletId : outletId // ignore: cast_nullable_to_non_nullable
as String?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [UserCompany].
extension UserCompanyPatterns on UserCompany {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserCompany value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserCompany() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserCompany value)  $default,){
final _that = this;
switch (_that) {
case _UserCompany():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserCompany value)?  $default,){
final _that = this;
switch (_that) {
case _UserCompany() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'company_id')  String companyId, @JsonKey(name: 'role_id')  String? roleId, @JsonKey(name: 'branch_id')  String? branchId, @JsonKey(name: 'warehouse_id')  String? warehouseId, @JsonKey(name: 'outlet_id')  String? outletId,  String role, @JsonKey(name: 'is_active')  bool isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserCompany() when $default != null:
return $default(_that.id,_that.userId,_that.companyId,_that.roleId,_that.branchId,_that.warehouseId,_that.outletId,_that.role,_that.isActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'company_id')  String companyId, @JsonKey(name: 'role_id')  String? roleId, @JsonKey(name: 'branch_id')  String? branchId, @JsonKey(name: 'warehouse_id')  String? warehouseId, @JsonKey(name: 'outlet_id')  String? outletId,  String role, @JsonKey(name: 'is_active')  bool isActive)  $default,) {final _that = this;
switch (_that) {
case _UserCompany():
return $default(_that.id,_that.userId,_that.companyId,_that.roleId,_that.branchId,_that.warehouseId,_that.outletId,_that.role,_that.isActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'company_id')  String companyId, @JsonKey(name: 'role_id')  String? roleId, @JsonKey(name: 'branch_id')  String? branchId, @JsonKey(name: 'warehouse_id')  String? warehouseId, @JsonKey(name: 'outlet_id')  String? outletId,  String role, @JsonKey(name: 'is_active')  bool isActive)?  $default,) {final _that = this;
switch (_that) {
case _UserCompany() when $default != null:
return $default(_that.id,_that.userId,_that.companyId,_that.roleId,_that.branchId,_that.warehouseId,_that.outletId,_that.role,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserCompany implements UserCompany {
  const _UserCompany({required this.id, @JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'company_id') required this.companyId, @JsonKey(name: 'role_id') this.roleId, @JsonKey(name: 'branch_id') this.branchId, @JsonKey(name: 'warehouse_id') this.warehouseId, @JsonKey(name: 'outlet_id') this.outletId, required this.role, @JsonKey(name: 'is_active') required this.isActive});
  factory _UserCompany.fromJson(Map<String, dynamic> json) => _$UserCompanyFromJson(json);

@override final  String id;
@override@JsonKey(name: 'user_id') final  String userId;
/// The company this membership belongs to. The till compares it with the company
/// pairing locked (`session.companyId`) to pick the membership that counts.
@override@JsonKey(name: 'company_id') final  String companyId;
@override@JsonKey(name: 'role_id') final  String? roleId;
@override@JsonKey(name: 'branch_id') final  String? branchId;
@override@JsonKey(name: 'warehouse_id') final  String? warehouseId;
@override@JsonKey(name: 'outlet_id') final  String? outletId;
/// A plain string, not an enum: the source's union ends in `| string` because tenants
/// can define their own roles, and an enum would throw on the first one.
@override final  String role;
@override@JsonKey(name: 'is_active') final  bool isActive;

/// Create a copy of UserCompany
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserCompanyCopyWith<_UserCompany> get copyWith => __$UserCompanyCopyWithImpl<_UserCompany>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserCompanyToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserCompany&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.roleId, roleId) || other.roleId == roleId)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.warehouseId, warehouseId) || other.warehouseId == warehouseId)&&(identical(other.outletId, outletId) || other.outletId == outletId)&&(identical(other.role, role) || other.role == role)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,userId,companyId,roleId,branchId,warehouseId,outletId,role,isActive);
}

@override
String toString() {
    return 'UserCompany(id: $id, userId: $userId, companyId: $companyId, roleId: $roleId, branchId: $branchId, warehouseId: $warehouseId, outletId: $outletId, role: $role, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$UserCompanyCopyWith<$Res> implements $UserCompanyCopyWith<$Res> {
  factory _$UserCompanyCopyWith(_UserCompany value, $Res Function(_UserCompany) _then) = __$UserCompanyCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'company_id') String companyId,@JsonKey(name: 'role_id') String? roleId,@JsonKey(name: 'branch_id') String? branchId,@JsonKey(name: 'warehouse_id') String? warehouseId,@JsonKey(name: 'outlet_id') String? outletId, String role,@JsonKey(name: 'is_active') bool isActive
});




}
/// @nodoc
class __$UserCompanyCopyWithImpl<$Res>
    implements _$UserCompanyCopyWith<$Res> {
  __$UserCompanyCopyWithImpl(this._self, this._then);

  final _UserCompany _self;
  final $Res Function(_UserCompany) _then;

/// Create a copy of UserCompany
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? companyId = null,Object? roleId = freezed,Object? branchId = freezed,Object? warehouseId = freezed,Object? outletId = freezed,Object? role = null,Object? isActive = null,}) {
  return _then(_UserCompany(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,roleId: freezed == roleId ? _self.roleId : roleId // ignore: cast_nullable_to_non_nullable
as String?,branchId: freezed == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String?,warehouseId: freezed == warehouseId ? _self.warehouseId : warehouseId // ignore: cast_nullable_to_non_nullable
as String?,outletId: freezed == outletId ? _self.outletId : outletId // ignore: cast_nullable_to_non_nullable
as String?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$Outlet {

 String get id; String get name;
/// Create a copy of Outlet
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OutletCopyWith<Outlet> get copyWith => _$OutletCopyWithImpl<Outlet>(this as Outlet, _$identity);

  /// Serializes this Outlet to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Outlet;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Outlet&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Outlet;
  return Object.hash(runtimeType,_this.id,_this.name);
}

@override
String toString() {
  final _this = this as Outlet;
  return 'Outlet(id: ${_this.id}, name: ${_this.name})';
}


}

/// @nodoc
abstract mixin class $OutletCopyWith<$Res>  {
  factory $OutletCopyWith(Outlet value, $Res Function(Outlet) _then) = _$OutletCopyWithImpl;
@useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class _$OutletCopyWithImpl<$Res>
    implements $OutletCopyWith<$Res> {
  _$OutletCopyWithImpl(this._self, this._then);

  final Outlet _self;
  final $Res Function(Outlet) _then;

/// Create a copy of Outlet
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(Outlet(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Outlet].
extension OutletPatterns on Outlet {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Outlet value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Outlet() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Outlet value)  $default,){
final _that = this;
switch (_that) {
case _Outlet():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Outlet value)?  $default,){
final _that = this;
switch (_that) {
case _Outlet() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Outlet() when $default != null:
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name)  $default,) {final _that = this;
switch (_that) {
case _Outlet():
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name)?  $default,) {final _that = this;
switch (_that) {
case _Outlet() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Outlet implements Outlet {
  const _Outlet({required this.id, required this.name});
  factory _Outlet.fromJson(Map<String, dynamic> json) => _$OutletFromJson(json);

@override final  String id;
@override final  String name;

/// Create a copy of Outlet
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OutletCopyWith<_Outlet> get copyWith => __$OutletCopyWithImpl<_Outlet>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OutletToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Outlet&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name);
}

@override
String toString() {
    return 'Outlet(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$OutletCopyWith<$Res> implements $OutletCopyWith<$Res> {
  factory _$OutletCopyWith(_Outlet value, $Res Function(_Outlet) _then) = __$OutletCopyWithImpl;
@override @useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class __$OutletCopyWithImpl<$Res>
    implements _$OutletCopyWith<$Res> {
  __$OutletCopyWithImpl(this._self, this._then);

  final _Outlet _self;
  final $Res Function(_Outlet) _then;

/// Create a copy of Outlet
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_Outlet(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
