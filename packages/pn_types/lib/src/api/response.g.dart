// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PaginationMeta _$PaginationMetaFromJson(Map<String, dynamic> json) =>
    _PaginationMeta(
      nextCursor: json['next_cursor'] as String?,
      prevCursor: json['prev_cursor'] as String?,
      pageSize: (json['page_size'] as num?)?.toInt(),
      page: (json['page'] as num?)?.toInt(),
      total: (json['total'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PaginationMetaToJson(_PaginationMeta instance) =>
    <String, dynamic>{
      'next_cursor': instance.nextCursor,
      'prev_cursor': instance.prevCursor,
      'page_size': instance.pageSize,
      'page': instance.page,
      'total': instance.total,
    };

_ResponseData<R> _$ResponseDataFromJson<R>(
  Map<String, dynamic> json,
  R Function(Object? json) fromJsonR,
) => _ResponseData<R>(
  data: fromJsonR(json['data']),
  error: json['error'] == null
      ? null
      : ApiErrorTypes.fromJson(json['error'] as Map<String, dynamic>),
  message: json['message'] as String?,
  meta: json['meta'] == null
      ? null
      : PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ResponseDataToJson<R>(
  _ResponseData<R> instance,
  Object? Function(R value) toJsonR,
) => <String, dynamic>{
  'data': toJsonR(instance.data),
  'error': instance.error,
  'message': instance.message,
  'meta': instance.meta,
};
