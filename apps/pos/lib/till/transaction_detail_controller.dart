/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pn_pos/src/pos_transaction_detail.dart';
import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/api/endpoints/master.dart';
import 'package:pn_types/src/api/endpoints/pos.dart';
import 'package:pn_types/src/master_data.dart';
import 'package:pn_types/src/pos.dart';
import 'package:pos/state/loadable.dart';
import 'package:pos/till/quick_create.dart';

/// One page of the customer picker. The server does the searching, so a shop with more customers
/// than fit on a screen can still find the one standing at the till.
const _pageSize = 50;

/// The transaction detail being filled in, and the customer picker it is filled from.
///
/// There is no object to port: the detail and the picker's two reads are one component's state
/// in a page. It is a controller here because the till's summary row reads the detail while the
/// sheet edits it, and because the picker's reads are worth testing without a widget.
///
/// **It does not decide what the sale is attributed to.** The server owns that: when the till
/// sends no customer it falls back to the company's `default_customer_id`, and refuses the sale
/// with `pos_customer_required` when there is no default either (`pos_service.go:1506-1513`).
/// What this controller adds is the part the cashier needs to *see*: the default is attached to
/// the detail so the row can name it, instead of the row claiming there is no customer on a sale
/// that has one.
class TransactionDetailController extends ChangeNotifier with RequestGuard {
  TransactionDetailController({
    required this.client,
    required this.outletId,

    /// From `POSPreferences`: a dine-in outlet shows a table number, a queue one does not.
    this.showTableNumber = false,
    this.showQueueNumber = false,

    /// Whether the company auto-numbers the queue. The field is drawn from [showQueueNumber];
    /// this is what asks the server for a number to put in it.
    this.queueNumberAuto = false,

    /// Whether the cashier may create a customer at all.
    ///
    /// `POST /pos/customers` needs `pos.quick_create` or `master.contact.manage`
    /// (`canQuickAddCustomer`). Asked of the caller rather than decided here, because the answer
    /// comes from the permission list the caller reads. Defaults to allowed: a caller that has
    /// not worked it out is not the same as one that has said no.
    this._canCreateContact = true,

    /// The company's `default_customer_id`, when it has one.
    ///
    /// Attached at once, before any read, because the till's summary row is drawn whether or not
    /// this sheet is ever opened. The **name** comes from the picker's list once it arrives: a
    /// name is worth having for the row, and is not worth a request of its own.
    this.defaultCustomerId,

    /// How long the search text has to sit still before the server is asked. The tablet's
    /// keyboard types a letter at a time, and a request per letter is what N+1 looks like from
    /// the UI (`optimization.md` §6.1).
    this.debounce = const Duration(milliseconds: 300),
  }) {
    _detail = _freshDetail();
  }

  final ApiClient client;

  /// The outlet this till sells from. Stock, queue numbers and customers are all per tenant,
  /// but the queue number is per outlet.
  final String outletId;

  final bool showTableNumber;
  final bool showQueueNumber;
  final bool queueNumberAuto;
  final Duration debounce;
  final String? defaultCustomerId;

  bool _canCreateContact;
  TransactionDetail _detail = TransactionDetail.empty;
  LoadState<List<TransactionDetail>> _state = const Loading();
  String _search = '';

  /// The trimmed text the list on screen was asked for. Apart from [_search] so that a trailing
  /// space, which changes the field and nothing else, is not a new request.
  String _applied = '';
  String? _queuePlaceholder;

  /// The default customer's name, once either read has found it. Kept apart from [_detail]
  /// because [reset] rebuilds that.
  String? _defaultName;
  Timer? _debounceTimer;
  bool _opened = false;
  bool _disposed = false;
  final _creating = QuickCreateRunner<Contact>();

  /// Whether the picker offers "Add customer".
  bool get canCreateContact => _canCreateContact;

  /// Changed by the caller once it knows: the till reads the cashier's permissions after this
  /// controller is built, and the picker is drawn from this answer.
  set canCreateContact(bool value) {
    if (value == _canCreateContact) return;
    _canCreateContact = value;
    notifyListeners();
  }

  /// What the cashier has filled in so far. Read by the till's summary row as well as by the
  /// sheet, which is why it lives here and not in the sheet's own state.
  TransactionDetail get detail => _detail;

