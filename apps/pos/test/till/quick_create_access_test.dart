/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/api/transport_fake.dart';
import 'package:pn_types/src/tenant.dart';
import 'package:pos/till/quick_create_access.dart';

// Written new. The till used to ask nothing: it passed no permission list to `Permissions`, so
// only an owner ever saw "Add customer". The cashier role now holds `pos.quick_create`, and the
// buttons are worth drawing for them, so the till asks `team/my-permissions` once.

const _json = {'content-type': 'application/json'};

TransportResponse granted(List<String> codes) => TransportResponse(
  status: 200,
  headers: _json,
  body: jsonEncode({'data': codes}),
);

const cashier = UserCompany(
  id: 'm1',
  userId: 'u1',
  companyId: 'co1',
  isActive: true,
  role: 'cashier',
);

const owner = UserCompany(
  id: 'm2',
  userId: 'u2',
  companyId: 'co1',
  isActive: true,
  role: 'owner',
);

({QuickCreateAccess access, FakeApiTransport transport}) rig(
  UserCompany? membership,
) {
  final transport = FakeApiTransport();
  final access = QuickCreateAccess(
    client: ApiClient(transport: transport, language: () => 'id'),
    membership: membership,
  );
  addTearDown(access.dispose);
  return (access: access, transport: transport);
}

void main() {
  test('offers nothing before the list has been read', () {
    final (:access, :transport) = rig(cashier);

    expect(access.canAddProduct, isFalse);
    expect(access.canAddCustomer, isFalse);
  });

  test('a cashier holding pos.quick_create may add both', () async {
    final (:access, :transport) = rig(cashier);
    transport.respond(granted(['pos.cashier.access', 'pos.quick_create']));

    await access.load();

    expect(access.canAddProduct, isTrue);
    expect(access.canAddCustomer, isTrue);
    expect(
      Uri.parse(transport.requests.single.path).path,
      '/api/v1/team/my-permissions',
    );
  });

  test('a contact manager may add a customer and not a product', () async {
    final (:access, :transport) = rig(cashier);
    transport.respond(granted(['master.contact.manage']));

    await access.load();

    expect(access.canAddCustomer, isTrue);
    expect(access.canAddProduct, isFalse);
  });

  test('a cashier holding neither may add nothing', () async {
    final (:access, :transport) = rig(cashier);
    transport.respond(granted(['pos.cashier.access']));

    await access.load();

    expect(access.canAddProduct, isFalse);
    expect(access.canAddCustomer, isFalse);
  });

  test('the owner may add both without asking', () async {
    final (:access, :transport) = rig(owner);

    await access.load();

    expect(access.canAddProduct, isTrue);
    expect(access.canAddCustomer, isTrue);
    expect(transport.requests, isEmpty);
  });

  test('no answer leaves nothing offered, and is not an error', () async {
    // The safe direction: a button that appears late is better than one the server refuses.
    final (:access, :transport) = rig(cashier);
    transport.fail(TransportException('offline'));

    await access.load();

    expect(access.canAddProduct, isFalse);
    expect(access.canAddCustomer, isFalse);
  });

  test('a refusal leaves nothing offered either', () async {
    final (:access, :transport) = rig(cashier);
    transport.respond(
      TransportResponse(
        status: 403,
        headers: _json,
        body: jsonEncode({
          'error': {'message': 'Forbidden'},
        }),
      ),
    );

    await access.load();

    expect(access.canAddCustomer, isFalse);
  });

  test('tells its listeners once the answer is in', () async {
    final (:access, :transport) = rig(cashier);
    transport.respond(granted(['pos.quick_create']));
    var heard = 0;
    access.addListener(() => heard++);

    await access.load();

    expect(heard, 1);
  });

  test('no membership at all is nobody to ask about', () async {
    final (:access, :transport) = rig(null);
    transport.respond(granted(['pos.quick_create']));

    await access.load();

    // The server answers for whoever the session is; with no membership in the paired company
    // there is no owner check to skip, so it is still asked.
    expect(access.canAddCustomer, isTrue);
  });
}
