/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import '../../pos.dart';
import '../../pos_shift.dart';
import '../endpoint.dart';
import '../http_method.dart';
import '../parsers.dart';

String _nextQueueNumber(Object? data) =>
    (data as Map<String, dynamic>)['next_queue_number'] as String;

/// `finnesia-monorepo/packages/shared/src/api/all-endpoints/pos.ts` — only the 13
/// endpoints the POS uses; device, void and settings-update are the web app's.
///
/// Every entry carries its own request and response types, so a payload of the wrong shape
/// is a compile error at the call site (`api-client/README.md` §1).
abstract final class PosApi {
  static final queueNext = ReadEndpoint<String>(
    '/api/v1/pos/queue/next',
    _nextQueueNumber,
  );

  static final salesCheckout = WriteEndpoint<POSCheckoutDTO, POSSale>(
    HttpMethod.post,
    '/api/v1/pos/sales/checkout',
    parseObject(POSSale.fromJson),
    (dto) => dto.toJson(),
  );

  // Paged: the shift screen scrolls it, so the cursor of the next page comes with the rows.
  static final salesList = PagedEndpoint<POSSale>(
    '/api/v1/pos/sales',
    parseList(POSSale.fromJson),
  );

  // Without `invoice` (the goods sold): the sale detail screen adds that model.
  static final salesGet = ReadEndpointP<ById, POSSale>(
    (p) => '/api/v1/pos/sales/${Uri.encodeComponent(p.id)}',
    parseObject(POSSale.fromJson),
  );

  static final settingsGet = ReadEndpoint<POSPreferences>(
    '/api/v1/pos/settings',
    parseObject(POSPreferences.fromJson),
  );

  // Null when no shift is open: that is an answer, not a malformed response.
  static final shiftsGetActive = ReadEndpoint<POSShift?>(
    '/api/v1/pos/shifts/active',
    parseOrNull(POSShift.fromJson),
  );

  static final shiftsGetSummary = ReadEndpointP<ById, ShiftSummaryResponse>(
    (p) => '/api/v1/pos/shifts/${Uri.encodeComponent(p.id)}',
    parseObject(ShiftSummaryResponse.fromJson),
  );

  // Paged: the history screen scrolls it. Newest first, which is the server's default order.
  static final shiftsList = PagedEndpoint<POSShift>(
    '/api/v1/pos/shifts',
    parseList(POSShift.fromJson),
  );

  static final shiftsOpen = WriteEndpoint<OpenShiftDTO, POSShift>(
    HttpMethod.post,
    '/api/v1/pos/shifts/open',
    parseObject(POSShift.fromJson),
    (dto) => dto.toJson(),
  );

  static final shiftsClose = WriteEndpointP<ById, CloseShiftDTO, POSShift>(
    HttpMethod.post,
    (p) => '/api/v1/pos/shifts/${Uri.encodeComponent(p.id)}/close',
    parseObject(POSShift.fromJson),
    (dto) => dto.toJson(),
  );

  static final shiftsCashMovements = ReadEndpointP<ById, List<POSCashMovement>>(
    (p) => '/api/v1/pos/shifts/${Uri.encodeComponent(p.id)}/cash-movements',
    parseList(POSCashMovement.fromJson),
  );

  // The response carries nothing.
  static final shiftsRecordCashMovement =
      WriteEndpointP<ById, CashMovementDTO, void>(
        HttpMethod.post,
        (p) => '/api/v1/pos/shifts/${Uri.encodeComponent(p.id)}/cash-movement',
        parseNothing,
        (dto) => dto.toJson(),
      );

  static final stock = ReadEndpoint<Map<String, num>>(
    '/api/v1/pos/stock',
    parseStock,
  );
}
