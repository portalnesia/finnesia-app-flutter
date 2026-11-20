// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'master_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Contact _$ContactFromJson(Map<String, dynamic> json) => _Contact(
  id: json['id'] as String,
  name: json['name'] as String,
  type: $enumDecodeNullable(
    _$ContactTypeEnumMap,
    json['type'],
    unknownValue: JsonKey.nullForUndefinedEnumValue,
  ),
  companyName: json['company_name'] as String?,
  email: json['email'] as String?,
  phone: json['phone'] as String?,
);

Map<String, dynamic> _$ContactToJson(_Contact instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'type': _$ContactTypeEnumMap[instance.type],
  'company_name': instance.companyName,
  'email': instance.email,
  'phone': instance.phone,
};

const _$ContactTypeEnumMap = {
  ContactType.customer: 'CUSTOMER',
  ContactType.supplier: 'SUPPLIER',
  ContactType.sales: 'SALES',
};

_Unit _$UnitFromJson(Map<String, dynamic> json) => _Unit(
  id: json['id'] as String,
  name: json['name'] as String,
  symbol: json['symbol'] as String,
);

Map<String, dynamic> _$UnitToJson(_Unit instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'symbol': instance.symbol,
};

_ChartOfAccount _$ChartOfAccountFromJson(Map<String, dynamic> json) =>
    _ChartOfAccount(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$ChartOfAccountToJson(_ChartOfAccount instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
    };
