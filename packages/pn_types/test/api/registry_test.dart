/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/api/endpoint.dart';
import 'package:pn_types/src/api/endpoints/auth.dart';
import 'package:pn_types/src/api/endpoints/features.dart';
import 'package:pn_types/src/api/endpoints/master.dart';
import 'package:pn_types/src/api/endpoints/pos.dart';
import 'package:pn_types/src/api/endpoints/products.dart';
import 'package:pn_types/src/api/endpoints/team.dart';
import 'package:pn_types/src/api/endpoints/tenant.dart';
import 'package:pn_types/src/api/http_method.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/api/transport_fake.dart';
import 'package:pn_types/src/master_data.dart';
import 'package:pn_types/src/pos.dart';
import 'package:pn_types/src/pos_shift.dart';
import 'package:test/test.dart';

// The table is the contract: the 23 endpoints the POS uses, with the method and path the
// monorepo's own registry (`packages/shared/src/api/all-endpoints/`) declares. Each
// `path` below was copied from that registry's output, and `plan/api-client/findings.md`
// records the comparison of this table against it. `:id` marks a path parameter.

// The parameter used when a path has one. Not a real id: it lets the test tell a built path
// from a template and check that the parameter was actually substituted.
const id = 'ID';

typedef Row = ({
  String key,
  HttpMethod method,
  String path,
  HttpMethod actualMethod,
  String actualPath,
});

Row read(String key, String path, ReadEndpoint<Object?> e) => (
  key: key,
  method: HttpMethod.get,
  path: path,
  actualMethod: e.method,
  actualPath: e.path,
);

Row paged(String key, String path, PagedEndpoint<Object?> e) => (
  key: key,
  method: HttpMethod.get,
  path: path,
  actualMethod: e.method,
  actualPath: e.path,
);

Row readP(String key, String path, ReadEndpointP<ById, Object?> e) => (
  key: key,
  method: HttpMethod.get,
  path: path.replaceAll(':id', id),
  actualMethod: e.method,
  actualPath: e.buildPath((id: id)),
);

Row write(
  String key,
  HttpMethod method,
  String path,
  WriteEndpoint<Object?, Object?> e,
) => (
  key: key,
  method: method,
  path: path,
  actualMethod: e.method,
  actualPath: e.path,
);

Row writeP(
  String key,
  HttpMethod method,
  String path,
  WriteEndpointP<ById, Object?, Object?> e,
) => (
  key: key,
  method: method,
  path: path.replaceAll(':id', id),
  actualMethod: e.method,
  actualPath: e.buildPath((id: id)),
);

TransportResponse answer(String body) => TransportResponse(
  status: 200,
  headers: {'content-type': 'application/json'},
  body: body,
);

({ApiClient client, FakeApiTransport transport}) makeClient(String body) {
  final transport = FakeApiTransport()..respond(answer(body));
  return (
    client: ApiClient(transport: transport, language: () => 'id'),
    transport: transport,
  );
}

// A recorded sale as the API sends it, for the tests that read one back.
const saleJson = '''
{"id":"x1","number":"POS-0001","shift_id":"s1","outlet_id":"o1","cashier_id":"u1",
 "transaction_date":"2026-09-20","subtotal":15000,"discount_amount":0,"tax_amount":0,
 "grand_total":15000,"tendered_amount":20000,"change_amount":5000,
 "status":"POSTED","created_at":"2026-09-20T03:00:00Z"}''';

// An open drawer as the API sends it.
const shiftJson = '''
{"id":"s1","number":"SHF-001","cashier_id":"u1","outlet_id":"o1",
 "opened_at":"2026-09-20T01:00:00Z","opening_cash":100000,"total_sales":15000,
 "total_transactions":1}''';

