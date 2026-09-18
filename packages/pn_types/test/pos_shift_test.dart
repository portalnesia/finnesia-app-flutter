/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:pn_types/src/pos_shift.dart';
import 'package:test/test.dart';

// Every input is a string the API really sends, run through `jsonDecode` the way the
// transport will. `jsonDecode` returns `int` for `10` and `double` for `10.5`, and a field
// declared `double` throws on the first (`api-client/README.md` §4.2), so the money tests
// below use both.
Map<String, dynamic> obj(String json) =>
    jsonDecode(json) as Map<String, dynamic>;

void main() {
  group('POSShift', () {
    const wire = '''
{"id":"s1","number":"SHF-001","cashier_id":"u1","outlet_id":"o1",
 "opened_at":"2026-09-20T01:00:00Z","opening_cash":100000,
 "total_sales":250000.5,"total_transactions":7,
 "cashier":{"id":"u1","name":"Sari"}}''';

    test('reads the fields the till and the gate need', () {
      final shift = POSShift.fromJson(obj(wire));

      expect(shift.id, 's1');
      expect(shift.number, 'SHF-001');
      expect(shift.cashierId, 'u1');
      expect(shift.outletId, 'o1');
      expect(shift.openedAt, '2026-09-20T01:00:00Z');
      expect(shift.totalTransactions, 7);
      expect(shift.cashier?.name, 'Sari');
    });

    test('says whether the shift is open, and when it closed', () {
      final open = POSShift.fromJson(
        obj(wire.replaceFirst('{"id"', '{"status":"OPEN","id"')),
      );
      final closed = POSShift.fromJson(
        obj(
          wire.replaceFirst(
            '{"id"',
            '{"status":"CLOSED","closed_at":"2026-09-20T09:00:00Z","id"',
          ),
        ),
      );

      expect(open.status, ShiftStatus.open);
      expect(open.closedAt, isNull);
      expect(closed.status, ShiftStatus.closed);
      expect(closed.closedAt, '2026-09-20T09:00:00Z');
    });

    test('a status this build does not know reads as null, not a failure', () {
      final shift = POSShift.fromJson(
        obj(wire.replaceFirst('{"id"', '{"status":"ARCHIVED","id"')),
      );

      // One row from a newer API must not take the whole history down.
      expect(shift.status, isNull);
    });

    test('accepts money as int and as double', () {
      final shift = POSShift.fromJson(obj(wire));

      expect(shift.openingCash, 100000); // int on the wire
      expect(shift.totalSales, 250000.5); // double on the wire
    });
  });

  group('POSCashMovement', () {
    String wire(String type) =>
        '''
{"id":"m1","shift_id":"s1","type":"$type","amount":15000.25,"reason":"Beli es batu",
 "created_at":"2026-09-20T03:00:00Z","product_id":"p1",
 "creator":{"id":"u1","name":"Sari"},"product":{"id":"p1","name":"Es batu"}}''';

    test('reads the wire type, not the Dart name', () {
      expect(
        POSCashMovement.fromJson(obj(wire('CASH_IN'))).type,
        CashMovementType.cashIn,
      );
      expect(
        POSCashMovement.fromJson(obj(wire('CASH_OUT'))).type,
        CashMovementType.cashOut,
      );
      expect(
        POSCashMovement.fromJson(obj(wire('DROP'))).type,
        CashMovementType.drop,
      );
    });

    test('reads the amount, the reason and the preloaded relations', () {
      final m = POSCashMovement.fromJson(obj(wire('CASH_OUT')));

      expect(m.id, 'm1');
      expect(m.amount, 15000.25);
      expect(m.reason, 'Beli es batu');
      expect(m.createdAt, '2026-09-20T03:00:00Z');
      expect(m.creator?.name, 'Sari');
      expect(m.product?.name, 'Es batu');
    });

    test('accepts an integer amount', () {
      final m = POSCashMovement.fromJson(
        obj(wire('CASH_IN').replaceFirst('15000.25', '15000')),
      );

      expect(m.amount, 15000);
    });
  });

  group('CashMovementDTO', () {
    test('writes the wire type', () {
      const dto = CashMovementDTO(
        type: CashMovementType.drop,
        amount: 5000,
        reason: 'Setor ke brankas',
      );

      expect(dto.toJson()['type'], 'DROP');
    });

    test('leaves out the optional ids that were not chosen', () {
      // `account_id` and `product_id` are validated `omitempty,ulid` server-side. Absent is
      // fine; a key the cashier never set must not be sent at all.
      const dto = CashMovementDTO(
        type: CashMovementType.cashOut,
        amount: 5000,
        reason: 'Parkir',
      );

      expect(dto.toJson().keys, unorderedEquals(['type', 'amount', 'reason']));
    });

    test('sends the account and product when they were chosen', () {
      const dto = CashMovementDTO(
        type: CashMovementType.cashOut,
        amount: 5000,
        reason: 'Parkir',
        accountId: 'a1',
        productId: 'p1',
      );

      expect(dto.toJson()['account_id'], 'a1');
      expect(dto.toJson()['product_id'], 'p1');
    });
  });

  group('OpenShiftDTO and CloseShiftDTO', () {
    test(
      'open writes only the outlet and the float when nothing else is set',
      () {
        const dto = OpenShiftDTO(outletId: 'o1', openingCash: 100000);

        expect(dto.toJson(), {'outlet_id': 'o1', 'opening_cash': 100000});
      },
    );

    test('open sends the warehouse and the note when they were set', () {
      final json = const OpenShiftDTO(
        outletId: 'o1',
        openingCash: 0,
        warehouseId: 'w1',
        notes: 'shift pagi',
      ).toJson();

      expect(json['warehouse_id'], 'w1');
      expect(json['notes'], 'shift pagi');
      expect(
        json['opening_cash'],
        0,
      ); // zero is a real float, not an absent one
    });

    test('close writes the count, and the note only when there is one', () {
      expect(const CloseShiftDTO(countedCash: 315000).toJson(), {
        'counted_cash': 315000,
      });
      expect(
        const CloseShiftDTO(
          countedCash: 315000,
          notes: 'selisih parkir',
        ).toJson(),
        {'counted_cash': 315000, 'notes': 'selisih parkir'},
      );
    });
  });

  group('ShiftSummaryResponse', () {
    const wire = '''
{"shift_id":"s1","number":"SHF-001","status":"OPEN","outlet_id":"o1","cashier_id":"u1",
 "cashier_name":"Sari","outlet_name":"Kasir Utama","opened_at":"2026-09-20T01:00:00Z",
 "total_transactions":7,"total_sales":250000.5,"opening_cash":100000,
 "expected_cash":300000,"cash_in":0,"cash_out":15000.25,"cash_drop":0,
 "sales_by_method":{"CASH":150000,"TRANSFER":100000.5},
 "non_cash_tenders":[
   {"method":"GIRO","reference":"r-1","amount":100000.5,"sale_number":"POS-9",
    "created_at":"2026-09-20T02:00:00Z"}],
 "product_sales":[
   {"product_id":"p1","product_name":"Kopi","quantity":3,"unit_price":15000,"total":45000}]}''';

    test('reads the identity and the counted figures', () {
      final s = ShiftSummaryResponse.fromJson(obj(wire));

      expect(s.shiftId, 's1');
      expect(s.number, 'SHF-001');
      expect(s.cashierId, 'u1');
      expect(s.cashierName, 'Sari');
      expect(s.outletName, 'Kasir Utama');
      expect(s.totalTransactions, 7);
      expect(s.expectedCash, 300000);
      expect(s.cashOut, 15000.25);
    });

    test('leaves the closing fields null while the shift is open', () {
      final s = ShiftSummaryResponse.fromJson(obj(wire));

      expect(s.closedAt, isNull);
      expect(s.countedCash, isNull);
      expect(s.cashVariance, isNull);
    });

    test('reads the wire status, not the Dart name', () {
      ShiftSummaryResponse withStatus(String status) =>
          ShiftSummaryResponse.fromJson(
            obj(wire.replaceFirst('"status":"OPEN"', '"status":"$status"')),
          );

      expect(withStatus('OPEN').status, ShiftStatus.open);
      expect(withStatus('CLOSED').status, ShiftStatus.closed);
    });

    test('accepts money as int and as double in every map value', () {
      final s = ShiftSummaryResponse.fromJson(obj(wire));

      expect(s.salesByMethod['CASH'], 150000); // int
      expect(s.salesByMethod['TRANSFER'], 100000.5); // double
    });

    test('keeps a tender method the enum no longer offers as a plain string', () {
      // A shift closed before 2026-09-09 can carry GIRO, and the closing report must
      // still print it (`NonCashTenderLine` in `pos.ts`).
      final line = ShiftSummaryResponse.fromJson(
        obj(wire),
      ).nonCashTenders.single;

      expect(line.method, 'GIRO');
      expect(line.reference, 'r-1');
      expect(line.amount, 100000.5);
      expect(line.saleNumber, 'POS-9');
    });

    test('reads null or missing collections as empty, not as an error', () {
      // A Go nil slice marshals to `null`, not `[]`. A summary with no non-cash tenders
      // must still open the closing screen.
      final nulls = ShiftSummaryResponse.fromJson(
        obj(
          wire
              .replaceFirst(
                RegExp(r'"non_cash_tenders":\[.*?\}\]', dotAll: true),
                '"non_cash_tenders":null',
              )
              .replaceFirst(
                RegExp(r'"product_sales":\[.*?\}\]', dotAll: true),
                '"product_sales":null',
              )
              .replaceFirst(
                RegExp(r'"sales_by_method":\{.*?\}'),
                '"sales_by_method":null',
              ),
        ),
      );

      expect(nulls.nonCashTenders, isEmpty);
      expect(nulls.productSales, isEmpty);
      expect(nulls.salesByMethod, isEmpty);
    });

    test('reads a status this build does not know as null', () {
      final s = ShiftSummaryResponse.fromJson(
        obj(wire.replaceFirst('"status":"OPEN"', '"status":"REOPENED"')),
      );

      expect(s.status, isNull);
    });

    test('reads the per-product breakdown', () {
      final line = ShiftSummaryResponse.fromJson(obj(wire)).productSales.single;

      expect(line.productName, 'Kopi');
      expect(line.quantity, 3);
      expect(line.unitPrice, 15000);
      expect(line.total, 45000);
    });
  });
}
