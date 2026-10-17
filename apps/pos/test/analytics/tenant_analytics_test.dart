/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/native/analytics_fake.dart';
import 'package:pn_types/src/pos.dart';
import 'package:pos/analytics/tenant_analytics.dart';

const sale = POSSale(
  id: 'sale_1',
  invoiceId: 'invoice_1',
  number: 'POS-0001',
  shiftId: 'shift_1',
  outletId: 'outlet_1',
  cashierId: 'cashier_1',
  transactionDate: '2026-10-18',
  subtotal: 100000,
  discountAmount: 1000,
  taxAmount: 0,
  grandTotal: 99000,
  tenderedAmount: 100000,
  changeAmount: 1000,
  createdAt: '2026-10-18T01:00:00Z',
  notes: 'Private customer notes',
);
const payload = POSCheckoutDTO(
  outletId: 'outlet_1',
  transactionDate: '2026-10-18',
  customerId: 'customer_1',
  notes: 'Private cashier notes',
  items: [
    POSCheckoutItemDTO(
      productId: 'p1',
      unitId: 'u1',
      quantity: 2,
      price: 50000,
    ),
  ],
  payments: [
    POSTenderDTO(method: POSTenderMethod.cash, amount: 50000),
    POSTenderDTO(
      method: POSTenderMethod.qris,
      amount: 49000,
      reference: 'private-reference',
    ),
  ],
);

class BrokenAnalytics extends FakeAnalytics {
  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    throw StateError('Unavailable analytics');
  }
}

void main() {
  test(
    'uses the shared web schema with server amounts and no private fields',
    () async {
      final analytics = FakeAnalytics();
      await logTenantSaleCompleted(
        analytics,
        sale: sale,
        payload: payload,
        offline: false,
      );
      expect(analytics.logged.single.$1, 'tenant_sale_completed');
      expect(analytics.logged.single.$2, {
        'transaction_id': 'invoice_1',
        'value': 99000,
        'currency': 'IDR',
        'item_count': 1,
        'payment_methods': 'CASH,QRIS',
        'offline': 0,
      });
    },
  );

  test(
    'uses a stable sale id when an older response omits the invoice id',
    () async {
      for (final invoiceId in [null, '']) {
        final analytics = FakeAnalytics();
        await logTenantSaleCompleted(
          analytics,
          sale: sale.copyWith(invoiceId: invoiceId),
          payload: payload,
          offline: true,
        );
        expect(analytics.logged.single.$2?['transaction_id'], 'sale_1');
        expect(analytics.logged.single.$2?['offline'], 1);
      }
    },
  );

  test(
    'does not turn an analytics adapter failure into a failed sale',
    () async {
      await expectLater(
        logTenantSaleCompleted(
          BrokenAnalytics(),
          sale: sale,
          payload: payload,
          offline: false,
        ),
        completes,
      );
    },
  );
}
