// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserCompany _$UserCompanyFromJson(Map<String, dynamic> json) => _UserCompany(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  companyId: json['company_id'] as String,
  roleId: json['role_id'] as String?,
  branchId: json['branch_id'] as String?,
  warehouseId: json['warehouse_id'] as String?,
  outletId: json['outlet_id'] as String?,
  role: json['role'] as String,
  isActive: json['is_active'] as bool,
  company: json['company'] == null
      ? null
      : CompanyRef.fromJson(json['company'] as Map<String, dynamic>),
);

Map<String, dynamic> _$UserCompanyToJson(_UserCompany instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'company_id': instance.companyId,
      'role_id': instance.roleId,
      'branch_id': instance.branchId,
      'warehouse_id': instance.warehouseId,
      'outlet_id': instance.outletId,
      'role': instance.role,
      'is_active': instance.isActive,
      'company': instance.company,
    };

_CompanyRef _$CompanyRefFromJson(Map<String, dynamic> json) => _CompanyRef(
  name: json['name'] as String? ?? '',
  logo: json['logo'] == null
      ? null
      : FileRef.fromJson(json['logo'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CompanyRefToJson(_CompanyRef instance) =>
    <String, dynamic>{'name': instance.name, 'logo': instance.logo};

_Outlet _$OutletFromJson(Map<String, dynamic> json) =>
    _Outlet(id: json['id'] as String, name: json['name'] as String);

Map<String, dynamic> _$OutletToJson(_Outlet instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
};
