/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// Render-to-command: the ESC/POS equivalent of the customer receipt, the kitchen/bar
/// category ticket, and the shift closing report.
///
/// Ported from `apps/web/src/lib/pos-escpos-format.ts` in `finnesia-monorepo`.
///
/// Same data ([posReceiptLines], [PrintableLine], the shift summary), same content, but
/// built into raw printer bytes instead of JSX. Labels arrive **pre-translated** — the
/// caller already has a translation function, so these stay pure functions with no
/// language context, exactly as `.claude/rules/style.md` §7.1 requires. That is also what
/// makes them testable with `dart test` and no device.
///
/// ## Why the inputs are named parameters rather than ported types
///
/// The source takes `POSSale` and `ShiftSummaryResponse` — forty-odd fields each, most of
/// them loaded by a relation this formatter never reads. Dart has no structural typing, so
/// each entry point asks for the fields it actually uses ([ReceiptSale],
/// [ShiftReportSummary]) instead of forcing a caller to build a whole wire type to print
/// one ticket. Same reasoning as `hasCashTender` and `openShiftNotice`
/// (`.claude/rules/patterns.md` §2.1). It also means the API layer can declare the real
/// wire types once, in one place, without this module owning a thinner second copy of them.
///
/// ## Payment methods are raw wire strings, not the enum
///
/// The source types `payments[].method` as `POSTenderMethod`, but the shift report's
/// `sales_by_method` is `Record<string, number>` and `NonCashTenderLine.method` is a plain
/// `string` — deliberately, because a shift closed before 2026-09-09 can still carry a
/// `GIRO` tender that the enum no longer offers (`pos.dart`). Making the receipt side
/// stricter than the report side would put the two halves of the same feature on different
/// rules, so both take strings here. `labels.tenderMethod` already receives a plain string
/// in the web app (`t('pos', \`tenderMethod${method}\`)`), so nothing is lost.
library;

import 'dart:typed_data';

import 'package:pn_types/src/pos.dart';

import 'datetime.dart';
import 'escpos.dart';
import 'format.dart';
import 'js_compat.dart';
import 'pos_print_category.dart';
import 'pos_receipt.dart';
import 'pos_tender.dart';

/// One payment row as a receipt or report reads it.
///
/// A record rather than a class: two fields, compared by value, never serialized.
/// `.claude/rules/patterns.md` §2a.2.
typedef PaymentLine = ({String method, num amount});

/// The sale fields the customer receipt prints.
///
/// [createdAt] and [transactionDate] are both nullable because the source's chain is
/// `sale.created_at || sale.transaction_date`: the first one that is non-empty wins, and
/// if neither is, the date row prints the `-` that [formatDateTime] gives for an empty
/// value. See [formatReceiptEscPos].
///
/// [invoiceItems] is `sale.invoice?.items`; pass `null` or an empty list for a sale whose
/// invoice was not loaded. A sale from the list endpoint carries no invoice relation, and
/// the receipt must render its "no items" row rather than throw on the way to the printer.
typedef ReceiptSale = ({
  String number,
  String? createdAt,
  String? transactionDate,
  String? outletName,
  String? cashierName,
  String? tableNumber,
  String? queueNumber,
  num subtotal,
  num discountAmount,
  num taxAmount,
  num grandTotal,
  num tenderedAmount,
  num changeAmount,

  /// The **wire** value, not [POSSaleStatus]. The comparison below goes through
  /// `POSSaleStatus.voided.wire`, so the string is still written down once — but a status
  /// this client does not recognise must print as itself rather than be rejected by a
  /// parse that has no fallback. [POSSaleStatus.tryParse] is the door for callers that
  /// need to branch on it.
  String status,
  List<InvoiceItem>? invoiceItems,
  List<PaymentLine>? payments,
});

/// Every translated string the customer receipt needs.
///
/// Passed in rather than looked up, so this module stays a pure function with no language
/// context (`.claude/rules/style.md` §7.1). [tenderMethod] and [paidByMethod] are
/// functions because the caller's translation needs the method name as an argument.
class ReceiptEscPosLabels {
  const ReceiptEscPosLabels({
    required this.title,
    required this.cashier,
    required this.tableNumber,
    required this.queueNumber,
    required this.discount,
    required this.subtotal,
    required this.tax,
    required this.paymentMethodLabel,
    required this.paymentTotal,
    required this.cashTendered,
    required this.change,
    required this.voided,
    required this.noItems,
    required this.tenderMethod,
    required this.paidByMethod,
    required this.finnesiaBranding,
  });

