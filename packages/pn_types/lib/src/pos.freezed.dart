// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pos.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NamedRef {

 String get id; String? get name;
/// Create a copy of NamedRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NamedRefCopyWith<NamedRef> get copyWith => _$NamedRefCopyWithImpl<NamedRef>(this as NamedRef, _$identity);

  /// Serializes this NamedRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NamedRef;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NamedRef&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NamedRef;
  return Object.hash(runtimeType,_this.id,_this.name);
}

@override
String toString() {
  final _this = this as NamedRef;
  return 'NamedRef(id: ${_this.id}, name: ${_this.name})';
}


}

/// @nodoc
abstract mixin class $NamedRefCopyWith<$Res>  {
  factory $NamedRefCopyWith(NamedRef value, $Res Function(NamedRef) _then) = _$NamedRefCopyWithImpl;
@useResult
$Res call({
 String id, String? name
});




}
/// @nodoc
class _$NamedRefCopyWithImpl<$Res>
    implements $NamedRefCopyWith<$Res> {
  _$NamedRefCopyWithImpl(this._self, this._then);

  final NamedRef _self;
  final $Res Function(NamedRef) _then;

/// Create a copy of NamedRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = freezed,}) {
  return _then(NamedRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [NamedRef].
extension NamedRefPatterns on NamedRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NamedRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NamedRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NamedRef value)  $default,){
final _that = this;
switch (_that) {
case _NamedRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NamedRef value)?  $default,){
final _that = this;
switch (_that) {
case _NamedRef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NamedRef() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? name)  $default,) {final _that = this;
switch (_that) {
case _NamedRef():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? name)?  $default,) {final _that = this;
switch (_that) {
case _NamedRef() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NamedRef implements NamedRef {
  const _NamedRef({required this.id, this.name});
  factory _NamedRef.fromJson(Map<String, dynamic> json) => _$NamedRefFromJson(json);

@override final  String id;
@override final  String? name;

/// Create a copy of NamedRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NamedRefCopyWith<_NamedRef> get copyWith => __$NamedRefCopyWithImpl<_NamedRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NamedRefToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NamedRef&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name);
}

@override
String toString() {
    return 'NamedRef(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$NamedRefCopyWith<$Res> implements $NamedRefCopyWith<$Res> {
  factory _$NamedRefCopyWith(_NamedRef value, $Res Function(_NamedRef) _then) = __$NamedRefCopyWithImpl;
@override @useResult
$Res call({
 String id, String? name
});




}
/// @nodoc
class __$NamedRefCopyWithImpl<$Res>
    implements _$NamedRefCopyWith<$Res> {
  __$NamedRefCopyWithImpl(this._self, this._then);

  final _NamedRef _self;
  final $Res Function(_NamedRef) _then;

/// Create a copy of NamedRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,}) {
  return _then(_NamedRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$POSSalePayment {

 String get id; String get method; num get amount; String? get reference;
/// Create a copy of POSSalePayment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$POSSalePaymentCopyWith<POSSalePayment> get copyWith => _$POSSalePaymentCopyWithImpl<POSSalePayment>(this as POSSalePayment, _$identity);

  /// Serializes this POSSalePayment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as POSSalePayment;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is POSSalePayment&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.method, _this.method) || other.method == _this.method)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.reference, _this.reference) || other.reference == _this.reference));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as POSSalePayment;
  return Object.hash(runtimeType,_this.id,_this.method,_this.amount,_this.reference);
}

@override
String toString() {
  final _this = this as POSSalePayment;
  return 'POSSalePayment(id: ${_this.id}, method: ${_this.method}, amount: ${_this.amount}, reference: ${_this.reference})';
}


}

/// @nodoc
abstract mixin class $POSSalePaymentCopyWith<$Res>  {
  factory $POSSalePaymentCopyWith(POSSalePayment value, $Res Function(POSSalePayment) _then) = _$POSSalePaymentCopyWithImpl;
@useResult
$Res call({
 String id, String method, num amount, String? reference
});




}
/// @nodoc
class _$POSSalePaymentCopyWithImpl<$Res>
    implements $POSSalePaymentCopyWith<$Res> {
  _$POSSalePaymentCopyWithImpl(this._self, this._then);

  final POSSalePayment _self;
  final $Res Function(POSSalePayment) _then;

/// Create a copy of POSSalePayment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? method = null,Object? amount = null,Object? reference = freezed,}) {
  return _then(POSSalePayment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as num,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [POSSalePayment].
extension POSSalePaymentPatterns on POSSalePayment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _POSSalePayment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _POSSalePayment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _POSSalePayment value)  $default,){
final _that = this;
switch (_that) {
case _POSSalePayment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _POSSalePayment value)?  $default,){
final _that = this;
switch (_that) {
case _POSSalePayment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String method,  num amount,  String? reference)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _POSSalePayment() when $default != null:
return $default(_that.id,_that.method,_that.amount,_that.reference);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String method,  num amount,  String? reference)  $default,) {final _that = this;
switch (_that) {
case _POSSalePayment():
return $default(_that.id,_that.method,_that.amount,_that.reference);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String method,  num amount,  String? reference)?  $default,) {final _that = this;
switch (_that) {
case _POSSalePayment() when $default != null:
return $default(_that.id,_that.method,_that.amount,_that.reference);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _POSSalePayment implements POSSalePayment {
  const _POSSalePayment({required this.id, required this.method, required this.amount, this.reference});
  factory _POSSalePayment.fromJson(Map<String, dynamic> json) => _$POSSalePaymentFromJson(json);

@override final  String id;
@override final  String method;
@override final  num amount;
@override final  String? reference;

/// Create a copy of POSSalePayment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$POSSalePaymentCopyWith<_POSSalePayment> get copyWith => __$POSSalePaymentCopyWithImpl<_POSSalePayment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$POSSalePaymentToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _POSSalePayment&&(identical(other.id, id) || other.id == id)&&(identical(other.method, method) || other.method == method)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.reference, reference) || other.reference == reference));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,method,amount,reference);
}

@override
String toString() {
    return 'POSSalePayment(id: $id, method: $method, amount: $amount, reference: $reference)';
}


}

/// @nodoc
abstract mixin class _$POSSalePaymentCopyWith<$Res> implements $POSSalePaymentCopyWith<$Res> {
  factory _$POSSalePaymentCopyWith(_POSSalePayment value, $Res Function(_POSSalePayment) _then) = __$POSSalePaymentCopyWithImpl;
@override @useResult
$Res call({
 String id, String method, num amount, String? reference
});




}
/// @nodoc
class __$POSSalePaymentCopyWithImpl<$Res>
    implements _$POSSalePaymentCopyWith<$Res> {
  __$POSSalePaymentCopyWithImpl(this._self, this._then);

  final _POSSalePayment _self;
  final $Res Function(_POSSalePayment) _then;

/// Create a copy of POSSalePayment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? method = null,Object? amount = null,Object? reference = freezed,}) {
  return _then(_POSSalePayment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as num,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SalesInvoiceItem {

 String get id; num get quantity; num get price;@JsonKey(name: 'line_subtotal') num get lineSubtotal;@JsonKey(name: 'line_total') num get lineTotal; String? get description; NamedRef? get product;
/// Create a copy of SalesInvoiceItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SalesInvoiceItemCopyWith<SalesInvoiceItem> get copyWith => _$SalesInvoiceItemCopyWithImpl<SalesInvoiceItem>(this as SalesInvoiceItem, _$identity);

  /// Serializes this SalesInvoiceItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SalesInvoiceItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SalesInvoiceItem&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.quantity, _this.quantity) || other.quantity == _this.quantity)&&(identical(other.price, _this.price) || other.price == _this.price)&&(identical(other.lineSubtotal, _this.lineSubtotal) || other.lineSubtotal == _this.lineSubtotal)&&(identical(other.lineTotal, _this.lineTotal) || other.lineTotal == _this.lineTotal)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.product, _this.product) || other.product == _this.product));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SalesInvoiceItem;
  return Object.hash(runtimeType,_this.id,_this.quantity,_this.price,_this.lineSubtotal,_this.lineTotal,_this.description,_this.product);
}

@override
String toString() {
  final _this = this as SalesInvoiceItem;
  return 'SalesInvoiceItem(id: ${_this.id}, quantity: ${_this.quantity}, price: ${_this.price}, lineSubtotal: ${_this.lineSubtotal}, lineTotal: ${_this.lineTotal}, description: ${_this.description}, product: ${_this.product})';
}


}

/// @nodoc
abstract mixin class $SalesInvoiceItemCopyWith<$Res>  {
  factory $SalesInvoiceItemCopyWith(SalesInvoiceItem value, $Res Function(SalesInvoiceItem) _then) = _$SalesInvoiceItemCopyWithImpl;
@useResult
$Res call({
 String id, num quantity, num price,@JsonKey(name: 'line_subtotal') num lineSubtotal,@JsonKey(name: 'line_total') num lineTotal, String? description, NamedRef? product
});


$NamedRefCopyWith<$Res>? get product;

}
/// @nodoc
class _$SalesInvoiceItemCopyWithImpl<$Res>
    implements $SalesInvoiceItemCopyWith<$Res> {
  _$SalesInvoiceItemCopyWithImpl(this._self, this._then);

  final SalesInvoiceItem _self;
  final $Res Function(SalesInvoiceItem) _then;

/// Create a copy of SalesInvoiceItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? quantity = null,Object? price = null,Object? lineSubtotal = null,Object? lineTotal = null,Object? description = freezed,Object? product = freezed,}) {
  return _then(SalesInvoiceItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as num,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as num,lineSubtotal: null == lineSubtotal ? _self.lineSubtotal : lineSubtotal // ignore: cast_nullable_to_non_nullable
as num,lineTotal: null == lineTotal ? _self.lineTotal : lineTotal // ignore: cast_nullable_to_non_nullable
as num,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,product: freezed == product ? _self.product : product // ignore: cast_nullable_to_non_nullable
as NamedRef?,
  ));
}
/// Create a copy of SalesInvoiceItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NamedRefCopyWith<$Res>? get product {
    if (_self.product == null) {
    return null;
  }

  return $NamedRefCopyWith<$Res>(_self.product!, (value) {
    return _then(_self.copyWith(product: value));
  });
}
}


/// Adds pattern-matching-related methods to [SalesInvoiceItem].
extension SalesInvoiceItemPatterns on SalesInvoiceItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SalesInvoiceItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SalesInvoiceItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SalesInvoiceItem value)  $default,){
final _that = this;
switch (_that) {
case _SalesInvoiceItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SalesInvoiceItem value)?  $default,){
final _that = this;
switch (_that) {
case _SalesInvoiceItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  num quantity,  num price, @JsonKey(name: 'line_subtotal')  num lineSubtotal, @JsonKey(name: 'line_total')  num lineTotal,  String? description,  NamedRef? product)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SalesInvoiceItem() when $default != null:
return $default(_that.id,_that.quantity,_that.price,_that.lineSubtotal,_that.lineTotal,_that.description,_that.product);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  num quantity,  num price, @JsonKey(name: 'line_subtotal')  num lineSubtotal, @JsonKey(name: 'line_total')  num lineTotal,  String? description,  NamedRef? product)  $default,) {final _that = this;
switch (_that) {
case _SalesInvoiceItem():
return $default(_that.id,_that.quantity,_that.price,_that.lineSubtotal,_that.lineTotal,_that.description,_that.product);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  num quantity,  num price, @JsonKey(name: 'line_subtotal')  num lineSubtotal, @JsonKey(name: 'line_total')  num lineTotal,  String? description,  NamedRef? product)?  $default,) {final _that = this;
switch (_that) {
case _SalesInvoiceItem() when $default != null:
return $default(_that.id,_that.quantity,_that.price,_that.lineSubtotal,_that.lineTotal,_that.description,_that.product);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _SalesInvoiceItem implements SalesInvoiceItem {
  const _SalesInvoiceItem({required this.id, required this.quantity, required this.price, @JsonKey(name: 'line_subtotal') required this.lineSubtotal, @JsonKey(name: 'line_total') required this.lineTotal, this.description, this.product});
  factory _SalesInvoiceItem.fromJson(Map<String, dynamic> json) => _$SalesInvoiceItemFromJson(json);

@override final  String id;
@override final  num quantity;
@override final  num price;
@override@JsonKey(name: 'line_subtotal') final  num lineSubtotal;
@override@JsonKey(name: 'line_total') final  num lineTotal;
@override final  String? description;
@override final  NamedRef? product;

/// Create a copy of SalesInvoiceItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SalesInvoiceItemCopyWith<_SalesInvoiceItem> get copyWith => __$SalesInvoiceItemCopyWithImpl<_SalesInvoiceItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SalesInvoiceItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SalesInvoiceItem&&(identical(other.id, id) || other.id == id)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.price, price) || other.price == price)&&(identical(other.lineSubtotal, lineSubtotal) || other.lineSubtotal == lineSubtotal)&&(identical(other.lineTotal, lineTotal) || other.lineTotal == lineTotal)&&(identical(other.description, description) || other.description == description)&&(identical(other.product, product) || other.product == product));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,quantity,price,lineSubtotal,lineTotal,description,product);
}

@override
String toString() {
    return 'SalesInvoiceItem(id: $id, quantity: $quantity, price: $price, lineSubtotal: $lineSubtotal, lineTotal: $lineTotal, description: $description, product: $product)';
}


}

/// @nodoc
abstract mixin class _$SalesInvoiceItemCopyWith<$Res> implements $SalesInvoiceItemCopyWith<$Res> {
  factory _$SalesInvoiceItemCopyWith(_SalesInvoiceItem value, $Res Function(_SalesInvoiceItem) _then) = __$SalesInvoiceItemCopyWithImpl;
@override @useResult
$Res call({
 String id, num quantity, num price,@JsonKey(name: 'line_subtotal') num lineSubtotal,@JsonKey(name: 'line_total') num lineTotal, String? description, NamedRef? product
});


@override $NamedRefCopyWith<$Res>? get product;

}
/// @nodoc
class __$SalesInvoiceItemCopyWithImpl<$Res>
    implements _$SalesInvoiceItemCopyWith<$Res> {
  __$SalesInvoiceItemCopyWithImpl(this._self, this._then);

  final _SalesInvoiceItem _self;
  final $Res Function(_SalesInvoiceItem) _then;

/// Create a copy of SalesInvoiceItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? quantity = null,Object? price = null,Object? lineSubtotal = null,Object? lineTotal = null,Object? description = freezed,Object? product = freezed,}) {
  return _then(_SalesInvoiceItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as num,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as num,lineSubtotal: null == lineSubtotal ? _self.lineSubtotal : lineSubtotal // ignore: cast_nullable_to_non_nullable
as num,lineTotal: null == lineTotal ? _self.lineTotal : lineTotal // ignore: cast_nullable_to_non_nullable
as num,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,product: freezed == product ? _self.product : product // ignore: cast_nullable_to_non_nullable
as NamedRef?,
  ));
}

