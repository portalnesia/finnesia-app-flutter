// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pos_shift.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NonCashTenderLine {

 String get method; String? get reference; num get amount;@JsonKey(name: 'sale_number') String get saleNumber;
/// Create a copy of NonCashTenderLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NonCashTenderLineCopyWith<NonCashTenderLine> get copyWith => _$NonCashTenderLineCopyWithImpl<NonCashTenderLine>(this as NonCashTenderLine, _$identity);

  /// Serializes this NonCashTenderLine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NonCashTenderLine;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NonCashTenderLine&&(identical(other.method, _this.method) || other.method == _this.method)&&(identical(other.reference, _this.reference) || other.reference == _this.reference)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.saleNumber, _this.saleNumber) || other.saleNumber == _this.saleNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NonCashTenderLine;
  return Object.hash(runtimeType,_this.method,_this.reference,_this.amount,_this.saleNumber);
}

@override
String toString() {
  final _this = this as NonCashTenderLine;
  return 'NonCashTenderLine(method: ${_this.method}, reference: ${_this.reference}, amount: ${_this.amount}, saleNumber: ${_this.saleNumber})';
}


}

/// @nodoc
abstract mixin class $NonCashTenderLineCopyWith<$Res>  {
  factory $NonCashTenderLineCopyWith(NonCashTenderLine value, $Res Function(NonCashTenderLine) _then) = _$NonCashTenderLineCopyWithImpl;
@useResult
$Res call({
 String method, String? reference, num amount,@JsonKey(name: 'sale_number') String saleNumber
});




}
/// @nodoc
class _$NonCashTenderLineCopyWithImpl<$Res>
    implements $NonCashTenderLineCopyWith<$Res> {
  _$NonCashTenderLineCopyWithImpl(this._self, this._then);

  final NonCashTenderLine _self;
  final $Res Function(NonCashTenderLine) _then;

/// Create a copy of NonCashTenderLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? method = null,Object? reference = freezed,Object? amount = null,Object? saleNumber = null,}) {
  return _then(NonCashTenderLine(
method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as num,saleNumber: null == saleNumber ? _self.saleNumber : saleNumber // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [NonCashTenderLine].
extension NonCashTenderLinePatterns on NonCashTenderLine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NonCashTenderLine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NonCashTenderLine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NonCashTenderLine value)  $default,){
final _that = this;
switch (_that) {
case _NonCashTenderLine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NonCashTenderLine value)?  $default,){
final _that = this;
switch (_that) {
case _NonCashTenderLine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String method,  String? reference,  num amount, @JsonKey(name: 'sale_number')  String saleNumber)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NonCashTenderLine() when $default != null:
return $default(_that.method,_that.reference,_that.amount,_that.saleNumber);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String method,  String? reference,  num amount, @JsonKey(name: 'sale_number')  String saleNumber)  $default,) {final _that = this;
switch (_that) {
case _NonCashTenderLine():
return $default(_that.method,_that.reference,_that.amount,_that.saleNumber);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String method,  String? reference,  num amount, @JsonKey(name: 'sale_number')  String saleNumber)?  $default,) {final _that = this;
switch (_that) {
case _NonCashTenderLine() when $default != null:
return $default(_that.method,_that.reference,_that.amount,_that.saleNumber);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NonCashTenderLine implements NonCashTenderLine {
  const _NonCashTenderLine({required this.method, this.reference, required this.amount, @JsonKey(name: 'sale_number') required this.saleNumber});
  factory _NonCashTenderLine.fromJson(Map<String, dynamic> json) => _$NonCashTenderLineFromJson(json);

@override final  String method;
@override final  String? reference;
@override final  num amount;
@override@JsonKey(name: 'sale_number') final  String saleNumber;

/// Create a copy of NonCashTenderLine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NonCashTenderLineCopyWith<_NonCashTenderLine> get copyWith => __$NonCashTenderLineCopyWithImpl<_NonCashTenderLine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NonCashTenderLineToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NonCashTenderLine&&(identical(other.method, method) || other.method == method)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.saleNumber, saleNumber) || other.saleNumber == saleNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,method,reference,amount,saleNumber);
}

@override
String toString() {
    return 'NonCashTenderLine(method: $method, reference: $reference, amount: $amount, saleNumber: $saleNumber)';
}


}

/// @nodoc
abstract mixin class _$NonCashTenderLineCopyWith<$Res> implements $NonCashTenderLineCopyWith<$Res> {
  factory _$NonCashTenderLineCopyWith(_NonCashTenderLine value, $Res Function(_NonCashTenderLine) _then) = __$NonCashTenderLineCopyWithImpl;
@override @useResult
$Res call({
 String method, String? reference, num amount,@JsonKey(name: 'sale_number') String saleNumber
});




}
/// @nodoc
class __$NonCashTenderLineCopyWithImpl<$Res>
    implements _$NonCashTenderLineCopyWith<$Res> {
  __$NonCashTenderLineCopyWithImpl(this._self, this._then);

  final _NonCashTenderLine _self;
  final $Res Function(_NonCashTenderLine) _then;

/// Create a copy of NonCashTenderLine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? method = null,Object? reference = freezed,Object? amount = null,Object? saleNumber = null,}) {
  return _then(_NonCashTenderLine(
method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as num,saleNumber: null == saleNumber ? _self.saleNumber : saleNumber // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ProductSalesLine {

@JsonKey(name: 'product_id') String get productId;@JsonKey(name: 'product_name') String get productName; num get quantity;@JsonKey(name: 'unit_price') num get unitPrice; num get total;
/// Create a copy of ProductSalesLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductSalesLineCopyWith<ProductSalesLine> get copyWith => _$ProductSalesLineCopyWithImpl<ProductSalesLine>(this as ProductSalesLine, _$identity);

  /// Serializes this ProductSalesLine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ProductSalesLine;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductSalesLine&&(identical(other.productId, _this.productId) || other.productId == _this.productId)&&(identical(other.productName, _this.productName) || other.productName == _this.productName)&&(identical(other.quantity, _this.quantity) || other.quantity == _this.quantity)&&(identical(other.unitPrice, _this.unitPrice) || other.unitPrice == _this.unitPrice)&&(identical(other.total, _this.total) || other.total == _this.total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ProductSalesLine;
  return Object.hash(runtimeType,_this.productId,_this.productName,_this.quantity,_this.unitPrice,_this.total);
}

@override
String toString() {
  final _this = this as ProductSalesLine;
  return 'ProductSalesLine(productId: ${_this.productId}, productName: ${_this.productName}, quantity: ${_this.quantity}, unitPrice: ${_this.unitPrice}, total: ${_this.total})';
}


}

/// @nodoc
abstract mixin class $ProductSalesLineCopyWith<$Res>  {
  factory $ProductSalesLineCopyWith(ProductSalesLine value, $Res Function(ProductSalesLine) _then) = _$ProductSalesLineCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'product_id') String productId,@JsonKey(name: 'product_name') String productName, num quantity,@JsonKey(name: 'unit_price') num unitPrice, num total
});




}
/// @nodoc
class _$ProductSalesLineCopyWithImpl<$Res>
    implements $ProductSalesLineCopyWith<$Res> {
  _$ProductSalesLineCopyWithImpl(this._self, this._then);

  final ProductSalesLine _self;
  final $Res Function(ProductSalesLine) _then;

/// Create a copy of ProductSalesLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productId = null,Object? productName = null,Object? quantity = null,Object? unitPrice = null,Object? total = null,}) {
  return _then(ProductSalesLine(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as num,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as num,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as num,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductSalesLine].
extension ProductSalesLinePatterns on ProductSalesLine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductSalesLine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductSalesLine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductSalesLine value)  $default,){
final _that = this;
switch (_that) {
case _ProductSalesLine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductSalesLine value)?  $default,){
final _that = this;
switch (_that) {
case _ProductSalesLine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'product_id')  String productId, @JsonKey(name: 'product_name')  String productName,  num quantity, @JsonKey(name: 'unit_price')  num unitPrice,  num total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductSalesLine() when $default != null:
return $default(_that.productId,_that.productName,_that.quantity,_that.unitPrice,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'product_id')  String productId, @JsonKey(name: 'product_name')  String productName,  num quantity, @JsonKey(name: 'unit_price')  num unitPrice,  num total)  $default,) {final _that = this;
switch (_that) {
case _ProductSalesLine():
return $default(_that.productId,_that.productName,_that.quantity,_that.unitPrice,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'product_id')  String productId, @JsonKey(name: 'product_name')  String productName,  num quantity, @JsonKey(name: 'unit_price')  num unitPrice,  num total)?  $default,) {final _that = this;
switch (_that) {
case _ProductSalesLine() when $default != null:
return $default(_that.productId,_that.productName,_that.quantity,_that.unitPrice,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductSalesLine implements ProductSalesLine {
  const _ProductSalesLine({@JsonKey(name: 'product_id') required this.productId, @JsonKey(name: 'product_name') required this.productName, required this.quantity, @JsonKey(name: 'unit_price') required this.unitPrice, required this.total});
  factory _ProductSalesLine.fromJson(Map<String, dynamic> json) => _$ProductSalesLineFromJson(json);

@override@JsonKey(name: 'product_id') final  String productId;
@override@JsonKey(name: 'product_name') final  String productName;
@override final  num quantity;
@override@JsonKey(name: 'unit_price') final  num unitPrice;
@override final  num total;

/// Create a copy of ProductSalesLine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductSalesLineCopyWith<_ProductSalesLine> get copyWith => __$ProductSalesLineCopyWithImpl<_ProductSalesLine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductSalesLineToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductSalesLine&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,productId,productName,quantity,unitPrice,total);
}

@override
String toString() {
    return 'ProductSalesLine(productId: $productId, productName: $productName, quantity: $quantity, unitPrice: $unitPrice, total: $total)';
}


}

/// @nodoc
abstract mixin class _$ProductSalesLineCopyWith<$Res> implements $ProductSalesLineCopyWith<$Res> {
  factory _$ProductSalesLineCopyWith(_ProductSalesLine value, $Res Function(_ProductSalesLine) _then) = __$ProductSalesLineCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'product_id') String productId,@JsonKey(name: 'product_name') String productName, num quantity,@JsonKey(name: 'unit_price') num unitPrice, num total
});




}
/// @nodoc
class __$ProductSalesLineCopyWithImpl<$Res>
    implements _$ProductSalesLineCopyWith<$Res> {
  __$ProductSalesLineCopyWithImpl(this._self, this._then);

  final _ProductSalesLine _self;
  final $Res Function(_ProductSalesLine) _then;

/// Create a copy of ProductSalesLine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productId = null,Object? productName = null,Object? quantity = null,Object? unitPrice = null,Object? total = null,}) {
  return _then(_ProductSalesLine(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as num,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as num,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as num,
  ));
}


}


