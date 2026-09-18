/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pn_pos/src/format.dart';
import 'package:pn_pos/src/pos_cart.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pn_ui/src/widgets/ledger_row.dart';
import 'package:pn_ui/src/widgets/money_text.dart';
import 'package:pn_ui/src/widgets/top_notice.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/screens/till/transaction_detail_sheet.dart';
import 'package:pos/till/cart_controller.dart';
import 'package:pos/till/transaction_detail_controller.dart';

/// What is in the basket, and what it comes to.
///
/// [onPay] is the way to the payment screen. It is null while the basket is empty, and the
/// button is then not drawn at all rather than drawn disabled: a cashier cannot pay for nothing,
/// and a greyed button on an empty cart is a control that never does anything (R-26).
///
/// [onHold] parks the basket in the store that survives a restart, and is absent for the same
/// reason.
class CartPane extends StatelessWidget {
  const CartPane({
    super.key,
    required this.cart,
    required this.detail,
    this.onPay,
    this.onHold,
  });

  final CartController cart;

  /// Who the sale is for. Drawn as one row above the lines, always the same height, so the
  /// cashier can see a customer is attached without the fields pushing the goods off the
  /// screen (`cart-panel.tsx`).
  final TransactionDetailController detail;

  /// Opens the payment screen. Null when the caller has no payment screen to open.
  final VoidCallback? onPay;

  /// Parks the basket. Absent while the basket is empty, like Pay: there is nothing to park.
  final VoidCallback? onHold;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: Listenable.merge([cart, detail]),
      builder: (context, _) {
        final lines = cart.lines;
        final totals = cart.totals;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.tillItemCount(cart.itemCount.toInt()),
                      style: theme.titleMedium,
                    ),
                  ),
                  if (lines.isNotEmpty)
                    TextButton(
                      onPressed: () => _confirmClear(context),
                      child: Text(l10n.tillClearCart),
                    ),
                ],
              ),
            ),
            TransactionDetailRow(
              detail: detail.detail,
              // The note is folded into the customer's parentheses for the company's nominated
              // walk-in, and stands on its own row for anyone else.
              isDefaultCustomer: _isDefaultCustomer(detail),
              showTableNumber: detail.showTableNumber,
              showQueueNumber: detail.showQueueNumber,
              onOpen: () =>
                  showTransactionDetailSheet(context, controller: detail),
            ),
            Expanded(
              child: lines.isEmpty
                  ? _Empty()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: lines.length,
                      itemBuilder: (context, i) => CartLineTile(
                        key: ValueKey(lines[i].id),
                        line: lines[i],
                        cart: cart,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  LedgerRow(
                    label: l10n.tillSubtotal,
                    value: formatCurrency(totals.subtotal),
                  ),
                  if (totals.discount > 0)
                    LedgerRow(
                      label: l10n.tillDiscount,
                      value: '-${formatCurrency(totals.discount)}',
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(l10n.tillTotal, style: theme.titleLarge),
                      ),
                      Expanded(
                        flex: 2,
                        child: MoneyText(
                          key: const Key('cart-total'),
                          formatCurrency(totals.grandTotal),
                          style: theme.headlineMedium,
                        ),
                      ),
                    ],
                  ),
                  // The one action this screen exists for, and the only amber on it.
                  if (onPay != null && lines.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (onHold != null) ...[
                          Expanded(
                            child: SizedBox(
                              height: PnTouch.primary,
                              child: OutlinedButton(
                                key: const Key('hold'),
                                onPressed: onHold,
                                child: Text(l10n.tillHold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: PnTouch.primary,
                            child: FilledButton(
                              key: const Key('pay'),
                              onPressed: onPay,
                              child: Text(l10n.posPay),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final l10n = L10n.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.tillClearTitle),
        content: Text(l10n.tillClearDesc),
        actions: [
          // Destructive, so it is the filled one and Cancel is the quiet one: the safe choice
          // should be the easier one to hit.
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.tillClearCart),
          ),
        ],
      ),
    );
    if (confirmed == true) cart.clear();
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.tillCartEmpty, style: theme.titleMedium),
            const SizedBox(height: 4),
            Text(
              l10n.tillCartEmptyDesc,
              style: theme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Whether the customer on the sale is the company's nominated walk-in.
///
/// Compared by id against the preference the till was given, not by name: the name is a label a
/// tenant can change, and two customers can share one.
bool _isDefaultCustomer(TransactionDetailController controller) {
  final id = controller.defaultCustomerId;
  return id != null && id.isNotEmpty && controller.detail.customerId == id;
}

/// One row of the basket.
///
/// Two lines, so it fits a phone: the name and what the row comes to, then the unit price and
/// the controls.
///
/// A change to one row rebuilds the rows that are on screen, not only that one: a widget cannot
/// be made to skip a rebuild by overriding `==` (Flutter forbids it), and the list is lazy, so
/// what is rebuilt is what is visible. The catalogue, which is the expensive part, is not
/// (`plan/ui/findings.md` F32).
class CartLineTile extends StatelessWidget {
  const CartLineTile({super.key, required this.line, required this.cart});

  final CartLine line;
  final CartController cart;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context).textTheme;
    final pn = context.pn;
    final name = line.product.name;
    final price = line.product.sellPrice ?? 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: pn.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(name, style: theme.titleSmall)),
                const SizedBox(width: 12),
                MoneyText(
                  formatCurrency(line.qty * price),
                  style: theme.titleSmall,
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    formatCurrency(price),
                    style: theme.bodySmall!.copyWith(color: pn.inkMuted),
                  ),
                ),
                IconButton(
                  tooltip: l10n.tillQtyLess(name),
                  icon: const Icon(Icons.remove),
                  onPressed: () => cart.setQty(line.id, line.qty - 1),
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    '${line.qty}',
                    textAlign: TextAlign.center,
                    style: theme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: l10n.tillQtyMore(name),
                  icon: const Icon(Icons.add),
                  onPressed: () => cart.setQty(line.id, line.qty + 1),
                ),
                IconButton(
                  tooltip: l10n.tillRemoveLine(name),
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => removeWithUndo(context, cart, line),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Removes [line] and offers to put it back for a few seconds: a slipped thumb costs a tap, not
/// a rescan. Swiping is not the way to remove (a gesture must never be the only way, R-32); this
/// button is.
///
/// The notice goes to the top of the screen (`showTopNotice`), not to the bottom where a
/// `SnackBar` would sit: the bottom of this pane is the Pay button, and a cashier who removes a
/// line and then wants to pay must not have to wait out a message they did not ask for.
void removeWithUndo(BuildContext context, CartController cart, CartLine line) {
  final l10n = L10n.of(context);
  cart.remove(line.id);
  showTopNotice(
    context,
    message: l10n.tillLineRemoved(line.product.name),
    actionLabel: l10n.tillUndo,
    onAction: cart.undoRemove,
  );
}