  final String title;
  final String cashier;
  final String tableNumber;
  final String queueNumber;
  final String discount;
  final String subtotal;
  final String tax;
  final String paymentMethodLabel;
  final String paymentTotal;
  final String cashTendered;
  final String change;
  final String voided;
  final String noItems;
  final String Function(String method) tenderMethod;
  final String Function(String method) paidByMethod;
  final String finnesiaBranding;
}

/// Builds the customer receipt.
///
/// [footerText] is the tenant's receipt footer, printed one line per `\n`. [showBranding]
/// adds the Finnesia line for tenants on a plan that shows it.
///
/// ## The date chain
///
/// The source is `formatDateTime(sale.created_at || sale.transaction_date)`. JavaScript's
/// `||` treats `''` as absent, so an empty `created_at` falls through to the transaction
/// date; Dart's `??` only skips `null`. [firstNonEmpty] carries that semantic, and when
/// both are empty it yields `''` — which [formatDateTime] renders as `-`, matching the
/// source rather than throwing.
///
/// ## When the payment breakdown prints
///
/// A single payment has its method named in the header, so the body prints only the cash
/// tendered/change breakdown, and **only when that one method was cash**. A split sale has
/// no single method to name up top, so each payment gets its own "paid by <method>" row
/// with one shared change row at the end.
///
/// `tendered_amount`/`change_amount` total **every** payment method, not cash
/// specifically — printing them for a pure KOMPLIMEN (or transfer/EDC/QRIS-only) sale
/// reads as if the customer paid cash for what was actually free or settled
/// electronically. Hence the [hasCashTender] gate on both branches.
Uint8List formatReceiptEscPos(
  ReceiptSale sale,
  String fallbackProductName,
  ReceiptEscPosLabels labels, [
  String? footerText,
  bool? showBranding,
]) {
  final lines = posReceiptLines(
    invoiceItems: sale.invoiceItems,
    fallbackName: fallbackProductName,
  );
  final payments = sale.payments ?? const <PaymentLine>[];
  final singleMethod = payments.length == 1;
  final ops = <Uint8List>[
    cmdInit(),
    cmdFeed(2),
    cmdAlign(EscPosAlign.center),
    cmdBold(true),
    cmdText(labels.title),
    cmdBold(false),
  ];

  final outletName = sale.outletName;
  if (outletName != null && outletName.isNotEmpty) {
    ops.add(cmdText(outletName));
  }
  ops.add(cmdText(sale.number));
  ops.add(cmdAlign(EscPosAlign.left));
  ops.add(cmdText(formatDateTime(
    firstNonEmpty([sale.createdAt, sale.transactionDate]),
  )));
  final cashierName = sale.cashierName;
  if (cashierName != null && cashierName.isNotEmpty) {
    ops.add(cmdText('${labels.cashier}: $cashierName'));
  }
  final tableNumber = sale.tableNumber;
  if (tableNumber != null && tableNumber.isNotEmpty) {
    ops.add(cmdText('${labels.tableNumber}: $tableNumber'));
  }
  final queueNumber = sale.queueNumber;
  if (queueNumber != null && queueNumber.isNotEmpty) {
    ops.add(cmdText('${labels.queueNumber}: $queueNumber'));
  }
  if (singleMethod) {
    final method = payments.first.method;
    ops.add(cmdText(
      '${labels.paymentMethodLabel}: ${labels.tenderMethod(method)}',
    ));
  }
  ops.add(cmdDivider());

  if (lines.isEmpty) {
    ops.add(cmdText(labels.noItems));
  } else {
    for (final line in lines) {
      ops.add(cmdText(line.name));
      ops.add(cmdLineColumns(
        '${jsNumber(line.quantity)} x ${formatCurrency(line.price)}',
        formatCurrency(line.total),
      ));
      // `> 0`, not `>= 0`: a zero discount row is noise on every full-price line.
      if (line.discount > 0) {
        ops.add(cmdLineColumns(
          labels.discount,
          '-${formatCurrency(line.discount)}',
        ));
      }
    }
  }

  ops.add(cmdDivider());
  ops.add(cmdLineColumns(labels.subtotal, formatCurrency(sale.subtotal)));
  if (sale.discountAmount > 0) {
    ops.add(cmdLineColumns(
      labels.discount,
      '-${formatCurrency(sale.discountAmount)}',
    ));
  }
  if (sale.taxAmount > 0) {
    ops.add(cmdLineColumns(labels.tax, formatCurrency(sale.taxAmount)));
  }
  ops.add(cmdBold(true));
  ops.add(cmdLineColumns(labels.paymentTotal, formatCurrency(sale.grandTotal)));
  ops.add(cmdBold(false));
  ops.add(cmdText(''));

  final hasCash = hasCashTender(payments.map((p) => p.method));
  if (singleMethod) {
    if (hasCash) {
      ops.add(cmdLineColumns(
        labels.cashTendered,
        formatCurrency(sale.tenderedAmount),
      ));
      ops.add(cmdBold(true));
      ops.add(cmdLineColumns(
        labels.change,
        formatCurrency(sale.changeAmount),
      ));
      ops.add(cmdBold(false));
    }
  } else {
    for (final payment in payments) {
      ops.add(cmdLineColumns(
        labels.paidByMethod(payment.method),
        formatCurrency(payment.amount),
      ));
    }
    if (hasCash) {
      ops.add(cmdBold(true));
      ops.add(cmdLineColumns(
        labels.change,
        formatCurrency(sale.changeAmount),
      ));
      ops.add(cmdBold(false));
    }
  }

  if (sale.status == POSSaleStatus.voided.wire) {
    ops.add(cmdAlign(EscPosAlign.center));
    ops.add(cmdBold(true));
    ops.add(cmdText(labels.voided));
    ops.add(cmdBold(false));
  }

  if (_hasFooter(footerText, showBranding)) {
    _addFooter(
      ops,
      footerText: footerText,
      showBranding: showBranding,
      brandingText: labels.finnesiaBranding,
    );
  }

  ops.add(cmdFeed(5));
  ops.add(cmdCut());
  return buildCommands(ops);
}

