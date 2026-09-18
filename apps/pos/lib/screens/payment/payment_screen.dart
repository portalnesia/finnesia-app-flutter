/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pn_pos/src/datetime.dart';
import 'package:pn_pos/src/format.dart';
import 'package:pn_pos/src/pos_cart.dart';
import 'package:pn_pos/src/pos_checkout.dart';
import 'package:pn_pos/src/pos_pending_sale.dart';
import 'package:pn_pos/src/pos_pending_sale_store.dart';
import 'package:pn_pos/src/pos_tender.dart';
import 'package:pn_pos/src/pos_transaction_detail.dart';
import 'package:pn_types/src/pos.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pn_ui/src/widgets/keypad.dart';
import 'package:pn_ui/src/widgets/keypad_shortcuts.dart';
import 'package:pn_ui/src/widgets/ledger_row.dart';
import 'package:pn_ui/src/widgets/money_text.dart';
import 'package:pos/checkout/checkout_service.dart';
import 'package:pos/checkout/payment_controller.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/screens/common/tender_label.dart';

/// S6: taking the money.
///
/// A whole screen, not a dialog over the catalogue: the cashier is counting notes and reading a
/// figure, and the web app's dialog covers the thing they were looking at.
///
/// The rules are `pn_pos`'s and the state is [PaymentController]'s. What is here is the layout
/// and the keypad: the tablet's own keyboard never opens over an amount (`plan/ui/README.md`
/// §1), which is why [Keypad] is in the screen rather than a `TextField`.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.grandTotal,
    required this.lines,
    required this.shiftId,
    required this.outletId,
    required this.companyId,
    required this.cashierId,
    required this.onCancel,
    required this.submit,
    this.detail = TransactionDetail.empty,
    this.transactionDate,
    this.outletName,
    this.cashierName,
    this.onSent,
    this.onDone,
  });

  final num grandTotal;

  /// The basket, for the payload. The screen does not edit it: by the time money is being
  /// taken, what is being sold is settled.
  final List<CartLine> lines;

  /// Who the sale is for, and what the floor or the kitchen needs to know about it. Settled
  /// before this screen is opened (S8), and only carried through here.
  final TransactionDetail detail;

  /// Null when the company runs without shifts; the server then owns the shift.
  final String? shiftId;
  final String outletId;

  /// The tenant, and **who is ringing this sale up**.
  ///
  /// The cashier id is written into the queue entry and never sent: the server attributes a sale
  /// to whoever is authenticated when it arrives, so this column is the only record of who
  /// actually took the money (`plan/offline-queue/findings.md` F4, D-Q1).
  final String companyId;
  final String cashierId;

  /// The outlet's and the cashier's names, for the **temporary** receipt: a sale that has not
  /// been sent has no server record to print from, and neither name is a checkout field
  /// (`plan/offline-queue/README.md` §4.2).
  ///
  /// Optional: neither is needed to print, and neither is a reason to hold up a sale — the same
  /// call `print_receipt.dart` makes for a recorded sale.
  final String? outletName;
  final String? cashierName;

  /// The calendar day the sale belongs to, `YYYY-MM-DD`.
  ///
  /// Injected for the same reason `now` is elsewhere: a test that built a payload on the wall
  /// clock would produce a different sale every day it ran, and a date is not something to
  /// discover by reading the device at the last moment. Defaults to [localToday] in the
  /// tablet's own zone, which is what the till passes.
  final String? transactionDate;

  final VoidCallback onCancel;

  /// `CheckoutService.submit`, injected so the screen can be tested without a network.
  ///
  /// Takes the entry builder as well as the basket: the row the queue writes needs the lines and
  /// the tenders, and this screen is where both are known.
  final Future<CheckoutOutcome> Function(
    POSCheckoutDTO payload, {
    required PendingSale Function(String clientRef) entry,
  })
  submit;

  /// Called when a request has gone out, before its answer. The till uses it to know a sale
  /// may be in flight.
  final void Function(POSCheckoutDTO payload)? onSent;

  /// Called when the sale was recorded, just before this screen pops with the same outcome.
  ///
  /// A refusal does not call it, and neither does a queued sale: the till must not treat a sale
  /// that is still only on this tablet as recorded.
  final void Function(CheckoutOutcome outcome)? onDone;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final PaymentController _controller = PaymentController(
    grandTotal: widget.grandTotal,
  );

  /// The row the keypad is typing into.
  late String _editing = _controller.tenders.first.id;

  /// Digits typed for the row being edited, as a string. Kept as text rather than a number so
  /// a trailing `0` is not swallowed while the cashier is still typing.
  var _digits = '';

  /// A refusal from the server, shown until the cashier changes something.
  String? _refusal;

  /// The queue could not even be written to, shown until the cashier changes something.
  ///
  /// Not a checkout outcome: `CheckoutService` never sent anything — the write it does *before*
  /// sending failed, so nothing about the sale is known to the server or the queue
  /// (`plan/offline-queue/README.md` §3). The cashier must not hand over goods for money that
  /// is recorded nowhere at all.
  bool _writeFailed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  TenderDraft get _row =>
      _controller.tenders.firstWhere((t) => t.id == _editing);

  /// What the keypad is showing: the digits typed so far, or the row's amount when nothing has
  /// been typed yet.
  num get _shown => _digits.isEmpty ? _row.amount : num.parse(_digits);

  void _onDigit(String digit) {
    // Leading zeros are not money: `00` after nothing is nothing.
    final next = _digits.isEmpty && digit == '0' ? '' : '$_digits$digit';
    setState(() {
      _digits = next;
      // A refusal was about the amount that was sent; changing it means trying something else.
      _refusal = null;
      _writeFailed = false;
    });
    _controller.setAmount(_editing, next.isEmpty ? 0 : num.parse(next));
  }

  void _onBackspace() {
    if (_digits.isEmpty) return;
    setState(() {
      _digits = _digits.substring(0, _digits.length - 1);
      _refusal = null;
      _writeFailed = false;
    });
    _controller.setAmount(_editing, _digits.isEmpty ? 0 : num.parse(_digits));
  }

  void _edit(String id) {
    setState(() {
      _editing = id;
      // Empty, so the keypad shows this row's own amount rather than the digits typed for
      // the row before it.
      _digits = '';
    });
  }

  /// Puts a suggested amount on the row being edited: the quick amounts, or the exact total.
  void _suggest(num amount) {
    setState(() {
      _digits = '';
      _refusal = null;
      _writeFailed = false;
    });
    _controller.setAmount(_editing, amount);
  }

  /// Sends the sale.
  ///
  /// **The double-tap guard is `_controller.canConfirm` and nothing else.** `submit` sets
  /// `isPaying` before it awaits, so the button is rebuilt disabled in the same frame the first
  /// tap lands in, and a second tap finds nothing to press. Measured, not assumed: removing
  /// every other guard leaves the test green, and removing this one turns it red.
  ///
  /// A guard written inside this method would be unreachable — the button is already disabled
  /// by the time it could run — and unreachable code that looks like a guard is worse than
  /// none, because it invites the next reader to trust a check that never executes.
  Future<void> _confirm() async {
    final built = _controller.buildTenders();
    if (built is! TenderBuildOk) return;

    final payload = buildCheckoutPayload(
      shiftId: widget.shiftId,
      outletId: widget.outletId,
      customerId: widget.detail.customerId,
      notes: widget.detail.customerMemo,
      tableNumber: widget.detail.tableNumber,
      queueNumber: widget.detail.queueNumber,
      discountAmount: 0,
      // The day the till is running in, in the tablet's own zone: the server validates
      // `transaction_date` against the shift it resolves.
      transactionDate: widget.transactionDate ?? localToday(),
      lines: widget.lines,
      payments: built.tenders,
    );
    widget.onSent?.call(payload);

    final CheckoutOutcome outcome;
    try {
      outcome = await _controller.submit(
        submit: (payload) => widget.submit(
          payload,
          // The row the queue writes for this sale. Built here because the lines and the
          // tenders are this screen's: `CheckoutService` only knows the basket.
          entry: (ref) => buildPendingSale(
            clientRef: ref,
            companyId: widget.companyId,
            outletId: widget.outletId,
            cashierId: widget.cashierId,
            shiftId: widget.shiftId,
            transactionDate: widget.transactionDate ?? localToday(),
            lines: widget.lines,
            payments: built.tenders,
            customerId: widget.detail.customerId,
            notes: widget.detail.customerMemo,
            tableNumber: widget.detail.tableNumber,
            queueNumber: widget.detail.queueNumber,
            discountAmount: 0,
            outletName: widget.outletName,
            cashierName: widget.cashierName,
          ),
        ),
        payload: payload,
      );
    } on PendingSaleStoreException {
      // The write `CheckoutService` does *before* it ever sends anything failed: no request
      // went out, and nothing about this sale exists anywhere but the cashier's hands. `submit`
      // has already reset `isPaying` in its `finally`, so the button is usable again on its own;
      // this only has to say why, and to keep it said until the cashier changes something.
      if (mounted) setState(() => _writeFailed = true);
      return;
    } on Object {
      // Anything else is a bug, not an answer: it stays loud for the caller to see.
      rethrow;
    }

    if (!mounted) return;
    switch (outcome) {
      case CheckoutSynced():
        // The sale is recorded, so this screen is done: it pops with the outcome and the till
        // shows S7. Popping here rather than leaving it to `onDone` is what makes the await in
        // `TillScreen._pay` finish at all — a screen that stayed put after a recorded sale
        // would leave the till waiting forever and the cashier looking at a payment form for a
        // sale that is already in the books.
        widget.onDone?.call(outcome);
        Navigator.of(context).pop(outcome);
      case CheckoutRejected(:final message):
        // The server's own sentence, unchanged: what to fix is often something only it
        // knows, and the cashier cannot fix an unmapped account themselves (F14).
        setState(() => _refusal = message);
      case CheckoutQueued():
        // The sale is written down and will be sent again, so the cashier is done: they must
        // not be left holding a customer while a queue drains. The screen goes to S7 in its
        // "not sent yet" form, which prints the temporary receipt and shows the change the app
        // worked out (`plan/offline-queue/README.md` §7, D-Q3).
        //
        // `onDone` is not called: the till must **not** treat this as a recorded sale.
        Navigator.of(context).pop(outcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final problem = _controller.problem;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: l10n.commonCancel,
          onPressed: _controller.isPaying ? null : widget.onCancel,
        ),
        title: Text(l10n.posPayment),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => LayoutBuilder(
            builder: (context, constraints) {
              // Two columns from 840 dp: the figures beside the keypad. Below that the keypad
              // is the thing the cashier is using, so it gets the bottom of the screen and the
              // figures scroll above it.
              final wide = constraints.maxWidth >= 840;
              final figures = _Figures(
                controller: _controller,
                editing: _editing,
                onEdit: _edit,
                onSuggest: _suggest,
                problem: problem,
                refusal: _refusal,
                writeFailed: _writeFailed,
                shown: _shown,
              );
              final pad = KeypadShortcuts(
                onDigit: _onDigit,
                onBackspace: _onBackspace,
                onSubmit: _controller.canConfirm ? _confirm : null,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Keypad(
                    onDigit: _onDigit,
                    onBackspace: _onBackspace,
                    backspaceLabel: l10n.commonDelete,
                    enabled: !_controller.isPaying,
                  ),
                ),
              );

              return Column(
                children: [
                  Expanded(
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(16),
                                  child: figures,
                                ),
                              ),
                              SizedBox(
                                width: 360,
                                child: SingleChildScrollView(child: pad),
                              ),
                            ],
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: figures,
                          ),
                  ),
                  if (!wide) pad,
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: PnTouch.primary,
                      child: FilledButton(
                        key: const Key('confirm-payment'),
                        onPressed: _controller.canConfirm ? _confirm : null,
                        child: _controller.isPaying
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(l10n.posPaying),
                                ],
                              )
                            : Text(l10n.posConfirmPayment),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The money: what is being paid, with what, and what is still owed.
