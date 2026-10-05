// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Product _$ProductFromJson(Map<String, dynamic> json) => _Product(
  id: json['id'] as String,
  name: json['name'] as String,
  sku: json['sku'] as String?,
  barcode: json['barcode'] as String?,
  unitId: json['unit_id'] as String,
  sellPrice: json['sell_price'] as num?,
  type: $enumDecodeNullable(
    _$ProductTypeEnumMap,
    json['type'],
    unknownValue: JsonKey.nullForUndefinedEnumValue,
  ),
  category: json['category'] == null
      ? null
      : Category.fromJson(json['category'] as Map<String, dynamic>),
  image: json['image'] == null
      ? null
      : FileRef.fromJson(json['image'] as Map<String, dynamic>),
  isActive: json['is_active'] as bool?,
);

Map<String, dynamic> _$ProductToJson(_Product instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'sku': instance.sku,
  'barcode': instance.barcode,
  'unit_id': instance.unitId,
  'sell_price': instance.sellPrice,
  'type': _$ProductTypeEnumMap[instance.type],
  'category': instance.category,
  'image': instance.image,
  'is_active': instance.isActive,
};

const _$ProductTypeEnumMap = {
  ProductType.inventory: 'INVENTORY',
  ProductType.nonInventory: 'NON_INVENTORY',
  ProductType.bundle: 'BUNDLE',
};