/// Every translated string the kitchen/bar ticket needs.
class CategoryTicketEscPosLabels {
  const CategoryTicketEscPosLabels({
    required this.noItems,
    required this.tableNumber,
    required this.queueNumber,
  });

  final String noItems;
  final String tableNumber;
  final String queueNumber;
}

/// Builds a kitchen/bar ticket for one top-level category.
///
/// [lines] is a group from [groupByCategory]. [outletName] and [saleNumber] are optional
/// because a ticket can be printed from a held basket that was never posted — there is no
/// sale number yet, and an empty string is treated as absent exactly as the source's
/// `if (outletName)` does.
///
/// ## The timestamp is generated here, and that is the source's design
///
/// The source calls `formatDateTime(new Date().toISOString())` — the ticket is stamped
/// when it is printed, not when the basket was filled. That makes this the one function in
/// the module that is **not deterministic**, so [now] exists to inject the clock: the
/// source has no such seam, and a test that read the wall clock would be asserting on the
/// machine's date rather than on the formatter. `apps/pos` passes nothing and gets the
/// source's behaviour. `.claude/rules/native-ports.md` §5.
Uint8List formatCategoryTicketEscPos(
  String categoryName,
  List<PrintableLine> lines,
  String? outletName,
  String? saleNumber,
  CategoryTicketEscPosLabels labels, [
  String? tableNumber,
  String? queueNumber,
  DateTime? now,
]) {
  final ops = <Uint8List>[
    cmdInit(),
    cmdFeed(2),
    cmdAlign(EscPosAlign.center),
    cmdBold(true),
    cmdText(categoryName),
    cmdBold(false),
  ];

  if (outletName != null && outletName.isNotEmpty) {
    ops.add(cmdText(outletName));
  }
  if (saleNumber != null && saleNumber.isNotEmpty) {
    ops.add(cmdText(saleNumber));
  }
  ops.add(cmdText(formatDateTime((now ?? DateTime.now()).toIso8601String())));
  ops.add(cmdAlign(EscPosAlign.left));
  if (tableNumber != null && tableNumber.isNotEmpty) {
    ops.add(cmdText('${labels.tableNumber}: $tableNumber'));
  }
  if (queueNumber != null && queueNumber.isNotEmpty) {
    ops.add(cmdText('${labels.queueNumber}: $queueNumber'));
  }
  ops.add(cmdDivider());

  if (lines.isEmpty) {
    ops.add(cmdAlign(EscPosAlign.center));
    ops.add(cmdText(labels.noItems));
  } else {
    for (final line in lines) {
      ops.add(cmdLineColumns(line.name, 'x${jsNumber(line.quantity)}'));
    }
  }

  ops.add(cmdFeed(5));
  ops.add(cmdCut());
  return buildCommands(ops);
}

