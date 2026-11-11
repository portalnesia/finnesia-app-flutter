/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pn_pos/src/pos_print_category.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pos/app/app_scope.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/printer/print_category_ticket.dart';
import 'package:pos/printer/print_receipt.dart' show readOutletName;
import 'package:pos/screens/common/print_flow.dart';

/// One `Print {category}` button per top-level category in [lines], in the order the categories
/// were first rung up: the kitchen/bar tickets of the web app's `POSPrintControls`.
///
/// Never gated by the draft-print restriction: a ticket goes to the kitchen, not the customer,
/// and posts nothing. The header's outlet is [outletName] when the caller has it (a queued sale's
/// copy), else read by [outletId] for a recorded sale. A held basket or the live cart has no sale
/// and passes neither, as the web does.
class CategoryTicketButtons extends StatelessWidget {
  const CategoryTicketButtons({
    super.key,
    required this.lines,
    this.outletName,
    this.outletId,
    this.saleNumber,
    this.tableNumber,
    this.queueNumber,
    this.leading,
  });

  /// The customer receipt's button, first in the same row, as the web lays them out.
  final Widget? leading;

  final List<PrintableLine> lines;
  final String? outletName;
  final String? outletId;
  final String? saleNumber;
  final String? tableNumber;
  final String? queueNumber;

  Future<void> _print(BuildContext context, CategoryGroup group) {
    final services = AppScope.of(context);
    final l10n = L10n.of(context);
    final outlet = outletId;
    return runPrint(
      context,
      successMessage: l10n.receiptSent,
      analyticsEvent: 'tenant_category_ticket_printed',
      print: () async => printCategoryTicket(
        group,
        outletName:
            outletName ??
            (outlet == null
                ? null
                : await readOutletName(services.client, outlet)),
        saleNumber: saleNumber,
        tableNumber: tableNumber,
        queueNumber: queueNumber,
        printer: services.printer,
        printQueue: services.printQueue,
        store: services.store,
        l10n: l10n,
        platform: defaultTargetPlatform,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final buttons = [
      ?leading,
      for (final group in groupByCategory(lines))
        OutlinedButton(
          onPressed: () => _print(context, group),
          child: Text(
            l10n.posPrintCategoryTicket(group.name),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
    ];
    if (buttons.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) =>
          _shareRows(buttons, constraints.maxWidth),
    );
  }
}

const _gap = 8.0;

/// Below this a button label is cut short, so a row holds no more buttons than fit at it.
const _minButtonWidth = 160.0;

/// The web's `flex flex-wrap gap-2` with `flex-1` buttons: as many to a row as fit, each row's
/// buttons sharing its width equally, all one height.
Widget _shareRows(List<Widget> buttons, double width) {
  final perRow = width.isFinite
      ? ((width + _gap) / (_minButtonWidth + _gap)).floor().clamp(
          1,
          buttons.length,
        )
      : buttons.length;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var start = 0; start < buttons.length; start += perRow) ...[
        if (start > 0) const SizedBox(height: _gap),
        Row(
          children: [
            for (
              var i = start;
              i < start + perRow && i < buttons.length;
              i++
            ) ...[
              if (i > start) const SizedBox(width: _gap),
              Expanded(
                child: SizedBox(height: PnTouch.min, child: buttons[i]),
              ),
            ],
          ],
        ),
      ],
    ],
  );
}
