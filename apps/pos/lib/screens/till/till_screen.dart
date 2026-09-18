/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pn_pos/src/format.dart';
import 'package:pn_pos/src/permission_viewer.dart';
import 'package:pn_pos/src/permissions.dart';
import 'package:pn_pos/src/pos_hold.dart';
import 'package:pn_types/src/api/api_error.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/pos.dart';
import 'package:pn_types/src/pos_shift.dart';
import 'package:pn_types/src/product.dart';
import 'package:pn_ui/src/layout/window_class.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pn_ui/src/widgets/status_strip.dart';
import 'package:pn_ui/src/widgets/top_notice.dart';
import 'package:pos/app/app_scope.dart';
import 'package:pos/checkout/checkout_service.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/screens/payment/done_screen.dart';
import 'package:pos/screens/payment/payment_screen.dart';
import 'package:pos/screens/queue/pending_sales_screen.dart';
import 'package:pos/screens/till/cart_pane.dart';
import 'package:pos/screens/till/held_orders_sheet.dart';
import 'package:pos/screens/till/hold_dialogs.dart';
import 'package:pos/screens/till/catalog_pane.dart';
import 'package:pos/screens/till/pos_sheet.dart';
import 'package:pos/till/cart_controller.dart';
import 'package:pos/till/catalog_controller.dart';
import 'package:pos/till/hold_controller.dart';
import 'package:pos/till/scan_buffer.dart';
import 'package:pos/till/transaction_detail_controller.dart';

/// S5: where the cashier sells. Signed-in cashiers land here, with no home screen in between
/// (every tap before the first sale is a tap the shop pays for on every shift).
///
/// Two columns from 840 dp: the catalogue, and the cart beside it. Under that the cart is a
/// bar with the total that opens a sheet, so the catalogue keeps the whole screen
/// (`plan/ui/README.md` §3.1).
class TillScreen extends StatefulWidget {
  const TillScreen({super.key, this.shift, this.preferences, this.clock});

  /// The shift the cashier is working in, or null when the company runs without shifts.
  final POSShift? shift;

  /// The company's POS preferences, or null when they have not been read.
  ///
  /// Read from the same answer the shift gate is decided on, so this screen does not ask for the
  /// settings a second time. Null means "not known yet", which draws the detail row without the
  /// table and queue fields rather than guessing at them.
  final POSPreferences? preferences;

  /// Time since some fixed point, for telling a scanner from a person. Tests hand in their own.
  final Duration Function()? clock;

  @override
  State<TillScreen> createState() => _TillScreenState();
}

class _TillScreenState extends State<TillScreen> {
  CartController? _cart;
  CatalogController? _catalog;
  TransactionDetailController? _detail;
  HoldController? _hold;
  final _search = TextEditingController();
  final _scan = ScanBuffer();
  final _stopwatch = Stopwatch()..start();

  /// Owns the `client_ref` that makes a retry safe. One per till screen, so the ref belongs to
  /// this cashier's basket and not to another device's.
  CheckoutService? _checkout;