/// One product's row in the shift report's per-product breakdown.
typedef ProductSalesLine = ({
  String productName,
  num quantity,
  num unitPrice,
  num total,
});

/// One itemized non-cash tender in the shift report.
///
/// [method] is a plain string for the reason in the library doc: a shift closed before
/// 2026-09-09 can carry a `GIRO` tender the enum no longer offers, and the report must
/// still be able to print it.
typedef NonCashTenderLine = ({
  String method,
  String? reference,
  num amount,
  String saleNumber,
});

/// The shift summary fields the closing report prints.
typedef ShiftReportSummary = ({
  String number,
  String? cashierName,
  String? openedAt,
  num totalSales,
  num openingCash,
  Map<String, num> salesByMethod,
  num cashOut,
  num cashDrop,
  List<NonCashTenderLine> nonCashTenders,
  List<ProductSalesLine> productSales,
});

/// Every translated string the shift closing report needs.
class ShiftReportEscPosLabels {
  const ShiftReportEscPosLabels({
    required this.title,
    required this.cashier,
    required this.openedAt,
    required this.printedAt,
    required this.totalSales,
    required this.paymentsByMethod,
    required this.total,
    required this.deposit,
    required this.openingCash,
    required this.cashSales,
    required this.cashOut,
    required this.totalDeposit,
    required this.nonCashPayments,
    required this.tenderMethod,
    required this.noTenders,
    required this.productsSoldTitle,
    required this.productsSoldTotal,
    required this.finnesiaBranding,
  });

  final String title;
  final String cashier;
  final String openedAt;
  final String printedAt;
  final String totalSales;
  final String paymentsByMethod;
  final String total;
  final String deposit;
  final String openingCash;
  final String cashSales;
  final String cashOut;
  final String totalDeposit;
  final String nonCashPayments;
  final String Function(String method) tenderMethod;
  final String noTenders;
  final String productsSoldTitle;
  final String productsSoldTotal;
  final String finnesiaBranding;
}

