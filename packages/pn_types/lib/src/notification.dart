/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification.freezed.dart';
part 'notification.g.dart';

@freezed
abstract class NotificationItemRef with _$NotificationItemRef {
  const factory NotificationItemRef({
    required String type,
    required String id,
  }) = _NotificationItemRef;

  factory NotificationItemRef.fromJson(Map<String, dynamic> json) =>
      _$NotificationItemRefFromJson(json);
}

@freezed
abstract class NotificationItemActor with _$NotificationItemActor {
  const factory NotificationItemActor({
    required String id,
    required String name,
    String? picture,
  }) = _NotificationItemActor;

  factory NotificationItemActor.fromJson(Map<String, dynamic> json) =>
      _$NotificationItemActorFromJson(json);
}

@freezed
abstract class NotificationItemIcon with _$NotificationItemIcon {
  const factory NotificationItemIcon({
    required String type,
    required String value,
    String? fallback,
  }) = _NotificationItemIcon;

  factory NotificationItemIcon.fromJson(Map<String, dynamic> json) =>
      _$NotificationItemIconFromJson(json);
}

@freezed
abstract class NotificationItemButton with _$NotificationItemButton {
  const factory NotificationItemButton({
    required String label,
    required String link,
    required String style,
  }) = _NotificationItemButton;

  factory NotificationItemButton.fromJson(Map<String, dynamic> json) =>
      _$NotificationItemButtonFromJson(json);
}

/// One recipient row. [id] is the row id used by mark-read; [notificationId] is
/// the notification id used by open, because a push/open applies to recipients.
@freezed
abstract class NotificationItem with _$NotificationItem {
  const factory NotificationItem({
    required String id,
    @JsonKey(name: 'notification_id') required String notificationId,
    required String type,
    required String category,
    required String title,
    required String body,
    String? link,
    NotificationItemRef? ref,
    @JsonKey(name: 'company_id') String? companyId,
    NotificationItemActor? actor,
    NotificationItemIcon? icon,
    String? image,
    @JsonKey(name: 'image_ratio') String? imageRatio,
    @Default(<NotificationItemButton>[]) List<NotificationItemButton> buttons,
    @JsonKey(name: 'read_at') DateTime? readAt,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _NotificationItem;

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      _$NotificationItemFromJson(json);
}

@freezed
abstract class NotificationListResponse with _$NotificationListResponse {
  const factory NotificationListResponse({
    @Default(<NotificationItem>[]) List<NotificationItem> items,
    @JsonKey(name: 'next_cursor') required String nextCursor,
  }) = _NotificationListResponse;

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) =>
      _$NotificationListResponseFromJson(json);
}

@freezed
abstract class NotificationUnreadCountResponse
    with _$NotificationUnreadCountResponse {
  const factory NotificationUnreadCountResponse({required int total}) =
      _NotificationUnreadCountResponse;

  factory NotificationUnreadCountResponse.fromJson(Map<String, dynamic> json) =>
      _$NotificationUnreadCountResponseFromJson(json);
}

@freezed
abstract class NotificationMarkReadRequest with _$NotificationMarkReadRequest {
  const factory NotificationMarkReadRequest({
    @Default(<String>[]) List<String> ids,
    @Default(false) bool all,
  }) = _NotificationMarkReadRequest;

  factory NotificationMarkReadRequest.fromJson(Map<String, dynamic> json) =>
      _$NotificationMarkReadRequestFromJson(json);
}

@freezed
abstract class NotificationMarkReadResponse
    with _$NotificationMarkReadResponse {
  const factory NotificationMarkReadResponse({required int updated}) =
      _NotificationMarkReadResponse;

  factory NotificationMarkReadResponse.fromJson(Map<String, dynamic> json) =>
      _$NotificationMarkReadResponseFromJson(json);
}

@freezed
abstract class NotificationOpenRequest with _$NotificationOpenRequest {
  const factory NotificationOpenRequest({
    @JsonKey(name: 'notification_id') required String notificationId,
    @JsonKey(name: 'company_id') String? companyId,
  }) = _NotificationOpenRequest;

  factory NotificationOpenRequest.fromJson(Map<String, dynamic> json) =>
      _$NotificationOpenRequestFromJson(json);
}

@freezed
abstract class NotificationOpenResponse with _$NotificationOpenResponse {
  const factory NotificationOpenResponse({
    @JsonKey(name: 'company_id') String? companyId,
    required String link,
    NotificationItem? item,
  }) = _NotificationOpenResponse;

  factory NotificationOpenResponse.fromJson(Map<String, dynamic> json) =>
      _$NotificationOpenResponseFromJson(json);
}
