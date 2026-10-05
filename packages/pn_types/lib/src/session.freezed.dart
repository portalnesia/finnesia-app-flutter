// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PosBranding {

@JsonKey(name: 'app_name') String? get appName;@JsonKey(name: 'logo') FileRef? get logo;@JsonKey(name: 'custom_domain') String? get customDomain;@JsonKey(name: 'account_mode') String? get accountMode;
/// Create a copy of PosBranding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PosBrandingCopyWith<PosBranding> get copyWith => _$PosBrandingCopyWithImpl<PosBranding>(this as PosBranding, _$identity);

  /// Serializes this PosBranding to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PosBranding;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PosBranding&&(identical(other.appName, _this.appName) || other.appName == _this.appName)&&(identical(other.logo, _this.logo) || other.logo == _this.logo)&&(identical(other.customDomain, _this.customDomain) || other.customDomain == _this.customDomain)&&(identical(other.accountMode, _this.accountMode) || other.accountMode == _this.accountMode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PosBranding;
  return Object.hash(runtimeType,_this.appName,_this.logo,_this.customDomain,_this.accountMode);
}

@override
String toString() {
  final _this = this as PosBranding;
  return 'PosBranding(appName: ${_this.appName}, logo: ${_this.logo}, customDomain: ${_this.customDomain}, accountMode: ${_this.accountMode})';
}


}

/// @nodoc
abstract mixin class $PosBrandingCopyWith<$Res>  {
  factory $PosBrandingCopyWith(PosBranding value, $Res Function(PosBranding) _then) = _$PosBrandingCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'app_name') String? appName,@JsonKey(name: 'logo') FileRef? logo,@JsonKey(name: 'custom_domain') String? customDomain,@JsonKey(name: 'account_mode') String? accountMode
});


$FileRefCopyWith<$Res>? get logo;

}
/// @nodoc
class _$PosBrandingCopyWithImpl<$Res>
    implements $PosBrandingCopyWith<$Res> {
  _$PosBrandingCopyWithImpl(this._self, this._then);

  final PosBranding _self;
  final $Res Function(PosBranding) _then;

/// Create a copy of PosBranding
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? appName = freezed,Object? logo = freezed,Object? customDomain = freezed,Object? accountMode = freezed,}) {
  return _then(PosBranding(
appName: freezed == appName ? _self.appName : appName // ignore: cast_nullable_to_non_nullable
as String?,logo: freezed == logo ? _self.logo : logo // ignore: cast_nullable_to_non_nullable
as FileRef?,customDomain: freezed == customDomain ? _self.customDomain : customDomain // ignore: cast_nullable_to_non_nullable
as String?,accountMode: freezed == accountMode ? _self.accountMode : accountMode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of PosBranding
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FileRefCopyWith<$Res>? get logo {
    if (_self.logo == null) {
    return null;
  }

  return $FileRefCopyWith<$Res>(_self.logo!, (value) {
    return _then(_self.copyWith(logo: value));
  });
}
}


/// Adds pattern-matching-related methods to [PosBranding].
extension PosBrandingPatterns on PosBranding {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PosBranding value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PosBranding() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PosBranding value)  $default,){
final _that = this;
switch (_that) {
case _PosBranding():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PosBranding value)?  $default,){
final _that = this;
switch (_that) {
case _PosBranding() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'app_name')  String? appName, @JsonKey(name: 'logo')  FileRef? logo, @JsonKey(name: 'custom_domain')  String? customDomain, @JsonKey(name: 'account_mode')  String? accountMode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PosBranding() when $default != null:
return $default(_that.appName,_that.logo,_that.customDomain,_that.accountMode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'app_name')  String? appName, @JsonKey(name: 'logo')  FileRef? logo, @JsonKey(name: 'custom_domain')  String? customDomain, @JsonKey(name: 'account_mode')  String? accountMode)  $default,) {final _that = this;
switch (_that) {
case _PosBranding():
return $default(_that.appName,_that.logo,_that.customDomain,_that.accountMode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'app_name')  String? appName, @JsonKey(name: 'logo')  FileRef? logo, @JsonKey(name: 'custom_domain')  String? customDomain, @JsonKey(name: 'account_mode')  String? accountMode)?  $default,) {final _that = this;
switch (_that) {
case _PosBranding() when $default != null:
return $default(_that.appName,_that.logo,_that.customDomain,_that.accountMode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PosBranding implements PosBranding {
  const _PosBranding({@JsonKey(name: 'app_name') this.appName, @JsonKey(name: 'logo') this.logo, @JsonKey(name: 'custom_domain') this.customDomain, @JsonKey(name: 'account_mode') this.accountMode});
  factory _PosBranding.fromJson(Map<String, dynamic> json) => _$PosBrandingFromJson(json);

@override@JsonKey(name: 'app_name') final  String? appName;
@override@JsonKey(name: 'logo') final  FileRef? logo;
@override@JsonKey(name: 'custom_domain') final  String? customDomain;
@override@JsonKey(name: 'account_mode') final  String? accountMode;

/// Create a copy of PosBranding
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PosBrandingCopyWith<_PosBranding> get copyWith => __$PosBrandingCopyWithImpl<_PosBranding>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PosBrandingToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PosBranding&&(identical(other.appName, appName) || other.appName == appName)&&(identical(other.logo, logo) || other.logo == logo)&&(identical(other.customDomain, customDomain) || other.customDomain == customDomain)&&(identical(other.accountMode, accountMode) || other.accountMode == accountMode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,appName,logo,customDomain,accountMode);
}

@override
String toString() {
    return 'PosBranding(appName: $appName, logo: $logo, customDomain: $customDomain, accountMode: $accountMode)';
}


}

/// @nodoc
abstract mixin class _$PosBrandingCopyWith<$Res> implements $PosBrandingCopyWith<$Res> {
  factory _$PosBrandingCopyWith(_PosBranding value, $Res Function(_PosBranding) _then) = __$PosBrandingCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'app_name') String? appName,@JsonKey(name: 'logo') FileRef? logo,@JsonKey(name: 'custom_domain') String? customDomain,@JsonKey(name: 'account_mode') String? accountMode
});


