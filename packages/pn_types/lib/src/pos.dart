/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

// ignore_for_file: invalid_annotation_target (freezed reads json_serializable's options from the factory constructor, which is the pattern its docs prescribe)

import 'package:freezed_annotation/freezed_annotation.dart';

part 'pos.freezed.dart';
part 'pos.g.dart';

/// How a payment was taken.
///
/// Ported from `finnesia-monorepo/packages/types/src/pos.ts`:
/// `export type POSTenderMethod = 'CASH' | 'TRANSFER' | 'EDC' | 'QRIS' | 'KOMPLIMEN'`.
///
/// GIRO was removed and EDC/KOMPLIMEN added on 2026-09-09. A shift closed before
/// that date can still carry a GIRO tender, which is why the *report* side reads a
/// plain string instead of this enum — see `POSTenderLine` in `pos.dart`. Anywhere
/// that offers a choice must use this enum, so a removed method cannot be recorded
/// again.
///
/// `valueField: 'wire'` makes json_serializable read and write [wire]. Without it the
/// generated map uses the Dart *name* (`cash`), and every response carrying a tender
/// throws on the real `CASH`.
@JsonEnum(valueField: 'wire')
enum POSTenderMethod {
  cash('CASH'),
  transfer('TRANSFER'),
  edc('EDC'),
  qris('QRIS'),

  /// A free give-away, not money received. Settles into an expense account instead
  /// of cash/bank.
  komplimen('KOMPLIMEN');

  const POSTenderMethod(this.wire);

  /// The exact string the API sends and expects.
  final String wire;

  /// Returns `null` for a wire value this enum does not know, which is the honest
  /// answer for historical rows: a GIRO tender from before 2026-09-09 is real data
  /// that must still render, but it is not a choice the till may offer again.
  static POSTenderMethod? tryParse(String wire) {
    for (final m in POSTenderMethod.values) {
      if (m.wire == wire) return m;
    }
    return null;
  }
}

/// Whether a posted sale still stands or has been reversed.
///
/// Ported from `POSSale['status']` in `packages/types/src/pos.ts`:
/// `export type POSSaleStatus = 'POSTED' | 'VOID'`.
///
/// An enum rather than a plain string even though the receipt makes a single comparison
/// against it. A voided sale that fails to print its "DIBATALKAN" marker looks exactly
/// like a valid one on paper, and a mistyped string literal compares unequal in silence —
/// the compiler catches the typo here instead.
///
/// `valueField: 'wire'`, as on `POSTenderMethod`: without it `POSSale.fromJson` reads the
/// Dart name (`voided`) and throws on the real `VOID`. It was left off until a JSON class
/// used this enum (`api-client/README.md` §4.1); [POSSale] is that class.
@JsonEnum(valueField: 'wire')
enum POSSaleStatus {
  posted('POSTED'),
  voided('VOID');

  const POSSaleStatus(this.wire);

  /// The exact string the API sends and expects.
  final String wire;

  /// Returns `null` for a wire value this enum does not know, matching
  /// [POSTenderMethod.tryParse]. The server only ever sends these two today, so an
  /// unknown value means the API moved ahead of this client.
  static POSSaleStatus? tryParse(String wire) {
    for (final s in POSSaleStatus.values) {
      if (s.wire == wire) return s;
    }
    return null;
  }
}

/// A related person or record the API preloads as `{ id, name? }`: a shift's or sale's
/// cashier, a cash movement's creator.
///
/// Ported from the inline `cashier?: { id: string; name?: string }` in
/// `packages/types/src/pos.ts`. `name` is nullable because the source declares it optional:
/// a cashier whose profile carries no name is real (`menu-page.tsx` falls back to the email).
@freezed
abstract class NamedRef with _$NamedRef {
  const factory NamedRef({required String id, String? name}) = _NamedRef;

  factory NamedRef.fromJson(Map<String, dynamic> json) =>
      _$NamedRefFromJson(json);
}

/// One payment on a recorded sale.
///
/// Ported from `POSSalePayment` in `pos.ts`. [method] is a plain string, not
/// [POSTenderMethod]: the source types it as the enum, but a sale from before 2026-09-09
/// can carry `GIRO`, and the receipt must print it as it is (`NonCashTenderLine` in the same
/// file says so). Anywhere that offers a choice uses the enum.
@freezed
abstract class POSSalePayment with _$POSSalePayment {
  const factory POSSalePayment({
    required String id,
    required String method,
    required num amount,
    String? reference,
  }) = _POSSalePayment;

  factory POSSalePayment.fromJson(Map<String, dynamic> json) =>
      _$POSSalePaymentFromJson(json);
}

