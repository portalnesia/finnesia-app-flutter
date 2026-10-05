// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Product {

 String get id; String get name; String? get sku; String? get barcode;@JsonKey(name: 'unit_id') String get unitId;/// Nullable because the source's only read site treats it as possibly absent: the
/// checkout payload writes `l.product.sell_price ?? 0`
/// (`apps/web/src/pages/pos/pos-cart-page.tsx`). The TypeScript type declares it
/// non-optional, so that `?? 0` is the observed contract and it wins.
@JsonKey(name: 'sell_price') num? get sellPrice;/// What kind of thing this is. Drives the stock badge and whether it can run out.
/// A type this build does not know reads as `null`, matching
/// [ProductType.tryParse]: a newer catalogue must not crash the till.
@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) ProductType? get type;/// The product's own category, which may be nested one level. `topLevelCategory`
/// rolls a sub-category up to its parent for kitchen/bar tickets.
 Category? get category;/// The catalogue photo, as a file reference: the tile renders it only when
/// [FileRef.renderableUrl] is non-null, and falls back to an icon otherwise.
@JsonKey(name: 'image') FileRef? get image;/// Null on rows that predate the field, which the till reads as active
/// (`p.is_active !== false`).
@JsonKey(name: 'is_active') bool? get isActive;
/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductCopyWith<Product> get copyWith => _$ProductCopyWithImpl<Product>(this as Product, _$identity);

  /// Serializes this Product to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Product;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Product&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.sku, _this.sku) || other.sku == _this.sku)&&(identical(other.barcode, _this.barcode) || other.barcode == _this.barcode)&&(identical(other.unitId, _this.unitId) || other.unitId == _this.unitId)&&(identical(other.sellPrice, _this.sellPrice) || other.sellPrice == _this.sellPrice)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.image, _this.image) || other.image == _this.image)&&(identical(other.isActive, _this.isActive) || other.isActive == _this.isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Product;
  return Object.hash(runtimeType,_this.id,_this.name,_this.sku,_this.barcode,_this.unitId,_this.sellPrice,_this.type,_this.category,_this.image,_this.isActive);
}

@override
String toString() {
  final _this = this as Product;
  return 'Product(id: ${_this.id}, name: ${_this.name}, sku: ${_this.sku}, barcode: ${_this.barcode}, unitId: ${_this.unitId}, sellPrice: ${_this.sellPrice}, type: ${_this.type}, category: ${_this.category}, image: ${_this.image}, isActive: ${_this.isActive})';
}


}

/// @nodoc
abstract mixin class $ProductCopyWith<$Res>  {
  factory $ProductCopyWith(Product value, $Res Function(Product) _then) = _$ProductCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? sku, String? barcode,@JsonKey(name: 'unit_id') String unitId,@JsonKey(name: 'sell_price') num? sellPrice,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) ProductType? type, Category? category,@JsonKey(name: 'image') FileRef? image,@JsonKey(name: 'is_active') bool? isActive
});


