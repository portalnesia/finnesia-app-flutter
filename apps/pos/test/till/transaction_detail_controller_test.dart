/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_pos/src/pos_transaction_detail.dart';
import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/api/transport_fake.dart';
import 'package:pos/state/loadable.dart';
import 'package:pos/till/transaction_detail_controller.dart';

// Written new. The detail and the picker's two reads are one component's state, so there is no
// object to port. The behaviours are: the picker's first page is read when the sheet opens,
// typing searches the server after a pause, creating a customer is part of picking one, and the
// next queue number is only read when the company asked for it.

/// An [ApiTransport] whose answers the test releases by hand, so two requests can be in flight at
/// once and the test decides which one lands first.
///
/// [FakeApiTransport] cannot express that: it answers in the order it was asked, so a request can
/// never be overtaken and a staleness guard can never be exercised. A guard that no test can reach
/// is a guard nobody has checked.
class HeldTransport implements ApiTransport {
  final requests = <TransportRequest>[];
  final _pending = <Completer<TransportResponse>>[];

  @override
  Future<TransportResponse> send(TransportRequest request) {
    requests.add(request);
    final answer = Completer<TransportResponse>();
    _pending.add(answer);
    return answer.future;
  }

  void release(int index, TransportResponse response) =>
      _pending[index].complete(response);
}

const _json = {'content-type': 'application/json'};

TransportResponse ok(Object? data) => TransportResponse(
  status: 200,
  headers: _json,
  body: jsonEncode({'data': data}),
);

TransportResponse page(List<Map<String, Object?>> items, {String? next}) =>
    TransportResponse(
      status: 200,
      headers: _json,
      body: jsonEncode({
        'data': items,
        'meta': {'next_cursor': next},
      }),
    );

Map<String, Object?> contactJson(String id, String name) => {
  'id': id,
  'name': name,
  'type': 'CUSTOMER',
};

/// What opening the sheet reads, in the order it reads it.
void opening(
  FakeApiTransport transport, {
  List<Map<String, Object?>>? customers,
  String? next,
  bool queueNumber = false,
}) {
  transport.respond(page(customers ?? [contactJson('c1', 'Budi')], next: next));
  if (queueNumber) transport.respond(ok({'next_queue_number': '7'}));
}

({TransactionDetailController controller, FakeApiTransport transport}) rig({
  bool showTableNumber = false,
  bool showQueueNumber = false,
  bool queueNumberAuto = false,
  bool canCreateContact = true,
  String? defaultCustomerId,
  Duration debounce = const Duration(milliseconds: 20),
}) {
  final transport = FakeApiTransport();
  final controller = TransactionDetailController(
    client: ApiClient(transport: transport, language: () => 'id'),
    outletId: 'out_1',
    showTableNumber: showTableNumber,
    showQueueNumber: showQueueNumber,
    canCreateContact: canCreateContact,
    defaultCustomerId: defaultCustomerId,
    queueNumberAuto: queueNumberAuto,
    debounce: debounce,
  );
  addTearDown(controller.dispose);
  return (controller: controller, transport: transport);
}

Uri uriOf(TransportRequest request) => Uri.parse(request.path);

List<TransportRequest> contactRequests(FakeApiTransport t) => t.requests
    .where((r) => uriOf(r).path == '/api/v1/master/contacts')
    .toList();