/// @nodoc
mixin _$ShiftSummaryResponse {

@JsonKey(name: 'shift_id') String get shiftId; String get number;/// An unknown value reads as `null`, the way `ProductType` does: a newer API must not
/// take the closing screen down. `null` is treated as "not open", so no close action
/// is offered for a shift whose state this build cannot read.
@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) ShiftStatus? get status;@JsonKey(name: 'outlet_id') String get outletId;@JsonKey(name: 'cashier_id') String get cashierId;@JsonKey(name: 'cashier_name') String? get cashierName;@JsonKey(name: 'outlet_name') String? get outletName;@JsonKey(name: 'opened_at') String get openedAt;@JsonKey(name: 'closed_at') String? get closedAt; String? get notes;@JsonKey(name: 'total_transactions') int get totalTransactions;@JsonKey(name: 'total_sales') num get totalSales;@JsonKey(name: 'opening_cash') num get openingCash;@JsonKey(name: 'expected_cash') num get expectedCash;@JsonKey(name: 'counted_cash') num? get countedCash;@JsonKey(name: 'cash_variance') num? get cashVariance;@JsonKey(name: 'cash_in') num get cashIn;@JsonKey(name: 'cash_out') num get cashOut;@JsonKey(name: 'cash_drop') num get cashDrop;@JsonKey(name: 'sales_by_method') Map<String, num> get salesByMethod;@JsonKey(name: 'non_cash_tenders') List<NonCashTenderLine> get nonCashTenders;@JsonKey(name: 'product_sales') List<ProductSalesLine> get productSales;
/// Create a copy of ShiftSummaryResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShiftSummaryResponseCopyWith<ShiftSummaryResponse> get copyWith => _$ShiftSummaryResponseCopyWithImpl<ShiftSummaryResponse>(this as ShiftSummaryResponse, _$identity);

  /// Serializes this ShiftSummaryResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ShiftSummaryResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShiftSummaryResponse&&(identical(other.shiftId, _this.shiftId) || other.shiftId == _this.shiftId)&&(identical(other.number, _this.number) || other.number == _this.number)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.outletId, _this.outletId) || other.outletId == _this.outletId)&&(identical(other.cashierId, _this.cashierId) || other.cashierId == _this.cashierId)&&(identical(other.cashierName, _this.cashierName) || other.cashierName == _this.cashierName)&&(identical(other.outletName, _this.outletName) || other.outletName == _this.outletName)&&(identical(other.openedAt, _this.openedAt) || other.openedAt == _this.openedAt)&&(identical(other.closedAt, _this.closedAt) || other.closedAt == _this.closedAt)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&(identical(other.totalTransactions, _this.totalTransactions) || other.totalTransactions == _this.totalTransactions)&&(identical(other.totalSales, _this.totalSales) || other.totalSales == _this.totalSales)&&(identical(other.openingCash, _this.openingCash) || other.openingCash == _this.openingCash)&&(identical(other.expectedCash, _this.expectedCash) || other.expectedCash == _this.expectedCash)&&(identical(other.countedCash, _this.countedCash) || other.countedCash == _this.countedCash)&&(identical(other.cashVariance, _this.cashVariance) || other.cashVariance == _this.cashVariance)&&(identical(other.cashIn, _this.cashIn) || other.cashIn == _this.cashIn)&&(identical(other.cashOut, _this.cashOut) || other.cashOut == _this.cashOut)&&(identical(other.cashDrop, _this.cashDrop) || other.cashDrop == _this.cashDrop)&&const DeepCollectionEquality().equals(other.salesByMethod, _this.salesByMethod)&&const DeepCollectionEquality().equals(other.nonCashTenders, _this.nonCashTenders)&&const DeepCollectionEquality().equals(other.productSales, _this.productSales));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ShiftSummaryResponse;
  return Object.hashAll([runtimeType,_this.shiftId,_this.number,_this.status,_this.outletId,_this.cashierId,_this.cashierName,_this.outletName,_this.openedAt,_this.closedAt,_this.notes,_this.totalTransactions,_this.totalSales,_this.openingCash,_this.expectedCash,_this.countedCash,_this.cashVariance,_this.cashIn,_this.cashOut,_this.cashDrop,const DeepCollectionEquality().hash(_this.salesByMethod),const DeepCollectionEquality().hash(_this.nonCashTenders),const DeepCollectionEquality().hash(_this.productSales)]);
}

@override
String toString() {
  final _this = this as ShiftSummaryResponse;
  return 'ShiftSummaryResponse(shiftId: ${_this.shiftId}, number: ${_this.number}, status: ${_this.status}, outletId: ${_this.outletId}, cashierId: ${_this.cashierId}, cashierName: ${_this.cashierName}, outletName: ${_this.outletName}, openedAt: ${_this.openedAt}, closedAt: ${_this.closedAt}, notes: ${_this.notes}, totalTransactions: ${_this.totalTransactions}, totalSales: ${_this.totalSales}, openingCash: ${_this.openingCash}, expectedCash: ${_this.expectedCash}, countedCash: ${_this.countedCash}, cashVariance: ${_this.cashVariance}, cashIn: ${_this.cashIn}, cashOut: ${_this.cashOut}, cashDrop: ${_this.cashDrop}, salesByMethod: ${_this.salesByMethod}, nonCashTenders: ${_this.nonCashTenders}, productSales: ${_this.productSales})';
}


}

/// @nodoc
abstract mixin class $ShiftSummaryResponseCopyWith<$Res>  {
  factory $ShiftSummaryResponseCopyWith(ShiftSummaryResponse value, $Res Function(ShiftSummaryResponse) _then) = _$ShiftSummaryResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'shift_id') String shiftId, String number,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) ShiftStatus? status,@JsonKey(name: 'outlet_id') String outletId,@JsonKey(name: 'cashier_id') String cashierId,@JsonKey(name: 'cashier_name') String? cashierName,@JsonKey(name: 'outlet_name') String? outletName,@JsonKey(name: 'opened_at') String openedAt,@JsonKey(name: 'closed_at') String? closedAt, String? notes,@JsonKey(name: 'total_transactions') int totalTransactions,@JsonKey(name: 'total_sales') num totalSales,@JsonKey(name: 'opening_cash') num openingCash,@JsonKey(name: 'expected_cash') num expectedCash,@JsonKey(name: 'counted_cash') num? countedCash,@JsonKey(name: 'cash_variance') num? cashVariance,@JsonKey(name: 'cash_in') num cashIn,@JsonKey(name: 'cash_out') num cashOut,@JsonKey(name: 'cash_drop') num cashDrop,@JsonKey(name: 'sales_by_method') Map<String, num> salesByMethod,@JsonKey(name: 'non_cash_tenders') List<NonCashTenderLine> nonCashTenders,@JsonKey(name: 'product_sales') List<ProductSalesLine> productSales
});




}
/// @nodoc
class _$ShiftSummaryResponseCopyWithImpl<$Res>
    implements $ShiftSummaryResponseCopyWith<$Res> {
  _$ShiftSummaryResponseCopyWithImpl(this._self, this._then);

  final ShiftSummaryResponse _self;
  final $Res Function(ShiftSummaryResponse) _then;

/// Create a copy of ShiftSummaryResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? shiftId = null,Object? number = null,Object? status = freezed,Object? outletId = null,Object? cashierId = null,Object? cashierName = freezed,Object? outletName = freezed,Object? openedAt = null,Object? closedAt = freezed,Object? notes = freezed,Object? totalTransactions = null,Object? totalSales = null,Object? openingCash = null,Object? expectedCash = null,Object? countedCash = freezed,Object? cashVariance = freezed,Object? cashIn = null,Object? cashOut = null,Object? cashDrop = null,Object? salesByMethod = null,Object? nonCashTenders = null,Object? productSales = null,}) {
  return _then(ShiftSummaryResponse(
shiftId: null == shiftId ? _self.shiftId : shiftId // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ShiftStatus?,outletId: null == outletId ? _self.outletId : outletId // ignore: cast_nullable_to_non_nullable
as String,cashierId: null == cashierId ? _self.cashierId : cashierId // ignore: cast_nullable_to_non_nullable
as String,cashierName: freezed == cashierName ? _self.cashierName : cashierName // ignore: cast_nullable_to_non_nullable
as String?,outletName: freezed == outletName ? _self.outletName : outletName // ignore: cast_nullable_to_non_nullable
as String?,openedAt: null == openedAt ? _self.openedAt : openedAt // ignore: cast_nullable_to_non_nullable
as String,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,totalTransactions: null == totalTransactions ? _self.totalTransactions : totalTransactions // ignore: cast_nullable_to_non_nullable
as int,totalSales: null == totalSales ? _self.totalSales : totalSales // ignore: cast_nullable_to_non_nullable
as num,openingCash: null == openingCash ? _self.openingCash : openingCash // ignore: cast_nullable_to_non_nullable
as num,expectedCash: null == expectedCash ? _self.expectedCash : expectedCash // ignore: cast_nullable_to_non_nullable
as num,countedCash: freezed == countedCash ? _self.countedCash : countedCash // ignore: cast_nullable_to_non_nullable
as num?,cashVariance: freezed == cashVariance ? _self.cashVariance : cashVariance // ignore: cast_nullable_to_non_nullable
as num?,cashIn: null == cashIn ? _self.cashIn : cashIn // ignore: cast_nullable_to_non_nullable
as num,cashOut: null == cashOut ? _self.cashOut : cashOut // ignore: cast_nullable_to_non_nullable
as num,cashDrop: null == cashDrop ? _self.cashDrop : cashDrop // ignore: cast_nullable_to_non_nullable
as num,salesByMethod: null == salesByMethod ? _self.salesByMethod : salesByMethod // ignore: cast_nullable_to_non_nullable
as Map<String, num>,nonCashTenders: null == nonCashTenders ? _self.nonCashTenders : nonCashTenders // ignore: cast_nullable_to_non_nullable
as List<NonCashTenderLine>,productSales: null == productSales ? _self.productSales : productSales // ignore: cast_nullable_to_non_nullable
as List<ProductSalesLine>,
  ));
}

}