$CategoryCopyWith<$Res>? get category;$FileRefCopyWith<$Res>? get image;

}
/// @nodoc
class _$ProductCopyWithImpl<$Res>
    implements $ProductCopyWith<$Res> {
  _$ProductCopyWithImpl(this._self, this._then);

  final Product _self;
  final $Res Function(Product) _then;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? sku = freezed,Object? barcode = freezed,Object? unitId = null,Object? sellPrice = freezed,Object? type = freezed,Object? category = freezed,Object? image = freezed,Object? isActive = freezed,}) {
  return _then(Product(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sku: freezed == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String?,barcode: freezed == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String?,unitId: null == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String,sellPrice: freezed == sellPrice ? _self.sellPrice : sellPrice // ignore: cast_nullable_to_non_nullable
as num?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ProductType?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as Category?,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as FileRef?,isActive: freezed == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}
/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryCopyWith<$Res>? get category {
    if (_self.category == null) {
    return null;
  }

  return $CategoryCopyWith<$Res>(_self.category!, (value) {
    return _then(_self.copyWith(category: value));
  });
}/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FileRefCopyWith<$Res>? get image {
    if (_self.image == null) {
    return null;
  }

  return $FileRefCopyWith<$Res>(_self.image!, (value) {
    return _then(_self.copyWith(image: value));
  });
}
}


/// Adds pattern-matching-related methods to [Product].
extension ProductPatterns on Product {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Product value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Product() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Product value)  $default,){
final _that = this;
switch (_that) {
case _Product():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Product value)?  $default,){
final _that = this;
switch (_that) {
case _Product() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? sku,  String? barcode, @JsonKey(name: 'unit_id')  String unitId, @JsonKey(name: 'sell_price')  num? sellPrice, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  ProductType? type,  Category? category, @JsonKey(name: 'image')  FileRef? image, @JsonKey(name: 'is_active')  bool? isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that.id,_that.name,_that.sku,_that.barcode,_that.unitId,_that.sellPrice,_that.type,_that.category,_that.image,_that.isActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? sku,  String? barcode, @JsonKey(name: 'unit_id')  String unitId, @JsonKey(name: 'sell_price')  num? sellPrice, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  ProductType? type,  Category? category, @JsonKey(name: 'image')  FileRef? image, @JsonKey(name: 'is_active')  bool? isActive)  $default,) {final _that = this;
switch (_that) {
case _Product():
return $default(_that.id,_that.name,_that.sku,_that.barcode,_that.unitId,_that.sellPrice,_that.type,_that.category,_that.image,_that.isActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? sku,  String? barcode, @JsonKey(name: 'unit_id')  String unitId, @JsonKey(name: 'sell_price')  num? sellPrice, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  ProductType? type,  Category? category, @JsonKey(name: 'image')  FileRef? image, @JsonKey(name: 'is_active')  bool? isActive)?  $default,) {final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that.id,_that.name,_that.sku,_that.barcode,_that.unitId,_that.sellPrice,_that.type,_that.category,_that.image,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Product implements Product {
  const _Product({required this.id, required this.name, this.sku, this.barcode, @JsonKey(name: 'unit_id') required this.unitId, @JsonKey(name: 'sell_price') this.sellPrice, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) this.type, this.category, @JsonKey(name: 'image') this.image, @JsonKey(name: 'is_active') this.isActive});
  factory _Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? sku;
@override final  String? barcode;
@override@JsonKey(name: 'unit_id') final  String unitId;
/// Nullable because the source's only read site treats it as possibly absent: the
/// checkout payload writes `l.product.sell_price ?? 0`
/// (`apps/web/src/pages/pos/pos-cart-page.tsx`). The TypeScript type declares it
/// non-optional, so that `?? 0` is the observed contract and it wins.
@override@JsonKey(name: 'sell_price') final  num? sellPrice;
/// What kind of thing this is. Drives the stock badge and whether it can run out.
/// A type this build does not know reads as `null`, matching
/// [ProductType.tryParse]: a newer catalogue must not crash the till.
@override@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) final  ProductType? type;
/// The product's own category, which may be nested one level. `topLevelCategory`
/// rolls a sub-category up to its parent for kitchen/bar tickets.
@override final  Category? category;
/// The catalogue photo, as a file reference: the tile renders it only when
/// [FileRef.renderableUrl] is non-null, and falls back to an icon otherwise.
@override@JsonKey(name: 'image') final  FileRef? image;
/// Null on rows that predate the field, which the till reads as active
/// (`p.is_active !== false`).
@override@JsonKey(name: 'is_active') final  bool? isActive;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductCopyWith<_Product> get copyWith => __$ProductCopyWithImpl<_Product>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Product&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.sellPrice, sellPrice) || other.sellPrice == sellPrice)&&(identical(other.type, type) || other.type == type)&&(identical(other.category, category) || other.category == category)&&(identical(other.image, image) || other.image == image)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,sku,barcode,unitId,sellPrice,type,category,image,isActive);
}

@override
String toString() {
    return 'Product(id: $id, name: $name, sku: $sku, barcode: $barcode, unitId: $unitId, sellPrice: $sellPrice, type: $type, category: $category, image: $image, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$ProductCopyWith<$Res> implements $ProductCopyWith<$Res> {
  factory _$ProductCopyWith(_Product value, $Res Function(_Product) _then) = __$ProductCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? sku, String? barcode,@JsonKey(name: 'unit_id') String unitId,@JsonKey(name: 'sell_price') num? sellPrice,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) ProductType? type, Category? category,@JsonKey(name: 'image') FileRef? image,@JsonKey(name: 'is_active') bool? isActive
});


@override $CategoryCopyWith<$Res>? get category;@override $FileRefCopyWith<$Res>? get image;

}
/// @nodoc
class __$ProductCopyWithImpl<$Res>
    implements _$ProductCopyWith<$Res> {
  __$ProductCopyWithImpl(this._self, this._then);

  final _Product _self;
  final $Res Function(_Product) _then;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? sku = freezed,Object? barcode = freezed,Object? unitId = null,Object? sellPrice = freezed,Object? type = freezed,Object? category = freezed,Object? image = freezed,Object? isActive = freezed,}) {
  return _then(_Product(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sku: freezed == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String?,barcode: freezed == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String?,unitId: null == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String,sellPrice: freezed == sellPrice ? _self.sellPrice : sellPrice // ignore: cast_nullable_to_non_nullable
as num?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ProductType?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as Category?,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as FileRef?,isActive: freezed == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryCopyWith<$Res>? get category {
    if (_self.category == null) {
    return null;
  }

  return $CategoryCopyWith<$Res>(_self.category!, (value) {
    return _then(_self.copyWith(category: value));
  });
}/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FileRefCopyWith<$Res>? get image {
    if (_self.image == null) {
    return null;
  }

  return $FileRefCopyWith<$Res>(_self.image!, (value) {
    return _then(_self.copyWith(image: value));
  });
}
}

// dart format on