/// Create a copy of SalesInvoiceItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NamedRefCopyWith<$Res>? get product {
    if (_self.product == null) {
    return null;
  }

  return $NamedRefCopyWith<$Res>(_self.product!, (value) {
    return _then(_self.copyWith(product: value));
  });
}
}


/// @nodoc
mixin _$SalesInvoice {

 List<SalesInvoiceItem> get items;
/// Create a copy of SalesInvoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SalesInvoiceCopyWith<SalesInvoice> get copyWith => _$SalesInvoiceCopyWithImpl<SalesInvoice>(this as SalesInvoice, _$identity);

  /// Serializes this SalesInvoice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SalesInvoice;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SalesInvoice&&const DeepCollectionEquality().equals(other.items, _this.items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SalesInvoice;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items));
}

@override
String toString() {
  final _this = this as SalesInvoice;
  return 'SalesInvoice(items: ${_this.items})';
}


}

/// @nodoc
abstract mixin class $SalesInvoiceCopyWith<$Res>  {
  factory $SalesInvoiceCopyWith(SalesInvoice value, $Res Function(SalesInvoice) _then) = _$SalesInvoiceCopyWithImpl;
@useResult
$Res call({
 List<SalesInvoiceItem> items
});




}
/// @nodoc
class _$SalesInvoiceCopyWithImpl<$Res>
    implements $SalesInvoiceCopyWith<$Res> {
  _$SalesInvoiceCopyWithImpl(this._self, this._then);

  final SalesInvoice _self;
  final $Res Function(SalesInvoice) _then;

/// Create a copy of SalesInvoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,}) {
  return _then(SalesInvoice(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<SalesInvoiceItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [SalesInvoice].
extension SalesInvoicePatterns on SalesInvoice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SalesInvoice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SalesInvoice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SalesInvoice value)  $default,){
final _that = this;
switch (_that) {
case _SalesInvoice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SalesInvoice value)?  $default,){
final _that = this;
switch (_that) {
case _SalesInvoice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SalesInvoiceItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SalesInvoice() when $default != null:
return $default(_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SalesInvoiceItem> items)  $default,) {final _that = this;
switch (_that) {
case _SalesInvoice():
return $default(_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SalesInvoiceItem> items)?  $default,) {final _that = this;
switch (_that) {
case _SalesInvoice() when $default != null:
return $default(_that.items);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _SalesInvoice implements SalesInvoice {
  const _SalesInvoice({ List<SalesInvoiceItem> items = const <SalesInvoiceItem>[]}): _items = items;
  factory _SalesInvoice.fromJson(Map<String, dynamic> json) => _$SalesInvoiceFromJson(json);

 final  List<SalesInvoiceItem> _items;
@override@JsonKey() List<SalesInvoiceItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of SalesInvoice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SalesInvoiceCopyWith<_SalesInvoice> get copyWith => __$SalesInvoiceCopyWithImpl<_SalesInvoice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SalesInvoiceToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SalesInvoice&&const DeepCollectionEquality().equals(other.items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items));
}

@override
String toString() {
    return 'SalesInvoice(items: $items)';
}


}

/// @nodoc
abstract mixin class _$SalesInvoiceCopyWith<$Res> implements $SalesInvoiceCopyWith<$Res> {
  factory _$SalesInvoiceCopyWith(_SalesInvoice value, $Res Function(_SalesInvoice) _then) = __$SalesInvoiceCopyWithImpl;
@override @useResult
$Res call({
 List<SalesInvoiceItem> items
});




}
/// @nodoc
class __$SalesInvoiceCopyWithImpl<$Res>
    implements _$SalesInvoiceCopyWith<$Res> {
  __$SalesInvoiceCopyWithImpl(this._self, this._then);

  final _SalesInvoice _self;
  final $Res Function(_SalesInvoice) _then;

/// Create a copy of SalesInvoice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,}) {
  return _then(_SalesInvoice(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<SalesInvoiceItem>,
  ));
}


}


/// @nodoc
mixin _$POSSale {

 String get id; String get number;@JsonKey(name: 'shift_id') String get shiftId;@JsonKey(name: 'outlet_id') String get outletId;@JsonKey(name: 'cashier_id') String get cashierId;@JsonKey(name: 'transaction_date') String get transactionDate; num get subtotal;@JsonKey(name: 'discount_amount') num get discountAmount;@JsonKey(name: 'tax_amount') num get taxAmount;@JsonKey(name: 'grand_total') num get grandTotal;@JsonKey(name: 'tendered_amount') num get tenderedAmount;@JsonKey(name: 'change_amount') num get changeAmount;/// A status this build does not know reads as `null`, like `ProductType`: a newer API
/// must not take the transaction list down over one row.
@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) POSSaleStatus? get status;@JsonKey(name: 'created_at') String get createdAt;@JsonKey(name: 'client_ref') String? get clientRef;@JsonKey(name: 'paid_at') String? get paidAt; String? get notes;@JsonKey(name: 'table_number') String? get tableNumber;@JsonKey(name: 'queue_number') String? get queueNumber; List<POSSalePayment>? get payments; SalesInvoice? get invoice; NamedRef? get cashier;
/// Create a copy of POSSale
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$POSSaleCopyWith<POSSale> get copyWith => _$POSSaleCopyWithImpl<POSSale>(this as POSSale, _$identity);

  /// Serializes this POSSale to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as POSSale;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is POSSale&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.number, _this.number) || other.number == _this.number)&&(identical(other.shiftId, _this.shiftId) || other.shiftId == _this.shiftId)&&(identical(other.outletId, _this.outletId) || other.outletId == _this.outletId)&&(identical(other.cashierId, _this.cashierId) || other.cashierId == _this.cashierId)&&(identical(other.transactionDate, _this.transactionDate) || other.transactionDate == _this.transactionDate)&&(identical(other.subtotal, _this.subtotal) || other.subtotal == _this.subtotal)&&(identical(other.discountAmount, _this.discountAmount) || other.discountAmount == _this.discountAmount)&&(identical(other.taxAmount, _this.taxAmount) || other.taxAmount == _this.taxAmount)&&(identical(other.grandTotal, _this.grandTotal) || other.grandTotal == _this.grandTotal)&&(identical(other.tenderedAmount, _this.tenderedAmount) || other.tenderedAmount == _this.tenderedAmount)&&(identical(other.changeAmount, _this.changeAmount) || other.changeAmount == _this.changeAmount)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.clientRef, _this.clientRef) || other.clientRef == _this.clientRef)&&(identical(other.paidAt, _this.paidAt) || other.paidAt == _this.paidAt)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&(identical(other.tableNumber, _this.tableNumber) || other.tableNumber == _this.tableNumber)&&(identical(other.queueNumber, _this.queueNumber) || other.queueNumber == _this.queueNumber)&&const DeepCollectionEquality().equals(other.payments, _this.payments)&&(identical(other.invoice, _this.invoice) || other.invoice == _this.invoice)&&(identical(other.cashier, _this.cashier) || other.cashier == _this.cashier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as POSSale;
  return Object.hashAll([runtimeType,_this.id,_this.number,_this.shiftId,_this.outletId,_this.cashierId,_this.transactionDate,_this.subtotal,_this.discountAmount,_this.taxAmount,_this.grandTotal,_this.tenderedAmount,_this.changeAmount,_this.status,_this.createdAt,_this.clientRef,_this.paidAt,_this.notes,_this.tableNumber,_this.queueNumber,const DeepCollectionEquality().hash(_this.payments),_this.invoice,_this.cashier]);
}

@override
String toString() {
  final _this = this as POSSale;
  return 'POSSale(id: ${_this.id}, number: ${_this.number}, shiftId: ${_this.shiftId}, outletId: ${_this.outletId}, cashierId: ${_this.cashierId}, transactionDate: ${_this.transactionDate}, subtotal: ${_this.subtotal}, discountAmount: ${_this.discountAmount}, taxAmount: ${_this.taxAmount}, grandTotal: ${_this.grandTotal}, tenderedAmount: ${_this.tenderedAmount}, changeAmount: ${_this.changeAmount}, status: ${_this.status}, createdAt: ${_this.createdAt}, clientRef: ${_this.clientRef}, paidAt: ${_this.paidAt}, notes: ${_this.notes}, tableNumber: ${_this.tableNumber}, queueNumber: ${_this.queueNumber}, payments: ${_this.payments}, invoice: ${_this.invoice}, cashier: ${_this.cashier})';
}


}