/// Adds pattern-matching-related methods to [ShiftSummaryResponse].
extension ShiftSummaryResponsePatterns on ShiftSummaryResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShiftSummaryResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShiftSummaryResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShiftSummaryResponse value)  $default,){
final _that = this;
switch (_that) {
case _ShiftSummaryResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShiftSummaryResponse value)?  $default,){
final _that = this;
switch (_that) {
case _ShiftSummaryResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'shift_id')  String shiftId,  String number, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  ShiftStatus? status, @JsonKey(name: 'outlet_id')  String outletId, @JsonKey(name: 'cashier_id')  String cashierId, @JsonKey(name: 'cashier_name')  String? cashierName, @JsonKey(name: 'outlet_name')  String? outletName, @JsonKey(name: 'opened_at')  String openedAt, @JsonKey(name: 'closed_at')  String? closedAt,  String? notes, @JsonKey(name: 'total_transactions')  int totalTransactions, @JsonKey(name: 'total_sales')  num totalSales, @JsonKey(name: 'opening_cash')  num openingCash, @JsonKey(name: 'expected_cash')  num expectedCash, @JsonKey(name: 'counted_cash')  num? countedCash, @JsonKey(name: 'cash_variance')  num? cashVariance, @JsonKey(name: 'cash_in')  num cashIn, @JsonKey(name: 'cash_out')  num cashOut, @JsonKey(name: 'cash_drop')  num cashDrop, @JsonKey(name: 'sales_by_method')  Map<String, num> salesByMethod, @JsonKey(name: 'non_cash_tenders')  List<NonCashTenderLine> nonCashTenders, @JsonKey(name: 'product_sales')  List<ProductSalesLine> productSales)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShiftSummaryResponse() when $default != null:
return $default(_that.shiftId,_that.number,_that.status,_that.outletId,_that.cashierId,_that.cashierName,_that.outletName,_that.openedAt,_that.closedAt,_that.notes,_that.totalTransactions,_that.totalSales,_that.openingCash,_that.expectedCash,_that.countedCash,_that.cashVariance,_that.cashIn,_that.cashOut,_that.cashDrop,_that.salesByMethod,_that.nonCashTenders,_that.productSales);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'shift_id')  String shiftId,  String number, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  ShiftStatus? status, @JsonKey(name: 'outlet_id')  String outletId, @JsonKey(name: 'cashier_id')  String cashierId, @JsonKey(name: 'cashier_name')  String? cashierName, @JsonKey(name: 'outlet_name')  String? outletName, @JsonKey(name: 'opened_at')  String openedAt, @JsonKey(name: 'closed_at')  String? closedAt,  String? notes, @JsonKey(name: 'total_transactions')  int totalTransactions, @JsonKey(name: 'total_sales')  num totalSales, @JsonKey(name: 'opening_cash')  num openingCash, @JsonKey(name: 'expected_cash')  num expectedCash, @JsonKey(name: 'counted_cash')  num? countedCash, @JsonKey(name: 'cash_variance')  num? cashVariance, @JsonKey(name: 'cash_in')  num cashIn, @JsonKey(name: 'cash_out')  num cashOut, @JsonKey(name: 'cash_drop')  num cashDrop, @JsonKey(name: 'sales_by_method')  Map<String, num> salesByMethod, @JsonKey(name: 'non_cash_tenders')  List<NonCashTenderLine> nonCashTenders, @JsonKey(name: 'product_sales')  List<ProductSalesLine> productSales)  $default,) {final _that = this;
switch (_that) {
case _ShiftSummaryResponse():
return $default(_that.shiftId,_that.number,_that.status,_that.outletId,_that.cashierId,_that.cashierName,_that.outletName,_that.openedAt,_that.closedAt,_that.notes,_that.totalTransactions,_that.totalSales,_that.openingCash,_that.expectedCash,_that.countedCash,_that.cashVariance,_that.cashIn,_that.cashOut,_that.cashDrop,_that.salesByMethod,_that.nonCashTenders,_that.productSales);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'shift_id')  String shiftId,  String number, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  ShiftStatus? status, @JsonKey(name: 'outlet_id')  String outletId, @JsonKey(name: 'cashier_id')  String cashierId, @JsonKey(name: 'cashier_name')  String? cashierName, @JsonKey(name: 'outlet_name')  String? outletName, @JsonKey(name: 'opened_at')  String openedAt, @JsonKey(name: 'closed_at')  String? closedAt,  String? notes, @JsonKey(name: 'total_transactions')  int totalTransactions, @JsonKey(name: 'total_sales')  num totalSales, @JsonKey(name: 'opening_cash')  num openingCash, @JsonKey(name: 'expected_cash')  num expectedCash, @JsonKey(name: 'counted_cash')  num? countedCash, @JsonKey(name: 'cash_variance')  num? cashVariance, @JsonKey(name: 'cash_in')  num cashIn, @JsonKey(name: 'cash_out')  num cashOut, @JsonKey(name: 'cash_drop')  num cashDrop, @JsonKey(name: 'sales_by_method')  Map<String, num> salesByMethod, @JsonKey(name: 'non_cash_tenders')  List<NonCashTenderLine> nonCashTenders, @JsonKey(name: 'product_sales')  List<ProductSalesLine> productSales)?  $default,) {final _that = this;
switch (_that) {
case _ShiftSummaryResponse() when $default != null:
return $default(_that.shiftId,_that.number,_that.status,_that.outletId,_that.cashierId,_that.cashierName,_that.outletName,_that.openedAt,_that.closedAt,_that.notes,_that.totalTransactions,_that.totalSales,_that.openingCash,_that.expectedCash,_that.countedCash,_that.cashVariance,_that.cashIn,_that.cashOut,_that.cashDrop,_that.salesByMethod,_that.nonCashTenders,_that.productSales);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShiftSummaryResponse implements ShiftSummaryResponse {
  const _ShiftSummaryResponse({@JsonKey(name: 'shift_id') required this.shiftId, required this.number, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) this.status, @JsonKey(name: 'outlet_id') required this.outletId, @JsonKey(name: 'cashier_id') required this.cashierId, @JsonKey(name: 'cashier_name') this.cashierName, @JsonKey(name: 'outlet_name') this.outletName, @JsonKey(name: 'opened_at') required this.openedAt, @JsonKey(name: 'closed_at') this.closedAt, this.notes, @JsonKey(name: 'total_transactions') required this.totalTransactions, @JsonKey(name: 'total_sales') required this.totalSales, @JsonKey(name: 'opening_cash') required this.openingCash, @JsonKey(name: 'expected_cash') required this.expectedCash, @JsonKey(name: 'counted_cash') this.countedCash, @JsonKey(name: 'cash_variance') this.cashVariance, @JsonKey(name: 'cash_in') required this.cashIn, @JsonKey(name: 'cash_out') required this.cashOut, @JsonKey(name: 'cash_drop') required this.cashDrop, @JsonKey(name: 'sales_by_method')  Map<String, num> salesByMethod = const <String, num>{}, @JsonKey(name: 'non_cash_tenders')  List<NonCashTenderLine> nonCashTenders = const <NonCashTenderLine>[], @JsonKey(name: 'product_sales')  List<ProductSalesLine> productSales = const <ProductSalesLine>[]}): _salesByMethod = salesByMethod,_nonCashTenders = nonCashTenders,_productSales = productSales;
  factory _ShiftSummaryResponse.fromJson(Map<String, dynamic> json) => _$ShiftSummaryResponseFromJson(json);

@override@JsonKey(name: 'shift_id') final  String shiftId;
@override final  String number;
/// An unknown value reads as `null`, the way `ProductType` does: a newer API must not
/// take the closing screen down. `null` is treated as "not open", so no close action
/// is offered for a shift whose state this build cannot read.
@override@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) final  ShiftStatus? status;
@override@JsonKey(name: 'outlet_id') final  String outletId;
@override@JsonKey(name: 'cashier_id') final  String cashierId;
@override@JsonKey(name: 'cashier_name') final  String? cashierName;
@override@JsonKey(name: 'outlet_name') final  String? outletName;
@override@JsonKey(name: 'opened_at') final  String openedAt;
@override@JsonKey(name: 'closed_at') final  String? closedAt;
@override final  String? notes;
@override@JsonKey(name: 'total_transactions') final  int totalTransactions;
@override@JsonKey(name: 'total_sales') final  num totalSales;
@override@JsonKey(name: 'opening_cash') final  num openingCash;
@override@JsonKey(name: 'expected_cash') final  num expectedCash;
@override@JsonKey(name: 'counted_cash') final  num? countedCash;
@override@JsonKey(name: 'cash_variance') final  num? cashVariance;
@override@JsonKey(name: 'cash_in') final  num cashIn;
@override@JsonKey(name: 'cash_out') final  num cashOut;
@override@JsonKey(name: 'cash_drop') final  num cashDrop;
 final  Map<String, num> _salesByMethod;
@override@JsonKey(name: 'sales_by_method') Map<String, num> get salesByMethod {
  if (_salesByMethod is EqualUnmodifiableMapView) return _salesByMethod;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_salesByMethod);
}

 final  List<NonCashTenderLine> _nonCashTenders;