Future<void> settle([int ms = 60]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  restoring();
  group('opening the sheet', () {
    test('reads one page of customers, once', () async {
      final (:controller, :transport) = rig();
      opening(transport);

      await controller.open();

      expect(contactRequests(transport), hasLength(1));
      final query = uriOf(contactRequests(transport).single).queryParameters;
      expect(query['type'], 'CUSTOMER');
      expect(query['page_size'], '50');
      // Nothing typed yet, so there is nothing to search for. Sending an empty `q` would be a
      // LIKE on nothing.
      expect(query.containsKey('q'), isFalse);
    });

    test('shows the customers it read', () async {
      final (:controller, :transport) = rig();
      opening(transport, customers: [contactJson('c1', 'Budi')]);

      await controller.open();

      expect(controller.state, isA<Ready<List<TransactionDetail>>>());
      expect(switch (controller.state) {
        Ready(:final data) => data.single.customerName,
        _ => null,
      }, 'Budi');
    });

    test(
      'does not read the queue number unless the company auto-numbers',
      () async {
        final (:controller, :transport) = rig();
        opening(transport);

        await controller.open();

        expect(
          transport.requests.where(
            (r) => uriOf(r).path == '/api/v1/pos/queue/next',
          ),
          isEmpty,
        );
        expect(controller.queuePlaceholder, isNull);
      },
    );

    test('reads the next queue number when auto-numbering is on', () async {
      final (:controller, :transport) = rig(
        showQueueNumber: true,
        queueNumberAuto: true,
      );
      opening(transport, queueNumber: true);

      await controller.open();

      final ask = transport.requests
          .map(uriOf)
          .singleWhere((u) => u.path == '/api/v1/pos/queue/next');
      expect(ask.queryParameters['outlet_id'], 'out_1');
      expect(controller.queuePlaceholder, '7');
    });

    test(
      'does not read the queue number when only the field is shown',
      () async {
        // `show_queue_number` draws the field; `queue_number_auto` is what asks the server for a
        // number to put in it. The source gates the query on both.
        final (:controller, :transport) = rig(showQueueNumber: true);
        opening(transport);

        await controller.open();

        expect(
          transport.requests.where(
            (u) => uriOf(u).path == '/api/v1/pos/queue/next',
          ),
          isEmpty,
        );
      },
    );

    test('opened twice reads once', () async {
      final (:controller, :transport) = rig();
      opening(transport);

      await controller.open();
      await controller.open();

      expect(contactRequests(transport), hasLength(1));
    });

    test(
      'a list that could not be read is reported, not shown as empty',
      () async {
        final (:controller, :transport) = rig();
        transport.fail(TransportException('offline'));

        await controller.open();

        expect(controller.state, isA<Failed<List<TransactionDetail>>>());
      },
    );

    test('a first attempt that failed can be tried again', () async {
      // The "already read" flag is set on success, not on the attempt. A sheet reopened after a
      // dropped connection must not be stuck on the failure for ever.
      final (:controller, :transport) = rig();
      transport.fail(TransportException('offline'));
      await controller.open();
      transport.respond(page([contactJson('c1', 'Budi')]));

      await controller.open();

      expect(controller.state, isA<Ready<List<TransactionDetail>>>());
      expect(contactRequests(transport), hasLength(2));
    });

    test(
      'a queue number that could not be read does not take the list with it',
      () async {
        // The two reads are separate: a shop that cannot be given a queue number still has to be
        // able to attach a customer.
        final (:controller, :transport) = rig(
          showQueueNumber: true,
          queueNumberAuto: true,
        );
        transport.respond(page([contactJson('c1', 'Budi')]));
        transport.fail(TransportException('offline'));

        await controller.open();

        expect(controller.state, isA<Ready<List<TransactionDetail>>>());
        expect(controller.queuePlaceholder, isNull);
      },
    );
  });

  group('searching', () {
    test('asks the server once the typing stops', () async {
      final (:controller, :transport) = rig();
      opening(transport);
      await controller.open();
      transport.respond(page([contactJson('c2', 'Budi Santoso')]));

      controller.setSearch('bud');
      await settle();

      final asked = contactRequests(transport).last;
      expect(uriOf(asked).queryParameters['q'], 'bud');
      expect(controller.state, isA<Ready<List<TransactionDetail>>>());
    });

    test('does not ask for every letter', () async {
      // A request per keystroke is what N+1 looks like from the UI (`optimization.md` §6.1).
      final (:controller, :transport) = rig(
        debounce: const Duration(milliseconds: 40),
      );
      opening(transport);
      await controller.open();
      transport.respond(page([contactJson('c2', 'Budi Santoso')]));

      controller.setSearch('b');
      controller.setSearch('bu');
      controller.setSearch('bud');
      await settle(120);

      // One read for opening, one for the search.
      expect(contactRequests(transport), hasLength(2));
    });

    test('a search that is only spaces is not a search', () async {
      final (:controller, :transport) = rig();
      opening(transport);
      await controller.open();

      controller.setSearch('   ');
      await settle();

      expect(contactRequests(transport), hasLength(1));
    });

    test('the answer to a search that was overtaken is dropped', () async {
      // Two searches in flight, the older one landing last, would put the wrong list on screen
      // (`optimization.md` §6.1). The answers are released out of order on purpose: that is the
      // only arrangement in which the guard does anything.
      final transport = HeldTransport();
      final controller = TransactionDetailController(
        client: ApiClient(transport: transport, language: () => 'id'),
        outletId: 'out_1',
        debounce: Duration.zero,
      );
      addTearDown(controller.dispose);

      controller.setSearch('a');
      await pumpEventQueue();
      controller.setSearch('ab');
      await pumpEventQueue();
      expect(transport.requests, hasLength(2));

      // The newer answer lands first, the older one after it.
      transport.release(1, page([contactJson('new', 'New')]));
      await pumpEventQueue();
      transport.release(0, page([contactJson('old', 'Old')]));
      await pumpEventQueue();

      final shown = switch (controller.state) {
        Ready(:final data) => data.map((d) => d.customerName).toList(),
        _ => null,
      };
      expect(shown, ['New']);
    });

    test('clearing the search reads the first page again', () async {
      final (:controller, :transport) = rig(debounce: Duration.zero);
      opening(transport);
      await controller.open();
      transport.respond(page([contactJson('c2', 'Budi Santoso')]));
      controller.setSearch('bud');
      await settle(10);
      transport.respond(page([contactJson('c1', 'Budi')]));

      controller.setSearch('');
      await settle(10);

      expect(
        uriOf(contactRequests(transport).last).queryParameters.containsKey('q'),
        isFalse,
      );
    });
  });

  group('creating a customer', () {
    test('posts only what was filled in', () async {
      final (:controller, :transport) = rig();
      opening(transport);
      await controller.open();
      transport.respond(ok(contactJson('c9', 'Sari')));

      final result = await controller.create(
        name: 'Sari',
        phone: '0812',
        email: '',
        companyName: '',
        address: '',
      );

      expect(result, isA<CreateContactOk>());
      expect(jsonDecode(transport.requests.last.body!), {
        'name': 'Sari',
        'type': 'CUSTOMER',
        'is_active': true,
        'phone': '0812',
      });
    });

    test(
      'trims what the cashier typed, and leaves out what is empty',
      () async {
        final (:controller, :transport) = rig();
        opening(transport);
        await controller.open();
        transport.respond(ok(contactJson('c9', 'Sari')));

        await controller.create(
          name: '  Sari  ',
          phone: '   ',
          email: '',
          companyName: '  Toko Sari ',
          address: '',
        );

        expect(jsonDecode(transport.requests.last.body!), {
          'name': 'Sari',
          'type': 'CUSTOMER',
          'is_active': true,
          'company_name': 'Toko Sari',
        });
      },
    );

    test('a name of only spaces is not sent', () async {
      final (:controller, :transport) = rig();
      opening(transport);
      await controller.open();

      final result = await controller.create(
        name: '   ',
        phone: '',
        email: '',
        companyName: '',
        address: '',
      );

      expect(result, isA<CreateContactInvalid>());
      // Nothing was sent: a request with no name would be refused by the server anyway, and
      // this way the cashier is told before it leaves.
      expect(transport.requests.where((r) => r.method.wire == 'POST'), isEmpty);
    });

    test('the server refusing is reported with its own sentence', () async {
      final (:controller, :transport) = rig();
      opening(transport);
      await controller.open();
      transport.respond(
        TransportResponse(
          status: 422,
          headers: _json,
          body: jsonEncode({
            'error': {'message': 'Nama sudah dipakai'},
          }),
        ),
      );

      final result = await controller.create(
        name: 'Sari',
        phone: '',
        email: '',
        companyName: '',
        address: '',
      );

      expect(result, isA<CreateContactRejected>());
      expect((result as CreateContactRejected).message, 'Nama sudah dipakai');
    });

    test('no answer at all is a different answer from a refusal', () async {
      final (:controller, :transport) = rig();
      opening(transport);
      await controller.open();
      transport.fail(TransportException('offline'));

      final result = await controller.create(
        name: 'Sari',
        phone: '',
        email: '',
        companyName: '',
        address: '',
      );

      expect(result, isA<CreateContactUnavailable>());
    });

    test('a created customer is offered at the top of the list', () async {
      // The cashier has just made this customer and wants to pick them; making them search for
      // the name they just typed would be a strange way to finish the job.
      final (:controller, :transport) = rig();
      opening(transport, customers: [contactJson('c1', 'Budi')]);
      await controller.open();
      transport.respond(ok(contactJson('c9', 'Sari')));

      await controller.create(
        name: 'Sari',
        phone: '',
        email: '',
        companyName: '',
        address: '',
      );

      final shown = switch (controller.state) {
        Ready(:final data) => data.map((d) => d.customerName).toList(),
        _ => null,
      };
      expect(shown, ['Sari', 'Budi']);
    });

    test('a created customer is not added twice', () async {
      final (:controller, :transport) = rig();
      opening(transport, customers: [contactJson('c1', 'Budi')]);
      await controller.open();
      transport.respond(ok(contactJson('c9', 'Sari')));
      await controller.create(
        name: 'Sari',
        phone: '',
        email: '',
        companyName: '',
        address: '',
      );
      transport.respond(ok(contactJson('c9', 'Sari')));

      await controller.create(
        name: 'Sari',
        phone: '',
        email: '',
        companyName: '',
        address: '',
      );

      final shown = switch (controller.state) {
        Ready(:final data) => data.map((d) => d.customerId).toList(),
        _ => null,
      };
      expect(shown, ['c9', 'c1']);
    });

    test('only one create goes out at a time', () async {
      final (:controller, :transport) = rig();
      opening(transport);
      await controller.open();
      transport.respond(ok(contactJson('c9', 'Sari')));

      final first = controller.create(
        name: 'Sari',
        phone: '',
        email: '',
        companyName: '',
        address: '',
      );
      final second = controller.create(
        name: 'Sari',
        phone: '',
        email: '',
        companyName: '',
        address: '',
      );
      await Future.wait([first, second]);

      expect(
        transport.requests.where((r) => r.method.wire == 'POST'),
        hasLength(1),
      );
    });
  });

  group('the detail being edited', () {
    test('starts empty', () {
      final (:controller, :transport) = rig();

      expect(controller.detail, TransactionDetail.empty);
    });

    test('a field the outlet did not ask for is still carried', () {
      // The outlet decides what is *shown*, not what the sale may carry: a table number typed
      // before the preference changed is not thrown away.
      final (:controller, :transport) = rig();

      controller.setTableNumber('12');

      expect(controller.detail.tableNumber, '12');
      expect(controller.showTableNumber, isFalse);
    });

    test('the queue number is pre-filled from the server once', () async {
      final (:controller, :transport) = rig(
        showQueueNumber: true,
        queueNumberAuto: true,
      );
      opening(transport, queueNumber: true);

      await controller.open();

      expect(controller.detail.queueNumber, '7');
    });

    test(
      'the queue number is not pre-filled over what the cashier typed',
      () async {
        final (:controller, :transport) = rig(
          showQueueNumber: true,
          queueNumberAuto: true,
        );
        opening(transport, queueNumber: true);
        controller.setQueueNumber('99');

        await controller.open();

        expect(controller.detail.queueNumber, '99');
      },
    );

    test('resetting empties it', () {
      final (:controller, :transport) = rig();
      controller.setTableNumber('12');
      controller.setMemo('tanpa gula');

      controller.reset();

      expect(controller.detail, TransactionDetail.empty);
    });

    test('tells its listeners when the detail changes', () {
      final (:controller, :transport) = rig();
      var told = 0;
      controller.addListener(() => told++);

      controller.setMemo('tanpa gula');

      expect(told, 1);
    });
  });

  group('the customer the company nominates', () {
    // The server already attributes a sale to `default_customer_id` when the till sends no
    // customer (`pos_service.go:1509`), and it refuses the sale outright with
    // `pos_customer_required` when there is no default either. The till therefore has to know
    // the id: without it the summary row says "add a detail" for a sale that already has a
    // customer on it, and the cashier is left guessing who the receipt is for.

    test(
      'is attached as soon as the sheet opens, without asking the server',
      () async {
        final (:controller, :transport) = rig(defaultCustomerId: 'c1');
        opening(transport, customers: [contactJson('c1', 'UMUM')]);

        await controller.open();

        expect(controller.detail.customerId, 'c1');
        expect(controller.detail.customerName, 'UMUM');
      },
    );

    test('is attached before the sheet is opened at all', () {
      // The row is drawn on the till, where the sheet may never be opened. A customer that only
      // appeared once the sheet had been opened would make the row lie until then.
      final (:controller, :transport) = rig(defaultCustomerId: 'c1');

      expect(controller.detail.customerId, 'c1');
    });

    test('does not override a customer the cashier already picked', () async {
      final (:controller, :transport) = rig(defaultCustomerId: 'c1');
      opening(
        transport,
        customers: [contactJson('c1', 'UMUM'), contactJson('c2', 'Budi')],
      );

      controller.pickCustomer(
        const TransactionDetail(customerId: 'c2', customerName: 'Budi'),
      );
      await controller.open();

      expect(controller.detail.customerId, 'c2');
      expect(controller.detail.customerName, 'Budi');
    });

    test('a default the list does not name is still attached', () async {
      // The list is one page of fifty. A default customer outside it must still be attached:
      // the id is what the sale carries, and the server does not need the name.
      final (:controller, :transport) = rig(defaultCustomerId: 'c9');
      opening(transport, customers: [contactJson('c1', 'Budi')]);

      await controller.open();

      expect(controller.detail.customerId, 'c9');
      expect(controller.detail.customerName, isNull);
    });

    test('is named without the sheet being opened', () async {
      // The row is drawn on the till from the first frame. Until the name arrived it read
      // "Pelanggan: Pelanggan", and it only arrived once the cashier had opened the sheet.
      final (:controller, :transport) = rig(defaultCustomerId: 'c9');
      transport.respond(ok(contactJson('c9', 'UMUM')));

      await controller.loadDefault();

      expect(controller.detail.customerId, 'c9');
      expect(controller.detail.customerName, 'UMUM');
      // Read by id, so a default outside the picker's first page is found all the same.
      expect(transport.requests.single.path, '/api/v1/master/contacts/c9');
    });

    test('keeps the name for the next sale', () async {
      final (:controller, :transport) = rig(defaultCustomerId: 'c9');
      transport.respond(ok(contactJson('c9', 'UMUM')));
      await controller.loadDefault();

      controller.pickCustomer(
        const TransactionDetail(customerId: 'c2', customerName: 'Budi'),
      );
      controller.reset();

      expect(controller.detail.customerId, 'c9');
      expect(controller.detail.customerName, 'UMUM');
    });

    test('does not put its name on a customer the cashier picked', () async {
      final (:controller, :transport) = rig(defaultCustomerId: 'c9');
      transport.respond(ok(contactJson('c9', 'UMUM')));

      controller.pickCustomer(
        const TransactionDetail(customerId: 'c2', customerName: 'Budi'),
      );
      await controller.loadDefault();

      expect(controller.detail.customerId, 'c2');
      expect(controller.detail.customerName, 'Budi');
    });

    test('stays attached, unnamed, when the name cannot be read', () async {
      // The id is what the sale carries; the name is only for the row.
      final (:controller, :transport) = rig(defaultCustomerId: 'c9');
      transport.fail(TransportException('offline'));

      await controller.loadDefault();

      expect(controller.detail.customerId, 'c9');
      expect(controller.detail.customerName, isNull);
    });

    test('asks for nothing when the company has no default', () async {
      final (:controller, :transport) = rig();

      await controller.loadDefault();

      expect(transport.requests, isEmpty);
    });

    test('there is no default when the company has none', () async {
      final (:controller, :transport) = rig();
      opening(transport);

      await controller.open();

      expect(controller.detail.customerId, isEmpty);
    });
  });

  group('whether a customer may be created here', () {
    // `POST /master/contacts` needs `master.contact.manage`, and the seeded cashier role does
    // not have it (`rbac_and_membership.sql`). A button drawn for a cashier would be refused by
    // the server, so it is not drawn at all (R-26). The owner has said the permission will be
    // granted later; when it is, this gate loosens without the screen changing.

    test('is asked of the caller, not decided here', () {
      final (:controller, :transport) = rig(canCreateContact: false);

      expect(controller.canCreateContact, isFalse);
    });

    test('defaults to allowed when the caller does not say', () {
      // The caller is the one holding the permission list; a caller that has not worked it out
      // yet is not the same as one that has said no.
      final transport = FakeApiTransport();
      final controller = TransactionDetailController(
        client: ApiClient(transport: transport, language: () => 'id'),
        outletId: 'out_1',
      );
      addTearDown(controller.dispose);

      expect(controller.canCreateContact, isTrue);
    });
  });
}