/// @nodoc
abstract mixin class $POSSaleCopyWith<$Res>  {
  factory $POSSaleCopyWith(POSSale value, $Res Function(POSSale) _then) = _$POSSaleCopyWithImpl;
@useResult
$Res call({
 String id, String number,@JsonKey(name: 'shift_id') String shiftId,@JsonKey(name: 'outlet_id') String outletId,@JsonKey(name: 'cashier_id') String cashierId,@JsonKey(name: 'transaction_date') String transactionDate, num subtotal,@JsonKey(name: 'discount_amount') num discountAmount,@JsonKey(name: 'tax_amount') num taxAmount,@JsonKey(name: 'grand_total') num grandTotal,@JsonKey(name: 'tendered_amount') num tenderedAmount,@JsonKey(name: 'change_amount') num changeAmount,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) POSSaleStatus? status,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'client_ref') String? clientRef,@JsonKey(name: 'paid_at') String? paidAt, String? notes,@JsonKey(name: 'table_number') String? tableNumber,@JsonKey(name: 'queue_number') String? queueNumber, List<POSSalePayment>? payments, SalesInvoice? invoice, NamedRef? cashier
});


$SalesInvoiceCopyWith<$Res>? get invoice;$NamedRefCopyWith<$Res>? get cashier;

}
/// @nodoc
class _$POSSaleCopyWithImpl<$Res>
    implements $POSSaleCopyWith<$Res> {
  _$POSSaleCopyWithImpl(this._self, this._then);

  final POSSale _self;
  final $Res Function(POSSale) _then;

/// Create a copy of POSSale
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? number = null,Object? shiftId = null,Object? outletId = null,Object? cashierId = null,Object? transactionDate = null,Object? subtotal = null,Object? discountAmount = null,Object? taxAmount = null,Object? grandTotal = null,Object? tenderedAmount = null,Object? changeAmount = null,Object? status = freezed,Object? createdAt = null,Object? clientRef = freezed,Object? paidAt = freezed,Object? notes = freezed,Object? tableNumber = freezed,Object? queueNumber = freezed,Object? payments = freezed,Object? invoice = freezed,Object? cashier = freezed,}) {
  return _then(POSSale(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,shiftId: null == shiftId ? _self.shiftId : shiftId // ignore: cast_nullable_to_non_nullable
as String,outletId: null == outletId ? _self.outletId : outletId // ignore: cast_nullable_to_non_nullable
as String,cashierId: null == cashierId ? _self.cashierId : cashierId // ignore: cast_nullable_to_non_nullable
as String,transactionDate: null == transactionDate ? _self.transactionDate : transactionDate // ignore: cast_nullable_to_non_nullable
as String,subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as num,discountAmount: null == discountAmount ? _self.discountAmount : discountAmount // ignore: cast_nullable_to_non_nullable
as num,taxAmount: null == taxAmount ? _self.taxAmount : taxAmount // ignore: cast_nullable_to_non_nullable
as num,grandTotal: null == grandTotal ? _self.grandTotal : grandTotal // ignore: cast_nullable_to_non_nullable
as num,tenderedAmount: null == tenderedAmount ? _self.tenderedAmount : tenderedAmount // ignore: cast_nullable_to_non_nullable
as num,changeAmount: null == changeAmount ? _self.changeAmount : changeAmount // ignore: cast_nullable_to_non_nullable
as num,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as POSSaleStatus?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,clientRef: freezed == clientRef ? _self.clientRef : clientRef // ignore: cast_nullable_to_non_nullable
as String?,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,tableNumber: freezed == tableNumber ? _self.tableNumber : tableNumber // ignore: cast_nullable_to_non_nullable
as String?,queueNumber: freezed == queueNumber ? _self.queueNumber : queueNumber // ignore: cast_nullable_to_non_nullable
as String?,payments: freezed == payments ? _self.payments : payments // ignore: cast_nullable_to_non_nullable
as List<POSSalePayment>?,invoice: freezed == invoice ? _self.invoice : invoice // ignore: cast_nullable_to_non_nullable
as SalesInvoice?,cashier: freezed == cashier ? _self.cashier : cashier // ignore: cast_nullable_to_non_nullable
as NamedRef?,
  ));
}
/// Create a copy of POSSale
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SalesInvoiceCopyWith<$Res>? get invoice {
    if (_self.invoice == null) {
    return null;
  }

  return $SalesInvoiceCopyWith<$Res>(_self.invoice!, (value) {
    return _then(_self.copyWith(invoice: value));
  });
}/// Create a copy of POSSale
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NamedRefCopyWith<$Res>? get cashier {
    if (_self.cashier == null) {
    return null;
  }

  return $NamedRefCopyWith<$Res>(_self.cashier!, (value) {
    return _then(_self.copyWith(cashier: value));
  });
}
}


/// Adds pattern-matching-related methods to [POSSale].
extension POSSalePatterns on POSSale {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _POSSale value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _POSSale() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _POSSale value)  $default,){
final _that = this;
switch (_that) {
case _POSSale():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _POSSale value)?  $default,){
final _that = this;
switch (_that) {
case _POSSale() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String number, @JsonKey(name: 'shift_id')  String shiftId, @JsonKey(name: 'outlet_id')  String outletId, @JsonKey(name: 'cashier_id')  String cashierId, @JsonKey(name: 'transaction_date')  String transactionDate,  num subtotal, @JsonKey(name: 'discount_amount')  num discountAmount, @JsonKey(name: 'tax_amount')  num taxAmount, @JsonKey(name: 'grand_total')  num grandTotal, @JsonKey(name: 'tendered_amount')  num tenderedAmount, @JsonKey(name: 'change_amount')  num changeAmount, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  POSSaleStatus? status, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'client_ref')  String? clientRef, @JsonKey(name: 'paid_at')  String? paidAt,  String? notes, @JsonKey(name: 'table_number')  String? tableNumber, @JsonKey(name: 'queue_number')  String? queueNumber,  List<POSSalePayment>? payments,  SalesInvoice? invoice,  NamedRef? cashier)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _POSSale() when $default != null:
return $default(_that.id,_that.number,_that.shiftId,_that.outletId,_that.cashierId,_that.transactionDate,_that.subtotal,_that.discountAmount,_that.taxAmount,_that.grandTotal,_that.tenderedAmount,_that.changeAmount,_that.status,_that.createdAt,_that.clientRef,_that.paidAt,_that.notes,_that.tableNumber,_that.queueNumber,_that.payments,_that.invoice,_that.cashier);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String number, @JsonKey(name: 'shift_id')  String shiftId, @JsonKey(name: 'outlet_id')  String outletId, @JsonKey(name: 'cashier_id')  String cashierId, @JsonKey(name: 'transaction_date')  String transactionDate,  num subtotal, @JsonKey(name: 'discount_amount')  num discountAmount, @JsonKey(name: 'tax_amount')  num taxAmount, @JsonKey(name: 'grand_total')  num grandTotal, @JsonKey(name: 'tendered_amount')  num tenderedAmount, @JsonKey(name: 'change_amount')  num changeAmount, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  POSSaleStatus? status, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'client_ref')  String? clientRef, @JsonKey(name: 'paid_at')  String? paidAt,  String? notes, @JsonKey(name: 'table_number')  String? tableNumber, @JsonKey(name: 'queue_number')  String? queueNumber,  List<POSSalePayment>? payments,  SalesInvoice? invoice,  NamedRef? cashier)  $default,) {final _that = this;
switch (_that) {
case _POSSale():
return $default(_that.id,_that.number,_that.shiftId,_that.outletId,_that.cashierId,_that.transactionDate,_that.subtotal,_that.discountAmount,_that.taxAmount,_that.grandTotal,_that.tenderedAmount,_that.changeAmount,_that.status,_that.createdAt,_that.clientRef,_that.paidAt,_that.notes,_that.tableNumber,_that.queueNumber,_that.payments,_that.invoice,_that.cashier);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String number, @JsonKey(name: 'shift_id')  String shiftId, @JsonKey(name: 'outlet_id')  String outletId, @JsonKey(name: 'cashier_id')  String cashierId, @JsonKey(name: 'transaction_date')  String transactionDate,  num subtotal, @JsonKey(name: 'discount_amount')  num discountAmount, @JsonKey(name: 'tax_amount')  num taxAmount, @JsonKey(name: 'grand_total')  num grandTotal, @JsonKey(name: 'tendered_amount')  num tenderedAmount, @JsonKey(name: 'change_amount')  num changeAmount, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  POSSaleStatus? status, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'client_ref')  String? clientRef, @JsonKey(name: 'paid_at')  String? paidAt,  String? notes, @JsonKey(name: 'table_number')  String? tableNumber, @JsonKey(name: 'queue_number')  String? queueNumber,  List<POSSalePayment>? payments,  SalesInvoice? invoice,  NamedRef? cashier)?  $default,) {final _that = this;
switch (_that) {
case _POSSale() when $default != null:
return $default(_that.id,_that.number,_that.shiftId,_that.outletId,_that.cashierId,_that.transactionDate,_that.subtotal,_that.discountAmount,_that.taxAmount,_that.grandTotal,_that.tenderedAmount,_that.changeAmount,_that.status,_that.createdAt,_that.clientRef,_that.paidAt,_that.notes,_that.tableNumber,_that.queueNumber,_that.payments,_that.invoice,_that.cashier);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _POSSale implements POSSale {
  const _POSSale({required this.id, required this.number, @JsonKey(name: 'shift_id') required this.shiftId, @JsonKey(name: 'outlet_id') required this.outletId, @JsonKey(name: 'cashier_id') required this.cashierId, @JsonKey(name: 'transaction_date') required this.transactionDate, required this.subtotal, @JsonKey(name: 'discount_amount') required this.discountAmount, @JsonKey(name: 'tax_amount') required this.taxAmount, @JsonKey(name: 'grand_total') required this.grandTotal, @JsonKey(name: 'tendered_amount') required this.tenderedAmount, @JsonKey(name: 'change_amount') required this.changeAmount, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) this.status, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'client_ref') this.clientRef, @JsonKey(name: 'paid_at') this.paidAt, this.notes, @JsonKey(name: 'table_number') this.tableNumber, @JsonKey(name: 'queue_number') this.queueNumber,  List<POSSalePayment>? payments, this.invoice, this.cashier}): _payments = payments;
  factory _POSSale.fromJson(Map<String, dynamic> json) => _$POSSaleFromJson(json);

@override final  String id;
@override final  String number;
@override@JsonKey(name: 'shift_id') final  String shiftId;
@override@JsonKey(name: 'outlet_id') final  String outletId;
@override@JsonKey(name: 'cashier_id') final  String cashierId;
@override@JsonKey(name: 'transaction_date') final  String transactionDate;
@override final  num subtotal;
@override@JsonKey(name: 'discount_amount') final  num discountAmount;
@override@JsonKey(name: 'tax_amount') final  num taxAmount;
@override@JsonKey(name: 'grand_total') final  num grandTotal;
@override@JsonKey(name: 'tendered_amount') final  num tenderedAmount;
@override@JsonKey(name: 'change_amount') final  num changeAmount;
/// A status this build does not know reads as `null`, like `ProductType`: a newer API
/// must not take the transaction list down over one row.
@override@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) final  POSSaleStatus? status;
@override@JsonKey(name: 'created_at') final  String createdAt;
@override@JsonKey(name: 'client_ref') final  String? clientRef;
@override@JsonKey(name: 'paid_at') final  String? paidAt;
@override final  String? notes;
@override@JsonKey(name: 'table_number') final  String? tableNumber;
@override@JsonKey(name: 'queue_number') final  String? queueNumber;
 final  List<POSSalePayment>? _payments;