@override@JsonKey(name: 'non_cash_tenders') List<NonCashTenderLine> get nonCashTenders {
  if (_nonCashTenders is EqualUnmodifiableListView) return _nonCashTenders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_nonCashTenders);
}

 final  List<ProductSalesLine> _productSales;
@override@JsonKey(name: 'product_sales') List<ProductSalesLine> get productSales {
  if (_productSales is EqualUnmodifiableListView) return _productSales;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_productSales);
}


/// Create a copy of ShiftSummaryResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShiftSummaryResponseCopyWith<_ShiftSummaryResponse> get copyWith => __$ShiftSummaryResponseCopyWithImpl<_ShiftSummaryResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShiftSummaryResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShiftSummaryResponse&&(identical(other.shiftId, shiftId) || other.shiftId == shiftId)&&(identical(other.number, number) || other.number == number)&&(identical(other.status, status) || other.status == status)&&(identical(other.outletId, outletId) || other.outletId == outletId)&&(identical(other.cashierId, cashierId) || other.cashierId == cashierId)&&(identical(other.cashierName, cashierName) || other.cashierName == cashierName)&&(identical(other.outletName, outletName) || other.outletName == outletName)&&(identical(other.openedAt, openedAt) || other.openedAt == openedAt)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.totalTransactions, totalTransactions) || other.totalTransactions == totalTransactions)&&(identical(other.totalSales, totalSales) || other.totalSales == totalSales)&&(identical(other.openingCash, openingCash) || other.openingCash == openingCash)&&(identical(other.expectedCash, expectedCash) || other.expectedCash == expectedCash)&&(identical(other.countedCash, countedCash) || other.countedCash == countedCash)&&(identical(other.cashVariance, cashVariance) || other.cashVariance == cashVariance)&&(identical(other.cashIn, cashIn) || other.cashIn == cashIn)&&(identical(other.cashOut, cashOut) || other.cashOut == cashOut)&&(identical(other.cashDrop, cashDrop) || other.cashDrop == cashDrop)&&const DeepCollectionEquality().equals(other.salesByMethod, _salesByMethod)&&const DeepCollectionEquality().equals(other.nonCashTenders, _nonCashTenders)&&const DeepCollectionEquality().equals(other.productSales, _productSales));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,shiftId,number,status,outletId,cashierId,cashierName,outletName,openedAt,closedAt,notes,totalTransactions,totalSales,openingCash,expectedCash,countedCash,cashVariance,cashIn,cashOut,cashDrop,const DeepCollectionEquality().hash(_salesByMethod),const DeepCollectionEquality().hash(_nonCashTenders),const DeepCollectionEquality().hash(_productSales)]);
}

@override
String toString() {
    return 'ShiftSummaryResponse(shiftId: $shiftId, number: $number, status: $status, outletId: $outletId, cashierId: $cashierId, cashierName: $cashierName, outletName: $outletName, openedAt: $openedAt, closedAt: $closedAt, notes: $notes, totalTransactions: $totalTransactions, totalSales: $totalSales, openingCash: $openingCash, expectedCash: $expectedCash, countedCash: $countedCash, cashVariance: $cashVariance, cashIn: $cashIn, cashOut: $cashOut, cashDrop: $cashDrop, salesByMethod: $salesByMethod, nonCashTenders: $nonCashTenders, productSales: $productSales)';
}


}

/// @nodoc
abstract mixin class _$ShiftSummaryResponseCopyWith<$Res> implements $ShiftSummaryResponseCopyWith<$Res> {
  factory _$ShiftSummaryResponseCopyWith(_ShiftSummaryResponse value, $Res Function(_ShiftSummaryResponse) _then) = __$ShiftSummaryResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'shift_id') String shiftId, String number,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) ShiftStatus? status,@JsonKey(name: 'outlet_id') String outletId,@JsonKey(name: 'cashier_id') String cashierId,@JsonKey(name: 'cashier_name') String? cashierName,@JsonKey(name: 'outlet_name') String? outletName,@JsonKey(name: 'opened_at') String openedAt,@JsonKey(name: 'closed_at') String? closedAt, String? notes,@JsonKey(name: 'total_transactions') int totalTransactions,@JsonKey(name: 'total_sales') num totalSales,@JsonKey(name: 'opening_cash') num openingCash,@JsonKey(name: 'expected_cash') num expectedCash,@JsonKey(name: 'counted_cash') num? countedCash,@JsonKey(name: 'cash_variance') num? cashVariance,@JsonKey(name: 'cash_in') num cashIn,@JsonKey(name: 'cash_out') num cashOut,@JsonKey(name: 'cash_drop') num cashDrop,@JsonKey(name: 'sales_by_method') Map<String, num> salesByMethod,@JsonKey(name: 'non_cash_tenders') List<NonCashTenderLine> nonCashTenders,@JsonKey(name: 'product_sales') List<ProductSalesLine> productSales
});




}
/// @nodoc
class __$ShiftSummaryResponseCopyWithImpl<$Res>
    implements _$ShiftSummaryResponseCopyWith<$Res> {
  __$ShiftSummaryResponseCopyWithImpl(this._self, this._then);

  final _ShiftSummaryResponse _self;
  final $Res Function(_ShiftSummaryResponse) _then;

/// Create a copy of ShiftSummaryResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? shiftId = null,Object? number = null,Object? status = freezed,Object? outletId = null,Object? cashierId = null,Object? cashierName = freezed,Object? outletName = freezed,Object? openedAt = null,Object? closedAt = freezed,Object? notes = freezed,Object? totalTransactions = null,Object? totalSales = null,Object? openingCash = null,Object? expectedCash = null,Object? countedCash = freezed,Object? cashVariance = freezed,Object? cashIn = null,Object? cashOut = null,Object? cashDrop = null,Object? salesByMethod = null,Object? nonCashTenders = null,Object? productSales = null,}) {
  return _then(_ShiftSummaryResponse(
shiftId: null == shiftId ? _self.shiftId : shiftId // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ShiftStatus?,outletId: null == outletId ? _self.outletId : outletId // ignore: cast_nullable_to_non_nullable
as String,cashierId: null == cashierId ? _self.cashierId : cashierId // ignore: cast_nullable_to_non_nullable
as String,cashierName: freezed == cashierName ? _self.cashierName : cashierName // ignore: cast_nullable_to_non_nullable
as String?,outletName: freezed == outletName ? _self.outletName : outletName // ignore: cast_nullable_to_non_nullable
as String?,openedAt: null == openedAt ? _self.openedAt : openedAt // ignore: cast_nullable_to_non_nullable
as String,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,totalTransactions: null == totalTransactions ? _self.totalTransactions : totalTransactions // ignore: cast_nullable_to_non_nullable
as int,totalSales: null == totalSales ? _self.totalSales : totalSales // ignore: cast_nullable_to_non_nullable
as num,openingCash: null == openingCash ? _self.openingCash : openingCash // ignore: cast_nullable_to_non_nullable
as num,expectedCash: null == expectedCash ? _self.expectedCash : expectedCash // ignore: cast_nullable_to_non_nullable
as num,countedCash: freezed == countedCash ? _self.countedCash : countedCash // ignore: cast_nullable_to_non_nullable
as num?,cashVariance: freezed == cashVariance ? _self.cashVariance : cashVariance // ignore: cast_nullable_to_non_nullable
as num?,cashIn: null == cashIn ? _self.cashIn : cashIn // ignore: cast_nullable_to_non_nullable
as num,cashOut: null == cashOut ? _self.cashOut : cashOut // ignore: cast_nullable_to_non_nullable
as num,cashDrop: null == cashDrop ? _self.cashDrop : cashDrop // ignore: cast_nullable_to_non_nullable
as num,salesByMethod: null == salesByMethod ? _self._salesByMethod : salesByMethod // ignore: cast_nullable_to_non_nullable
as Map<String, num>,nonCashTenders: null == nonCashTenders ? _self._nonCashTenders : nonCashTenders // ignore: cast_nullable_to_non_nullable
as List<NonCashTenderLine>,productSales: null == productSales ? _self._productSales : productSales // ignore: cast_nullable_to_non_nullable
as List<ProductSalesLine>,
  ));
}


}


