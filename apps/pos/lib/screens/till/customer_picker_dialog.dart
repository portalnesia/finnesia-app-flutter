/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pn_pos/src/pos_transaction_detail.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pn_ui/src/widgets/state_view.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/state/loadable.dart';
import 'package:pos/till/transaction_detail_controller.dart';

/// Picks the customer for the sale, in a dialog of its own.
///
/// The web app uses a combobox because a browser has no other shape for a choice from a long list.
/// A till does: the list is a separate, fixed-size surface with the search on top and rows that
/// are built as they scroll, and choosing one row is the whole interaction. Drawn inside the
/// transaction sheet instead, every customer it listed pushed the fields below it further down,
/// and a shop with hundreds of customers made those fields unreachable.
///
/// Choosing a customer, or adding one, closes the dialog; the sale already holds the result. Closing
/// it any other way leaves the customer as it was.
Future<void> showCustomerPickerDialog(
  BuildContext context, {
  required TransactionDetailController controller,
}) async {
  await showDialog<void>(
    context: context,
    builder: (context) => CustomerPickerDialog(controller: controller),
  );
  // The next opening lists everyone, not whatever the last one was searching for.
  if (controller.search.isNotEmpty) controller.setSearch('');
}

class CustomerPickerDialog extends StatefulWidget {
  const CustomerPickerDialog({super.key, required this.controller});

  final TransactionDetailController controller;

  @override
  State<CustomerPickerDialog> createState() => _CustomerPickerDialogState();
}

class _CustomerPickerDialogState extends State<CustomerPickerDialog> {
  late final _search = TextEditingController(text: widget.controller.search);