@override List<POSSalePayment>? get payments {
  final value = _payments;
  if (value == null) return null;
  if (_payments is EqualUnmodifiableListView) return _payments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  SalesInvoice? invoice;
@override final  NamedRef? cashier;

/// Create a copy of POSSale
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$POSSaleCopyWith<_POSSale> get copyWith => __$POSSaleCopyWithImpl<_POSSale>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$POSSaleToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _POSSale&&(identical(other.id, id) || other.id == id)&&(identical(other.number, number) || other.number == number)&&(identical(other.shiftId, shiftId) || other.shiftId == shiftId)&&(identical(other.outletId, outletId) || other.outletId == outletId)&&(identical(other.cashierId, cashierId) || other.cashierId == cashierId)&&(identical(other.transactionDate, transactionDate) || other.transactionDate == transactionDate)&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.discountAmount, discountAmount) || other.discountAmount == discountAmount)&&(identical(other.taxAmount, taxAmount) || other.taxAmount == taxAmount)&&(identical(other.grandTotal, grandTotal) || other.grandTotal == grandTotal)&&(identical(other.tenderedAmount, tenderedAmount) || other.tenderedAmount == tenderedAmount)&&(identical(other.changeAmount, changeAmount) || other.changeAmount == changeAmount)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.clientRef, clientRef) || other.clientRef == clientRef)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.tableNumber, tableNumber) || other.tableNumber == tableNumber)&&(identical(other.queueNumber, queueNumber) || other.queueNumber == queueNumber)&&const DeepCollectionEquality().equals(other.payments, _payments)&&(identical(other.invoice, invoice) || other.invoice == invoice)&&(identical(other.cashier, cashier) || other.cashier == cashier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,id,number,shiftId,outletId,cashierId,transactionDate,subtotal,discountAmount,taxAmount,grandTotal,tenderedAmount,changeAmount,status,createdAt,clientRef,paidAt,notes,tableNumber,queueNumber,const DeepCollectionEquality().hash(_payments),invoice,cashier]);
}

@override
String toString() {
    return 'POSSale(id: $id, number: $number, shiftId: $shiftId, outletId: $outletId, cashierId: $cashierId, transactionDate: $transactionDate, subtotal: $subtotal, discountAmount: $discountAmount, taxAmount: $taxAmount, grandTotal: $grandTotal, tenderedAmount: $tenderedAmount, changeAmount: $changeAmount, status: $status, createdAt: $createdAt, clientRef: $clientRef, paidAt: $paidAt, notes: $notes, tableNumber: $tableNumber, queueNumber: $queueNumber, payments: $payments, invoice: $invoice, cashier: $cashier)';
}


}

/// @nodoc
abstract mixin class _$POSSaleCopyWith<$Res> implements $POSSaleCopyWith<$Res> {
  factory _$POSSaleCopyWith(_POSSale value, $Res Function(_POSSale) _then) = __$POSSaleCopyWithImpl;
@override @useResult
$Res call({
 String id, String number,@JsonKey(name: 'shift_id') String shiftId,@JsonKey(name: 'outlet_id') String outletId,@JsonKey(name: 'cashier_id') String cashierId,@JsonKey(name: 'transaction_date') String transactionDate, num subtotal,@JsonKey(name: 'discount_amount') num discountAmount,@JsonKey(name: 'tax_amount') num taxAmount,@JsonKey(name: 'grand_total') num grandTotal,@JsonKey(name: 'tendered_amount') num tenderedAmount,@JsonKey(name: 'change_amount') num changeAmount,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) POSSaleStatus? status,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'client_ref') String? clientRef,@JsonKey(name: 'paid_at') String? paidAt, String? notes,@JsonKey(name: 'table_number') String? tableNumber,@JsonKey(name: 'queue_number') String? queueNumber, List<POSSalePayment>? payments, SalesInvoice? invoice, NamedRef? cashier
});


@override $SalesInvoiceCopyWith<$Res>? get invoice;@override $NamedRefCopyWith<$Res>? get cashier;

}
/// @nodoc
class __$POSSaleCopyWithImpl<$Res>
    implements _$POSSaleCopyWith<$Res> {
  __$POSSaleCopyWithImpl(this._self, this._then);

  final _POSSale _self;
  final $Res Function(_POSSale) _then;

/// Create a copy of POSSale
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? number = null,Object? shiftId = null,Object? outletId = null,Object? cashierId = null,Object? transactionDate = null,Object? subtotal = null,Object? discountAmount = null,Object? taxAmount = null,Object? grandTotal = null,Object? tenderedAmount = null,Object? changeAmount = null,Object? status = freezed,Object? createdAt = null,Object? clientRef = freezed,Object? paidAt = freezed,Object? notes = freezed,Object? tableNumber = freezed,Object? queueNumber = freezed,Object? payments = freezed,Object? invoice = freezed,Object? cashier = freezed,}) {
  return _then(_POSSale(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,shiftId: null == shiftId ? _self.shiftId : shiftId // ignore: cast_nullable_to_non_nullable
as String,outletId: null == outletId ? _self.outletId : outletId // ignore: cast_nullable_to_non_nullable
as String,cashierId: null == cashierId ? _self.cashierId : cashierId // ignore: cast_nullable_to_non_nullable
as String,transactionDate: null == transactionDate ? _self.transactionDate : transactionDate // ignore: cast_nullable_to_non_nullable
as String,subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as num,discountAmount: null == discountAmount ? _self.discountAmount : discountAmount // ignore: cast_nullable_to_non_nullable
as num,taxAmount: null == taxAmount ? _self.taxAmount : taxAmount // ignore: cast_nullable_to_non_nullable
as num,grandTotal: null == grandTotal ? _self.grandTotal : grandTotal // ignore: cast_nullable_to_non_nullable
as num,tenderedAmount: null == tenderedAmount ? _self.tenderedAmount : tenderedAmount // ignore: cast_nullable_to_non_nullable
as num,changeAmount: null == changeAmount ? _self.changeAmount : changeAmount // ignore: cast_nullable_to_non_nullable
as num,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as POSSaleStatus?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,clientRef: freezed == clientRef ? _self.clientRef : clientRef // ignore: cast_nullable_to_non_nullable
as String?,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,tableNumber: freezed == tableNumber ? _self.tableNumber : tableNumber // ignore: cast_nullable_to_non_nullable
as String?,queueNumber: freezed == queueNumber ? _self.queueNumber : queueNumber // ignore: cast_nullable_to_non_nullable
as String?,payments: freezed == payments ? _self._payments : payments // ignore: cast_nullable_to_non_nullable
as List<POSSalePayment>?,invoice: freezed == invoice ? _self.invoice : invoice // ignore: cast_nullable_to_non_nullable
as SalesInvoice?,cashier: freezed == cashier ? _self.cashier : cashier // ignore: cast_nullable_to_non_nullable
as NamedRef?,
  ));
}

/// Create a copy of POSSale
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SalesInvoiceCopyWith<$Res>? get invoice {
    if (_self.invoice == null) {
    return null;
  }

  return $SalesInvoiceCopyWith<$Res>(_self.invoice!, (value) {
    return _then(_self.copyWith(invoice: value));
  });
}/// Create a copy of POSSale
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NamedRefCopyWith<$Res>? get cashier {
    if (_self.cashier == null) {
    return null;
  }

  return $NamedRefCopyWith<$Res>(_self.cashier!, (value) {
    return _then(_self.copyWith(cashier: value));
  });
}
}