/// @nodoc
mixin _$POSCashMovement {

 String get id;@JsonKey(name: 'shift_id') String get shiftId; CashMovementType get type; num get amount; String get reason;@JsonKey(name: 'created_at') String get createdAt; NamedRef? get creator; NamedRef? get product;
/// Create a copy of POSCashMovement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$POSCashMovementCopyWith<POSCashMovement> get copyWith => _$POSCashMovementCopyWithImpl<POSCashMovement>(this as POSCashMovement, _$identity);

  /// Serializes this POSCashMovement to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as POSCashMovement;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is POSCashMovement&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.shiftId, _this.shiftId) || other.shiftId == _this.shiftId)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.reason, _this.reason) || other.reason == _this.reason)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.creator, _this.creator) || other.creator == _this.creator)&&(identical(other.product, _this.product) || other.product == _this.product));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as POSCashMovement;
  return Object.hash(runtimeType,_this.id,_this.shiftId,_this.type,_this.amount,_this.reason,_this.createdAt,_this.creator,_this.product);
}

@override
String toString() {
  final _this = this as POSCashMovement;
  return 'POSCashMovement(id: ${_this.id}, shiftId: ${_this.shiftId}, type: ${_this.type}, amount: ${_this.amount}, reason: ${_this.reason}, createdAt: ${_this.createdAt}, creator: ${_this.creator}, product: ${_this.product})';
}


}

/// @nodoc
abstract mixin class $POSCashMovementCopyWith<$Res>  {
  factory $POSCashMovementCopyWith(POSCashMovement value, $Res Function(POSCashMovement) _then) = _$POSCashMovementCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'shift_id') String shiftId, CashMovementType type, num amount, String reason,@JsonKey(name: 'created_at') String createdAt, NamedRef? creator, NamedRef? product
});


$NamedRefCopyWith<$Res>? get creator;$NamedRefCopyWith<$Res>? get product;

}
/// @nodoc
class _$POSCashMovementCopyWithImpl<$Res>
    implements $POSCashMovementCopyWith<$Res> {
  _$POSCashMovementCopyWithImpl(this._self, this._then);

  final POSCashMovement _self;
  final $Res Function(POSCashMovement) _then;

/// Create a copy of POSCashMovement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? shiftId = null,Object? type = null,Object? amount = null,Object? reason = null,Object? createdAt = null,Object? creator = freezed,Object? product = freezed,}) {
  return _then(POSCashMovement(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,shiftId: null == shiftId ? _self.shiftId : shiftId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CashMovementType,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as num,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,creator: freezed == creator ? _self.creator : creator // ignore: cast_nullable_to_non_nullable
as NamedRef?,product: freezed == product ? _self.product : product // ignore: cast_nullable_to_non_nullable
as NamedRef?,
  ));
}
/// Create a copy of POSCashMovement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NamedRefCopyWith<$Res>? get creator {
    if (_self.creator == null) {
    return null;
  }

  return $NamedRefCopyWith<$Res>(_self.creator!, (value) {
    return _then(_self.copyWith(creator: value));
  });
}/// Create a copy of POSCashMovement
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


/// Adds pattern-matching-related methods to [POSCashMovement].
extension POSCashMovementPatterns on POSCashMovement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _POSCashMovement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _POSCashMovement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _POSCashMovement value)  $default,){
final _that = this;
switch (_that) {
case _POSCashMovement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _POSCashMovement value)?  $default,){
final _that = this;
switch (_that) {
case _POSCashMovement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'shift_id')  String shiftId,  CashMovementType type,  num amount,  String reason, @JsonKey(name: 'created_at')  String createdAt,  NamedRef? creator,  NamedRef? product)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _POSCashMovement() when $default != null:
return $default(_that.id,_that.shiftId,_that.type,_that.amount,_that.reason,_that.createdAt,_that.creator,_that.product);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'shift_id')  String shiftId,  CashMovementType type,  num amount,  String reason, @JsonKey(name: 'created_at')  String createdAt,  NamedRef? creator,  NamedRef? product)  $default,) {final _that = this;
switch (_that) {
case _POSCashMovement():
return $default(_that.id,_that.shiftId,_that.type,_that.amount,_that.reason,_that.createdAt,_that.creator,_that.product);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'shift_id')  String shiftId,  CashMovementType type,  num amount,  String reason, @JsonKey(name: 'created_at')  String createdAt,  NamedRef? creator,  NamedRef? product)?  $default,) {final _that = this;
switch (_that) {
case _POSCashMovement() when $default != null:
return $default(_that.id,_that.shiftId,_that.type,_that.amount,_that.reason,_that.createdAt,_that.creator,_that.product);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _POSCashMovement implements POSCashMovement {
  const _POSCashMovement({required this.id, @JsonKey(name: 'shift_id') required this.shiftId, required this.type, required this.amount, required this.reason, @JsonKey(name: 'created_at') required this.createdAt, this.creator, this.product});
  factory _POSCashMovement.fromJson(Map<String, dynamic> json) => _$POSCashMovementFromJson(json);

@override final  String id;
@override@JsonKey(name: 'shift_id') final  String shiftId;
@override final  CashMovementType type;
@override final  num amount;
@override final  String reason;
@override@JsonKey(name: 'created_at') final  String createdAt;
@override final  NamedRef? creator;
@override final  NamedRef? product;

/// Create a copy of POSCashMovement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$POSCashMovementCopyWith<_POSCashMovement> get copyWith => __$POSCashMovementCopyWithImpl<_POSCashMovement>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$POSCashMovementToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _POSCashMovement&&(identical(other.id, id) || other.id == id)&&(identical(other.shiftId, shiftId) || other.shiftId == shiftId)&&(identical(other.type, type) || other.type == type)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.creator, creator) || other.creator == creator)&&(identical(other.product, product) || other.product == product));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,shiftId,type,amount,reason,createdAt,creator,product);
}

@override
String toString() {
    return 'POSCashMovement(id: $id, shiftId: $shiftId, type: $type, amount: $amount, reason: $reason, createdAt: $createdAt, creator: $creator, product: $product)';
}


}

/// @nodoc
abstract mixin class _$POSCashMovementCopyWith<$Res> implements $POSCashMovementCopyWith<$Res> {
  factory _$POSCashMovementCopyWith(_POSCashMovement value, $Res Function(_POSCashMovement) _then) = __$POSCashMovementCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'shift_id') String shiftId, CashMovementType type, num amount, String reason,@JsonKey(name: 'created_at') String createdAt, NamedRef? creator, NamedRef? product
});


@override $NamedRefCopyWith<$Res>? get creator;@override $NamedRefCopyWith<$Res>? get product;

}
/// @nodoc
class __$POSCashMovementCopyWithImpl<$Res>
    implements _$POSCashMovementCopyWith<$Res> {
  __$POSCashMovementCopyWithImpl(this._self, this._then);

  final _POSCashMovement _self;
  final $Res Function(_POSCashMovement) _then;

/// Create a copy of POSCashMovement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? shiftId = null,Object? type = null,Object? amount = null,Object? reason = null,Object? createdAt = null,Object? creator = freezed,Object? product = freezed,}) {
  return _then(_POSCashMovement(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,shiftId: null == shiftId ? _self.shiftId : shiftId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CashMovementType,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as num,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,creator: freezed == creator ? _self.creator : creator // ignore: cast_nullable_to_non_nullable
as NamedRef?,product: freezed == product ? _self.product : product // ignore: cast_nullable_to_non_nullable
as NamedRef?,
  ));
}

/// Create a copy of POSCashMovement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NamedRefCopyWith<$Res>? get creator {
    if (_self.creator == null) {
    return null;
  }

  return $NamedRefCopyWith<$Res>(_self.creator!, (value) {
    return _then(_self.copyWith(creator: value));
  });
}/// Create a copy of POSCashMovement
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
mixin _$CashMovementDTO {

 CashMovementType get type; num get amount; String get reason;@JsonKey(name: 'account_id') String? get accountId;@JsonKey(name: 'product_id') String? get productId;
/// Create a copy of CashMovementDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CashMovementDTOCopyWith<CashMovementDTO> get copyWith => _$CashMovementDTOCopyWithImpl<CashMovementDTO>(this as CashMovementDTO, _$identity);

  /// Serializes this CashMovementDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CashMovementDTO;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CashMovementDTO&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.reason, _this.reason) || other.reason == _this.reason)&&(identical(other.accountId, _this.accountId) || other.accountId == _this.accountId)&&(identical(other.productId, _this.productId) || other.productId == _this.productId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CashMovementDTO;
  return Object.hash(runtimeType,_this.type,_this.amount,_this.reason,_this.accountId,_this.productId);
}

