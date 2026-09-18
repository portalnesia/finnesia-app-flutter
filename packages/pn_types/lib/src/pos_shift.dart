/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

// ignore_for_file: invalid_annotation_target (freezed reads json_serializable's options from the factory constructor, which is the pattern its docs prescribe)

import 'package:freezed_annotation/freezed_annotation.dart';

import 'pos.dart';

part 'pos_shift.freezed.dart';
part 'pos_shift.g.dart';

/// Whether a drawer is still counting sales.
///
/// Ported from `status: 'OPEN' | 'CLOSED'` in `pos.ts`. `valueField: 'wire'` for the same
/// reason as `POSTenderMethod`: without it the generated map uses the Dart name (`open`).
@JsonEnum(valueField: 'wire')
enum ShiftStatus {
  open('OPEN'),
  closed('CLOSED');

  const ShiftStatus(this.wire);

  /// The exact string the API sends and expects.
  final String wire;
}

/// One itemized non-cash tender in the closing report.
///
/// [method] is a plain string, not `POSTenderMethod`: a shift closed before 2026-09-09 can
/// still carry a `GIRO` tender the enum no longer offers, and the report must print it
/// (`NonCashTenderLine` in `pos.ts`). Not the record of the same name in `pn_pos`: that one
/// is the formatter's input, this is the wire shape it is built from.
@freezed
abstract class NonCashTenderLine with _$NonCashTenderLine {
  const factory NonCashTenderLine({
    required String method,
    String? reference,
    required num amount,
    @JsonKey(name: 'sale_number') required String saleNumber,
  }) = _NonCashTenderLine;

  factory NonCashTenderLine.fromJson(Map<String, dynamic> json) =>
      _$NonCashTenderLineFromJson(json);
}

/// One product's row in the shift report's "Rincian Produk".
@freezed
abstract class ProductSalesLine with _$ProductSalesLine {
  const factory ProductSalesLine({
    @JsonKey(name: 'product_id') required String productId,
    @JsonKey(name: 'product_name') required String productName,
    required num quantity,
    @JsonKey(name: 'unit_price') required num unitPrice,
    required num total,
  }) = _ProductSalesLine;

  factory ProductSalesLine.fromJson(Map<String, dynamic> json) =>
      _$ProductSalesLineFromJson(json);
}

/// What the closing screen counts the drawer against, and what the closing report prints.
///
/// Ported from `ShiftSummaryResponse` in `pos.ts`: every field, because the shift screen,
/// the close dialog and the printed report between them read all of them.
@freezed
abstract class ShiftSummaryResponse with _$ShiftSummaryResponse {
  const factory ShiftSummaryResponse({
    @JsonKey(name: 'shift_id') required String shiftId,
    required String number,

    /// An unknown value reads as `null`, the way `ProductType` does: a newer API must not
    /// take the closing screen down. `null` is treated as "not open", so no close action
    /// is offered for a shift whose state this build cannot read.
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    ShiftStatus? status,
    @JsonKey(name: 'outlet_id') required String outletId,
    @JsonKey(name: 'cashier_id') required String cashierId,
    @JsonKey(name: 'cashier_name') String? cashierName,
    @JsonKey(name: 'outlet_name') String? outletName,
    @JsonKey(name: 'opened_at') required String openedAt,
    @JsonKey(name: 'closed_at') String? closedAt,
    String? notes,
    @JsonKey(name: 'total_transactions') required int totalTransactions,
    @JsonKey(name: 'total_sales') required num totalSales,
    @JsonKey(name: 'opening_cash') required num openingCash,
    @JsonKey(name: 'expected_cash') required num expectedCash,
    @JsonKey(name: 'counted_cash') num? countedCash,
    @JsonKey(name: 'cash_variance') num? cashVariance,
    @JsonKey(name: 'cash_in') required num cashIn,
    @JsonKey(name: 'cash_out') required num cashOut,
    @JsonKey(name: 'cash_drop') required num cashDrop,

    // The three collections default to empty because a Go nil slice or map marshals to
    // `null`: a shift with no non-cash tenders must still open the closing screen.
    @JsonKey(name: 'sales_by_method')
    @Default(<String, num>{})
    Map<String, num> salesByMethod,
    @JsonKey(name: 'non_cash_tenders')
    @Default(<NonCashTenderLine>[])
    List<NonCashTenderLine> nonCashTenders,
    @JsonKey(name: 'product_sales')
    @Default(<ProductSalesLine>[])
    List<ProductSalesLine> productSales,
  }) = _ShiftSummaryResponse;

  factory ShiftSummaryResponse.fromJson(Map<String, dynamic> json) =>
      _$ShiftSummaryResponseFromJson(json);
}

/// Money that enters or leaves the drawer without a sale.
///
/// Ported from `type: 'CASH_IN' | 'CASH_OUT' | 'DROP'` in `pos.ts`. [drop] is a mid-shift
/// deposit to the safe, and the till labels it "cashDrop", so the Dart name follows the
/// wire (`DROP`), not the label.
@JsonEnum(valueField: 'wire')
enum CashMovementType {
  cashIn('CASH_IN'),
  cashOut('CASH_OUT'),
  drop('DROP');