/// One line of the goods a sale sold.
///
/// Ported from `SalesInvoiceItem` in `packages/types/src/sales.ts`, partially: what the receipt
/// and the sale detail read. [product] is a [NamedRef] and not the whole `Product`: only its name
/// is read, and a full `Product.fromJson` would fail the sale over a catalogue field it never
/// shows.
///
/// `explicitToJson`: without it [product] stays a `NamedRef` instance rather than a map, and
/// `jsonEncode` on the result fails with "not a subtype of `Map<String, dynamic>`". Nothing in
/// the app encoded this type until the offline queue did — a sale only ever arrives from the
/// server, so it was decoded and never written (`plan/offline-queue/README.md` §4.2).
@freezed
abstract class SalesInvoiceItem with _$SalesInvoiceItem {
  @JsonSerializable(explicitToJson: true)
  const factory SalesInvoiceItem({
    required String id,
    required num quantity,
    required num price,
    @JsonKey(name: 'line_subtotal') required num lineSubtotal,
    @JsonKey(name: 'line_total') required num lineTotal,
    String? description,
    NamedRef? product,
  }) = _SalesInvoiceItem;

  factory SalesInvoiceItem.fromJson(Map<String, dynamic> json) =>
      _$SalesInvoiceItemFromJson(json);
}

/// The invoice a sale posted, which is where its goods live: `pos_sales` has no lines of its own.
///
/// Ported from `SalesInvoice`, keeping only [items].
///
/// `explicitToJson` for the same reason as [SalesInvoiceItem]: without it [items] stays a list of
/// live objects, and the map is not yet JSON.
@freezed
abstract class SalesInvoice with _$SalesInvoice {
  @JsonSerializable(explicitToJson: true)
  const factory SalesInvoice({
    // A Go nil slice marshals to `null`, and a sale with none must still open.
    @Default(<SalesInvoiceItem>[]) List<SalesInvoiceItem> items,
  }) = _SalesInvoice;

  factory SalesInvoice.fromJson(Map<String, dynamic> json) =>
      _$SalesInvoiceFromJson(json);
}

/// A sale the server recorded.
///
/// Ported from `POSSale` in `pos.ts`, partially: what the change screen, the shift's
/// transaction list, the sale detail and a receipt read. Not carried yet: `outlet`, and the
/// company/branch/warehouse/invoice ids.
///
/// [payments] is `null` when the endpoint did not preload them, which is not the same
/// answer as "no payments". So is [invoice]: only the single-sale endpoint loads it, and a
/// sale from the list has none to show.
@freezed
abstract class POSSale with _$POSSale {
  const factory POSSale({
    required String id,
    required String number,
    @JsonKey(name: 'shift_id') required String shiftId,
    @JsonKey(name: 'outlet_id') required String outletId,
    @JsonKey(name: 'cashier_id') required String cashierId,
    @JsonKey(name: 'transaction_date') required String transactionDate,
    required num subtotal,
    @JsonKey(name: 'discount_amount') required num discountAmount,
    @JsonKey(name: 'tax_amount') required num taxAmount,
    @JsonKey(name: 'grand_total') required num grandTotal,
    @JsonKey(name: 'tendered_amount') required num tenderedAmount,
    @JsonKey(name: 'change_amount') required num changeAmount,

    /// A status this build does not know reads as `null`, like `ProductType`: a newer API
    /// must not take the transaction list down over one row.
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    POSSaleStatus? status,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'client_ref') String? clientRef,
    @JsonKey(name: 'paid_at') String? paidAt,
    String? notes,
    @JsonKey(name: 'table_number') String? tableNumber,
    @JsonKey(name: 'queue_number') String? queueNumber,
    List<POSSalePayment>? payments,
    SalesInvoice? invoice,
    NamedRef? cashier,
  }) = _POSSale;

  factory POSSale.fromJson(Map<String, dynamic> json) =>
      _$POSSaleFromJson(json);
}

/// One line of the checkout payload.
///
/// Ported from `POSCheckoutItemDTO` in `pos.ts`, without `tax_id` and `description`: the till
/// sets neither. `includeIfNull: false`, because TypeScript drops an `undefined` field when
/// it serializes and the server validates the optional ones (see [POSCheckoutDTO]).
@freezed
abstract class POSCheckoutItemDTO with _$POSCheckoutItemDTO {
  @JsonSerializable(includeIfNull: false)
  const factory POSCheckoutItemDTO({
    @JsonKey(name: 'product_id') required String productId,
    @JsonKey(name: 'unit_id') required String unitId,
    required num quantity,
    required num price,
    @JsonKey(name: 'discount_percent') num? discountPercent,
    @JsonKey(name: 'discount_amount') num? discountAmount,
  }) = _POSCheckoutItemDTO;

  factory POSCheckoutItemDTO.fromJson(Map<String, dynamic> json) =>
      _$POSCheckoutItemDTOFromJson(json);
}

