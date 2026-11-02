// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NotificationItemRef _$NotificationItemRefFromJson(Map<String, dynamic> json) =>
    _NotificationItemRef(
      type: json['type'] as String,
      id: json['id'] as String,
    );

Map<String, dynamic> _$NotificationItemRefToJson(
  _NotificationItemRef instance,
) => <String, dynamic>{'type': instance.type, 'id': instance.id};

_NotificationItemActor _$NotificationItemActorFromJson(
  Map<String, dynamic> json,
) => _NotificationItemActor(
  id: json['id'] as String,
  name: json['name'] as String,
  picture: json['picture'] as String?,
);

Map<String, dynamic> _$NotificationItemActorToJson(
  _NotificationItemActor instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'picture': instance.picture,
};

_NotificationItemIcon _$NotificationItemIconFromJson(
  Map<String, dynamic> json,
) => _NotificationItemIcon(
  type: json['type'] as String,
  value: json['value'] as String,
  fallback: json['fallback'] as String?,
);

Map<String, dynamic> _$NotificationItemIconToJson(
  _NotificationItemIcon instance,
) => <String, dynamic>{
  'type': instance.type,
  'value': instance.value,
  'fallback': instance.fallback,
};

_NotificationItemButton _$NotificationItemButtonFromJson(
  Map<String, dynamic> json,
) => _NotificationItemButton(
  label: json['label'] as String,
  link: json['link'] as String,
  style: json['style'] as String,
);

Map<String, dynamic> _$NotificationItemButtonToJson(
  _NotificationItemButton instance,
) => <String, dynamic>{
  'label': instance.label,
  'link': instance.link,
  'style': instance.style,
};

_NotificationItem _$NotificationItemFromJson(Map<String, dynamic> json) =>
    _NotificationItem(
      id: json['id'] as String,
      notificationId: json['notification_id'] as String,
      type: json['type'] as String,
      category: json['category'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      link: json['link'] as String?,
      ref: json['ref'] == null
          ? null
          : NotificationItemRef.fromJson(json['ref'] as Map<String, dynamic>),
      companyId: json['company_id'] as String?,
      actor: json['actor'] == null
          ? null
          : NotificationItemActor.fromJson(
              json['actor'] as Map<String, dynamic>,
            ),
      icon: json['icon'] == null
          ? null
          : NotificationItemIcon.fromJson(json['icon'] as Map<String, dynamic>),
      image: json['image'] as String?,
      imageRatio: json['image_ratio'] as String?,
      buttons:
          (json['buttons'] as List<dynamic>?)
              ?.map(
                (e) =>
                    NotificationItemButton.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <NotificationItemButton>[],
      readAt: json['read_at'] == null
          ? null
          : DateTime.parse(json['read_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$NotificationItemToJson(_NotificationItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'notification_id': instance.notificationId,
      'type': instance.type,
      'category': instance.category,
      'title': instance.title,
      'body': instance.body,
      'link': instance.link,
      'ref': instance.ref,
      'company_id': instance.companyId,
      'actor': instance.actor,
      'icon': instance.icon,
      'image': instance.image,
      'image_ratio': instance.imageRatio,
      'buttons': instance.buttons,
      'read_at': instance.readAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };

_NotificationListResponse _$NotificationListResponseFromJson(
  Map<String, dynamic> json,
) => _NotificationListResponse(
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <NotificationItem>[],
  nextCursor: json['next_cursor'] as String,
);

Map<String, dynamic> _$NotificationListResponseToJson(
  _NotificationListResponse instance,
) => <String, dynamic>{
  'items': instance.items,
  'next_cursor': instance.nextCursor,
};

_NotificationUnreadCountResponse _$NotificationUnreadCountResponseFromJson(
  Map<String, dynamic> json,
) => _NotificationUnreadCountResponse(total: (json['total'] as num).toInt());

Map<String, dynamic> _$NotificationUnreadCountResponseToJson(
  _NotificationUnreadCountResponse instance,
) => <String, dynamic>{'total': instance.total};

_NotificationMarkReadRequest _$NotificationMarkReadRequestFromJson(
  Map<String, dynamic> json,
) => _NotificationMarkReadRequest(
  ids:
      (json['ids'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  all: json['all'] as bool? ?? false,
);

Map<String, dynamic> _$NotificationMarkReadRequestToJson(
  _NotificationMarkReadRequest instance,
) => <String, dynamic>{'ids': instance.ids, 'all': instance.all};

_NotificationMarkReadResponse _$NotificationMarkReadResponseFromJson(
  Map<String, dynamic> json,
) => _NotificationMarkReadResponse(updated: (json['updated'] as num).toInt());

Map<String, dynamic> _$NotificationMarkReadResponseToJson(
  _NotificationMarkReadResponse instance,
) => <String, dynamic>{'updated': instance.updated};

_NotificationOpenRequest _$NotificationOpenRequestFromJson(
  Map<String, dynamic> json,
) => _NotificationOpenRequest(
  notificationId: json['notification_id'] as String,
  companyId: json['company_id'] as String?,
);

Map<String, dynamic> _$NotificationOpenRequestToJson(
  _NotificationOpenRequest instance,
) => <String, dynamic>{
  'notification_id': instance.notificationId,
  'company_id': instance.companyId,
};

_NotificationOpenResponse _$NotificationOpenResponseFromJson(
  Map<String, dynamic> json,
) => _NotificationOpenResponse(
  companyId: json['company_id'] as String?,
  link: json['link'] as String,
  item: json['item'] == null
      ? null
      : NotificationItem.fromJson(json['item'] as Map<String, dynamic>),
);

Map<String, dynamic> _$NotificationOpenResponseToJson(
  _NotificationOpenResponse instance,
) => <String, dynamic>{
  'company_id': instance.companyId,
  'link': instance.link,
  'item': instance.item,
};