void restoring() {
  // A held basket carries the customer's id and nothing else about them, so resuming it has to
  // find the name again for the row: the source resolves it from the picker's own list, and this
  // reads it by id, as `loadDefault` does (a list is one page of fifty, and the customer is not
  // promised to be on it).
  group('taking back what a held basket carried', () {
    const held = TransactionDetail(
      customerId: 'c2',
      customerMemo: 'Alergi kacang',
      tableNumber: '4',
      queueNumber: 'A-7',
    );

    test('puts all four fields back at once, the customer as attached but '
        'not yet named', () async {
      final (:controller, :transport) = rig();
      transport.respond(ok(contactJson('c2', 'Budi')));

      final done = controller.restore(held);

      // Before the name has come: what the cashier sees the moment the basket opens.
      expect(controller.detail.customerId, 'c2');
      expect(controller.detail.customerMemo, 'Alergi kacang');
      expect(controller.detail.tableNumber, '4');
      expect(controller.detail.queueNumber, 'A-7');
      expect(controller.detail.customerName, '');
      await done;
    });

    test('names the customer by id', () async {
      final (:controller, :transport) = rig();
      transport.respond(ok(contactJson('c2', 'Budi')));

      await controller.restore(held);

      expect(controller.detail.customerName, 'Budi');
      expect(transport.requests.single.path, '/api/v1/master/contacts/c2');
    });

    test(
      'a customer whose name cannot be read stays attached, and unnamed',
      () async {
        final (:controller, :transport) = rig();
        transport.fail(TransportException('offline'));

        await controller.restore(held);

        expect(controller.detail.customerId, 'c2');
        expect(controller.detail.customerName, '');
      },
    );

    test(
      'does not name a customer the cashier has changed in the meantime',
      () async {
        final transport = HeldTransport();
        final controller = TransactionDetailController(
          client: ApiClient(transport: transport, language: () => 'id'),
          outletId: 'out_1',
        );
        addTearDown(controller.dispose);
        final done = controller.restore(held);

        controller.pickCustomer(
          const TransactionDetail(customerId: 'c5', customerName: 'Sari'),
        );
        transport.release(0, ok(contactJson('c2', 'Budi')));
        await done;

        expect(controller.detail.customerId, 'c5');
        expect(controller.detail.customerName, 'Sari');
      },
    );

    test('a basket with no customer asks for no name', () async {
      final (:controller, :transport) = rig();

      await controller.restore(const TransactionDetail(tableNumber: '4'));

      expect(transport.requests, isEmpty);
      expect(controller.detail.customerName, isNull);
      expect(controller.detail.tableNumber, '4');
    });
  });
}