/// Builds the shift closing report.
///
/// The structure follows the reference receipt: cashier/login/printed-at/total sales,
/// payments-by-method with a total, a cash deposit breakdown, an optional per-product
/// breakdown, and non-cash tenders itemized per transaction.
///
/// [printedAt] is passed in rather than read from the clock because the caller already
/// has the instant the button was pressed, and the report is otherwise deterministic.
///
/// [showProductSales] gates the per-product section: the response always carries
/// `product_sales` regardless of the tenant's `show_product_sales_summary` preference, so
/// the preference is applied by the caller and the formatter stays silent unless told.
Uint8List formatShiftReportEscPos(
  ShiftReportSummary summary,
  String printedAt,
  ShiftReportEscPosLabels labels, [
  bool? showProductSales,
  String? footerText,
  bool? showBranding,
]) {
  // `?? 0` is load-bearing, not defensive: a card-only shift has no CASH key at all, and
  // the deposit total would become NaN without it.
  final cashSales = summary.salesByMethod['CASH'] ?? 0;
  final totalDeposit =
      summary.openingCash + cashSales - summary.cashOut - summary.cashDrop;

  final ops = <Uint8List>[
    cmdInit(),
    cmdFeed(2),
    cmdAlign(EscPosAlign.center),
    cmdBold(true),
    cmdText(labels.title),
    cmdBold(false),
    cmdText(summary.number),
    cmdAlign(EscPosAlign.left),
    cmdDivider(),
  ];

  final cashierName = summary.cashierName;
  if (cashierName != null && cashierName.isNotEmpty) {
    ops.add(cmdLineColumns(labels.cashier, cashierName));
  }
  ops.add(cmdLineColumns(labels.openedAt, formatDateTime(summary.openedAt)));
  ops.add(cmdLineColumns(labels.printedAt, formatDateTime(printedAt)));
  ops.add(cmdBold(true));
  ops.add(cmdLineColumns(
    labels.totalSales,
    formatCurrency(summary.totalSales),
  ));
  ops.add(cmdBold(false));
  ops.add(cmdDivider());

  ops.add(cmdBold(true));
  ops.add(cmdText(labels.paymentsByMethod));
  ops.add(cmdBold(false));
  // Insertion order, which is what `Object.entries` gives in JavaScript and what `Map`
  // gives in Dart. Stated rather than assumed — a sorted port would print CASH before
  // QRIS and look entirely plausible.
  for (final entry in summary.salesByMethod.entries) {
    ops.add(cmdLineColumns(
      labels.tenderMethod(entry.key),
      formatCurrency(entry.value),
    ));
  }
  ops.add(cmdLineColumns(labels.total, formatCurrency(summary.totalSales)));
  ops.add(cmdDivider());

  ops.add(cmdBold(true));
  ops.add(cmdText(labels.deposit));
  ops.add(cmdBold(false));
  ops.add(cmdLineColumns(
    labels.openingCash,
    formatCurrency(summary.openingCash),
  ));
  ops.add(cmdLineColumns(labels.cashSales, formatCurrency(cashSales)));
  ops.add(cmdLineColumns(
    labels.cashOut,
    '-${formatCurrency(summary.cashOut + summary.cashDrop)}',
  ));
  ops.add(cmdBold(true));
  ops.add(cmdLineColumns(
    labels.totalDeposit,
    formatCurrency(totalDeposit),
  ));
  ops.add(cmdBold(false));
  ops.add(cmdDivider());

  if (showProductSales == true && summary.productSales.isNotEmpty) {
    // A second divider, so the section is set off from the deposit above it. Present in
    // the source, and it does produce two adjacent divider rows there.
    ops.add(cmdDivider());
    ops.add(cmdBold(true));
    ops.add(cmdText(labels.productsSoldTitle));
    ops.add(cmdBold(false));
    for (final line in summary.productSales) {
      ops.add(cmdText(line.productName));
      ops.add(cmdLineColumns(
        '${jsNumber(line.quantity)} x ${formatCurrency(line.unitPrice)}',
        formatCurrency(line.total),
      ));
    }
    // Summed from the product lines themselves, not from `total_sales` — the two differ
    // whenever a sale carried a discount or a tax, and the audit requirement (I18) is that
    // this row reconciles against the lines printed above it.
    final productsTotal = summary.productSales.fold<num>(
      0,
      (sum, line) => sum + line.total,
    );
    ops.add(cmdBold(true));
    ops.add(cmdLineColumns(
      labels.productsSoldTotal,
      formatCurrency(productsTotal),
    ));
    ops.add(cmdBold(false));
  }

  ops.add(cmdDivider());
  ops.add(cmdBold(true));
  ops.add(cmdText(labels.nonCashPayments));
  ops.add(cmdBold(false));
  if (summary.nonCashTenders.isEmpty) {
    ops.add(cmdText(labels.noTenders));
  } else {
    // Two lines per tender, not one combined line: sale number + method + reference
    // together routinely exceed a 32-column thermal printer's width, and the amount — the
    // figure that matters most when reconciling — is the one thing that must never get
    // truncated away.
    for (final tender in summary.nonCashTenders) {
      ops.add(cmdText(
        '${tender.saleNumber} ${labels.tenderMethod(tender.method)}',
      ));
      ops.add(cmdLineColumns(
        tender.reference ?? '',
        formatCurrency(tender.amount),
      ));
    }
  }

  if (_hasFooter(footerText, showBranding)) {
    _addFooter(
      ops,
      footerText: footerText,
      showBranding: showBranding,
      brandingText: labels.finnesiaBranding,
    );
  }

  ops.add(cmdFeed(5));
  ops.add(cmdCut());
  return buildCommands(ops);
}

/// Whether the source's `if (footerText || showBranding)` branch runs.
///
/// A blank [footerText] does not open the branch — that is the JavaScript `||` over a
/// string again, and it matters here because opening the branch also re-centers the
/// alignment and emits a blank line.
bool _hasFooter(String? footerText, bool? showBranding) =>
    firstNonEmpty([footerText]).isNotEmpty || showBranding == true;

/// Emits the blank line, the re-centering, the footer lines, and the branding line.
///
/// Shared by the receipt and the shift report: both end with the identical block, and the
/// source's two copies are byte-for-byte the same. `.claude/rules/patterns.md` §2.1.
void _addFooter(
  List<Uint8List> ops, {
  required String? footerText,
  required bool? showBranding,
  required String brandingText,
}) {
  ops.add(cmdText(''));
  ops.add(cmdAlign(EscPosAlign.center));
  // `footerText?.split('\n') ?? []`: an absent footer emits nothing, while an empty
  // string splits to one empty line and so emits a blank row — which is what the source
  // does, and it is only reachable when showBranding opened the branch on its own.
  for (final line in footerText?.split('\n') ?? const <String>[]) {
    ops.add(cmdText(line));
  }
  if (showBranding == true) ops.add(cmdText(brandingText));
}