@override
String toString() {
  final _this = this as CashMovementDTO;
  return 'CashMovementDTO(type: ${_this.type}, amount: ${_this.amount}, reason: ${_this.reason}, accountId: ${_this.accountId}, productId: ${_this.productId})';
}


}

/// @nodoc
abstract mixin class $CashMovementDTOCopyWith<$Res>  {
  factory $CashMovementDTOCopyWith(CashMovementDTO value, $Res Function(CashMovementDTO) _then) = _$CashMovementDTOCopyWithImpl;
@useResult
$Res call({
 CashMovementType type, num amount, String reason,@JsonKey(name: 'account_id') String? accountId,@JsonKey(name: 'product_id') String? productId
});




}
/// @nodoc
class _$CashMovementDTOCopyWithImpl<$Res>
    implements $CashMovementDTOCopyWith<$Res> {
  _$CashMovementDTOCopyWithImpl(this._self, this._then);

  final CashMovementDTO _self;
  final $Res Function(CashMovementDTO) _then;

/// Create a copy of CashMovementDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? amount = null,Object? reason = null,Object? accountId = freezed,Object? productId = freezed,}) {
  return _then(CashMovementDTO(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CashMovementType,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as num,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,productId: freezed == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CashMovementDTO].
extension CashMovementDTOPatterns on CashMovementDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CashMovementDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CashMovementDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CashMovementDTO value)  $default,){
final _that = this;
switch (_that) {
case _CashMovementDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CashMovementDTO value)?  $default,){
final _that = this;
switch (_that) {
case _CashMovementDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CashMovementType type,  num amount,  String reason, @JsonKey(name: 'account_id')  String? accountId, @JsonKey(name: 'product_id')  String? productId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CashMovementDTO() when $default != null:
return $default(_that.type,_that.amount,_that.reason,_that.accountId,_that.productId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CashMovementType type,  num amount,  String reason, @JsonKey(name: 'account_id')  String? accountId, @JsonKey(name: 'product_id')  String? productId)  $default,) {final _that = this;
switch (_that) {
case _CashMovementDTO():
return $default(_that.type,_that.amount,_that.reason,_that.accountId,_that.productId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CashMovementType type,  num amount,  String reason, @JsonKey(name: 'account_id')  String? accountId, @JsonKey(name: 'product_id')  String? productId)?  $default,) {final _that = this;
switch (_that) {
case _CashMovementDTO() when $default != null:
return $default(_that.type,_that.amount,_that.reason,_that.accountId,_that.productId);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(includeIfNull: false)
class _CashMovementDTO implements CashMovementDTO {
  const _CashMovementDTO({required this.type, required this.amount, required this.reason, @JsonKey(name: 'account_id') this.accountId, @JsonKey(name: 'product_id') this.productId});
  factory _CashMovementDTO.fromJson(Map<String, dynamic> json) => _$CashMovementDTOFromJson(json);

@override final  CashMovementType type;
@override final  num amount;
@override final  String reason;
@override@JsonKey(name: 'account_id') final  String? accountId;
@override@JsonKey(name: 'product_id') final  String? productId;

/// Create a copy of CashMovementDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CashMovementDTOCopyWith<_CashMovementDTO> get copyWith => __$CashMovementDTOCopyWithImpl<_CashMovementDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CashMovementDTOToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CashMovementDTO&&(identical(other.type, type) || other.type == type)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.productId, productId) || other.productId == productId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,amount,reason,accountId,productId);
}

@override
String toString() {
    return 'CashMovementDTO(type: $type, amount: $amount, reason: $reason, accountId: $accountId, productId: $productId)';
}


}

/// @nodoc
abstract mixin class _$CashMovementDTOCopyWith<$Res> implements $CashMovementDTOCopyWith<$Res> {
  factory _$CashMovementDTOCopyWith(_CashMovementDTO value, $Res Function(_CashMovementDTO) _then) = __$CashMovementDTOCopyWithImpl;
@override @useResult
$Res call({
 CashMovementType type, num amount, String reason,@JsonKey(name: 'account_id') String? accountId,@JsonKey(name: 'product_id') String? productId
});




}
/// @nodoc
class __$CashMovementDTOCopyWithImpl<$Res>
    implements _$CashMovementDTOCopyWith<$Res> {
  __$CashMovementDTOCopyWithImpl(this._self, this._then);

  final _CashMovementDTO _self;
  final $Res Function(_CashMovementDTO) _then;

/// Create a copy of CashMovementDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? amount = null,Object? reason = null,Object? accountId = freezed,Object? productId = freezed,}) {
  return _then(_CashMovementDTO(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CashMovementType,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as num,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,productId: freezed == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$OpenShiftDTO {

@JsonKey(name: 'outlet_id') String get outletId;@JsonKey(name: 'opening_cash') num get openingCash;@JsonKey(name: 'warehouse_id') String? get warehouseId; String? get notes;
/// Create a copy of OpenShiftDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpenShiftDTOCopyWith<OpenShiftDTO> get copyWith => _$OpenShiftDTOCopyWithImpl<OpenShiftDTO>(this as OpenShiftDTO, _$identity);

  /// Serializes this OpenShiftDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as OpenShiftDTO;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpenShiftDTO&&(identical(other.outletId, _this.outletId) || other.outletId == _this.outletId)&&(identical(other.openingCash, _this.openingCash) || other.openingCash == _this.openingCash)&&(identical(other.warehouseId, _this.warehouseId) || other.warehouseId == _this.warehouseId)&&(identical(other.notes, _this.notes) || other.notes == _this.notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as OpenShiftDTO;
  return Object.hash(runtimeType,_this.outletId,_this.openingCash,_this.warehouseId,_this.notes);
}

@override
String toString() {
  final _this = this as OpenShiftDTO;
  return 'OpenShiftDTO(outletId: ${_this.outletId}, openingCash: ${_this.openingCash}, warehouseId: ${_this.warehouseId}, notes: ${_this.notes})';
}


}

/// @nodoc
abstract mixin class $OpenShiftDTOCopyWith<$Res>  {
  factory $OpenShiftDTOCopyWith(OpenShiftDTO value, $Res Function(OpenShiftDTO) _then) = _$OpenShiftDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'outlet_id') String outletId,@JsonKey(name: 'opening_cash') num openingCash,@JsonKey(name: 'warehouse_id') String? warehouseId, String? notes
});




}
/// @nodoc
class _$OpenShiftDTOCopyWithImpl<$Res>
    implements $OpenShiftDTOCopyWith<$Res> {
  _$OpenShiftDTOCopyWithImpl(this._self, this._then);

  final OpenShiftDTO _self;
  final $Res Function(OpenShiftDTO) _then;

/// Create a copy of OpenShiftDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? outletId = null,Object? openingCash = null,Object? warehouseId = freezed,Object? notes = freezed,}) {
  return _then(OpenShiftDTO(
outletId: null == outletId ? _self.outletId : outletId // ignore: cast_nullable_to_non_nullable
as String,openingCash: null == openingCash ? _self.openingCash : openingCash // ignore: cast_nullable_to_non_nullable
as num,warehouseId: freezed == warehouseId ? _self.warehouseId : warehouseId // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [OpenShiftDTO].
extension OpenShiftDTOPatterns on OpenShiftDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OpenShiftDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpenShiftDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OpenShiftDTO value)  $default,){
final _that = this;
switch (_that) {
case _OpenShiftDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OpenShiftDTO value)?  $default,){
final _that = this;
switch (_that) {
case _OpenShiftDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'outlet_id')  String outletId, @JsonKey(name: 'opening_cash')  num openingCash, @JsonKey(name: 'warehouse_id')  String? warehouseId,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpenShiftDTO() when $default != null:
return $default(_that.outletId,_that.openingCash,_that.warehouseId,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'outlet_id')  String outletId, @JsonKey(name: 'opening_cash')  num openingCash, @JsonKey(name: 'warehouse_id')  String? warehouseId,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _OpenShiftDTO():
return $default(_that.outletId,_that.openingCash,_that.warehouseId,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'outlet_id')  String outletId, @JsonKey(name: 'opening_cash')  num openingCash, @JsonKey(name: 'warehouse_id')  String? warehouseId,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _OpenShiftDTO() when $default != null:
return $default(_that.outletId,_that.openingCash,_that.warehouseId,_that.notes);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(includeIfNull: false)
class _OpenShiftDTO implements OpenShiftDTO {
  const _OpenShiftDTO({@JsonKey(name: 'outlet_id') required this.outletId, @JsonKey(name: 'opening_cash') required this.openingCash, @JsonKey(name: 'warehouse_id') this.warehouseId, this.notes});
  factory _OpenShiftDTO.fromJson(Map<String, dynamic> json) => _$OpenShiftDTOFromJson(json);

@override@JsonKey(name: 'outlet_id') final  String outletId;
@override@JsonKey(name: 'opening_cash') final  num openingCash;
@override@JsonKey(name: 'warehouse_id') final  String? warehouseId;
@override final  String? notes;

/// Create a copy of OpenShiftDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpenShiftDTOCopyWith<_OpenShiftDTO> get copyWith => __$OpenShiftDTOCopyWithImpl<_OpenShiftDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OpenShiftDTOToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpenShiftDTO&&(identical(other.outletId, outletId) || other.outletId == outletId)&&(identical(other.openingCash, openingCash) || other.openingCash == openingCash)&&(identical(other.warehouseId, warehouseId) || other.warehouseId == warehouseId)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,outletId,openingCash,warehouseId,notes);
}

@override
String toString() {
    return 'OpenShiftDTO(outletId: $outletId, openingCash: $openingCash, warehouseId: $warehouseId, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$OpenShiftDTOCopyWith<$Res> implements $OpenShiftDTOCopyWith<$Res> {
  factory _$OpenShiftDTOCopyWith(_OpenShiftDTO value, $Res Function(_OpenShiftDTO) _then) = __$OpenShiftDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'outlet_id') String outletId,@JsonKey(name: 'opening_cash') num openingCash,@JsonKey(name: 'warehouse_id') String? warehouseId, String? notes
});




}
/// @nodoc
class __$OpenShiftDTOCopyWithImpl<$Res>
    implements _$OpenShiftDTOCopyWith<$Res> {
  __$OpenShiftDTOCopyWithImpl(this._self, this._then);

  final _OpenShiftDTO _self;
  final $Res Function(_OpenShiftDTO) _then;

/// Create a copy of OpenShiftDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? outletId = null,Object? openingCash = null,Object? warehouseId = freezed,Object? notes = freezed,}) {
  return _then(_OpenShiftDTO(
outletId: null == outletId ? _self.outletId : outletId // ignore: cast_nullable_to_non_nullable
as String,openingCash: null == openingCash ? _self.openingCash : openingCash // ignore: cast_nullable_to_non_nullable
as num,warehouseId: freezed == warehouseId ? _self.warehouseId : warehouseId // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$CloseShiftDTO {

@JsonKey(name: 'counted_cash') num get countedCash; String? get notes;
/// Create a copy of CloseShiftDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CloseShiftDTOCopyWith<CloseShiftDTO> get copyWith => _$CloseShiftDTOCopyWithImpl<CloseShiftDTO>(this as CloseShiftDTO, _$identity);

  /// Serializes this CloseShiftDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CloseShiftDTO;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CloseShiftDTO&&(identical(other.countedCash, _this.countedCash) || other.countedCash == _this.countedCash)&&(identical(other.notes, _this.notes) || other.notes == _this.notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CloseShiftDTO;
  return Object.hash(runtimeType,_this.countedCash,_this.notes);
}

@override
String toString() {
  final _this = this as CloseShiftDTO;
  return 'CloseShiftDTO(countedCash: ${_this.countedCash}, notes: ${_this.notes})';
}


}

/// @nodoc
abstract mixin class $CloseShiftDTOCopyWith<$Res>  {
  factory $CloseShiftDTOCopyWith(CloseShiftDTO value, $Res Function(CloseShiftDTO) _then) = _$CloseShiftDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'counted_cash') num countedCash, String? notes
});




}
/// @nodoc
class _$CloseShiftDTOCopyWithImpl<$Res>
    implements $CloseShiftDTOCopyWith<$Res> {
  _$CloseShiftDTOCopyWithImpl(this._self, this._then);

  final CloseShiftDTO _self;
  final $Res Function(CloseShiftDTO) _then;

/// Create a copy of CloseShiftDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? countedCash = null,Object? notes = freezed,}) {
  return _then(CloseShiftDTO(
countedCash: null == countedCash ? _self.countedCash : countedCash // ignore: cast_nullable_to_non_nullable
as num,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CloseShiftDTO].
extension CloseShiftDTOPatterns on CloseShiftDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CloseShiftDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CloseShiftDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CloseShiftDTO value)  $default,){
final _that = this;
switch (_that) {
case _CloseShiftDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CloseShiftDTO value)?  $default,){
final _that = this;
switch (_that) {
case _CloseShiftDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'counted_cash')  num countedCash,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CloseShiftDTO() when $default != null:
return $default(_that.countedCash,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'counted_cash')  num countedCash,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _CloseShiftDTO():
return $default(_that.countedCash,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'counted_cash')  num countedCash,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _CloseShiftDTO() when $default != null:
return $default(_that.countedCash,_that.notes);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(includeIfNull: false)
class _CloseShiftDTO implements CloseShiftDTO {
  const _CloseShiftDTO({@JsonKey(name: 'counted_cash') required this.countedCash, this.notes});
  factory _CloseShiftDTO.fromJson(Map<String, dynamic> json) => _$CloseShiftDTOFromJson(json);

@override@JsonKey(name: 'counted_cash') final  num countedCash;
@override final  String? notes;

/// Create a copy of CloseShiftDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CloseShiftDTOCopyWith<_CloseShiftDTO> get copyWith => __$CloseShiftDTOCopyWithImpl<_CloseShiftDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CloseShiftDTOToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CloseShiftDTO&&(identical(other.countedCash, countedCash) || other.countedCash == countedCash)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,countedCash,notes);
}

@override
String toString() {
    return 'CloseShiftDTO(countedCash: $countedCash, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$CloseShiftDTOCopyWith<$Res> implements $CloseShiftDTOCopyWith<$Res> {
  factory _$CloseShiftDTOCopyWith(_CloseShiftDTO value, $Res Function(_CloseShiftDTO) _then) = __$CloseShiftDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'counted_cash') num countedCash, String? notes
});




}
/// @nodoc
class __$CloseShiftDTOCopyWithImpl<$Res>
    implements _$CloseShiftDTOCopyWith<$Res> {
  __$CloseShiftDTOCopyWithImpl(this._self, this._then);

  final _CloseShiftDTO _self;
  final $Res Function(_CloseShiftDTO) _then;

/// Create a copy of CloseShiftDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? countedCash = null,Object? notes = freezed,}) {
  return _then(_CloseShiftDTO(
countedCash: null == countedCash ? _self.countedCash : countedCash // ignore: cast_nullable_to_non_nullable
as num,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$POSShift {

 String get id; String get number;@JsonKey(name: 'cashier_id') String get cashierId;@JsonKey(name: 'outlet_id') String get outletId;@JsonKey(name: 'opened_at') String get openedAt;@JsonKey(name: 'opening_cash') num get openingCash;@JsonKey(name: 'total_sales') num get totalSales;@JsonKey(name: 'total_transactions') int get totalTransactions;/// Whether the drawer is still counting. Only the history list needs it (the active shift is
/// open by definition), and a value this build does not know reads as `null`, like
/// [ShiftSummaryResponse.status]: one row from a newer API must not take the whole list down.
@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) ShiftStatus? get status;@JsonKey(name: 'closed_at') String? get closedAt; NamedRef? get cashier;
/// Create a copy of POSShift
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$POSShiftCopyWith<POSShift> get copyWith => _$POSShiftCopyWithImpl<POSShift>(this as POSShift, _$identity);

  /// Serializes this POSShift to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as POSShift;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is POSShift&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.number, _this.number) || other.number == _this.number)&&(identical(other.cashierId, _this.cashierId) || other.cashierId == _this.cashierId)&&(identical(other.outletId, _this.outletId) || other.outletId == _this.outletId)&&(identical(other.openedAt, _this.openedAt) || other.openedAt == _this.openedAt)&&(identical(other.openingCash, _this.openingCash) || other.openingCash == _this.openingCash)&&(identical(other.totalSales, _this.totalSales) || other.totalSales == _this.totalSales)&&(identical(other.totalTransactions, _this.totalTransactions) || other.totalTransactions == _this.totalTransactions)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.closedAt, _this.closedAt) || other.closedAt == _this.closedAt)&&(identical(other.cashier, _this.cashier) || other.cashier == _this.cashier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as POSShift;
  return Object.hash(runtimeType,_this.id,_this.number,_this.cashierId,_this.outletId,_this.openedAt,_this.openingCash,_this.totalSales,_this.totalTransactions,_this.status,_this.closedAt,_this.cashier);
}

@override
String toString() {
  final _this = this as POSShift;
  return 'POSShift(id: ${_this.id}, number: ${_this.number}, cashierId: ${_this.cashierId}, outletId: ${_this.outletId}, openedAt: ${_this.openedAt}, openingCash: ${_this.openingCash}, totalSales: ${_this.totalSales}, totalTransactions: ${_this.totalTransactions}, status: ${_this.status}, closedAt: ${_this.closedAt}, cashier: ${_this.cashier})';
}


}

/// @nodoc
abstract mixin class $POSShiftCopyWith<$Res>  {
  factory $POSShiftCopyWith(POSShift value, $Res Function(POSShift) _then) = _$POSShiftCopyWithImpl;
@useResult
$Res call({
 String id, String number,@JsonKey(name: 'cashier_id') String cashierId,@JsonKey(name: 'outlet_id') String outletId,@JsonKey(name: 'opened_at') String openedAt,@JsonKey(name: 'opening_cash') num openingCash,@JsonKey(name: 'total_sales') num totalSales,@JsonKey(name: 'total_transactions') int totalTransactions,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) ShiftStatus? status,@JsonKey(name: 'closed_at') String? closedAt, NamedRef? cashier
});


$NamedRefCopyWith<$Res>? get cashier;

}
/// @nodoc
class _$POSShiftCopyWithImpl<$Res>
    implements $POSShiftCopyWith<$Res> {
  _$POSShiftCopyWithImpl(this._self, this._then);

  final POSShift _self;
  final $Res Function(POSShift) _then;

/// Create a copy of POSShift
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? number = null,Object? cashierId = null,Object? outletId = null,Object? openedAt = null,Object? openingCash = null,Object? totalSales = null,Object? totalTransactions = null,Object? status = freezed,Object? closedAt = freezed,Object? cashier = freezed,}) {
  return _then(POSShift(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,cashierId: null == cashierId ? _self.cashierId : cashierId // ignore: cast_nullable_to_non_nullable
as String,outletId: null == outletId ? _self.outletId : outletId // ignore: cast_nullable_to_non_nullable
as String,openedAt: null == openedAt ? _self.openedAt : openedAt // ignore: cast_nullable_to_non_nullable
as String,openingCash: null == openingCash ? _self.openingCash : openingCash // ignore: cast_nullable_to_non_nullable
as num,totalSales: null == totalSales ? _self.totalSales : totalSales // ignore: cast_nullable_to_non_nullable
as num,totalTransactions: null == totalTransactions ? _self.totalTransactions : totalTransactions // ignore: cast_nullable_to_non_nullable
as int,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ShiftStatus?,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as String?,cashier: freezed == cashier ? _self.cashier : cashier // ignore: cast_nullable_to_non_nullable
as NamedRef?,
  ));
}
/// Create a copy of POSShift
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