  // Only one lookup at a time: a second Enter while the first is out would ring the
  // same item up twice.
  var _isLookingUp = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_cart != null) return;
    final services = AppScope.of(context);
    _cart = CartController(analytics: services.analytics);
    _checkout = CheckoutService(
      client: services.client,
      // The queue belongs to the tenant the device is paired with, which is why the store is
      // built from the session rather than being a global (`plan/offline-queue/README.md`
      // §4.1). A store bound to another company would read its own queue as empty.
      queue: services.pendingSaleStore,
      analytics: services.analytics,
    );
    final catalog = CatalogController(
      client: services.client,
      outletId: services.session.current?.outletId ?? '',
      analytics: services.analytics,
    );
    _catalog = catalog;
    // Not awaited: each part reports its own state, and a bug it rethrows stays loud.
    catalog.load();

    final preferences = widget.preferences;
    _detail = TransactionDetailController(
      client: services.client,
      outletId: services.session.current?.outletId ?? '',
      showTableNumber: preferences?.showTableNumber ?? false,
      showQueueNumber: preferences?.showQueueNumber ?? false,
      queueNumberAuto: preferences?.queueNumberAuto ?? false,
      defaultCustomerId: preferences?.defaultCustomerId,
      // `POST /master/contacts` needs `master.contact.manage`, which the seeded cashier role
      // does not hold. The button is therefore not drawn for a cashier at all: a control the
      // server refuses is worse than no control (R-26). The owner has said the permission will
      // be granted later, and when it is this gate loosens without the screen changing.
      canCreateContact: Permissions.of(
        membership: resolvePermissionViewer(services.session.current)
            .activeUserCompany,
      ).can('master.contact.manage'),
    );
    // Not awaited: the row shows "Pelanggan" until the name arrives, and a bug it rethrows stays
    // loud.
    _detail!.loadDefault();

    _hold = HoldController(
      store: services.holdStore,
      outletId: services.session.current?.outletId ?? '',
      cart: _cart!,
      detail: _detail!,
      analytics: services.analytics,
    );
    // Not awaited: the count shows when it arrives, and a bug it rethrows stays loud.
    _hold!.refresh();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _search.dispose();
    _hold?.dispose();
    _detail?.dispose();
    _catalog?.dispose();
    _cart?.dispose();
    super.dispose();
  }

  /// Parks the basket under a name the cashier gives it, and clears the till for the next
  /// customer.
  Future<void> _holdBasket() async {
    final hold = _hold!;
    final name = await showHoldNameDialog(
      context,
      initial: hold.resumedLabel ?? '',
    );
    if (name == null || !mounted) return;
    final l10n = L10n.of(context);
    final outcome = await hold.hold(label: name);
    final message = switch (outcome) {
      HoldOutcome.held => l10n.tillHoldDone,
      HoldOutcome.notStored => l10n.tillHoldNotStored,
      // The button is absent on an empty till, so there is nothing to say.
      HoldOutcome.nothingToHold => null,
    };
    if (message != null) _report(message);
  }

  /// Opens the list of held baskets.
  Future<void> _openHeld() =>
      showHeldOrdersSheet(context, hold: _hold!, onResume: _resumeHeld);

  /// Takes a held basket back onto the till, parking the one that was there.
  Future<void> _resumeHeld(HeldOrder order) async {
    final outcome = await _hold!.resume(order);
    if (!mounted) return;
    if (outcome == ResumeOutcome.currentNotStored) {
      _report(L10n.of(context).tillResumeNotStored);
      return;
    }
    // The list has done its job; the basket is on the till.
    Navigator.of(context).pop();
  }

  void _add(Product product) {
    _cart!.add(product);
    HapticFeedback.lightImpact();
  }

  /// Takes the money.
  ///
  /// The payment screen is pushed, not shown as a dialog: the cashier is counting notes and
  /// reading a figure, and the catalogue is not what they are looking at (`plan/ui/README.md`
  /// §1). The basket is emptied only after the server has recorded the sale.
  Future<void> _pay() async {
    final cart = _cart!;
    if (cart.lines.isEmpty) return;
    final services = AppScope.of(context);
    final current = services.session.current;
    if (current == null) return;

    final outcome = await Navigator.of(context).push<CheckoutOutcome>(
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          grandTotal: cart.totals.grandTotal,
          lines: cart.lines,
          shiftId: widget.shift?.id,
          outletId: current.outletId,
          companyId: current.companyId,
          cashierId: current.user?.id ?? '',
          // The cashier's name comes from the session. The outlet's is not on the shift, so it
          // is left to the caller that can read it (`plan/offline-queue/README.md` §4.2): the
          // formatter prints no line for a name it was not given.
          cashierName: current.user?.name,
          detail: _detail!.detail,
          onCancel: () => Navigator.of(context).pop(),
          submit: _checkout!.submit,
        ),
      ),
    );
    if (!mounted) return;

    // A sale that is written down is done as far as the cashier is concerned: the customer gets
    // their change and their receipt, and the queue sends it when it can. The basket is cleared
    // for the same reason it is cleared for a recorded sale — the goods have left the shop — but
    // `_hold.paid()` is called first, exactly as below: emptying the cart makes the hold
    // controller forget which basket it was a copy of, and the paid one would stay in the queue
    // to be sold again.
    if (outcome is CheckoutQueued) {
      await _hold!.paid();
      if (!mounted) return;
      cart.clear();
      _detail!.reset();
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => DoneScreen(
            pending: outcome.entry,
            onNewSale: () => Navigator.of(context).pop(),
          ),
        ),
      );
      return;
    }

    // A sale the server recorded is the only other one that clears the basket. A refusal leaves
    // it exactly as it was, so the cashier can try again with the same items rather than
    // re-scanning what is in front of them.
    if (outcome is! CheckoutSynced) return;
    // Before the cart is cleared, not after: emptying the cart makes the hold controller forget
    // which basket it was a copy of, and the paid one would stay in the queue to be sold again.
    await _hold!.paid();
    if (!mounted) return;
    cart.clear();
    // The detail belonged to the sale that was just paid for. The next customer starts fresh,
    // with the company's default customer attached again.
    _detail!.reset();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => DoneScreen(
          sale: outcome.sale,
          onNewSale: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  /// Looks [code] up and rings the product up. Returns it, or null when there is none or the
  /// lookup did not work (which is reported).
  ///
  /// One at a time: a second Enter while the first is out would ring the same item up
  /// twice.
  ///
  /// [logScan] is true only for the physical scanner (`_onKey`), not the search field's own
  /// Enter (`_submitSearch`): both call this, but only one is a barcode scan.
  Future<Product?> _lookup(
    String code, {
    bool reportMiss = false,
    bool logScan = false,
  }) async {
    if (_isLookingUp) return null;
    _isLookingUp = true;
    try {
      final found = await _catalog!.findByCode(code);
      if (!mounted) return null;
      if (logScan) {
        await AppScope.of(context).analytics
            .logEvent('barcode_scanned', parameters: {'found': found != null});
        if (!mounted) return null;
      }
      if (found == null) {
        if (reportMiss) _report(L10n.of(context).tillCodeNotFound(code));
        return null;
      }
      _add(found);
      return found;
    } on ApiError catch (_) {
      _report(L10n.of(context).tillLookupFailed);
    } on TransportException catch (_) {
      _report(L10n.of(context).tillLookupFailed);
    } finally {
      _isLookingUp = false;
    }
    return null;
  }

  Duration _now() => widget.clock?.call() ?? _stopwatch.elapsed;

  /// The search field's Enter: rings up an exact code, and otherwise leaves the grid to show what
  /// matches. A miss is silent, because it as often means the cashier pressed Enter out of habit
  /// while typing a partial name.
  Future<void> _submitSearch(String text) async {
    final found = await _lookup(text);
    if (!mounted) return;
    if (found != null) {
      _search.clear();
      _catalog!.setSearch('');
    }
  }

  /// A barcode scanner is a keyboard that types fast and finishes with Enter, so the window can
  /// tell it from a person without a focused field (`ScanBuffer`). It only listens while this
  /// screen is the one in front and no text field has the keyboard: behind a dialog it would add
  /// items nobody can see, and in the search field the field's own Enter does the lookup, so the
  /// same product would be rung up twice.
  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (!(ModalRoute.of(context)?.isCurrent ?? false) || _isTypingInAField()) {
      _scan.clear();
      return false;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      final code = _scan.enter(_now());
      if (code == null) return false;
      _lookup(code, reportMiss: true, logScan: true);
      // Consumed: a scan's Enter must not also press whatever button has focus.
      return true;
    }
    final char = event.character;
    if (char != null && char.length == 1 && char.codeUnitAt(0) >= 0x20) {
      _scan.character(char, _now());
    }
    return false;
  }

  bool _isTypingInAField() {
    final focus = FocusManager.instance.primaryFocus?.context;
    if (focus == null) return false;
    return focus.widget is EditableText ||
        focus.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  /// A short fact about something that just happened: a scan found nothing, a lookup failed.
  ///
  /// At the top of the screen (`showTopNotice`), not the bottom: the bottom is where Pay is.
  void _report(String message) {
    if (!mounted) return;
    showTopNotice(context, message: message);
  }

  @override
  Widget build(BuildContext context) {
    final cart = _cart!;
    final catalog = _catalog!;
    final detail = _detail!;
    final l10n = L10n.of(context);
    final services = AppScope.of(context);
    final session = services.session.current;
    final cashier = session?.user?.name;

    final wide = context.windowClass != WindowClass.compact;
    final body = wide
        ? Row(
            children: [
              Expanded(
                child: CatalogPane(catalog: catalog, onPick: _add),
              ),
              _CartColumn(
                width: context.windowClass == WindowClass.wide ? 440 : 380,
                child: CartPane(
                  cart: cart,
                  detail: detail,
                  onPay: _pay,
                  onHold: _holdBasket,
                ),
              ),
            ],
          )
        : Column(
            children: [
              Expanded(
                child: CatalogPane(catalog: catalog, onPick: _add),
              ),
              _SummaryBar(
                cart: cart,
                detail: detail,
                onPay: _pay,
                onHold: _holdBasket,
              ),
            ],
          );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // The queue's own counts, not the store: they are what `QueueSync` already keeps up
            // to date, and re-reading the store here would be a second, disagreeing source of
            // the same number (`plan/offline-queue/README.md` §7).
            ListenableBuilder(
              listenable: services.queueSync,
              builder: (context, _) {
                final pending = services.queueSync.pendingCount;
                final failed = services.queueSync.failedCount;
                final total = pending + failed;
                return StatusStrip(
                  items: [
                    if (cashier != null && cashier.isNotEmpty)
                      (label: l10n.tillStatusCashier(cashier), onTap: null),
                    // The shift number used to sit here. Removed on the owner's decision
                    // (2026-09-20): it changes every shift, it is a variable rather than a fact
                    // about this session, and it sat directly above the search field the cashier
                    // reads and types into all day. The shift is still named where it is the
                    // subject — the Menu, and the shift gate's own panels.
                    //
                    // Present only while there is something to say (`plan/ui/README.md` R3): the
                    // strip is capped at four items, and a device with nothing queued must not
                    // spend one of them on zero.
                    if (total > 0)
                      (
                        label: failed > 0
                            ? l10n.tillStatusQueueFailed(total)
                            : l10n.tillStatusQueue(total),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const PendingSalesScreen(),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _search,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: l10n.tillSearchHint,
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: catalog.setSearch,
                      onSubmitted: _submitSearch,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ListenableBuilder(
                    listenable: _hold!,
                    builder: (context, _) => SizedBox(
                      height: PnTouch.min,
                      child: OutlinedButton(
                        key: const Key('held-button'),
                        onPressed: _openHeld,
                        child: Text(
                          _hold!.count == 0
                              ? l10n.tillHeld
                              : l10n.tillHeldCount(_hold!.count),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _CartColumn extends StatelessWidget {
  const _CartColumn({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: context.pn.surface,
        border: Border(left: BorderSide(color: context.pn.border)),
      ),
      child: child,
    ),
  );
}

/// The cart on a narrow screen: what it holds and what it comes to, always in view, opening the
/// whole cart on a tap. A fixed height, not a share of the screen.
///
/// [onPay] is here as well as in the cart pane, because on this layout the cart is behind a
/// sheet: a cashier in portrait would otherwise have to open the sheet to reach the one action
/// the screen exists for. It is hidden while the basket is empty, like the one in the pane.
class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.cart,
    required this.detail,
    required this.onPay,
    required this.onHold,
  });

  final CartController cart;
  final TransactionDetailController detail;
  final VoidCallback onPay;
  final Future<void> Function() onHold;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context).textTheme;
    final pn = context.pn;

    return ListenableBuilder(
      listenable: Listenable.merge([cart, detail]),
      builder: (context, _) => Material(
        color: pn.surface,
        shape: Border(top: BorderSide(color: pn.border)),
        child: InkWell(
          onTap: () => showPosSheet<void>(
            context,
            heightFactor: 0.85,
            builder: (sheetContext) => CartPane(
              cart: cart,
              detail: detail,
              onPay: onPay,
              onHold: () async {
                await onHold();
                // Parked: the cart is empty, and the sheet has nothing left to show.
                if (sheetContext.mounted && cart.lines.isEmpty) {
                  Navigator.of(sheetContext).pop();
                }
              },
            ),
          ),
          child: ConstrainedBox(
            // A floor, not a fixed height. It was `SizedBox(height: PnTouch.primary)`, which
            // held while the bar carried two lines of text; the Pay button makes three things
            // to fit, and at 360 dp with 1.3x text a fixed 56 dp overflowed by 50 (measured by
            // the layout test). The bar grows instead, because a control that does not fit is
            // worse than a bar that is taller than the minimum tap target.
            constraints: const BoxConstraints(minHeight: PnTouch.primary),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  // Two lines, so the total is never the thing that gives way: at 360 dp and a
                  // large text size a single line would not hold the count, the total and the
                  // label together, and a total that is cut off is a wrong number.
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.tillItemCount(cart.itemCount.toInt()),
                          style: theme.bodySmall,
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            formatCurrency(cart.totals.grandTotal),
                            maxLines: 1,
                            style: theme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // The cart stays reachable while the bar also carries Pay. Replacing the
                  // label with the button would have made the sheet unreachable from here,
                  // and the sheet is where a line is corrected.
                  Text(l10n.tillCartTitle, style: theme.labelLarge),
                  if (cart.lines.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    SizedBox(
                      height: PnTouch.primary - 8,
                      child: FilledButton(
                        key: const Key('pay'),
                        onPressed: onPay,
                        child: Text(l10n.posPay),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