  /// True while the cashier is filling in a new customer instead of picking an existing one.
  var _creating = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _pick(TransactionDetail picked) {
    widget.controller.pickCustomer(picked);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final pn = context.pn;
    final controller = widget.controller;

    return Dialog(
      key: const Key('customer-picker'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: _creating
            ? _NewCustomer(
                controller: controller,
                onCancel: () => setState(() => _creating = false),
                onCreated: Navigator.of(context).pop,
              )
            : ListenableBuilder(
                listenable: controller,
                builder: (context, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Title(
                      text: l10n.posCustomer,
                      closeKey: const Key('customer-picker-close'),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: TextField(
                        key: const Key('customer-search'),
                        controller: _search,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: l10n.posSearchCustomer,
                          prefixIcon: const Icon(Icons.search),
                        ),
                        onChanged: controller.setSearch,
                      ),
                    ),
                    Expanded(
                      child: _Results(controller: controller, onPick: _pick),
                    ),
                    if (controller.canCreateContact)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: pn.border)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              key: const Key('add-customer'),
                              onPressed: () => setState(() => _creating = true),
                              icon: const Icon(Icons.person_add_alt),
                              // The text the cashier typed is carried over, so they retype
                              // nothing. It is also what the source does with `onCreateOption`.
                              label: Text(
                                _search.text.trim().isEmpty
                                    ? l10n.contactQuickAddTitle
                                    : l10n.posAddContactNamed(
                                        _search.text.trim(),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// The dialog's title bar, with the way out on it.
class _Title extends StatelessWidget {
  const _Title({required this.text, this.closeKey});

  final String text;
  final Key? closeKey;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return SizedBox(
      height: PnTouch.primary,
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(text, style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          IconButton(
            key: closeKey,
            onPressed: () => Navigator.of(context).pop(),
            tooltip: l10n.commonClose,
            icon: const Icon(Icons.close),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

/// What the picker's read is showing: the customers, still loading, or why there are none.
class _Results extends StatelessWidget {
  const _Results({required this.controller, required this.onPick});

  final TransactionDetailController controller;
  final ValueChanged<TransactionDetail> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final pn = context.pn;

    return switch (controller.state) {
      Loading() => StateView.loading(label: l10n.commonLoading),
      Failed(:final error) => StateView(
        title: failedReadText(error, l10n.tillDetailCustomerFailed),
        actionLabel: l10n.commonRetry,
        onAction: controller.open,
      ),
      Ready(:final data) when data.isEmpty => Center(
        child: Text(
          l10n.tillDetailCustomerNone,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium!
              .copyWith(color: pn.inkMuted),
        ),
      ),
      // Built as it scrolls: a page is up to fifty rows, and a tablet draws a dozen of them.
      Ready(:final data) => ListView.separated(
        key: const Key('customer-list'),
        itemCount: data.length,
        separatorBuilder: (_, _) => Divider(height: 1, color: pn.border),
        itemBuilder: (context, index) {
          final row = data[index];
          final isCurrent = row.customerId == controller.detail.customerId;
          return ListTile(
            key: ValueKey('customer-${row.customerId}'),
            title: Text(row.customerName ?? ''),
            selected: isCurrent,
            trailing: isCurrent ? const Icon(Icons.check) : null,
            onTap: () => onPick(row),
          );
        },
      ),
    };
  }
}

/// Adding a customer without leaving the till.
///
/// Drawn in place of the list, inside the same dialog: the customer is picked the moment it is
/// saved, so there is nothing to come back to.
class _NewCustomer extends StatefulWidget {
  const _NewCustomer({
    required this.controller,
    required this.onCancel,
    required this.onCreated,
  });

  final TransactionDetailController controller;
  final VoidCallback onCancel;
  final VoidCallback onCreated;

  @override
  State<_NewCustomer> createState() => _NewCustomerState();
}

class _NewCustomerState extends State<_NewCustomer> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _company = TextEditingController();
  final _address = TextEditingController();

  var _saving = false;
  String? _problem;

  @override
  void initState() {
    super.initState();
    // What the cashier typed into the picker, so they retype nothing.
    _name.text = widget.controller.search.trim();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _company.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final l10n = L10n.of(context);
    setState(() {
      _saving = true;
      _problem = null;
    });

    final outcome = await widget.controller.create(
      name: _name.text,
      phone: _phone.text,
      email: _email.text,
      companyName: _company.text,
      address: _address.text,
    );
    if (!mounted) return;

    switch (outcome) {
      case CreateContactOk(:final contact):
        // Picked straight away: the cashier made this customer to use them, and making them find
        // the name they just typed would be a strange way to finish.
        widget.controller.pickCustomer(
          TransactionDetail(customerId: contact.id, customerName: contact.name),
        );
        widget.onCreated();
      case CreateContactInvalid():
        setState(() {
          _saving = false;
          _problem = l10n.tillDetailNameRequired;
        });
      case CreateContactRejected(:final message):
        setState(() {
          _saving = false;
          _problem = message;
        });
      case CreateContactUnavailable():
        setState(() {
          _saving = false;
          _problem = l10n.tillDetailCreateNoAnswer;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final problem = _problem;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Title(text: l10n.contactQuickAddTitle),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (problem != null) ...[
                  Text(
                    problem,
                    style: Theme.of(context).textTheme.bodyMedium!
                        .copyWith(color: context.pn.errorText),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  key: const Key('new-customer-name'),
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.contactNameLabel,
                    hintText: l10n.contactNamePlaceholder,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l10n.contactPhoneLabel,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: l10n.contactEmailLabel,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _company,
                  decoration: InputDecoration(
                    labelText: l10n.contactCompanyLabel,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _address,
                  minLines: 2,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.contactAddressLabel,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: PnTouch.min,
                        child: OutlinedButton(
                          onPressed: _saving ? null : widget.onCancel,
                          child: Text(l10n.commonCancel),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: PnTouch.min,
                        child: FilledButton(
                          key: const Key('save-customer'),
                          onPressed: _saving ? null : _save,
                          child: Text(
                            _saving ? l10n.commonSaving : l10n.commonSave,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