@override $FileRefCopyWith<$Res>? get logo;

}
/// @nodoc
class __$PosBrandingCopyWithImpl<$Res>
    implements _$PosBrandingCopyWith<$Res> {
  __$PosBrandingCopyWithImpl(this._self, this._then);

  final _PosBranding _self;
  final $Res Function(_PosBranding) _then;

/// Create a copy of PosBranding
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? appName = freezed,Object? logo = freezed,Object? customDomain = freezed,Object? accountMode = freezed,}) {
  return _then(_PosBranding(
appName: freezed == appName ? _self.appName : appName // ignore: cast_nullable_to_non_nullable
as String?,logo: freezed == logo ? _self.logo : logo // ignore: cast_nullable_to_non_nullable
as FileRef?,customDomain: freezed == customDomain ? _self.customDomain : customDomain // ignore: cast_nullable_to_non_nullable
as String?,accountMode: freezed == accountMode ? _self.accountMode : accountMode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of PosBranding
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FileRefCopyWith<$Res>? get logo {
    if (_self.logo == null) {
    return null;
  }

  return $FileRefCopyWith<$Res>(_self.logo!, (value) {
    return _then(_self.copyWith(logo: value));
  });
}
}


/// @nodoc
mixin _$SessionUser {

 String get id; String? get name; String? get email;
/// Create a copy of SessionUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionUserCopyWith<SessionUser> get copyWith => _$SessionUserCopyWithImpl<SessionUser>(this as SessionUser, _$identity);

  /// Serializes this SessionUser to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SessionUser;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionUser&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.email, _this.email) || other.email == _this.email));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SessionUser;
  return Object.hash(runtimeType,_this.id,_this.name,_this.email);
}



}

/// @nodoc
abstract mixin class $SessionUserCopyWith<$Res>  {
  factory $SessionUserCopyWith(SessionUser value, $Res Function(SessionUser) _then) = _$SessionUserCopyWithImpl;
@useResult
$Res call({
 String id, String? name, String? email
});




}
/// @nodoc
class _$SessionUserCopyWithImpl<$Res>
    implements $SessionUserCopyWith<$Res> {
  _$SessionUserCopyWithImpl(this._self, this._then);

  final SessionUser _self;
  final $Res Function(SessionUser) _then;

/// Create a copy of SessionUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = freezed,Object? email = freezed,}) {
  return _then(SessionUser(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionUser].
extension SessionUserPatterns on SessionUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionUser value)  $default,){
final _that = this;
switch (_that) {
case _SessionUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionUser value)?  $default,){
final _that = this;
switch (_that) {
case _SessionUser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? name,  String? email)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionUser() when $default != null:
return $default(_that.id,_that.name,_that.email);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? name,  String? email)  $default,) {final _that = this;
switch (_that) {
case _SessionUser():
return $default(_that.id,_that.name,_that.email);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? name,  String? email)?  $default,) {final _that = this;
switch (_that) {
case _SessionUser() when $default != null:
return $default(_that.id,_that.name,_that.email);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionUser extends SessionUser {
  const _SessionUser({required this.id, this.name, this.email}): super._();
  factory _SessionUser.fromJson(Map<String, dynamic> json) => _$SessionUserFromJson(json);

@override final  String id;
@override final  String? name;
@override final  String? email;

/// Create a copy of SessionUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionUserCopyWith<_SessionUser> get copyWith => __$SessionUserCopyWithImpl<_SessionUser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionUserToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionUser&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,email);
}



}

/// @nodoc
abstract mixin class _$SessionUserCopyWith<$Res> implements $SessionUserCopyWith<$Res> {
  factory _$SessionUserCopyWith(_SessionUser value, $Res Function(_SessionUser) _then) = __$SessionUserCopyWithImpl;
@override @useResult
$Res call({
 String id, String? name, String? email
});




}
/// @nodoc
class __$SessionUserCopyWithImpl<$Res>
    implements _$SessionUserCopyWith<$Res> {
  __$SessionUserCopyWithImpl(this._self, this._then);

  final _SessionUser _self;
  final $Res Function(_SessionUser) _then;

/// Create a copy of SessionUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,Object? email = freezed,}) {
  return _then(_SessionUser(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$PosSession {

/// Tenant origin, locked from pairing. Example: https://erp.perusahaan.com
 String get baseUrl; String get companyId; String get outletId;/// Device name, sent at pairing and login (device audit).
 String? get deviceName;/// The credential that identifies this tablet, sent as `X-Device-Token` on every POS
/// request. Activation returns it exactly once and no endpoint fetches it again, so it is
/// persisted with the session rather than kept in memory.
///
/// `null` on a device paired before the registry change: it has no token, and the only way
/// to get one is to pair again. That is not an error — it is a device that has to re-pair,
/// and the transport reads it as "send no header" rather than sending an empty one.
 String? get deviceToken;/// Set when the server said this tablet is no longer registered, and cleared by pairing
/// again. It is what sends the device back to the pairing screen.
///
/// Deliberately separate from a missing [deviceToken]. A device paired against a backend
/// that predates the registry also has no token, and treating that as revoked would lock
/// every tablet out of the till until the backend caught up. Only an explicit rejection
/// from the server sets this.
 bool get deviceRevoked;/// Primary credential for the `Authorization: Bearer` header. Empty until login.
 String get sessionToken;/// Used by `POST /api/auth/refresh` when the session nears expiry.
 String? get sessionRefreshToken; String? get expiresAt; SessionUser? get user;/// The companies this cashier belongs to, as the login returned them.
///
/// Carried because the till has to answer "may this person take payment?" without a
/// round trip: the membership holds the role, and the role is what decides. `null` on a
/// device that is paired but not signed in — an empty list means the login returned no
/// memberships, which is a different fact.
 List<UserCompany>? get companies;/// Tenant branding from the activation response.
 PosBranding? get branding;
/// Create a copy of PosSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PosSessionCopyWith<PosSession> get copyWith => _$PosSessionCopyWithImpl<PosSession>(this as PosSession, _$identity);

  /// Serializes this PosSession to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PosSession;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PosSession&&(identical(other.baseUrl, _this.baseUrl) || other.baseUrl == _this.baseUrl)&&(identical(other.companyId, _this.companyId) || other.companyId == _this.companyId)&&(identical(other.outletId, _this.outletId) || other.outletId == _this.outletId)&&(identical(other.deviceName, _this.deviceName) || other.deviceName == _this.deviceName)&&(identical(other.deviceToken, _this.deviceToken) || other.deviceToken == _this.deviceToken)&&(identical(other.deviceRevoked, _this.deviceRevoked) || other.deviceRevoked == _this.deviceRevoked)&&(identical(other.sessionToken, _this.sessionToken) || other.sessionToken == _this.sessionToken)&&(identical(other.sessionRefreshToken, _this.sessionRefreshToken) || other.sessionRefreshToken == _this.sessionRefreshToken)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt)&&(identical(other.user, _this.user) || other.user == _this.user)&&const DeepCollectionEquality().equals(other.companies, _this.companies)&&(identical(other.branding, _this.branding) || other.branding == _this.branding));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PosSession;
  return Object.hash(runtimeType,_this.baseUrl,_this.companyId,_this.outletId,_this.deviceName,_this.deviceToken,_this.deviceRevoked,_this.sessionToken,_this.sessionRefreshToken,_this.expiresAt,_this.user,const DeepCollectionEquality().hash(_this.companies),_this.branding);
}



}

/// @nodoc
abstract mixin class $PosSessionCopyWith<$Res>  {
  factory $PosSessionCopyWith(PosSession value, $Res Function(PosSession) _then) = _$PosSessionCopyWithImpl;
@useResult
$Res call({
 String baseUrl, String companyId, String outletId, String? deviceName, String? deviceToken, bool deviceRevoked, String sessionToken, String? sessionRefreshToken, String? expiresAt, SessionUser? user, List<UserCompany>? companies, PosBranding? branding
});


$SessionUserCopyWith<$Res>? get user;$PosBrandingCopyWith<$Res>? get branding;

}
/// @nodoc
class _$PosSessionCopyWithImpl<$Res>
    implements $PosSessionCopyWith<$Res> {
  _$PosSessionCopyWithImpl(this._self, this._then);

  final PosSession _self;
  final $Res Function(PosSession) _then;

/// Create a copy of PosSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? baseUrl = null,Object? companyId = null,Object? outletId = null,Object? deviceName = freezed,Object? deviceToken = freezed,Object? deviceRevoked = null,Object? sessionToken = null,Object? sessionRefreshToken = freezed,Object? expiresAt = freezed,Object? user = freezed,Object? companies = freezed,Object? branding = freezed,}) {
  return _then(PosSession(
baseUrl: null == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,outletId: null == outletId ? _self.outletId : outletId // ignore: cast_nullable_to_non_nullable
as String,deviceName: freezed == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String?,deviceToken: freezed == deviceToken ? _self.deviceToken : deviceToken // ignore: cast_nullable_to_non_nullable
as String?,deviceRevoked: null == deviceRevoked ? _self.deviceRevoked : deviceRevoked // ignore: cast_nullable_to_non_nullable
as bool,sessionToken: null == sessionToken ? _self.sessionToken : sessionToken // ignore: cast_nullable_to_non_nullable
as String,sessionRefreshToken: freezed == sessionRefreshToken ? _self.sessionRefreshToken : sessionRefreshToken // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String?,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as SessionUser?,companies: freezed == companies ? _self.companies : companies // ignore: cast_nullable_to_non_nullable
as List<UserCompany>?,branding: freezed == branding ? _self.branding : branding // ignore: cast_nullable_to_non_nullable
as PosBranding?,
  ));
}
/// Create a copy of PosSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SessionUserCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $SessionUserCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}/// Create a copy of PosSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PosBrandingCopyWith<$Res>? get branding {
    if (_self.branding == null) {
    return null;
  }

  return $PosBrandingCopyWith<$Res>(_self.branding!, (value) {
    return _then(_self.copyWith(branding: value));
  });
}
}


/// Adds pattern-matching-related methods to [PosSession].
extension PosSessionPatterns on PosSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PosSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PosSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PosSession value)  $default,){
final _that = this;
switch (_that) {
case _PosSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PosSession value)?  $default,){
final _that = this;
switch (_that) {
case _PosSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String baseUrl,  String companyId,  String outletId,  String? deviceName,  String? deviceToken,  bool deviceRevoked,  String sessionToken,  String? sessionRefreshToken,  String? expiresAt,  SessionUser? user,  List<UserCompany>? companies,  PosBranding? branding)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PosSession() when $default != null:
return $default(_that.baseUrl,_that.companyId,_that.outletId,_that.deviceName,_that.deviceToken,_that.deviceRevoked,_that.sessionToken,_that.sessionRefreshToken,_that.expiresAt,_that.user,_that.companies,_that.branding);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String baseUrl,  String companyId,  String outletId,  String? deviceName,  String? deviceToken,  bool deviceRevoked,  String sessionToken,  String? sessionRefreshToken,  String? expiresAt,  SessionUser? user,  List<UserCompany>? companies,  PosBranding? branding)  $default,) {final _that = this;
switch (_that) {
case _PosSession():
return $default(_that.baseUrl,_that.companyId,_that.outletId,_that.deviceName,_that.deviceToken,_that.deviceRevoked,_that.sessionToken,_that.sessionRefreshToken,_that.expiresAt,_that.user,_that.companies,_that.branding);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String baseUrl,  String companyId,  String outletId,  String? deviceName,  String? deviceToken,  bool deviceRevoked,  String sessionToken,  String? sessionRefreshToken,  String? expiresAt,  SessionUser? user,  List<UserCompany>? companies,  PosBranding? branding)?  $default,) {final _that = this;
switch (_that) {
case _PosSession() when $default != null:
return $default(_that.baseUrl,_that.companyId,_that.outletId,_that.deviceName,_that.deviceToken,_that.deviceRevoked,_that.sessionToken,_that.sessionRefreshToken,_that.expiresAt,_that.user,_that.companies,_that.branding);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PosSession extends PosSession {
  const _PosSession({required this.baseUrl, required this.companyId, required this.outletId, this.deviceName, this.deviceToken, this.deviceRevoked = false, required this.sessionToken, this.sessionRefreshToken, this.expiresAt, this.user,  List<UserCompany>? companies, this.branding}): _companies = companies,super._();
  factory _PosSession.fromJson(Map<String, dynamic> json) => _$PosSessionFromJson(json);

/// Tenant origin, locked from pairing. Example: https://erp.perusahaan.com
@override final  String baseUrl;
@override final  String companyId;
@override final  String outletId;
/// Device name, sent at pairing and login (device audit).
@override final  String? deviceName;
/// The credential that identifies this tablet, sent as `X-Device-Token` on every POS
/// request. Activation returns it exactly once and no endpoint fetches it again, so it is
/// persisted with the session rather than kept in memory.
///
/// `null` on a device paired before the registry change: it has no token, and the only way
/// to get one is to pair again. That is not an error — it is a device that has to re-pair,
/// and the transport reads it as "send no header" rather than sending an empty one.
@override final  String? deviceToken;
/// Set when the server said this tablet is no longer registered, and cleared by pairing
/// again. It is what sends the device back to the pairing screen.
///
/// Deliberately separate from a missing [deviceToken]. A device paired against a backend
/// that predates the registry also has no token, and treating that as revoked would lock
/// every tablet out of the till until the backend caught up. Only an explicit rejection
/// from the server sets this.
@override@JsonKey() final  bool deviceRevoked;
/// Primary credential for the `Authorization: Bearer` header. Empty until login.
@override final  String sessionToken;
/// Used by `POST /api/auth/refresh` when the session nears expiry.
@override final  String? sessionRefreshToken;
@override final  String? expiresAt;
@override final  SessionUser? user;
/// The companies this cashier belongs to, as the login returned them.
///
/// Carried because the till has to answer "may this person take payment?" without a
/// round trip: the membership holds the role, and the role is what decides. `null` on a
/// device that is paired but not signed in — an empty list means the login returned no
/// memberships, which is a different fact.
 final  List<UserCompany>? _companies;
/// The companies this cashier belongs to, as the login returned them.
///
/// Carried because the till has to answer "may this person take payment?" without a
/// round trip: the membership holds the role, and the role is what decides. `null` on a
/// device that is paired but not signed in — an empty list means the login returned no
/// memberships, which is a different fact.
@override List<UserCompany>? get companies {
  final value = _companies;
  if (value == null) return null;
  if (_companies is EqualUnmodifiableListView) return _companies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Tenant branding from the activation response.
@override final  PosBranding? branding;

/// Create a copy of PosSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PosSessionCopyWith<_PosSession> get copyWith => __$PosSessionCopyWithImpl<_PosSession>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PosSessionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PosSession&&(identical(other.baseUrl, baseUrl) || other.baseUrl == baseUrl)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.outletId, outletId) || other.outletId == outletId)&&(identical(other.deviceName, deviceName) || other.deviceName == deviceName)&&(identical(other.deviceToken, deviceToken) || other.deviceToken == deviceToken)&&(identical(other.deviceRevoked, deviceRevoked) || other.deviceRevoked == deviceRevoked)&&(identical(other.sessionToken, sessionToken) || other.sessionToken == sessionToken)&&(identical(other.sessionRefreshToken, sessionRefreshToken) || other.sessionRefreshToken == sessionRefreshToken)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.user, user) || other.user == user)&&const DeepCollectionEquality().equals(other.companies, _companies)&&(identical(other.branding, branding) || other.branding == branding));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,baseUrl,companyId,outletId,deviceName,deviceToken,deviceRevoked,sessionToken,sessionRefreshToken,expiresAt,user,const DeepCollectionEquality().hash(_companies),branding);
}



}

/// @nodoc
abstract mixin class _$PosSessionCopyWith<$Res> implements $PosSessionCopyWith<$Res> {
  factory _$PosSessionCopyWith(_PosSession value, $Res Function(_PosSession) _then) = __$PosSessionCopyWithImpl;
@override @useResult
$Res call({
 String baseUrl, String companyId, String outletId, String? deviceName, String? deviceToken, bool deviceRevoked, String sessionToken, String? sessionRefreshToken, String? expiresAt, SessionUser? user, List<UserCompany>? companies, PosBranding? branding
});


@override $SessionUserCopyWith<$Res>? get user;@override $PosBrandingCopyWith<$Res>? get branding;

}
/// @nodoc
class __$PosSessionCopyWithImpl<$Res>
    implements _$PosSessionCopyWith<$Res> {
  __$PosSessionCopyWithImpl(this._self, this._then);

  final _PosSession _self;
  final $Res Function(_PosSession) _then;

/// Create a copy of PosSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? baseUrl = null,Object? companyId = null,Object? outletId = null,Object? deviceName = freezed,Object? deviceToken = freezed,Object? deviceRevoked = null,Object? sessionToken = null,Object? sessionRefreshToken = freezed,Object? expiresAt = freezed,Object? user = freezed,Object? companies = freezed,Object? branding = freezed,}) {
  return _then(_PosSession(
baseUrl: null == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,outletId: null == outletId ? _self.outletId : outletId // ignore: cast_nullable_to_non_nullable
as String,deviceName: freezed == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String?,deviceToken: freezed == deviceToken ? _self.deviceToken : deviceToken // ignore: cast_nullable_to_non_nullable
as String?,deviceRevoked: null == deviceRevoked ? _self.deviceRevoked : deviceRevoked // ignore: cast_nullable_to_non_nullable
as bool,sessionToken: null == sessionToken ? _self.sessionToken : sessionToken // ignore: cast_nullable_to_non_nullable
as String,sessionRefreshToken: freezed == sessionRefreshToken ? _self.sessionRefreshToken : sessionRefreshToken // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String?,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as SessionUser?,companies: freezed == companies ? _self._companies : companies // ignore: cast_nullable_to_non_nullable
as List<UserCompany>?,branding: freezed == branding ? _self.branding : branding // ignore: cast_nullable_to_non_nullable
as PosBranding?,
  ));
}

/// Create a copy of PosSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SessionUserCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $SessionUserCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}/// Create a copy of PosSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PosBrandingCopyWith<$Res>? get branding {
    if (_self.branding == null) {
    return null;
  }

  return $PosBrandingCopyWith<$Res>(_self.branding!, (value) {
    return _then(_self.copyWith(branding: value));
  });
}
}

// dart format on