  /// The customers the picker can offer: still loading, the page, or why there is none.
  LoadState<List<TransactionDetail>> get state => _state;

  /// The next queue number the server would assign, for the field's placeholder. Null when the
  /// company does not auto-number, or when the number could not be read.
  String? get queuePlaceholder => _queuePlaceholder;

  /// What is in the picker's search field, as typed.
  String get search => _search;

  /// Reads the company's default customer by id, to put a name on the row.
  ///
  /// The default is attached by id at once (`_freshDetail`), and the row is drawn from the first
  /// frame, so without this it read "Pelanggan: Pelanggan" until the sheet had been opened and
  /// the picker's list arrived. By id rather than from that list because the list is one page of
  /// fifty, and the default is not promised to be on it.
  ///
  /// A failure leaves the customer attached and unnamed: the id is what the sale carries, the
  /// name is only for the row.
  Future<void> loadDefault() async {
    final id = defaultCustomerId;
    if (id == null || id.isEmpty) return;
    final name = await _readName(id);
    if (name == null) return;
    _defaultName = name;
    _applyName(id, name);
  }

  /// The name of customer [id], or null when it could not be read (which is not an error here:
  /// the id is what the sale carries, and the name is only for the row).
  Future<String?> _readName(String id) async {
    final Contact contact;
    try {
      contact = await MasterApi.contactsGet(client, (id: id));
    } on Object catch (error) {
      if (!isServerOrNetworkFailure(error)) rethrow;
      return null;
    }
    return contact.name;
  }

  /// Puts [name] on the sale, only while [id] is still the customer on it: the cashier may have
  /// picked someone else while the read was on the wire.
  void _applyName(String id, String name) {
    if (_disposed || _detail.customerId != id) return;
    _detail = _detail.copyWith(customerName: name);
    notifyListeners();
  }

  /// Reads the picker's first page, once.
  ///
  /// Called when the sheet opens. Opening again does nothing, and a first attempt that failed is
  /// retried: the flag is set on success, not on the attempt.
  Future<void> open() async {
    if (_opened) return;
    await _readContacts();
    if (_state is! Ready) return;
    _opened = true;

    if (!(showQueueNumber && queueNumberAuto)) return;
    try {
      _queuePlaceholder = await PosApi.queueNext(
        client,
        query: {'outlet_id': outletId},
      );
    } on Object catch (error) {
      // A queue number that could not be read must not take the customer list with it: the two
      // are separate reads, and attaching a customer is still worth doing without a number.
      _queuePlaceholder = null;
      if (!isServerOrNetworkFailure(error)) rethrow;
    }
    _fillQueueNumber();
    notifyListeners();
  }