class _Figures extends StatelessWidget {
  const _Figures({
    required this.controller,
    required this.editing,
    required this.onEdit,
    required this.onSuggest,
    required this.problem,
    required this.refusal,
    required this.writeFailed,
    required this.shown,
  });

  final PaymentController controller;
  final String editing;
  final ValueChanged<String> onEdit;
  final ValueChanged<num> onSuggest;
  final TenderProblem? problem;
  final String? refusal;
  final bool writeFailed;
  final num shown;

  /// Amounts a cashier reaches for most: round notes, and the ones a 15.000 bill is paid with.
  static const _quick = [10_000, 20_000, 50_000, 100_000];

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context).textTheme;
    final pn = context.pn;
    final summary = controller.summary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The bill first, and large: it is the number the cashier reads out.
        Text(l10n.posGrandTotal, style: theme.bodySmall),
        MoneyText(
          formatCurrency(controller.grandTotal),
          style: theme.headlineMedium,
          key: const Key('grand-total'),
        ),
        const SizedBox(height: 16),

        for (final row in controller.tenders)
          _TenderRow(
            row: row,
            isEditing: row.id == editing,
            shown: row.id == editing ? shown : row.amount,
            canRemove: controller.tenders.length > 1,
            onTap: () => onEdit(row.id),
            onMethod: (m) => controller.setMethod(row.id, m),
            onReference: (r) => controller.setReference(row.id, r),
            onRemove: () => controller.removeRow(row.id),
          ),

        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: controller.addRow,
            icon: const Icon(Icons.add),
            label: Text(l10n.posAddTender),
          ),
        ),

        // Quick amounts and the exact total, for the row the keypad is on. Only cash: a
        // transfer settles exactly what is left, and guessing above it is never right.
        if (isCashTender(
          controller.tenders.firstWhere((t) => t.id == editing).method,
        ))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final amount in _quick)
                  OutlinedButton(
                    onPressed: () => onSuggest(amount),
                    child: Text(formatCurrency(amount)),
                  ),
                OutlinedButton(
                  onPressed: () => controller.fillExact(editing),
                  child: Text(l10n.posExactAmount),
                ),
              ],
            ),
          ),

        const Divider(),

        // The ledger: paid, and then either what is left or what is owed back.
        LedgerRow(
          label: l10n.posPaidAmount,
          value: formatCurrency(summary.paid),
        ),
        if (summary.remaining > 0)
          LedgerRow(
            label: l10n.posRemaining,
            value: formatCurrency(summary.remaining),
            emphasized: true,
          )
        else
          LedgerRow(
            label: l10n.posChangeDue,
            value: formatCurrency(summary.change),
            emphasized: true,
          ),

        // Why the button is not usable, in words. A button that refuses without saying why
        // leaves the cashier to guess what is wrong with the money in their hand.
        if (problem != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(switch (problem!) {
              TenderProblem.insufficient => l10n.posInsufficientCash,
              TenderProblem.overpaidNonCash => l10n.posTenderOverpaidNonCash,
              TenderProblem.emptyCart => l10n.posTenderEmptyCart,
            }, style: theme.bodySmall!.copyWith(color: pn.errorText)),
          ),

        if (refusal != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              refusal!,
              key: const Key('checkout-refusal'),
              style: theme.bodySmall!.copyWith(color: pn.errorText),
            ),
          ),

        if (writeFailed)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            // A live region: this appears without the cashier tapping anything that would
            // normally draw a screen reader's attention to it, and it is the one message here
            // that says outright not to hand over the goods.
            child: Semantics(
              liveRegion: true,
              child: Text(
                l10n.posCheckoutStorageFailed,
                key: const Key('checkout-write-failed'),
                style: theme.bodySmall!.copyWith(color: pn.errorText),
              ),
            ),
          ),
      ],
    );
  }
}