/// @nodoc
mixin _$POSCheckoutItemDTO {

@JsonKey(name: 'product_id') String get productId;@JsonKey(name: 'unit_id') String get unitId; num get quantity; num get price;@JsonKey(name: 'discount_percent') num? get discountPercent;@JsonKey(name: 'discount_amount') num? get discountAmount;
/// Create a copy of POSCheckoutItemDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$POSCheckoutItemDTOCopyWith<POSCheckoutItemDTO> get copyWith => _$POSCheckoutItemDTOCopyWithImpl<POSCheckoutItemDTO>(this as POSCheckoutItemDTO, _$identity);

  /// Serializes this POSCheckoutItemDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as POSCheckoutItemDTO;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is POSCheckoutItemDTO&&(identical(other.productId, _this.productId) || other.productId == _this.productId)&&(identical(other.unitId, _this.unitId) || other.unitId == _this.unitId)&&(identical(other.quantity, _this.quantity) || other.quantity == _this.quantity)&&(identical(other.price, _this.price) || other.price == _this.price)&&(identical(other.discountPercent, _this.discountPercent) || other.discountPercent == _this.discountPercent)&&(identical(other.discountAmount, _this.discountAmount) || other.discountAmount == _this.discountAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as POSCheckoutItemDTO;
  return Object.hash(runtimeType,_this.productId,_this.unitId,_this.quantity,_this.price,_this.discountPercent,_this.discountAmount);
}

@override
String toString() {
  final _this = this as POSCheckoutItemDTO;
  return 'POSCheckoutItemDTO(productId: ${_this.productId}, unitId: ${_this.unitId}, quantity: ${_this.quantity}, price: ${_this.price}, discountPercent: ${_this.discountPercent}, discountAmount: ${_this.discountAmount})';
}


}

/// @nodoc
abstract mixin class $POSCheckoutItemDTOCopyWith<$Res>  {
  factory $POSCheckoutItemDTOCopyWith(POSCheckoutItemDTO value, $Res Function(POSCheckoutItemDTO) _then) = _$POSCheckoutItemDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'product_id') String productId,@JsonKey(name: 'unit_id') String unitId, num quantity, num price,@JsonKey(name: 'discount_percent') num? discountPercent,@JsonKey(name: 'discount_amount') num? discountAmount
});




}
/// @nodoc
class _$POSCheckoutItemDTOCopyWithImpl<$Res>
    implements $POSCheckoutItemDTOCopyWith<$Res> {
  _$POSCheckoutItemDTOCopyWithImpl(this._self, this._then);

  final POSCheckoutItemDTO _self;
  final $Res Function(POSCheckoutItemDTO) _then;

/// Create a copy of POSCheckoutItemDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productId = null,Object? unitId = null,Object? quantity = null,Object? price = null,Object? discountPercent = freezed,Object? discountAmount = freezed,}) {
  return _then(POSCheckoutItemDTO(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,unitId: null == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as num,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as num,discountPercent: freezed == discountPercent ? _self.discountPercent : discountPercent // ignore: cast_nullable_to_non_nullable
as num?,discountAmount: freezed == discountAmount ? _self.discountAmount : discountAmount // ignore: cast_nullable_to_non_nullable
as num?,
  ));
}

}


/// Adds pattern-matching-related methods to [POSCheckoutItemDTO].
extension POSCheckoutItemDTOPatterns on POSCheckoutItemDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _POSCheckoutItemDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _POSCheckoutItemDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _POSCheckoutItemDTO value)  $default,){
final _that = this;
switch (_that) {
case _POSCheckoutItemDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _POSCheckoutItemDTO value)?  $default,){
final _that = this;
switch (_that) {
case _POSCheckoutItemDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'product_id')  String productId, @JsonKey(name: 'unit_id')  String unitId,  num quantity,  num price, @JsonKey(name: 'discount_percent')  num? discountPercent, @JsonKey(name: 'discount_amount')  num? discountAmount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _POSCheckoutItemDTO() when $default != null:
return $default(_that.productId,_that.unitId,_that.quantity,_that.price,_that.discountPercent,_that.discountAmount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'product_id')  String productId, @JsonKey(name: 'unit_id')  String unitId,  num quantity,  num price, @JsonKey(name: 'discount_percent')  num? discountPercent, @JsonKey(name: 'discount_amount')  num? discountAmount)  $default,) {final _that = this;
switch (_that) {
case _POSCheckoutItemDTO():
return $default(_that.productId,_that.unitId,_that.quantity,_that.price,_that.discountPercent,_that.discountAmount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'product_id')  String productId, @JsonKey(name: 'unit_id')  String unitId,  num quantity,  num price, @JsonKey(name: 'discount_percent')  num? discountPercent, @JsonKey(name: 'discount_amount')  num? discountAmount)?  $default,) {final _that = this;
switch (_that) {
case _POSCheckoutItemDTO() when $default != null:
return $default(_that.productId,_that.unitId,_that.quantity,_that.price,_that.discountPercent,_that.discountAmount);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(includeIfNull: false)
class _POSCheckoutItemDTO implements POSCheckoutItemDTO {
  const _POSCheckoutItemDTO({@JsonKey(name: 'product_id') required this.productId, @JsonKey(name: 'unit_id') required this.unitId, required this.quantity, required this.price, @JsonKey(name: 'discount_percent') this.discountPercent, @JsonKey(name: 'discount_amount') this.discountAmount});
  factory _POSCheckoutItemDTO.fromJson(Map<String, dynamic> json) => _$POSCheckoutItemDTOFromJson(json);

@override@JsonKey(name: 'product_id') final  String productId;
@override@JsonKey(name: 'unit_id') final  String unitId;
@override final  num quantity;
@override final  num price;
@override@JsonKey(name: 'discount_percent') final  num? discountPercent;
@override@JsonKey(name: 'discount_amount') final  num? discountAmount;

/// Create a copy of POSCheckoutItemDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$POSCheckoutItemDTOCopyWith<_POSCheckoutItemDTO> get copyWith => __$POSCheckoutItemDTOCopyWithImpl<_POSCheckoutItemDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$POSCheckoutItemDTOToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _POSCheckoutItemDTO&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.price, price) || other.price == price)&&(identical(other.discountPercent, discountPercent) || other.discountPercent == discountPercent)&&(identical(other.discountAmount, discountAmount) || other.discountAmount == discountAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,productId,unitId,quantity,price,discountPercent,discountAmount);
}

@override
String toString() {
    return 'POSCheckoutItemDTO(productId: $productId, unitId: $unitId, quantity: $quantity, price: $price, discountPercent: $discountPercent, discountAmount: $discountAmount)';
}


}

/// @nodoc
abstract mixin class _$POSCheckoutItemDTOCopyWith<$Res> implements $POSCheckoutItemDTOCopyWith<$Res> {
  factory _$POSCheckoutItemDTOCopyWith(_POSCheckoutItemDTO value, $Res Function(_POSCheckoutItemDTO) _then) = __$POSCheckoutItemDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'product_id') String productId,@JsonKey(name: 'unit_id') String unitId, num quantity, num price,@JsonKey(name: 'discount_percent') num? discountPercent,@JsonKey(name: 'discount_amount') num? discountAmount
});




}
/// @nodoc
class __$POSCheckoutItemDTOCopyWithImpl<$Res>
    implements _$POSCheckoutItemDTOCopyWith<$Res> {
  __$POSCheckoutItemDTOCopyWithImpl(this._self, this._then);

  final _POSCheckoutItemDTO _self;
  final $Res Function(_POSCheckoutItemDTO) _then;

/// Create a copy of POSCheckoutItemDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productId = null,Object? unitId = null,Object? quantity = null,Object? price = null,Object? discountPercent = freezed,Object? discountAmount = freezed,}) {
  return _then(_POSCheckoutItemDTO(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,unitId: null == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as num,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as num,discountPercent: freezed == discountPercent ? _self.discountPercent : discountPercent // ignore: cast_nullable_to_non_nullable
as num?,discountAmount: freezed == discountAmount ? _self.discountAmount : discountAmount // ignore: cast_nullable_to_non_nullable
as num?,
  ));
}


}


/// @nodoc
mixin _$POSCheckoutDTO {

@JsonKey(name: 'outlet_id') String get outletId;@JsonKey(name: 'transaction_date') String get transactionDate; List<POSCheckoutItemDTO> get items; List<POSTenderDTO> get payments;/// Omitted when the company runs without shifts: the server reuses the caller's open
/// shift at the outlet, or opens one.
@JsonKey(name: 'shift_id') String? get shiftId;@JsonKey(name: 'customer_id') String? get customerId;@JsonKey(name: 'discount_amount') num? get discountAmount; String? get notes;@JsonKey(name: 'table_number') String? get tableNumber;@JsonKey(name: 'queue_number') String? get queueNumber;@JsonKey(name: 'client_ref') String? get clientRef;@JsonKey(name: 'paid_at') String? get paidAt;
/// Create a copy of POSCheckoutDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$POSCheckoutDTOCopyWith<POSCheckoutDTO> get copyWith => _$POSCheckoutDTOCopyWithImpl<POSCheckoutDTO>(this as POSCheckoutDTO, _$identity);

  /// Serializes this POSCheckoutDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as POSCheckoutDTO;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is POSCheckoutDTO&&(identical(other.outletId, _this.outletId) || other.outletId == _this.outletId)&&(identical(other.transactionDate, _this.transactionDate) || other.transactionDate == _this.transactionDate)&&const DeepCollectionEquality().equals(other.items, _this.items)&&const DeepCollectionEquality().equals(other.payments, _this.payments)&&(identical(other.shiftId, _this.shiftId) || other.shiftId == _this.shiftId)&&(identical(other.customerId, _this.customerId) || other.customerId == _this.customerId)&&(identical(other.discountAmount, _this.discountAmount) || other.discountAmount == _this.discountAmount)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&(identical(other.tableNumber, _this.tableNumber) || other.tableNumber == _this.tableNumber)&&(identical(other.queueNumber, _this.queueNumber) || other.queueNumber == _this.queueNumber)&&(identical(other.clientRef, _this.clientRef) || other.clientRef == _this.clientRef)&&(identical(other.paidAt, _this.paidAt) || other.paidAt == _this.paidAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as POSCheckoutDTO;
  return Object.hash(runtimeType,_this.outletId,_this.transactionDate,const DeepCollectionEquality().hash(_this.items),const DeepCollectionEquality().hash(_this.payments),_this.shiftId,_this.customerId,_this.discountAmount,_this.notes,_this.tableNumber,_this.queueNumber,_this.clientRef,_this.paidAt);
}

