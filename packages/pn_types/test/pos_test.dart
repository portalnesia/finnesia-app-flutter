/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:pn_types/src/pos.dart';
import 'package:test/test.dart';

// Every input here is a string the API really sends, run through `jsonDecode` the way
// the transport will. A test that builds the input from `POSTenderMethod.cash` would
// pass on broken code: json_serializable once wrote the enum map from the Dart *name*
// (`cash`) instead of the wire value (`CASH`), and every tender-bearing response threw.
POSTenderDTO parse(String json) =>
    POSTenderDTO.fromJson(jsonDecode(json) as Map<String, dynamic>);

void main() {
  group('POSTenderDTO wire format', () {
    test('reads the uppercase wire value the API sends', () {
      expect(
        parse('{"method":"CASH","amount":1}').method,
        POSTenderMethod.cash,
      );
      expect(
        parse('{"method":"TRANSFER","amount":1}').method,
        POSTenderMethod.transfer,
      );
      expect(parse('{"method":"EDC","amount":1}').method, POSTenderMethod.edc);
      expect(
        parse('{"method":"QRIS","amount":1}').method,
        POSTenderMethod.qris,
      );
      expect(
        parse('{"method":"KOMPLIMEN","amount":1}').method,
        POSTenderMethod.komplimen,
      );
    });

    test('accepts the wire value of every enum case', () {
      for (final m in POSTenderMethod.values) {
        expect(parse('{"method":"${m.wire}","amount":1}').method, m);
      }
    });

    test('writes the wire value back, not the Dart name', () {
      const dto = POSTenderDTO(method: POSTenderMethod.qris, amount: 5);
      expect(dto.toJson()['method'], 'QRIS');
    });

    test('maps account_id and reference', () {
      final dto = parse(
        '{"method":"TRANSFER","amount":1,"account_id":"acc-1","reference":"r-9"}',
      );
      expect(dto.accountId, 'acc-1');
      expect(dto.reference, 'r-9');
    });

    test('leaves account_id and reference null when absent', () {
      final dto = parse('{"method":"CASH","amount":1}');
      expect(dto.accountId, isNull);
      expect(dto.reference, isNull);
    });

    test('rejects a method this enum does not offer', () {
      // GIRO was removed on 2026-09-09; historical rows read a plain string instead
      // (see `POSTenderMethod`). The checkout payload must never carry one.
      expect(
        () => parse('{"method":"GIRO","amount":1}'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects the lowercase Dart name', () {
      expect(
        () => parse('{"method":"cash","amount":1}'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('POSTenderDTO money', () {
    // `jsonDecode` yields int for `10` and double for `10.5`, `1e2` and `10.0`.
    // A field cast `as double` throws on the first; `num` accepts all four.
    test('accepts a whole-number amount (int)', () {
      expect(parse('{"method":"CASH","amount":10}').amount, 10);
    });

    test('accepts a fractional amount (double)', () {
      expect(parse('{"method":"CASH","amount":10.5}').amount, 10.5);
    });

    test('accepts exponent and trailing-zero forms (double)', () {
      expect(parse('{"method":"CASH","amount":1e2}').amount, 100);
      expect(parse('{"method":"CASH","amount":10.0}').amount, 10);
    });

    test('rejects a non-numeric amount', () {
      expect(
        () => parse('{"method":"CASH","amount":"10"}'),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('POSSale', () {
    Map<String, dynamic> sale([String status = 'POSTED']) =>
        jsonDecode('''
{"id":"x1","number":"POS-0001","shift_id":"s1","outlet_id":"o1","cashier_id":"u1",
 "transaction_date":"2026-09-20","subtotal":90000,"discount_amount":0,"tax_amount":0,
 "grand_total":87500.5,"tendered_amount":100000,"change_amount":12499.5,
 "status":"$status","created_at":"2026-09-20T03:00:00Z",
 "payments":[{"id":"p1","method":"GIRO","amount":87500.5,"reference":"r-1"}],
 "cashier":{"id":"u1","name":"Sari"}}''')
            as Map<String, dynamic>;

    test('reads the wire status, not the Dart name', () {
      expect(POSSale.fromJson(sale('POSTED')).status, POSSaleStatus.posted);
      expect(POSSale.fromJson(sale('VOID')).status, POSSaleStatus.voided);
    });

    test('reads a status this build does not know as null', () {
      expect(POSSale.fromJson(sale('ARCHIVED')).status, isNull);
    });

    test('accepts money as int and as double', () {
      final s = POSSale.fromJson(sale());

      expect(s.subtotal, 90000); // int
      expect(s.grandTotal, 87500.5); // double
      expect(s.tenderedAmount, 100000);
      expect(s.changeAmount, 12499.5);
    });

    test('reads the identity a receipt and the list need', () {
      final s = POSSale.fromJson(sale());

      expect(s.id, 'x1');
      expect(s.number, 'POS-0001');
      expect(s.transactionDate, '2026-09-20');
      expect(s.createdAt, '2026-09-20T03:00:00Z');
      expect(s.cashier?.name, 'Sari');
    });

    test('leaves the optional fields null when the API omits them', () {
      final s = POSSale.fromJson(sale());

      expect(s.notes, isNull);
      expect(s.tableNumber, isNull);
      expect(s.queueNumber, isNull);
      expect(s.clientRef, isNull);
      expect(s.paidAt, isNull);
    });

    test('reads payments with the method as a plain string', () {
      // A sale from before 2026-09-09 can carry GIRO, which `POSTenderMethod` no longer
      // has. The receipt prints the string as it is.
      final p = POSSale.fromJson(sale()).payments!.single;

      expect(p.method, 'GIRO');
      expect(p.amount, 87500.5);
      expect(p.reference, 'r-1');
    });

    test('reads a sale with no payments loaded as null, not empty', () {
      // "Not loaded" and "no payments" are different answers: the list endpoint does not
      // preload them, and a receipt must not read that as "paid nothing".
      final json = sale()..remove('payments');

      expect(POSSale.fromJson(json).payments, isNull);
    });

    Map<String, dynamic> withInvoice(String items) =>
        sale()..['invoice'] = jsonDecode('{"items":$items}');

    test('reads the goods sold from the invoice, money as int and double', () {
      final s = POSSale.fromJson(
        withInvoice('''[
          {"id":"i1","product_id":"p1","quantity":2,"price":15000,
           "line_subtotal":30000,"line_total":33300,"description":"",
           "product":{"id":"p1","name":"Kopi Susu"}},
          {"id":"i2","product_id":"p2","quantity":1.5,"price":1000.5,
           "line_subtotal":1500.75,"line_total":1500.75,"description":"Bungkus"}
        ]'''),
      );

      final items = s.invoice!.items;
      expect(items, hasLength(2));
      expect(items[0].id, 'i1');
      expect(items[0].product?.name, 'Kopi Susu');
      expect(items[0].quantity, 2); // int
      expect(items[0].lineTotal, 33300);
      expect(items[1].quantity, 1.5); // double
      expect(items[1].price, 1000.5);
      expect(items[1].description, 'Bungkus');
      expect(items[1].product, isNull);
    });

    test('has no invoice when the endpoint did not load it', () {
      // The list endpoint never does: "not loaded" is not "sold nothing".
      expect(POSSale.fromJson(sale()).invoice, isNull);
    });

    test('reads an invoice whose items came as null as having none', () {
      // A Go nil slice marshals to `null`, and the detail must still open.
      final json = sale()..['invoice'] = {'items': null};

      expect(POSSale.fromJson(json).invoice!.items, isEmpty);
    });
  });

  group('POSCheckoutDTO', () {
    const item = POSCheckoutItemDTO(
      productId: 'p1',
      unitId: 'u1',
      quantity: 2,
      price: 15000,
    );
    const cash = POSTenderDTO(method: POSTenderMethod.cash, amount: 30000);
    const minimal = POSCheckoutDTO(
      outletId: 'o1',
      transactionDate: '2026-09-20',
      items: [item],
      payments: [cash],
    );

    test('writes the wire names the API validates', () {
      final json = minimal.toJson();

      expect(json['outlet_id'], 'o1');
      expect(json['transaction_date'], '2026-09-20');
    });

    test('leaves out every optional field that was not set', () {
      // An optional field sent as null is not "absent" to a server that validates
      // `omitempty,ulid`: the cashier has taken the money by the time it is refused
      // (`pos-checkout.ts`). The keys must simply not be there.
      expect(
        minimal.toJson().keys,
        unorderedEquals(['outlet_id', 'transaction_date', 'items', 'payments']),
      );
    });

    test('sends the optional fields that were set, including client_ref', () {
      final json = minimal
          .copyWith(
            shiftId: 's1',
            customerId: 'c1',
            discountAmount: 1000,
            notes: 'tanpa gula',
            tableNumber: '7',
            queueNumber: 'A12',
            clientRef: '01J8ZV0000000000000000ABCD',
            paidAt: '2026-09-20T03:00:00Z',
          )
          .toJson();

      expect(json['shift_id'], 's1');
      expect(json['customer_id'], 'c1');
      expect(json['discount_amount'], 1000);
      expect(json['notes'], 'tanpa gula');
      expect(json['table_number'], '7');
      expect(json['queue_number'], 'A12');
      expect(json['client_ref'], '01J8ZV0000000000000000ABCD');
      expect(json['paid_at'], '2026-09-20T03:00:00Z');
    });

    test('writes the items as plain maps, so the body is already JSON', () {
      final items = minimal.toJson()['items'];

      expect(items, [
        {'product_id': 'p1', 'unit_id': 'u1', 'quantity': 2, 'price': 15000},
      ]);
    });

    test('writes an item discount only when one was set', () {
      final json = const POSCheckoutItemDTO(
        productId: 'p1',
        unitId: 'u1',
        quantity: 1,
        price: 5000,
        discountPercent: 10,
      ).toJson();

      expect(json['discount_percent'], 10);
      expect(json.containsKey('discount_amount'), isFalse);
    });

    test('writes the payments with the wire method and no empty keys', () {
      // A tender's `account_id` and `reference` are absent for cash. `null` would be
      // sent for both if the tender kept json_serializable's default.
      final payments = minimal.toJson()['payments'];

      expect(payments, [
        {'method': 'CASH', 'amount': 30000},
      ]);
    });
  });

  // The invoice types are only ever *decoded* today — a sale arrives from the server with its
  // invoice attached — so nothing caught that they cannot be encoded. The offline queue does
  // encode them: a queued sale's goods are stored as JSON text so the temporary receipt can be
  // printed without the server (`plan/offline-queue/README.md` §4.2).
  group('SalesInvoice serialization', () {
    const item = SalesInvoiceItem(
      id: 'i1',
      quantity: 2,
      price: 15000,
      lineSubtotal: 30000,
      lineTotal: 30000,
      description: 'Kopi Susu',
      product: NamedRef(id: 'p1', name: 'Kopi Susu'),
    );

    test('toJson writes plain maps, not live objects', () {
      // Without `explicitToJson` the nested `product` stays a `NamedRef` instance, and
      // `jsonEncode` on the *map* — which is what a store that keeps this as text does —
      // fails with "not a subtype of Map<String, dynamic>".
      final json = item.toJson();

      expect(json['product'], {'id': 'p1', 'name': 'Kopi Susu'});
      expect(jsonEncode(json), isA<String>());
    });

    test('an invoice with items survives a full encode and decode', () {
      const invoice = SalesInvoice(items: [item]);

      final text = jsonEncode(invoice.toJson());

      expect(SalesInvoice.fromJson(jsonDecode(text)), invoice);
    });

    test('the field names are the wire names, not the Dart ones', () {
      // The store writes this and reads it back, so a rename of a Dart field would silently
      // change what the database holds.
      expect(
        item.toJson().keys,
        unorderedEquals([
          'id',
          'quantity',
          'price',
          'line_subtotal',
          'line_total',
          'description',
          'product',
        ]),
      );
    });
  });

  group('POSPreferences', () {
    test('reads the settings the till branches on', () {
      final p = POSPreferences.fromJson(
        jsonDecode('''
{"require_shift":false,"show_table_number":true,"show_queue_number":true,
 "queue_number_auto":true,"show_product_sales_summary":true,
 "cash_account_id":"a1","receipt_footer_text":"Terima kasih"}''')
            as Map<String, dynamic>,
      );

      expect(p.requireShift, isFalse);
      expect(p.showTableNumber, isTrue);
      expect(p.showQueueNumber, isTrue);
      expect(p.queueNumberAuto, isTrue);
      expect(p.showProductSalesSummary, isTrue);
      expect(p.cashAccountId, 'a1');
      expect(p.receiptFooterText, 'Terima kasih');
    });

    test('reads the customer the company nominates', () {
      // The server attributes a sale to this customer when the till sends none
      // (`pos_service.go:1509`), and refuses the sale with `pos_customer_required` when there is
      // no default either. The till reads it so the cashier can see who the sale is for.
      final p = POSPreferences.fromJson(
        jsonDecode('{"require_shift":true,"default_customer_id":"c1"}')
            as Map<String, dynamic>,
      );

      expect(p.defaultCustomerId, 'c1');
    });

    test('treats the optional flags as off when the API omits them', () {
      // "Off by default" is written in `POSPreferences` in `pos.ts` for every one of them.
      final p = POSPreferences.fromJson(
        jsonDecode('{"require_shift":true}') as Map<String, dynamic>,
      );

      expect(p.showTableNumber, isFalse);
      expect(p.showQueueNumber, isFalse);
      expect(p.queueNumberAuto, isFalse);
      expect(p.showProductSalesSummary, isFalse);
      expect(p.cashAccountId, isNull);
      expect(p.receiptFooterText, isNull);
      expect(p.defaultCustomerId, isNull);
    });
  });
}