/// One payment row: how it was paid, how much, and the memo a non-cash row needs.
class _TenderRow extends StatelessWidget {
  const _TenderRow({
    required this.row,
    required this.isEditing,
    required this.shown,
    required this.canRemove,
    required this.onTap,
    required this.onMethod,
    required this.onReference,
    required this.onRemove,
  });

  final TenderDraft row;
  final bool isEditing;
  final num shown;
  final bool canRemove;
  final VoidCallback onTap;
  final ValueChanged<POSTenderMethod> onMethod;
  final ValueChanged<String> onReference;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context).textTheme;
    final pn = context.pn;
    final cash = isCashTender(row.method);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            // The row the keypad is typing into, marked by ink rather than by colour: the
            // one accent on this screen is the confirm button.
            color: isEditing ? pn.ink : pn.border,
            width: isEditing ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(PnRadius.control),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final method in posTenderMethods)
                    OutlinedButton(
                      onPressed: () => onMethod(method),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: row.method == method
                            ? pn.surfaceMuted
                            : null,
                      ),
                      child: Text(tenderMethodLabel(l10n, method.wire)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              InkWell(
                key: const Key('tender-amount'),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          cash ? l10n.posCashTendered : l10n.posTenderAmount,
                          style: theme.bodySmall,
                        ),
                      ),
                      MoneyText(formatCurrency(shown), style: theme.titleLarge),
                    ],
                  ),
                ),
              ),
              if (!cash)
                TextField(
                  decoration: InputDecoration(
                    labelText: l10n.posTenderReference,
                  ),
                  onChanged: onReference,
                  controller: TextEditingController(text: row.reference ?? '')
                    ..selection = TextSelection.collapsed(
                      offset: (row.reference ?? '').length,
                    ),
                ),
              if (canRemove)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l10n.posRemoveTender),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
