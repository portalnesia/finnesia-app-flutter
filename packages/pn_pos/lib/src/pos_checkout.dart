/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/pos.dart';

import 'js_compat.dart';
import 'pos_cart.dart';

/// Turns what is on the till screen into the payload `pos.sales.checkout` takes.
///
/// A function of its own for one reason that is not style: an optional field sent as
/// an empty string is not "absent" to the API. `customer_id: ''` is a customer that does not
/// exist, `table_number: ''` is a table nobody named, and the checkout is refused **after**
/// the cashier has taken the money. That rule is worth a test, and a test needs a function.
///
/// The JavaScript it replaces is `x || undefined`, and the two differ in ways that decide
/// whether a field is sent:
///
/// | Field | Source | Here |
/// | ----- | ------ | ---- |
/// | [shiftId], [customerId] | `x \|\| undefined`: `''` and `null` are absent, `'  '` is sent | `null` or empty is absent, **not trimmed** |
/// | [notes], [tableNumber], [queueNumber] | `x.trim() \|\| undefined` | trimmed, then empty is absent |
/// | [discountAmount] | `x \|\| undefined`: `0` and `NaN` are absent | `0` or NaN is absent |
///
/// `trim()` is not the same in the two languages for one code point: Dart also strips U+0085
/// (next line) and JavaScript does not. A cashier cannot type it and a scanner does not send
/// it, so it is recorded (`provenance.md`) and not handled.
///
/// There is no `client_ref` here, and the source has none either. The server looks a sale up
/// by it before creating one, which is what makes a retry safe, so it is not a field to fill in
/// casually: `CheckoutService` in `apps/pos` chooses it, per basket, and stamps it on the way
/// out.
POSCheckoutDTO buildCheckoutPayload({
  /// Null when the company runs without shifts; the server then owns the shift.
  required String? shiftId,
  required String outletId,
  required String customerId,
  required String notes,
  required String tableNumber,
  required String queueNumber,
  required num discountAmount,

  /// The calendar date the till is running in, already resolved by the caller.
  required String transactionDate,
  required List<CartLine> lines,

  /// Built and validated by `buildPOSTenders`, which owns the tender rules.
  required List<POSTenderDTO> payments,
}) {
  return POSCheckoutDTO(
    shiftId: orAbsent(shiftId),
    outletId: outletId,
    customerId: orAbsent(customerId),
    transactionDate: transactionDate,
    discountAmount:
        discountAmount == 0 || discountAmount.isNaN ? null : discountAmount,
    tableNumber: orAbsent(tableNumber.trim()),
    queueNumber: orAbsent(queueNumber.trim()),
    notes: orAbsent(notes.trim()),
    items: lines.map(_toCheckoutItem).toList(),
    payments: payments,
  );
}

POSCheckoutItemDTO _toCheckoutItem(CartLine line) => POSCheckoutItemDTO(
      productId: line.product.id,
      unitId: line.product.unitId,
      quantity: line.qty,
      price: line.product.sellPrice ?? 0,
      discountPercent: line.discountPercent,
      discountAmount: line.discountAmount,
    );