/// Adds pattern-matching-related methods to [POSShift].
extension POSShiftPatterns on POSShift {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _POSShift value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _POSShift() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _POSShift value)  $default,){
final _that = this;
switch (_that) {
case _POSShift():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _POSShift value)?  $default,){
final _that = this;
switch (_that) {
case _POSShift() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String number, @JsonKey(name: 'cashier_id')  String cashierId, @JsonKey(name: 'outlet_id')  String outletId, @JsonKey(name: 'opened_at')  String openedAt, @JsonKey(name: 'opening_cash')  num openingCash, @JsonKey(name: 'total_sales')  num totalSales, @JsonKey(name: 'total_transactions')  int totalTransactions, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  ShiftStatus? status, @JsonKey(name: 'closed_at')  String? closedAt,  NamedRef? cashier)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _POSShift() when $default != null:
return $default(_that.id,_that.number,_that.cashierId,_that.outletId,_that.openedAt,_that.openingCash,_that.totalSales,_that.totalTransactions,_that.status,_that.closedAt,_that.cashier);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String number, @JsonKey(name: 'cashier_id')  String cashierId, @JsonKey(name: 'outlet_id')  String outletId, @JsonKey(name: 'opened_at')  String openedAt, @JsonKey(name: 'opening_cash')  num openingCash, @JsonKey(name: 'total_sales')  num totalSales, @JsonKey(name: 'total_transactions')  int totalTransactions, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  ShiftStatus? status, @JsonKey(name: 'closed_at')  String? closedAt,  NamedRef? cashier)  $default,) {final _that = this;
switch (_that) {
case _POSShift():
return $default(_that.id,_that.number,_that.cashierId,_that.outletId,_that.openedAt,_that.openingCash,_that.totalSales,_that.totalTransactions,_that.status,_that.closedAt,_that.cashier);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String number, @JsonKey(name: 'cashier_id')  String cashierId, @JsonKey(name: 'outlet_id')  String outletId, @JsonKey(name: 'opened_at')  String openedAt, @JsonKey(name: 'opening_cash')  num openingCash, @JsonKey(name: 'total_sales')  num totalSales, @JsonKey(name: 'total_transactions')  int totalTransactions, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  ShiftStatus? status, @JsonKey(name: 'closed_at')  String? closedAt,  NamedRef? cashier)?  $default,) {final _that = this;
switch (_that) {
case _POSShift() when $default != null:
return $default(_that.id,_that.number,_that.cashierId,_that.outletId,_that.openedAt,_that.openingCash,_that.totalSales,_that.totalTransactions,_that.status,_that.closedAt,_that.cashier);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _POSShift implements POSShift {
  const _POSShift({required this.id, required this.number, @JsonKey(name: 'cashier_id') required this.cashierId, @JsonKey(name: 'outlet_id') required this.outletId, @JsonKey(name: 'opened_at') required this.openedAt, @JsonKey(name: 'opening_cash') required this.openingCash, @JsonKey(name: 'total_sales') required this.totalSales, @JsonKey(name: 'total_transactions') required this.totalTransactions, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) this.status, @JsonKey(name: 'closed_at') this.closedAt, this.cashier});
  factory _POSShift.fromJson(Map<String, dynamic> json) => _$POSShiftFromJson(json);

@override final  String id;
@override final  String number;
@override@JsonKey(name: 'cashier_id') final  String cashierId;
@override@JsonKey(name: 'outlet_id') final  String outletId;
@override@JsonKey(name: 'opened_at') final  String openedAt;
@override@JsonKey(name: 'opening_cash') final  num openingCash;
@override@JsonKey(name: 'total_sales') final  num totalSales;
@override@JsonKey(name: 'total_transactions') final  int totalTransactions;
/// Whether the drawer is still counting. Only the history list needs it (the active shift is
/// open by definition), and a value this build does not know reads as `null`, like
/// [ShiftSummaryResponse.status]: one row from a newer API must not take the whole list down.
@override@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) final  ShiftStatus? status;
@override@JsonKey(name: 'closed_at') final  String? closedAt;
@override final  NamedRef? cashier;

/// Create a copy of POSShift
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$POSShiftCopyWith<_POSShift> get copyWith => __$POSShiftCopyWithImpl<_POSShift>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$POSShiftToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _POSShift&&(identical(other.id, id) || other.id == id)&&(identical(other.number, number) || other.number == number)&&(identical(other.cashierId, cashierId) || other.cashierId == cashierId)&&(identical(other.outletId, outletId) || other.outletId == outletId)&&(identical(other.openedAt, openedAt) || other.openedAt == openedAt)&&(identical(other.openingCash, openingCash) || other.openingCash == openingCash)&&(identical(other.totalSales, totalSales) || other.totalSales == totalSales)&&(identical(other.totalTransactions, totalTransactions) || other.totalTransactions == totalTransactions)&&(identical(other.status, status) || other.status == status)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.cashier, cashier) || other.cashier == cashier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,number,cashierId,outletId,openedAt,openingCash,totalSales,totalTransactions,status,closedAt,cashier);
}

