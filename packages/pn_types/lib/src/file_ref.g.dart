// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_ref.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FileRef _$FileRefFromJson(Map<String, dynamic> json) => _FileRef(
  id: json['id'] == null ? '' : _asString(json['id']),
  name: _asNullableString(json['name']),
  status: json['status'] == null ? '' : _asString(json['status']),
  url: json['url'] == null ? '' : _asString(json['url']),
);

Map<String, dynamic> _$FileRefToJson(_FileRef instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'status': instance.status,
  'url': instance.url,
};
