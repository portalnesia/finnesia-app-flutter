/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_pos/src/pos_transaction_detail.dart';
import 'package:test/test.dart';

// Written new: there is no module to port and no `.test.ts` to be an oracle. The behaviours
// are the ones that decide what the server is sent and what the cashier is shown.
//
// The empty case is the one that matters: an optional field sent as `''` is a customer that
// does not exist, and the checkout is refused **after** the money is taken.

const _budi = TransactionDetail(customerId: 'c1', customerName: 'Budi');

void main() {
  group('a detail nobody has filled in', () {
    test('has no customer, no memo, no table and no queue', () {
      const detail = TransactionDetail.empty;

      expect(detail.customerId, isEmpty);
      expect(detail.customerName, isNull);
      expect(detail.customerMemo, isEmpty);
      expect(detail.tableNumber, isEmpty);
      expect(detail.queueNumber, isEmpty);
    });

    test("is what a fresh transaction starts from", () {
      // `EMPTY_TRANSACTION_DETAIL` in the source, and what `resetCart` writes back.
      expect(TransactionDetail.empty, const TransactionDetail());
    });

    test('shows none of its four fields', () {
      const detail = TransactionDetail.empty;

      expect(detail.shownCustomerName, isNull);
      expect(detail.shownTableNumber, isNull);
      expect(detail.shownQueueNumber, isNull);
      expect(detail.shownMemo, isNull);
      expect(detail.hasAnything, isFalse);
    });
  });

  group('picking a customer', () {
    test('carries the name as well as the id', () {
      final detail = TransactionDetail.empty.withCustomer(
        id: 'c1',
        name: 'Budi',
      );

      expect(detail.customerId, 'c1');
      expect(detail.customerName, 'Budi');
    });

    test('an unknown id leaves no name behind', () {
      // The picker offers a free-text "create this customer" option, and the source clears the
      // name when the id it sends matches nothing in the list it holds.
      final detail = TransactionDetail.empty.withCustomer(
        id: 'gone',
        name: null,
      );

      expect(detail.customerId, 'gone');
      expect(detail.customerName, isNull);
    });

    test('replacing a customer does not keep the old name', () {
      final detail = _budi.withCustomer(id: 'c2', name: 'Siti');

      expect(detail.customerId, 'c2');
      expect(detail.customerName, 'Siti');
    });

    test('clearing the customer clears the name with it', () {
      final detail = _budi.withCustomer(id: '', name: null);

      expect(detail.customerId, isEmpty);
      expect(detail.customerName, isNull);
    });

    test('picking somebody new keeps the rest of the detail', () {
      const detail = TransactionDetail(
        customerId: 'c1',
        customerName: 'Budi',
        tableNumber: '12',
        customerMemo: 'tanpa gula',
      );

      final next = detail.withCustomer(id: 'c2', name: 'Siti');

      expect(next.tableNumber, '12');
      expect(next.customerMemo, 'tanpa gula');
    });
  });

  group('a customer whose name is not known yet', () {
    test('still counts as a customer, so the row says so', () {
      // No path in the till produces this today: the picker always sends the name it has. The
      // rule is kept because it is the source's, and because the held-basket path in C7 is what
      // produces it (held orders store ids, and the source resolves the name back from the
      // picker's list). Collapsing the rule now is the change C7 would have to undo.
      const detail = TransactionDetail(customerId: 'c1');

      expect(detail.shownCustomerName, '');
      expect(detail.hasAnything, isTrue);
    });
  });

  group('what the summary row has to show', () {
    test('does not trim what the cashier typed', () {
      // The source tests `detail.tableNumber &&` and never trims: a table number of spaces is
      // truthy in JavaScript, so the row prints them. Trimming here would be a divergence the
      // source does not have. `buildCheckoutPayload` is where trimming belongs, and that is a
      // different rule (what the server is sent).
      const detail = TransactionDetail(tableNumber: '   ');

      expect(detail.shownTableNumber, '   ');
    });

    test('shows the table, the queue and the memo when they are filled in', () {
      const detail = TransactionDetail(
        customerMemo: 'tanpa gula',
        tableNumber: '12',
        queueNumber: '45',
      );

      expect(detail.shownCustomerName, isNull);
      expect(detail.shownTableNumber, '12');
      expect(detail.shownQueueNumber, '45');
      expect(detail.shownMemo, 'tanpa gula');
      expect(detail.hasAnything, isTrue);
    });

    test('counts a memo on its own as something to show', () {
      expect(
        const TransactionDetail(customerMemo: 'tanpa gula').hasAnything,
        isTrue,
      );
    });
  });

  group('where the note goes', () {
    // The owner's rule (2026-09-21): the note is folded into the customer's parentheses for the
    // company's **default** customer, and stands on its own for any other. The default is a
    // shared walk-in record, so the note is what tells one of its sales from another; a customer
    // the cashier picked by name is already identified by that name.
    //
    // The note is never printed twice and never dropped, whatever the combination.

    test('a picked customer keeps the note on its own row', () {
      const detail = TransactionDetail(
        customerId: 'c1',
        customerName: 'Budi',
        customerMemo: 'meja 4',
      );

      expect(detail.summaryTexts(isDefaultCustomer: false), (
        customer: 'Budi',
        memo: 'meja 4',
      ));
    });

    test('the default customer carries the note in parentheses', () {
      const detail = TransactionDetail(
        customerId: 'c1',
        customerName: 'UMUM',
        customerMemo: 'meja 4',
      );

      expect(detail.summaryTexts(isDefaultCustomer: true), (
        customer: 'UMUM (meja 4)',
        memo: null,
      ));
    });

    test('the default customer with no note is just the name', () {
      const detail = TransactionDetail(customerId: 'c1', customerName: 'UMUM');

      expect(detail.summaryTexts(isDefaultCustomer: true), (
        customer: 'UMUM',
        memo: null,
      ));
    });

    test('a note with nobody attached keeps its own row', () {
      // There is no customer to fold it into, so folding it would drop it.
      const detail = TransactionDetail(customerMemo: 'meja 4');

      expect(detail.summaryTexts(isDefaultCustomer: true), (
        customer: null,
        memo: 'meja 4',
      ));
    });

    test('nothing filled in says nothing', () {
      expect(TransactionDetail.empty.summaryTexts(isDefaultCustomer: true), (
        customer: null,
        memo: null,
      ));
      expect(TransactionDetail.empty.summaryTexts(isDefaultCustomer: false), (
        customer: null,
        memo: null,
      ));
    });

    test('a customer whose name is unknown keeps the note on its own row', () {
      // `customerName` null means the name is not known yet; folding would print "(meja 4)" as
      // if the note were the customer.
      const detail =
          TransactionDetail(customerId: 'c1', customerMemo: 'meja 4');

      expect(detail.summaryTexts(isDefaultCustomer: true), (
        customer: '',
        memo: 'meja 4',
      ));
    });

    test('the note is not trimmed on its way into the parentheses', () {
      const detail = TransactionDetail(
        customerId: 'c1',
        customerName: 'UMUM',
        customerMemo: '  meja 4  ',
      );

      expect(
        detail.summaryTexts(isDefaultCustomer: true).customer,
        'UMUM (  meja 4  )',
      );
    });
  });

  group('equality', () {
    test('two details with the same fields are the same detail', () {
      expect(_budi,
          const TransactionDetail(customerId: 'c1', customerName: 'Budi'));
    });

    test('a changed field makes a different detail', () {
      expect(_budi, isNot(_budi.copyWith(tableNumber: '12')));
    });
  });
}