  /// Records what the cashier typed, and asks the server once they stop.
  void setSearch(String text) {
    _search = text;
    notifyListeners();
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () {
      final wanted = text.trim();
      if (_disposed || wanted == _applied) return;
      _applied = wanted;
      _readContacts();
    });
  }

  /// Picks [picked] as the sale's customer, or clears it when its id is empty.
  void pickCustomer(TransactionDetail picked) {
    _detail = _detail.withCustomer(
      id: picked.customerId,
      name: picked.customerName,
    );
    notifyListeners();
  }

  void setMemo(String memo) {
    _detail = _detail.copyWith(customerMemo: memo);
    notifyListeners();
  }

  void setTableNumber(String number) {
    _detail = _detail.copyWith(tableNumber: number);
    notifyListeners();
  }

  void setQueueNumber(String number) {
    _detail = _detail.copyWith(queueNumber: number);
    notifyListeners();
  }

  /// Puts back what a held basket carried, and names the customer.
  ///
  /// The basket holds the customer's id and not their name, so the customer is attached at once
  /// with the name unknown (`''`, which is not `null`: see [TransactionDetail.shownCustomerName])
  /// and named when the read by id comes back.
  Future<void> restore(TransactionDetail held) async {
    _detail = held.copyWith(customerName: held.customerId.isEmpty ? null : '');
    notifyListeners();
    if (held.customerId.isEmpty) return;
    final name = await _readName(held.customerId);
    if (name != null) _applyName(held.customerId, name);
  }

  /// Back to nothing filled in, for the next sale. The company's default customer is attached
  /// again: a fresh sale belongs to the same default as the one before it.
  void reset() {
    _detail = _freshDetail();
    _search = '';
    _applied = '';
    _debounceTimer?.cancel();
    notifyListeners();
  }

  /// Adds a customer from the till, without leaving it, and offers it at the top of the list.
  ///
  /// Name, phone and email only: the three things a cashier can ask across the counter, and all
  /// `POST /pos/customers` takes. Terms, accounts and addresses stay on the contact page. A name
  /// of nothing but spaces is refused here, before it leaves; one create goes out at a time
  /// ([QuickCreateRunner]).
  Future<QuickCreateOutcome<Contact>> create({
    required String name,
    required String phone,
    required String email,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return const QuickCreateInvalid();

    final outcome = await _creating.run(
      () => PosApi.customersCreate(
        client,
        POSQuickCustomerDTO(
          name: trimmed,
          phone: orAbsent(phone),
          email: orAbsent(email),
        ),
      ),
    );
    if (outcome case QuickCreateOk(:final created)) {
      _offer(
        TransactionDetail(customerId: created.id, customerName: created.name),
      );
    }
    return outcome;
  }

  /// Reads the picker's page for whatever is in the search field now.
  Future<void> _readContacts() async {
    final request = startRequest();
    final shown = _state;
    if (shown is Ready<List<TransactionDetail>>) {
      // The list already on screen stays while the next one is on its way: clearing it would
      // make the picker blink empty on every letter.
      _state = Ready(shown.data, refreshing: true);
      notifyListeners();
    }
    try {
      final contacts = await MasterApi.contactsList(
        client,
        query: {
          'type': ContactType.customer.wire,
          'page_size': _pageSize,
          // An empty `q` would be a LIKE on nothing.
          if (_applied.isNotEmpty) 'q': _applied,
        },
      );
      if (!isCurrent(request)) return;
      _state = Ready([
        for (final contact in contacts)
          TransactionDetail(customerId: contact.id, customerName: contact.name),
      ]);
      _fillCustomerName();
    } on Object catch (error) {
      if (isCurrent(request)) _state = Failed(error);
      if (!isServerOrNetworkFailure(error)) rethrow;
    }
    if (_disposed) return;
    notifyListeners();
  }

  /// Puts [created] at the top of the picker's list, once.
  ///
  /// The cashier has just made this customer and wants to pick them; making them search for the
  /// name they just typed would be a strange way to finish the job.
  void _offer(TransactionDetail created) {
    final current = _state;
    final rows = current is Ready<List<TransactionDetail>>
        ? current.data
        : const <TransactionDetail>[];
    _state = Ready([
      created,
      for (final row in rows)
        if (row.customerId != created.customerId) row,
    ]);
    notifyListeners();
  }

  /// Fills in the name for a customer that is attached without one.
  ///
  /// The company's default customer is attached by id alone, because its name would otherwise
  /// cost a request of its own for a row that is usually read and never opened. Once the picker's
  /// list is in hand the name is there for free.
  void _fillCustomerName() {
    if (_detail.customerId.isEmpty) return;
    final name = _detail.customerName;
    if (name != null && name.isNotEmpty) return;
    final rows = switch (_state) {
      Ready(:final data) => data,
      _ => const <TransactionDetail>[],
    };
    for (final row in rows) {
      if (row.customerId == _detail.customerId) {
        _detail = _detail.copyWith(customerName: row.customerName);
        if (row.customerId == defaultCustomerId) {
          _defaultName = row.customerName;
        }
        return;
      }
    }
  }

  /// Puts the server's next queue number in the field, when the cashier has not filled it in.
  void _fillQueueNumber() {
    final number = _queuePlaceholder;
    if (number == null || number.isEmpty) return;
    if (_detail.queueNumber.isNotEmpty) return;
    _detail = _detail.copyWith(queueNumber: number);
  }

  /// A detail for a fresh sale: nothing filled in, with the company's default customer on it.
  TransactionDetail _freshDetail() {
    final id = defaultCustomerId;
    if (id == null || id.isEmpty) return TransactionDetail.empty;
    // The name once it is known, so the sale after this one starts with it and the row does not
    // go back to "Pelanggan" for want of a second request.
    return TransactionDetail(customerId: id, customerName: _defaultName);
  }

  @override
  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    super.dispose();
  }
}