@override
String toString() {
    return 'POSShift(id: $id, number: $number, cashierId: $cashierId, outletId: $outletId, openedAt: $openedAt, openingCash: $openingCash, totalSales: $totalSales, totalTransactions: $totalTransactions, status: $status, closedAt: $closedAt, cashier: $cashier)';
}


}

/// @nodoc
abstract mixin class _$POSShiftCopyWith<$Res> implements $POSShiftCopyWith<$Res> {
  factory _$POSShiftCopyWith(_POSShift value, $Res Function(_POSShift) _then) = __$POSShiftCopyWithImpl;
@override @useResult
$Res call({
 String id, String number,@JsonKey(name: 'cashier_id') String cashierId,@JsonKey(name: 'outlet_id') String outletId,@JsonKey(name: 'opened_at') String openedAt,@JsonKey(name: 'opening_cash') num openingCash,@JsonKey(name: 'total_sales') num totalSales,@JsonKey(name: 'total_transactions') int totalTransactions,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) ShiftStatus? status,@JsonKey(name: 'closed_at') String? closedAt, NamedRef? cashier
});


@override $NamedRefCopyWith<$Res>? get cashier;

}
/// @nodoc
class __$POSShiftCopyWithImpl<$Res>
    implements _$POSShiftCopyWith<$Res> {
  __$POSShiftCopyWithImpl(this._self, this._then);

  final _POSShift _self;
  final $Res Function(_POSShift) _then;

/// Create a copy of POSShift
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? number = null,Object? cashierId = null,Object? outletId = null,Object? openedAt = null,Object? openingCash = null,Object? totalSales = null,Object? totalTransactions = null,Object? status = freezed,Object? closedAt = freezed,Object? cashier = freezed,}) {
  return _then(_POSShift(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,cashierId: null == cashierId ? _self.cashierId : cashierId // ignore: cast_nullable_to_non_nullable
as String,outletId: null == outletId ? _self.outletId : outletId // ignore: cast_nullable_to_non_nullable
as String,openedAt: null == openedAt ? _self.openedAt : openedAt // ignore: cast_nullable_to_non_nullable
as String,openingCash: null == openingCash ? _self.openingCash : openingCash // ignore: cast_nullable_to_non_nullable
as num,totalSales: null == totalSales ? _self.totalSales : totalSales // ignore: cast_nullable_to_non_nullable
as num,totalTransactions: null == totalTransactions ? _self.totalTransactions : totalTransactions // ignore: cast_nullable_to_non_nullable
as int,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ShiftStatus?,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as String?,cashier: freezed == cashier ? _self.cashier : cashier // ignore: cast_nullable_to_non_nullable
as NamedRef?,
  ));
}

/// Create a copy of POSShift
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

// dart format on