@override
String toString() {
  final _this = this as POSCheckoutDTO;
  return 'POSCheckoutDTO(outletId: ${_this.outletId}, transactionDate: ${_this.transactionDate}, items: ${_this.items}, payments: ${_this.payments}, shiftId: ${_this.shiftId}, customerId: ${_this.customerId}, discountAmount: ${_this.discountAmount}, notes: ${_this.notes}, tableNumber: ${_this.tableNumber}, queueNumber: ${_this.queueNumber}, clientRef: ${_this.clientRef}, paidAt: ${_this.paidAt})';
}


}

/// @nodoc
abstract mixin class $POSCheckoutDTOCopyWith<$Res>  {
  factory $POSCheckoutDTOCopyWith(POSCheckoutDTO value, $Res Function(POSCheckoutDTO) _then) = _$POSCheckoutDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'outlet_id') String outletId,@JsonKey(name: 'transaction_date') String transactionDate, List<POSCheckoutItemDTO> items, List<POSTenderDTO> payments,@JsonKey(name: 'shift_id') String? shiftId,@JsonKey(name: 'customer_id') String? customerId,@JsonKey(name: 'discount_amount') num? discountAmount, String? notes,@JsonKey(name: 'table_number') String? tableNumber,@JsonKey(name: 'queue_number') String? queueNumber,@JsonKey(name: 'client_ref') String? clientRef,@JsonKey(name: 'paid_at') String? paidAt
});




}
/// @nodoc
class _$POSCheckoutDTOCopyWithImpl<$Res>
    implements $POSCheckoutDTOCopyWith<$Res> {
  _$POSCheckoutDTOCopyWithImpl(this._self, this._then);

  final POSCheckoutDTO _self;
  final $Res Function(POSCheckoutDTO) _then;

/// Create a copy of POSCheckoutDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? outletId = null,Object? transactionDate = null,Object? items = null,Object? payments = null,Object? shiftId = freezed,Object? customerId = freezed,Object? discountAmount = freezed,Object? notes = freezed,Object? tableNumber = freezed,Object? queueNumber = freezed,Object? clientRef = freezed,Object? paidAt = freezed,}) {
  return _then(POSCheckoutDTO(
outletId: null == outletId ? _self.outletId : outletId // ignore: cast_nullable_to_non_nullable
as String,transactionDate: null == transactionDate ? _self.transactionDate : transactionDate // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<POSCheckoutItemDTO>,payments: null == payments ? _self.payments : payments // ignore: cast_nullable_to_non_nullable
as List<POSTenderDTO>,shiftId: freezed == shiftId ? _self.shiftId : shiftId // ignore: cast_nullable_to_non_nullable
as String?,customerId: freezed == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String?,discountAmount: freezed == discountAmount ? _self.discountAmount : discountAmount // ignore: cast_nullable_to_non_nullable
as num?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,tableNumber: freezed == tableNumber ? _self.tableNumber : tableNumber // ignore: cast_nullable_to_non_nullable
as String?,queueNumber: freezed == queueNumber ? _self.queueNumber : queueNumber // ignore: cast_nullable_to_non_nullable
as String?,clientRef: freezed == clientRef ? _self.clientRef : clientRef // ignore: cast_nullable_to_non_nullable
as String?,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [POSCheckoutDTO].
extension POSCheckoutDTOPatterns on POSCheckoutDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _POSCheckoutDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _POSCheckoutDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _POSCheckoutDTO value)  $default,){
final _that = this;
switch (_that) {
case _POSCheckoutDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _POSCheckoutDTO value)?  $default,){
final _that = this;
switch (_that) {
case _POSCheckoutDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'outlet_id')  String outletId, @JsonKey(name: 'transaction_date')  String transactionDate,  List<POSCheckoutItemDTO> items,  List<POSTenderDTO> payments, @JsonKey(name: 'shift_id')  String? shiftId, @JsonKey(name: 'customer_id')  String? customerId, @JsonKey(name: 'discount_amount')  num? discountAmount,  String? notes, @JsonKey(name: 'table_number')  String? tableNumber, @JsonKey(name: 'queue_number')  String? queueNumber, @JsonKey(name: 'client_ref')  String? clientRef, @JsonKey(name: 'paid_at')  String? paidAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _POSCheckoutDTO() when $default != null:
return $default(_that.outletId,_that.transactionDate,_that.items,_that.payments,_that.shiftId,_that.customerId,_that.discountAmount,_that.notes,_that.tableNumber,_that.queueNumber,_that.clientRef,_that.paidAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'outlet_id')  String outletId, @JsonKey(name: 'transaction_date')  String transactionDate,  List<POSCheckoutItemDTO> items,  List<POSTenderDTO> payments, @JsonKey(name: 'shift_id')  String? shiftId, @JsonKey(name: 'customer_id')  String? customerId, @JsonKey(name: 'discount_amount')  num? discountAmount,  String? notes, @JsonKey(name: 'table_number')  String? tableNumber, @JsonKey(name: 'queue_number')  String? queueNumber, @JsonKey(name: 'client_ref')  String? clientRef, @JsonKey(name: 'paid_at')  String? paidAt)  $default,) {final _that = this;
switch (_that) {
case _POSCheckoutDTO():
return $default(_that.outletId,_that.transactionDate,_that.items,_that.payments,_that.shiftId,_that.customerId,_that.discountAmount,_that.notes,_that.tableNumber,_that.queueNumber,_that.clientRef,_that.paidAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'outlet_id')  String outletId, @JsonKey(name: 'transaction_date')  String transactionDate,  List<POSCheckoutItemDTO> items,  List<POSTenderDTO> payments, @JsonKey(name: 'shift_id')  String? shiftId, @JsonKey(name: 'customer_id')  String? customerId, @JsonKey(name: 'discount_amount')  num? discountAmount,  String? notes, @JsonKey(name: 'table_number')  String? tableNumber, @JsonKey(name: 'queue_number')  String? queueNumber, @JsonKey(name: 'client_ref')  String? clientRef, @JsonKey(name: 'paid_at')  String? paidAt)?  $default,) {final _that = this;
switch (_that) {
case _POSCheckoutDTO() when $default != null:
return $default(_that.outletId,_that.transactionDate,_that.items,_that.payments,_that.shiftId,_that.customerId,_that.discountAmount,_that.notes,_that.tableNumber,_that.queueNumber,_that.clientRef,_that.paidAt);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class _POSCheckoutDTO implements POSCheckoutDTO {
  const _POSCheckoutDTO({@JsonKey(name: 'outlet_id') required this.outletId, @JsonKey(name: 'transaction_date') required this.transactionDate, required  List<POSCheckoutItemDTO> items, required  List<POSTenderDTO> payments, @JsonKey(name: 'shift_id') this.shiftId, @JsonKey(name: 'customer_id') this.customerId, @JsonKey(name: 'discount_amount') this.discountAmount, this.notes, @JsonKey(name: 'table_number') this.tableNumber, @JsonKey(name: 'queue_number') this.queueNumber, @JsonKey(name: 'client_ref') this.clientRef, @JsonKey(name: 'paid_at') this.paidAt}): _items = items,_payments = payments;
  factory _POSCheckoutDTO.fromJson(Map<String, dynamic> json) => _$POSCheckoutDTOFromJson(json);

@override@JsonKey(name: 'outlet_id') final  String outletId;
@override@JsonKey(name: 'transaction_date') final  String transactionDate;
 final  List<POSCheckoutItemDTO> _items;
@override List<POSCheckoutItemDTO> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

 final  List<POSTenderDTO> _payments;
@override List<POSTenderDTO> get payments {
  if (_payments is EqualUnmodifiableListView) return _payments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_payments);
}

/// Omitted when the company runs without shifts: the server reuses the caller's open
/// shift at the outlet, or opens one.
@override@JsonKey(name: 'shift_id') final  String? shiftId;
@override@JsonKey(name: 'customer_id') final  String? customerId;
@override@JsonKey(name: 'discount_amount') final  num? discountAmount;
@override final  String? notes;
@override@JsonKey(name: 'table_number') final  String? tableNumber;
@override@JsonKey(name: 'queue_number') final  String? queueNumber;
@override@JsonKey(name: 'client_ref') final  String? clientRef;
@override@JsonKey(name: 'paid_at') final  String? paidAt;

/// Create a copy of POSCheckoutDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$POSCheckoutDTOCopyWith<_POSCheckoutDTO> get copyWith => __$POSCheckoutDTOCopyWithImpl<_POSCheckoutDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$POSCheckoutDTOToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _POSCheckoutDTO&&(identical(other.outletId, outletId) || other.outletId == outletId)&&(identical(other.transactionDate, transactionDate) || other.transactionDate == transactionDate)&&const DeepCollectionEquality().equals(other.items, _items)&&const DeepCollectionEquality().equals(other.payments, _payments)&&(identical(other.shiftId, shiftId) || other.shiftId == shiftId)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.discountAmount, discountAmount) || other.discountAmount == discountAmount)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.tableNumber, tableNumber) || other.tableNumber == tableNumber)&&(identical(other.queueNumber, queueNumber) || other.queueNumber == queueNumber)&&(identical(other.clientRef, clientRef) || other.clientRef == clientRef)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,outletId,transactionDate,const DeepCollectionEquality().hash(_items),const DeepCollectionEquality().hash(_payments),shiftId,customerId,discountAmount,notes,tableNumber,queueNumber,clientRef,paidAt);
}

@override
String toString() {
    return 'POSCheckoutDTO(outletId: $outletId, transactionDate: $transactionDate, items: $items, payments: $payments, shiftId: $shiftId, customerId: $customerId, discountAmount: $discountAmount, notes: $notes, tableNumber: $tableNumber, queueNumber: $queueNumber, clientRef: $clientRef, paidAt: $paidAt)';
}


}

