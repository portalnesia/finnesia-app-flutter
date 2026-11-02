/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */
import 'dart:convert';

import 'package:pn_types/src/native/push_messaging_port.dart';

/// Reads the backend's toast `launch` JSON without trusting its link or content.
///
/// Windows only needs the identifiers to fetch the notification from the authenticated API.
/// The server remains the source of truth for the notification and its validated link.
PushMessage? parseWindowsPushLaunchArguments(String? arguments) {
  final source = arguments?.trim() ?? '';
  if (source.isEmpty) return null;

  try {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) return null;

    final notificationId = decoded['notification_id'];
    if (notificationId is! String || notificationId.trim().isEmpty) {
      return null;
    }

    final data = <String, String>{'notification_id': notificationId.trim()};
    final companyId = decoded['company_id'];
    if (companyId is String && companyId.trim().isNotEmpty) {
      data['company_id'] = companyId.trim();
    }
    return PushMessage(data: data);
  } on FormatException {
    return null;
  }
}
