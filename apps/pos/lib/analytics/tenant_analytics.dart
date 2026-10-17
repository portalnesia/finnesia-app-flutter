/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/native/analytics_port.dart';
import 'package:pn_types/src/pos.dart';

/// A customer's till sale, never Finnesia's subscription `purchase` revenue.
///
/// Mirrors `apps/web/src/config/analytics.ts` at b5c9325 (`fix: analytics`).
/// Both send paths use the server's figures and invoice identity. No names,
/// customer details, notes, tender references or product names leave the till.
/// Call only after server confirmation and consuming the queue row, so a storage
/// failure followed by replay does not report the same sale a second time.
Future<void> logTenantSaleCompleted(
  AnalyticsPort analytics, {
  required POSSale sale,
  required POSCheckoutDTO payload,
  required bool offline,
}) async {
  try {
    final invoiceId = sale.invoiceId;
    await analytics.logEvent(
      'tenant_sale_completed',
      parameters: {
        'transaction_id': invoiceId == null || invoiceId.isEmpty
            ? sale.id
            : invoiceId,
        'value': sale.grandTotal,
        'currency': 'IDR',
        'item_count': payload.items.length,
        'payment_methods': payload.payments.map((p) => p.method.wire).join(','),
        // Firebase's native SDK only accepts String/num, unlike web GA4.
        'offline': offline ? 1 : 0,
      },
    );
  } catch (_) {
    // Analytics is best-effort, even if an adapter violates the port contract.
    // The sale is already committed and removed; reporting must never turn it
    // into an error or trigger another checkout.
  }
}