void main() {
  final rows = <Row>[
    read('auth.me', '/api/auth/me', AuthApi.me),
    read('features.company', '/api/v1/company-features', FeaturesApi.company),
    read(
      'master.categories.list',
      '/api/v1/master/categories',
      MasterApi.categoriesList,
    ),
    read('master.coa.list', '/api/v1/master/coa', MasterApi.coaList),
    read(
      'master.contacts.list',
      '/api/v1/master/contacts',
      MasterApi.contactsList,
    ),
    write(
      'master.contacts.create',
      HttpMethod.post,
      '/api/v1/master/contacts',
      MasterApi.contactsCreate,
    ),
    readP(
      'master.contacts.get',
      '/api/v1/master/contacts/:id',
      MasterApi.contactsGet,
    ),
    read('pos.queue.next', '/api/v1/pos/queue/next', PosApi.queueNext),
    write(
      'pos.sales.checkout',
      HttpMethod.post,
      '/api/v1/pos/sales/checkout',
      PosApi.salesCheckout,
    ),
    paged('pos.sales.list', '/api/v1/pos/sales', PosApi.salesList),
    readP('pos.sales.get', '/api/v1/pos/sales/:id', PosApi.salesGet),
    read('pos.settings.get', '/api/v1/pos/settings', PosApi.settingsGet),
    read(
      'pos.shifts.getActive',
      '/api/v1/pos/shifts/active',
      PosApi.shiftsGetActive,
    ),
    readP(
      'pos.shifts.getSummary',
      '/api/v1/pos/shifts/:id',
      PosApi.shiftsGetSummary,
    ),
    paged('pos.shifts.list', '/api/v1/pos/shifts', PosApi.shiftsList),
    write(
      'pos.shifts.open',
      HttpMethod.post,
      '/api/v1/pos/shifts/open',
      PosApi.shiftsOpen,
    ),
    writeP(
      'pos.shifts.close',
      HttpMethod.post,
      '/api/v1/pos/shifts/:id/close',
      PosApi.shiftsClose,
    ),
    readP(
      'pos.shifts.cashMovements',
      '/api/v1/pos/shifts/:id/cash-movements',
      PosApi.shiftsCashMovements,
    ),
    writeP(
      'pos.shifts.recordCashMovement',
      HttpMethod.post,
      '/api/v1/pos/shifts/:id/cash-movement',
      PosApi.shiftsRecordCashMovement,
    ),
    read('pos.stock', '/api/v1/pos/stock', PosApi.stock),
    paged('products.list', '/api/v1/products', ProductsApi.list),
    readP('tenant.outlets.get', '/api/v1/outlets/:id', TenantApi.outletsGet),
    read(
      'team.permissions.my',
      '/api/v1/team/my-permissions',
      TeamApi.permissionsMy,
    ),
  ];

  group('the registry table', () {
    test('has the 23 endpoints the POS uses', () {
      expect(rows, hasLength(23));
    });

    test(
      'declares every endpoint with the method and path of the source registry',
      () {
        for (final r in rows) {
          expect(r.actualMethod, r.method, reason: r.key);
          expect(r.actualPath, r.path, reason: r.key);
        }
      },
    );

    // Method AND path: `master.contacts` is a GET and a POST on one path.
    test('has no two endpoints on the same method and path', () {
      final seen = <String>{};
      for (final r in rows) {
        expect(
          seen.add('${r.actualMethod.wire} ${r.actualPath}'),
          isTrue,
          reason: r.key,
        );
      }
    });

    test('has no duplicate keys', () {
      expect(rows.map((r) => r.key).toSet(), hasLength(rows.length));
    });

    // A path is a path on the tenant host, never an absolute URL: the host comes from
    // pairing, and a template that leaked through would be a request to `/things/:id`.
    test('builds only relative API paths, with no placeholder left', () {
      for (final r in rows) {
        expect(r.actualPath, startsWith('/api/'), reason: r.key);
        expect(r.actualPath, isNot(contains(':')), reason: r.key);
        expect(r.actualPath, isNot(contains('?')), reason: r.key);
      }
    });
  });

  group('a path parameter', () {
    // The id is not trusted: it becomes one segment, whatever it contains.
    const nasty = 'a b/c?d#e';
    const encoded = 'a%20b%2Fc%3Fd%23e';

    test('is encoded into a single path segment', () {
      final paths = [
        PosApi.salesGet.buildPath((id: nasty)),
        PosApi.shiftsGetSummary.buildPath((id: nasty)),
        PosApi.shiftsClose.buildPath((id: nasty)),
        PosApi.shiftsCashMovements.buildPath((id: nasty)),
        PosApi.shiftsRecordCashMovement.buildPath((id: nasty)),
        TenantApi.outletsGet.buildPath((id: nasty)),
        MasterApi.contactsGet.buildPath((id: nasty)),
      ];

      for (final p in paths) {
        expect(p, contains(encoded), reason: p);
        expect(p, isNot(contains(' ')), reason: p);
        expect(p, isNot(contains('?')), reason: p);
        expect(p, isNot(contains('#')), reason: p);
        // Read back as a URL, the id is exactly one segment — its slash did not split it.
        expect(Uri.parse(p).pathSegments, contains(nasty), reason: p);
      }
    });
  });

  group('through the real registry', () {
    test(
      'checkout posts its DTO as the JSON body and returns the sale',
      () async {
        final t = makeClient('{"data":$saleJson}');

        final sale = await PosApi.salesCheckout(
          t.client,
          const POSCheckoutDTO(
            outletId: 'o1',
            transactionDate: '2026-09-20',
            items: [
              POSCheckoutItemDTO(
                productId: 'p1',
                unitId: 'u1',
                quantity: 2,
                price: 7500,
              ),
            ],
            payments: [
              POSTenderDTO(method: POSTenderMethod.cash, amount: 20000),
            ],
            clientRef: '01J8ZV0000000000000000ABCD',
          ),
        );

        expect(sale.number, 'POS-0001');
        expect(sale.changeAmount, 5000);
        final sent = t.transport.requests.single;
        expect(sent.method, HttpMethod.post);
        expect(sent.path, '/api/v1/pos/sales/checkout');
        expect(jsonDecode(sent.body!), {
          'outlet_id': 'o1',
          'transaction_date': '2026-09-20',
          'items': [
            {'product_id': 'p1', 'unit_id': 'u1', 'quantity': 2, 'price': 7500},
          ],
          'payments': [
            {'method': 'CASH', 'amount': 20000},
          ],
          'client_ref': '01J8ZV0000000000000000ABCD',
        });
      },
    );

    test('the POS settings come back as POSPreferences', () async {
      final t = makeClient(
        '{"data":{"require_shift":true,"show_table_number":true}}',
      );

      final settings = await PosApi.settingsGet(t.client);

      expect(settings.requireShift, isTrue);
      expect(settings.showTableNumber, isTrue);
      expect(settings.showQueueNumber, isFalse);
    });

    test('the sales of a shift come back as POSSales', () async {
      final t = makeClient(
        '{"data":[$saleJson],"meta":{"next_cursor":"cur_9"}}',
      );

      final sales = await PosApi.salesList(
        t.client,
        query: {'shift_id': 's1', 'page_size': 50},
      );

      expect(sales.items.single.number, 'POS-0001');
      expect(sales.nextCursor, 'cur_9');
      expect(
        t.transport.requests.single.path,
        '/api/v1/pos/sales?shift_id=s1&page_size=50',
      );
    });

    test('one sale comes back as a POSSale', () async {
      final t = makeClient('{"data":$saleJson}');

      final sale = await PosApi.salesGet(t.client, (id: 'x1'));

      expect(sale.grandTotal, 15000);
      expect(t.transport.requests.single.path, '/api/v1/pos/sales/x1');
    });

    test('opening a shift posts the float and returns the shift', () async {
      final t = makeClient('{"data":$shiftJson}');

      final shift = await PosApi.shiftsOpen(
        t.client,
        const OpenShiftDTO(outletId: 'o1', openingCash: 100000),
      );

      expect(shift.id, 's1');
      expect(t.transport.requests.single.path, '/api/v1/pos/shifts/open');
      expect(jsonDecode(t.transport.requests.single.body!), {
        'outlet_id': 'o1',
        'opening_cash': 100000,
      });
    });

    test('closing a shift posts the count to its own record', () async {
      final t = makeClient('{"data":$shiftJson}');

      final shift = await PosApi.shiftsClose(t.client, (
        id: 's1',
      ), const CloseShiftDTO(countedCash: 100000, notes: 'pas'));

      expect(shift.id, 's1');
      expect(t.transport.requests.single.path, '/api/v1/pos/shifts/s1/close');
      expect(jsonDecode(t.transport.requests.single.body!), {
        'counted_cash': 100000,
        'notes': 'pas',
      });
    });

    test(
      'the cash movements of a shift come back as POSCashMovements',
      () async {
        final t = makeClient('''
        {"data":[{"id":"m1","shift_id":"s1","type":"CASH_OUT","amount":5000,
         "reason":"Parkir","created_at":"2026-09-20T03:00:00Z"}]}''');

        final movements = await PosApi.shiftsCashMovements(t.client, (
          id: 's1',
        ));

        expect(movements.single.type, CashMovementType.cashOut);
        expect(
          t.transport.requests.single.path,
          '/api/v1/pos/shifts/s1/cash-movements',
        );
      },
    );

    test('the active shift comes back as a POSShift', () async {
      final t = makeClient('{"data":$shiftJson}');

      final shift = await PosApi.shiftsGetActive(
        t.client,
        query: {'outlet_id': 'o1'},
      );

      expect(shift!.number, 'SHF-001');
      expect(shift.cashierId, 'u1');
      expect(
        t.transport.requests.single.path,
        '/api/v1/pos/shifts/active?outlet_id=o1',
      );
    });

    test('a shift summary comes back as a ShiftSummaryResponse', () async {
      final t = makeClient('''
        {"data":{"shift_id":"s1","number":"SHF-001","status":"OPEN","outlet_id":"o1",
         "cashier_id":"u1","opened_at":"2026-09-20T01:00:00Z","total_transactions":1,
         "total_sales":15000,"opening_cash":100000,"expected_cash":115000,
         "cash_in":0,"cash_out":0,"cash_drop":0}}''');

      final summary = await PosApi.shiftsGetSummary(t.client, (id: 's1'));

      expect(summary.expectedCash, 115000);
      expect(summary.nonCashTenders, isEmpty);
      expect(t.transport.requests.single.path, '/api/v1/pos/shifts/s1');
    });

    test('the shift list comes back page by page, as POSShifts', () async {
      final t = makeClient(
        '{"data":[$shiftJson,$shiftJson],"meta":{"next_cursor":"cur_3"}}',
      );

      final page = await PosApi.shiftsList(
        t.client,
        query: {'outlet_id': 'o1', 'status': 'CLOSED', 'page_size': 25},
      );

      expect(page.items, hasLength(2));
      expect(page.nextCursor, 'cur_3');
      expect(
        t.transport.requests.single.path,
        '/api/v1/pos/shifts?outlet_id=o1&status=CLOSED&page_size=25',
      );
    });

    test('an active shift that is null is an answer, not an error', () async {
      final t = makeClient('{"data":null}');

      expect(await PosApi.shiftsGetActive(t.client), isNull);
    });

    test('stock reads product id to quantity', () async {
      final t = makeClient('{"data":{"p1":3,"p2":2.5}}');

      expect(await PosApi.stock(t.client), {'p1': 3, 'p2': 2.5});
    });

    test(
      'the next queue number is the string, not the wrapper object',
      () async {
        final t = makeClient('{"data":{"next_queue_number":"A-014"}}');

        expect(await PosApi.queueNext(t.client), 'A-014');
      },
    );

    test('products come back as Products', () async {
      final t = makeClient(
        '''
        {"data":[{"id":"p1","name":"Kopi","unit_id":"u1","sell_price":15000,"type":"INVENTORY"}]}''',
      );

      final products = await ProductsApi.list(
        t.client,
        query: {'page_size': 50},
      );

      expect(products.items.single.name, 'Kopi');
      expect(products.items.single.sellPrice, 15000);
      expect(t.transport.requests.single.path, '/api/v1/products?page_size=50');
    });

    test('categories come back as Categories', () async {
      final t = makeClient('{"data":[{"id":"c1","name":"Minuman"}]}');

      expect((await MasterApi.categoriesList(t.client)).single.name, 'Minuman');
    });

    test('customers come back as Contacts, filtered by the query', () async {
      final t = makeClient('''
        {"data":[{"id":"c1","name":"Budi","type":"CUSTOMER","phone":null}]}''');

      final contacts = await MasterApi.contactsList(
        t.client,
        query: {'type': 'CUSTOMER', 'q': 'bud', 'page_size': 50},
      );

      expect(contacts.single.name, 'Budi');
      expect(
        t.transport.requests.single.path,
        '/api/v1/master/contacts?type=CUSTOMER&q=bud&page_size=50',
      );
    });

    test('adding a customer posts the DTO and returns the Contact', () async {
      final t = makeClient(
        '{"data":{"id":"c2","name":"Sari","type":"CUSTOMER"}}',
      );

      final created = await MasterApi.contactsCreate(
        t.client,
        const CreateContactDTO(name: 'Sari', type: ContactType.customer),
      );

      expect(created.id, 'c2');
      expect(jsonDecode(t.transport.requests.single.body!), {
        'name': 'Sari',
        'type': 'CUSTOMER',
        'is_active': true,
      });
    });

    test('accounts come back as ChartOfAccounts', () async {
      final t = makeClient(
        '{"data":[{"id":"a1","code":"1-1100","name":"Kas Kecil"}]}',
      );

      expect((await MasterApi.coaList(t.client)).single.code, '1-1100');
    });

    test('my permissions come back as the strings the server grants', () async {
      final t = makeClient(
        '{"data":["pos.cashier.access","pos.shift.override"]}',
      );

      final granted = await TeamApi.permissionsMy(t.client);

      expect(granted, ['pos.cashier.access', 'pos.shift.override']);
      expect(t.transport.requests.single.path, '/api/v1/team/my-permissions');
    });

    test(
      'an owner is granted the wildcard, which is a string like any other',
      () async {
        // `team_service.go` answers `["*"]` for an owner or superadmin.
        final t = makeClient('{"data":["*"]}');

        expect(await TeamApi.permissionsMy(t.client), ['*']);
      },
    );

    test('no permissions at all is an empty list, not an error', () async {
      final t = makeClient('{"data":null}');

      expect(await TeamApi.permissionsMy(t.client), isEmpty);
    });

    test('an outlet comes back as an Outlet', () async {
      final t = makeClient('{"data":{"id":"o1","name":"Kasir Utama"}}');

      final outlet = await TenantApi.outletsGet(t.client, (id: 'o1'));

      expect(outlet.name, 'Kasir Utama');
      expect(t.transport.requests.single.path, '/api/v1/outlets/o1');
    });

    test('recording a cash movement returns nothing', () async {
      final t = makeClient('{"data":null}');

      await PosApi.shiftsRecordCashMovement(
        t.client,
        (id: 's1'),
        const CashMovementDTO(
          type: CashMovementType.cashOut,
          amount: 5000,
          reason: 'Parkir',
        ),
      );

      expect(
        t.transport.requests.single.path,
        '/api/v1/pos/shifts/s1/cash-movement',
      );
      expect(jsonDecode(t.transport.requests.single.body!), {
        'type': 'CASH_OUT',
        'amount': 5000,
        'reason': 'Parkir',
      });
    });
  });
}
