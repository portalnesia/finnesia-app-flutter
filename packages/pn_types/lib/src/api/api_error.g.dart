// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ApiErrorDetail _$ApiErrorDetailFromJson(Map<String, dynamic> json) =>
    _ApiErrorDetail(
      field: json['field'] as String?,
      id: json['id'] as String?,
      message: json['message'] as String,
    );

Map<String, dynamic> _$ApiErrorDetailToJson(_ApiErrorDetail instance) =>
    <String, dynamic>{
      'field': instance.field,
      'id': instance.id,
      'message': instance.message,
    };

_ApiErrorTypes _$ApiErrorTypesFromJson(Map<String, dynamic> json) =>
    _ApiErrorTypes(
      name: json['name'] as String?,
      code: (json['code'] as num?)?.toInt(),
      message: json['message'] as String?,
      description: json['description'] as String?,
      details: (json['details'] as List<dynamic>?)
          ?.map((e) => ApiErrorDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
      key: json['key'] as String?,
      params: json['params'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ApiErrorTypesToJson(_ApiErrorTypes instance) =>
    <String, dynamic>{
      'name': instance.name,
      'code': instance.code,
      'message': instance.message,
      'description': instance.description,
      'details': instance.details,
      'key': instance.key,
      'params': instance.params,
    };