  const CashMovementType(this.wire);

  /// The exact string the API sends and expects.
  final String wire;
}

/// One entry in the drawer's movement list.
///
/// Ported from `POSCashMovement` in `pos.ts`, partially: the fields the shift screen and the
/// cash-movement dialog show. `creator` and `product` are preloaded relations.
@freezed
abstract class POSCashMovement with _$POSCashMovement {
  const factory POSCashMovement({
    required String id,
    @JsonKey(name: 'shift_id') required String shiftId,
    required CashMovementType type,
    required num amount,
    required String reason,
    @JsonKey(name: 'created_at') required String createdAt,
    NamedRef? creator,
    NamedRef? product,
  }) = _POSCashMovement;

  factory POSCashMovement.fromJson(Map<String, dynamic> json) =>
      _$POSCashMovementFromJson(json);
}

/// What `POST /pos/shifts/:id/cash-movement` takes.
///
/// Ported from `CashMovementDTO` in `pos.ts`.
///
/// `includeIfNull: false`: TypeScript drops an `undefined` field when it serializes, so an
/// optional id the cashier did not pick is never on the wire. `null` would be sent here
/// otherwise, and the server validates these ids `omitempty,ulid`.
@freezed
abstract class CashMovementDTO with _$CashMovementDTO {
  @JsonSerializable(includeIfNull: false)
  const factory CashMovementDTO({
    required CashMovementType type,
    required num amount,
    required String reason,
    @JsonKey(name: 'account_id') String? accountId,
    @JsonKey(name: 'product_id') String? productId,
  }) = _CashMovementDTO;

  factory CashMovementDTO.fromJson(Map<String, dynamic> json) =>
      _$CashMovementDTOFromJson(json);
}

/// What `POST /pos/shifts/open` takes.
///
/// Ported from `OpenShiftDTO` in `pos.ts`. The tablet never sends a warehouse (pairing locked
/// the outlet, and the server resolves the warehouse from it), but the field is part of the
/// contract and costs nothing to carry.
@freezed
abstract class OpenShiftDTO with _$OpenShiftDTO {
  @JsonSerializable(includeIfNull: false)
  const factory OpenShiftDTO({
    @JsonKey(name: 'outlet_id') required String outletId,
    @JsonKey(name: 'opening_cash') required num openingCash,
    @JsonKey(name: 'warehouse_id') String? warehouseId,
    String? notes,
  }) = _OpenShiftDTO;

  factory OpenShiftDTO.fromJson(Map<String, dynamic> json) =>
      _$OpenShiftDTOFromJson(json);
}

/// What `POST /pos/shifts/:id/close` takes.
///
/// Ported from `CloseShiftDTO` in `pos.ts`. Whether a note is required (an override, or a
/// variance) is `shiftCloseState` in `pn_pos`; this class only carries it.
@freezed
abstract class CloseShiftDTO with _$CloseShiftDTO {
  @JsonSerializable(includeIfNull: false)
  const factory CloseShiftDTO({
    @JsonKey(name: 'counted_cash') required num countedCash,
    String? notes,
  }) = _CloseShiftDTO;

  factory CloseShiftDTO.fromJson(Map<String, dynamic> json) =>
      _$CloseShiftDTOFromJson(json);
}

/// The open drawer, as `GET /pos/shifts/active` answers.
///
/// Ported from `POSShift` in `finnesia-monorepo/packages/types/src/pos.ts`, partially
/// (`project.md` §2.2): the fields the till, the gate and the Menu read. The rest of the
/// record (company/branch/warehouse ids, `closed_by`, the preloaded outlet and warehouse)
/// is not read by any POS screen, and a later screen that needs one adds it here.
///
/// Money is `num`: `jsonDecode` returns `int` for `10` and `double` for `10.5`, and a
/// `double` field throws on the first.
@freezed
abstract class POSShift with _$POSShift {
  const factory POSShift({
    required String id,
    required String number,
    @JsonKey(name: 'cashier_id') required String cashierId,
    @JsonKey(name: 'outlet_id') required String outletId,
    @JsonKey(name: 'opened_at') required String openedAt,
    @JsonKey(name: 'opening_cash') required num openingCash,
    @JsonKey(name: 'total_sales') required num totalSales,
    @JsonKey(name: 'total_transactions') required int totalTransactions,

    /// Whether the drawer is still counting. Only the history list needs it (the active shift is
    /// open by definition), and a value this build does not know reads as `null`, like
    /// [ShiftSummaryResponse.status]: one row from a newer API must not take the whole list down.
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    ShiftStatus? status,
    @JsonKey(name: 'closed_at') String? closedAt,
    NamedRef? cashier,
  }) = _POSShift;

  factory POSShift.fromJson(Map<String, dynamic> json) =>
      _$POSShiftFromJson(json);
}