/// @nodoc
abstract mixin class _$POSCheckoutDTOCopyWith<$Res> implements $POSCheckoutDTOCopyWith<$Res> {
  factory _$POSCheckoutDTOCopyWith(_POSCheckoutDTO value, $Res Function(_POSCheckoutDTO) _then) = __$POSCheckoutDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'outlet_id') String outletId,@JsonKey(name: 'transaction_date') String transactionDate, List<POSCheckoutItemDTO> items, List<POSTenderDTO> payments,@JsonKey(name: 'shift_id') String? shiftId,@JsonKey(name: 'customer_id') String? customerId,@JsonKey(name: 'discount_amount') num? discountAmount, String? notes,@JsonKey(name: 'table_number') String? tableNumber,@JsonKey(name: 'queue_number') String? queueNumber,@JsonKey(name: 'client_ref') String? clientRef,@JsonKey(name: 'paid_at') String? paidAt
});




}
/// @nodoc
class __$POSCheckoutDTOCopyWithImpl<$Res>
    implements _$POSCheckoutDTOCopyWith<$Res> {
  __$POSCheckoutDTOCopyWithImpl(this._self, this._then);

  final _POSCheckoutDTO _self;
  final $Res Function(_POSCheckoutDTO) _then;

/// Create a copy of POSCheckoutDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? outletId = null,Object? transactionDate = null,Object? items = null,Object? payments = null,Object? shiftId = freezed,Object? customerId = freezed,Object? discountAmount = freezed,Object? notes = freezed,Object? tableNumber = freezed,Object? queueNumber = freezed,Object? clientRef = freezed,Object? paidAt = freezed,}) {
  return _then(_POSCheckoutDTO(
outletId: null == outletId ? _self.outletId : outletId // ignore: cast_nullable_to_non_nullable
as String,transactionDate: null == transactionDate ? _self.transactionDate : transactionDate // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<POSCheckoutItemDTO>,payments: null == payments ? _self._payments : payments // ignore: cast_nullable_to_non_nullable
as List<POSTenderDTO>,shiftId: freezed == shiftId ? _self.shiftId : shiftId // ignore: cast_nullable_to_non_nullable
as String?,customerId: freezed == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String?,discountAmount: freezed == discountAmount ? _self.discountAmount : discountAmount // ignore: cast_nullable_to_non_nullable
as num?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,tableNumber: freezed == tableNumber ? _self.tableNumber : tableNumber // ignore: cast_nullable_to_non_nullable
as String?,queueNumber: freezed == queueNumber ? _self.queueNumber : queueNumber // ignore: cast_nullable_to_non_nullable
as String?,clientRef: freezed == clientRef ? _self.clientRef : clientRef // ignore: cast_nullable_to_non_nullable
as String?,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$POSPreferences {

@JsonKey(name: 'require_shift') bool get requireShift;@JsonKey(name: 'show_table_number') bool get showTableNumber;@JsonKey(name: 'show_queue_number') bool get showQueueNumber;@JsonKey(name: 'queue_number_auto') bool get queueNumberAuto;@JsonKey(name: 'show_product_sales_summary') bool get showProductSalesSummary;/// Set once the company has a drawer account: a cash movement then has to name the
/// other side of its journal (`cash-movement-dialog.tsx`).
@JsonKey(name: 'cash_account_id') String? get cashAccountId;/// The walk-in customer the company nominates, or null when it has none.
///
/// The server owns what the sale is attributed to: when the till sends no customer it falls
/// back to this, and refuses the sale with `pos_customer_required` when this is empty too
/// (`pos_service.go:1506-1513`). The till reads it so the cashier can **see** who the sale
/// is for, rather than being shown "no customer" for a sale that has one.
@JsonKey(name: 'default_customer_id') String? get defaultCustomerId;@JsonKey(name: 'receipt_footer_text') String? get receiptFooterText;
/// Create a copy of POSPreferences
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$POSPreferencesCopyWith<POSPreferences> get copyWith => _$POSPreferencesCopyWithImpl<POSPreferences>(this as POSPreferences, _$identity);

  /// Serializes this POSPreferences to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as POSPreferences;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is POSPreferences&&(identical(other.requireShift, _this.requireShift) || other.requireShift == _this.requireShift)&&(identical(other.showTableNumber, _this.showTableNumber) || other.showTableNumber == _this.showTableNumber)&&(identical(other.showQueueNumber, _this.showQueueNumber) || other.showQueueNumber == _this.showQueueNumber)&&(identical(other.queueNumberAuto, _this.queueNumberAuto) || other.queueNumberAuto == _this.queueNumberAuto)&&(identical(other.showProductSalesSummary, _this.showProductSalesSummary) || other.showProductSalesSummary == _this.showProductSalesSummary)&&(identical(other.cashAccountId, _this.cashAccountId) || other.cashAccountId == _this.cashAccountId)&&(identical(other.defaultCustomerId, _this.defaultCustomerId) || other.defaultCustomerId == _this.defaultCustomerId)&&(identical(other.receiptFooterText, _this.receiptFooterText) || other.receiptFooterText == _this.receiptFooterText));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as POSPreferences;
  return Object.hash(runtimeType,_this.requireShift,_this.showTableNumber,_this.showQueueNumber,_this.queueNumberAuto,_this.showProductSalesSummary,_this.cashAccountId,_this.defaultCustomerId,_this.receiptFooterText);
}

@override
String toString() {
  final _this = this as POSPreferences;
  return 'POSPreferences(requireShift: ${_this.requireShift}, showTableNumber: ${_this.showTableNumber}, showQueueNumber: ${_this.showQueueNumber}, queueNumberAuto: ${_this.queueNumberAuto}, showProductSalesSummary: ${_this.showProductSalesSummary}, cashAccountId: ${_this.cashAccountId}, defaultCustomerId: ${_this.defaultCustomerId}, receiptFooterText: ${_this.receiptFooterText})';
}


}

/// @nodoc
abstract mixin class $POSPreferencesCopyWith<$Res>  {
  factory $POSPreferencesCopyWith(POSPreferences value, $Res Function(POSPreferences) _then) = _$POSPreferencesCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'require_shift') bool requireShift,@JsonKey(name: 'show_table_number') bool showTableNumber,@JsonKey(name: 'show_queue_number') bool showQueueNumber,@JsonKey(name: 'queue_number_auto') bool queueNumberAuto,@JsonKey(name: 'show_product_sales_summary') bool showProductSalesSummary,@JsonKey(name: 'cash_account_id') String? cashAccountId,@JsonKey(name: 'default_customer_id') String? defaultCustomerId,@JsonKey(name: 'receipt_footer_text') String? receiptFooterText
});




}
/// @nodoc
class _$POSPreferencesCopyWithImpl<$Res>
    implements $POSPreferencesCopyWith<$Res> {
  _$POSPreferencesCopyWithImpl(this._self, this._then);

  final POSPreferences _self;
  final $Res Function(POSPreferences) _then;

/// Create a copy of POSPreferences
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? requireShift = null,Object? showTableNumber = null,Object? showQueueNumber = null,Object? queueNumberAuto = null,Object? showProductSalesSummary = null,Object? cashAccountId = freezed,Object? defaultCustomerId = freezed,Object? receiptFooterText = freezed,}) {
  return _then(POSPreferences(
requireShift: null == requireShift ? _self.requireShift : requireShift // ignore: cast_nullable_to_non_nullable
as bool,showTableNumber: null == showTableNumber ? _self.showTableNumber : showTableNumber // ignore: cast_nullable_to_non_nullable
as bool,showQueueNumber: null == showQueueNumber ? _self.showQueueNumber : showQueueNumber // ignore: cast_nullable_to_non_nullable
as bool,queueNumberAuto: null == queueNumberAuto ? _self.queueNumberAuto : queueNumberAuto // ignore: cast_nullable_to_non_nullable
as bool,showProductSalesSummary: null == showProductSalesSummary ? _self.showProductSalesSummary : showProductSalesSummary // ignore: cast_nullable_to_non_nullable
as bool,cashAccountId: freezed == cashAccountId ? _self.cashAccountId : cashAccountId // ignore: cast_nullable_to_non_nullable
as String?,defaultCustomerId: freezed == defaultCustomerId ? _self.defaultCustomerId : defaultCustomerId // ignore: cast_nullable_to_non_nullable
as String?,receiptFooterText: freezed == receiptFooterText ? _self.receiptFooterText : receiptFooterText // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [POSPreferences].
extension POSPreferencesPatterns on POSPreferences {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _POSPreferences value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _POSPreferences() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _POSPreferences value)  $default,){
final _that = this;
switch (_that) {
case _POSPreferences():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _POSPreferences value)?  $default,){
final _that = this;
switch (_that) {
case _POSPreferences() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'require_shift')  bool requireShift, @JsonKey(name: 'show_table_number')  bool showTableNumber, @JsonKey(name: 'show_queue_number')  bool showQueueNumber, @JsonKey(name: 'queue_number_auto')  bool queueNumberAuto, @JsonKey(name: 'show_product_sales_summary')  bool showProductSalesSummary, @JsonKey(name: 'cash_account_id')  String? cashAccountId, @JsonKey(name: 'default_customer_id')  String? defaultCustomerId, @JsonKey(name: 'receipt_footer_text')  String? receiptFooterText)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _POSPreferences() when $default != null:
return $default(_that.requireShift,_that.showTableNumber,_that.showQueueNumber,_that.queueNumberAuto,_that.showProductSalesSummary,_that.cashAccountId,_that.defaultCustomerId,_that.receiptFooterText);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'require_shift')  bool requireShift, @JsonKey(name: 'show_table_number')  bool showTableNumber, @JsonKey(name: 'show_queue_number')  bool showQueueNumber, @JsonKey(name: 'queue_number_auto')  bool queueNumberAuto, @JsonKey(name: 'show_product_sales_summary')  bool showProductSalesSummary, @JsonKey(name: 'cash_account_id')  String? cashAccountId, @JsonKey(name: 'default_customer_id')  String? defaultCustomerId, @JsonKey(name: 'receipt_footer_text')  String? receiptFooterText)  $default,) {final _that = this;
switch (_that) {
case _POSPreferences():
return $default(_that.requireShift,_that.showTableNumber,_that.showQueueNumber,_that.queueNumberAuto,_that.showProductSalesSummary,_that.cashAccountId,_that.defaultCustomerId,_that.receiptFooterText);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'require_shift')  bool requireShift, @JsonKey(name: 'show_table_number')  bool showTableNumber, @JsonKey(name: 'show_queue_number')  bool showQueueNumber, @JsonKey(name: 'queue_number_auto')  bool queueNumberAuto, @JsonKey(name: 'show_product_sales_summary')  bool showProductSalesSummary, @JsonKey(name: 'cash_account_id')  String? cashAccountId, @JsonKey(name: 'default_customer_id')  String? defaultCustomerId, @JsonKey(name: 'receipt_footer_text')  String? receiptFooterText)?  $default,) {final _that = this;
switch (_that) {
case _POSPreferences() when $default != null:
return $default(_that.requireShift,_that.showTableNumber,_that.showQueueNumber,_that.queueNumberAuto,_that.showProductSalesSummary,_that.cashAccountId,_that.defaultCustomerId,_that.receiptFooterText);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _POSPreferences implements POSPreferences {
  const _POSPreferences({@JsonKey(name: 'require_shift') required this.requireShift, @JsonKey(name: 'show_table_number') this.showTableNumber = false, @JsonKey(name: 'show_queue_number') this.showQueueNumber = false, @JsonKey(name: 'queue_number_auto') this.queueNumberAuto = false, @JsonKey(name: 'show_product_sales_summary') this.showProductSalesSummary = false, @JsonKey(name: 'cash_account_id') this.cashAccountId, @JsonKey(name: 'default_customer_id') this.defaultCustomerId, @JsonKey(name: 'receipt_footer_text') this.receiptFooterText});
  factory _POSPreferences.fromJson(Map<String, dynamic> json) => _$POSPreferencesFromJson(json);

@override@JsonKey(name: 'require_shift') final  bool requireShift;
@override@JsonKey(name: 'show_table_number') final  bool showTableNumber;
@override@JsonKey(name: 'show_queue_number') final  bool showQueueNumber;
@override@JsonKey(name: 'queue_number_auto') final  bool queueNumberAuto;
@override@JsonKey(name: 'show_product_sales_summary') final  bool showProductSalesSummary;
/// Set once the company has a drawer account: a cash movement then has to name the
/// other side of its journal (`cash-movement-dialog.tsx`).
@override@JsonKey(name: 'cash_account_id') final  String? cashAccountId;
/// The walk-in customer the company nominates, or null when it has none.
///
/// The server owns what the sale is attributed to: when the till sends no customer it falls
/// back to this, and refuses the sale with `pos_customer_required` when this is empty too
/// (`pos_service.go:1506-1513`). The till reads it so the cashier can **see** who the sale
/// is for, rather than being shown "no customer" for a sale that has one.
@override@JsonKey(name: 'default_customer_id') final  String? defaultCustomerId;
@override@JsonKey(name: 'receipt_footer_text') final  String? receiptFooterText;

/// Create a copy of POSPreferences
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$POSPreferencesCopyWith<_POSPreferences> get copyWith => __$POSPreferencesCopyWithImpl<_POSPreferences>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$POSPreferencesToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _POSPreferences&&(identical(other.requireShift, requireShift) || other.requireShift == requireShift)&&(identical(other.showTableNumber, showTableNumber) || other.showTableNumber == showTableNumber)&&(identical(other.showQueueNumber, showQueueNumber) || other.showQueueNumber == showQueueNumber)&&(identical(other.queueNumberAuto, queueNumberAuto) || other.queueNumberAuto == queueNumberAuto)&&(identical(other.showProductSalesSummary, showProductSalesSummary) || other.showProductSalesSummary == showProductSalesSummary)&&(identical(other.cashAccountId, cashAccountId) || other.cashAccountId == cashAccountId)&&(identical(other.defaultCustomerId, defaultCustomerId) || other.defaultCustomerId == defaultCustomerId)&&(identical(other.receiptFooterText, receiptFooterText) || other.receiptFooterText == receiptFooterText));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,requireShift,showTableNumber,showQueueNumber,queueNumberAuto,showProductSalesSummary,cashAccountId,defaultCustomerId,receiptFooterText);
}