/// What `POST /pos/sales/checkout` takes.
///
/// Ported from `POSCheckoutDTO` in `pos.ts`. An optional field the cashier did not set must
/// not be on the wire at all: `customer_id: ''` is a customer that does not exist, and the
/// checkout is refused after the money has been taken (`pos-checkout.ts` says so). Building
/// the DTO from the till's state, and turning an empty string into an absent field, is
/// `buildCheckoutPayload` in `pn_pos`; this class only refuses to write a `null`.
///
/// [clientRef] is what makes a retried checkout idempotent: the server looks a sale up by it
/// before creating one (`pos_service.go`, "Idempotency by client_ref").
@freezed
abstract class POSCheckoutDTO with _$POSCheckoutDTO {
  // `explicitToJson`: without it `items` and `payments` stay lists of objects, and the
  // map a caller gets is not yet JSON.
  @JsonSerializable(includeIfNull: false, explicitToJson: true)
  const factory POSCheckoutDTO({
    @JsonKey(name: 'outlet_id') required String outletId,
    @JsonKey(name: 'transaction_date') required String transactionDate,
    required List<POSCheckoutItemDTO> items,
    required List<POSTenderDTO> payments,

    /// Omitted when the company runs without shifts: the server reuses the caller's open
    /// shift at the outlet, or opens one.
    @JsonKey(name: 'shift_id') String? shiftId,
    @JsonKey(name: 'customer_id') String? customerId,
    @JsonKey(name: 'discount_amount') num? discountAmount,
    String? notes,
    @JsonKey(name: 'table_number') String? tableNumber,
    @JsonKey(name: 'queue_number') String? queueNumber,
    @JsonKey(name: 'client_ref') String? clientRef,
    @JsonKey(name: 'paid_at') String? paidAt,
  }) = _POSCheckoutDTO;

  factory POSCheckoutDTO.fromJson(Map<String, dynamic> json) =>
      _$POSCheckoutDTOFromJson(json);
}

/// The company's POS settings the till branches on.
///
/// Ported from `POSPreferences` in `pos.ts`, partially: the flags and text the till, the
/// cash-movement dialog and the print buttons read. Every optional flag is "off by default"
/// in the source, which is what `@Default(false)` says. [requireShift] is required: it is
/// the one flag whose absence would change what the till does.
@freezed
abstract class POSPreferences with _$POSPreferences {
  const factory POSPreferences({
    @JsonKey(name: 'require_shift') required bool requireShift,
    @JsonKey(name: 'show_table_number') @Default(false) bool showTableNumber,
    @JsonKey(name: 'show_queue_number') @Default(false) bool showQueueNumber,
    @JsonKey(name: 'queue_number_auto') @Default(false) bool queueNumberAuto,
    @JsonKey(name: 'show_product_sales_summary')
    @Default(false)
    bool showProductSalesSummary,

    /// Set once the company has a drawer account: a cash movement then has to name the
    /// other side of its journal (`cash-movement-dialog.tsx`).
    @JsonKey(name: 'cash_account_id') String? cashAccountId,

    /// The walk-in customer the company nominates, or null when it has none.
    ///
    /// The server owns what the sale is attributed to: when the till sends no customer it falls
    /// back to this, and refuses the sale with `pos_customer_required` when this is empty too
    /// (`pos_service.go:1506-1513`). The till reads it so the cashier can **see** who the sale
    /// is for, rather than being shown "no customer" for a sale that has one.
    @JsonKey(name: 'default_customer_id') String? defaultCustomerId,
    @JsonKey(name: 'receipt_footer_text') String? receiptFooterText,
  }) = _POSPreferences;

  factory POSPreferences.fromJson(Map<String, dynamic> json) =>
      _$POSPreferencesFromJson(json);
}

/// One payment row as the checkout payload carries it.
///
/// Ported from `POSTenderDTO` in `packages/types/src/pos.ts`. `accountId` is
/// deliberately absent from the construction path in `pn_pos`: the account comes from
/// POS preferences, not from the cashier.
@freezed
abstract class POSTenderDTO with _$POSTenderDTO {
  // `includeIfNull: false`: cash carries neither `account_id` nor `reference`, and a `null`
  // for either is not "absent" to the server's `omitempty,ulid` validation.
  @JsonSerializable(includeIfNull: false)
  const factory POSTenderDTO({
    required POSTenderMethod method,
    required num amount,

    /// Required for every non-cash method: the money landed in a specific account.
    @JsonKey(name: 'account_id') String? accountId,
    String? reference,
  }) = _POSTenderDTO;

  factory POSTenderDTO.fromJson(Map<String, dynamic> json) =>
      _$POSTenderDTOFromJson(json);
}