@override
String toString() {
    return 'POSPreferences(requireShift: $requireShift, showTableNumber: $showTableNumber, showQueueNumber: $showQueueNumber, queueNumberAuto: $queueNumberAuto, showProductSalesSummary: $showProductSalesSummary, cashAccountId: $cashAccountId, defaultCustomerId: $defaultCustomerId, receiptFooterText: $receiptFooterText)';
}


}

/// @nodoc
abstract mixin class _$POSPreferencesCopyWith<$Res> implements $POSPreferencesCopyWith<$Res> {
  factory _$POSPreferencesCopyWith(_POSPreferences value, $Res Function(_POSPreferences) _then) = __$POSPreferencesCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'require_shift') bool requireShift,@JsonKey(name: 'show_table_number') bool showTableNumber,@JsonKey(name: 'show_queue_number') bool showQueueNumber,@JsonKey(name: 'queue_number_auto') bool queueNumberAuto,@JsonKey(name: 'show_product_sales_summary') bool showProductSalesSummary,@JsonKey(name: 'cash_account_id') String? cashAccountId,@JsonKey(name: 'default_customer_id') String? defaultCustomerId,@JsonKey(name: 'receipt_footer_text') String? receiptFooterText
});




}
/// @nodoc
class __$POSPreferencesCopyWithImpl<$Res>
    implements _$POSPreferencesCopyWith<$Res> {
  __$POSPreferencesCopyWithImpl(this._self, this._then);

  final _POSPreferences _self;
  final $Res Function(_POSPreferences) _then;

/// Create a copy of POSPreferences
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? requireShift = null,Object? showTableNumber = null,Object? showQueueNumber = null,Object? queueNumberAuto = null,Object? showProductSalesSummary = null,Object? cashAccountId = freezed,Object? defaultCustomerId = freezed,Object? receiptFooterText = freezed,}) {
  return _then(_POSPreferences(
requireShift: null == requireShift ? _self.requireShift : requireShift // ignore: cast_nullable_to_non_nullable
as bool,showTableNumber: null == showTableNumber ? _self.showTableNumber : showTableNumber // ignore: cast_nullable_to_non_nullable
as bool,showQueueNumber: null == showQueueNumber ? _self.showQueueNumber : showQueueNumber // ignore: cast_nullable_to_non_nullable
as bool,queueNumberAuto: null == queueNumberAuto ? _self.queueNumberAuto : queueNumberAuto // ignore: cast_nullable_to_non_nullable
as bool,showProductSalesSummary: null == showProductSalesSummary ? _self.showProductSalesSummary : showProductSalesSummary // ignore: cast_nullable_to_non_nullable
as bool,cashAccountId: freezed == cashAccountId ? _self.cashAccountId : cashAccountId // ignore: cast_nullable_to_non_nullable
as String?,defaultCustomerId: freezed == defaultCustomerId ? _self.defaultCustomerId : defaultCustomerId // ignore: cast_nullable_to_non_nullable
as String?,receiptFooterText: freezed == receiptFooterText ? _self.receiptFooterText : receiptFooterText // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$POSTenderDTO {

 POSTenderMethod get method; num get amount;/// Required for every non-cash method: the money landed in a specific account.
@JsonKey(name: 'account_id') String? get accountId; String? get reference;
/// Create a copy of POSTenderDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$POSTenderDTOCopyWith<POSTenderDTO> get copyWith => _$POSTenderDTOCopyWithImpl<POSTenderDTO>(this as POSTenderDTO, _$identity);

  /// Serializes this POSTenderDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as POSTenderDTO;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is POSTenderDTO&&(identical(other.method, _this.method) || other.method == _this.method)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.accountId, _this.accountId) || other.accountId == _this.accountId)&&(identical(other.reference, _this.reference) || other.reference == _this.reference));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as POSTenderDTO;
  return Object.hash(runtimeType,_this.method,_this.amount,_this.accountId,_this.reference);
}

@override
String toString() {
  final _this = this as POSTenderDTO;
  return 'POSTenderDTO(method: ${_this.method}, amount: ${_this.amount}, accountId: ${_this.accountId}, reference: ${_this.reference})';
}


}

/// @nodoc
abstract mixin class $POSTenderDTOCopyWith<$Res>  {
  factory $POSTenderDTOCopyWith(POSTenderDTO value, $Res Function(POSTenderDTO) _then) = _$POSTenderDTOCopyWithImpl;
@useResult
$Res call({
 POSTenderMethod method, num amount,@JsonKey(name: 'account_id') String? accountId, String? reference
});




}
/// @nodoc
class _$POSTenderDTOCopyWithImpl<$Res>
    implements $POSTenderDTOCopyWith<$Res> {
  _$POSTenderDTOCopyWithImpl(this._self, this._then);

  final POSTenderDTO _self;
  final $Res Function(POSTenderDTO) _then;

/// Create a copy of POSTenderDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? method = null,Object? amount = null,Object? accountId = freezed,Object? reference = freezed,}) {
  return _then(POSTenderDTO(
method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as POSTenderMethod,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as num,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [POSTenderDTO].
extension POSTenderDTOPatterns on POSTenderDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _POSTenderDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _POSTenderDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _POSTenderDTO value)  $default,){
final _that = this;
switch (_that) {
case _POSTenderDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _POSTenderDTO value)?  $default,){
final _that = this;
switch (_that) {
case _POSTenderDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( POSTenderMethod method,  num amount, @JsonKey(name: 'account_id')  String? accountId,  String? reference)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _POSTenderDTO() when $default != null:
return $default(_that.method,_that.amount,_that.accountId,_that.reference);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( POSTenderMethod method,  num amount, @JsonKey(name: 'account_id')  String? accountId,  String? reference)  $default,) {final _that = this;
switch (_that) {
case _POSTenderDTO():
return $default(_that.method,_that.amount,_that.accountId,_that.reference);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( POSTenderMethod method,  num amount, @JsonKey(name: 'account_id')  String? accountId,  String? reference)?  $default,) {final _that = this;
switch (_that) {
case _POSTenderDTO() when $default != null:
return $default(_that.method,_that.amount,_that.accountId,_that.reference);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(includeIfNull: false)
class _POSTenderDTO implements POSTenderDTO {
  const _POSTenderDTO({required this.method, required this.amount, @JsonKey(name: 'account_id') this.accountId, this.reference});
  factory _POSTenderDTO.fromJson(Map<String, dynamic> json) => _$POSTenderDTOFromJson(json);

@override final  POSTenderMethod method;
@override final  num amount;
/// Required for every non-cash method: the money landed in a specific account.
@override@JsonKey(name: 'account_id') final  String? accountId;
@override final  String? reference;

/// Create a copy of POSTenderDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$POSTenderDTOCopyWith<_POSTenderDTO> get copyWith => __$POSTenderDTOCopyWithImpl<_POSTenderDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$POSTenderDTOToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _POSTenderDTO&&(identical(other.method, method) || other.method == method)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.reference, reference) || other.reference == reference));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,method,amount,accountId,reference);
}

@override
String toString() {
    return 'POSTenderDTO(method: $method, amount: $amount, accountId: $accountId, reference: $reference)';
}


}

/// @nodoc
abstract mixin class _$POSTenderDTOCopyWith<$Res> implements $POSTenderDTOCopyWith<$Res> {
  factory _$POSTenderDTOCopyWith(_POSTenderDTO value, $Res Function(_POSTenderDTO) _then) = __$POSTenderDTOCopyWithImpl;
@override @useResult
$Res call({
 POSTenderMethod method, num amount,@JsonKey(name: 'account_id') String? accountId, String? reference
});




}
/// @nodoc
class __$POSTenderDTOCopyWithImpl<$Res>
    implements _$POSTenderDTOCopyWith<$Res> {
  __$POSTenderDTOCopyWithImpl(this._self, this._then);

  final _POSTenderDTO _self;
  final $Res Function(_POSTenderDTO) _then;

/// Create a copy of POSTenderDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? method = null,Object? amount = null,Object? accountId = freezed,Object? reference = freezed,}) {
  return _then(_POSTenderDTO(
method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as POSTenderMethod,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as num,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
