/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pn_pos/src/pos_quick_create.dart';
import 'package:pn_types/src/product.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pos/app/app_scope.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/screens/common/amount_entry.dart';
import 'package:pos/screens/till/pos_sheet.dart';
import 'package:pos/till/quick_create.dart';
import 'package:pos/till/quick_product_controller.dart';

/// Adds a product the till does not know yet, so the sale goes on instead of waiting for someone
/// with the catalogue permissions.
///
/// [initialName] is what the cashier was searching for: usually the name of the product that was
/// not found. Resolves to the saved product, or null when the sheet was closed without saving.
///
/// A sheet and not a dialog, like the cash movement: the price is typed on the on-screen keypad
/// (`AmountEntry`), which needs the height, and the save button stays fixed under it.
Future<Product?> showQuickProductSheet(
  BuildContext context, {
  required String initialName,
}) => showPosSheet<Product>(
  context,
  heightFactor: 0.92,
  builder: (context) => QuickProductSheet(initialName: initialName),
);

class QuickProductSheet extends StatefulWidget {
  const QuickProductSheet({super.key, required this.initialName});

  final String initialName;

  @override
  State<QuickProductSheet> createState() => _QuickProductSheetState();
}

class _QuickProductSheetState extends State<QuickProductSheet> {
  QuickProductController? _controller;
  late final _name = TextEditingController(text: widget.initialName.trim());
  var _price = 0;
  var _saving = false;
  String? _problem;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    // Not awaited: the controller reports its own state, and a bug it rethrows stays loud.
    _controller = QuickProductController(client: AppScope.of(context).client)
      ..open();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final l10n = L10n.of(context);
    setState(() {
      _saving = true;
      _problem = null;
    });
    final outcome = await _controller!.create(
      name: _name.text,
      sellPrice: _price,
    );
    if (!mounted) return;
    final String problem;
    switch (outcome) {
      case QuickCreateOk(:final created):
        Navigator.of(context).pop(created);
        return;
      case QuickCreateInvalid():
        problem = l10n.quickNameRequired;
      // In the sheet rather than a notice: the cashier has to read why the product was refused (a
      // product quota, say) before deciding what to tell the customer.
      case QuickCreateRejected(:final message):
        problem = message;
      case QuickCreateUnavailable():
        problem = l10n.tillDetailCreateNoAnswer;
    }
    setState(() {
      _saving = false;
      _problem = problem;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final controller = _controller!;
    final theme = Theme.of(context).textTheme;
    final pn = context.pn;
    final problem = _problem;
    // A modal sheet does not move for the tablet's keyboard by itself, and the name is a text
    // field: without this the keyboard sits over the save button.
    return Padding(
      key: const Key('quick-product-sheet'),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PosSheetHeader(title: l10n.quickProductTitle),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (problem != null) ...[
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      problem,
                      style: theme.bodyMedium!.copyWith(color: pn.errorText),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  key: const Key('quick-product-name'),
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.quickProductName,
                    hintText: l10n.quickProductNamePh,
                  ),
                ),
                const SizedBox(height: 16),
                ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) => _UnitField(controller: controller),
                ),
                const SizedBox(height: 24),
                AmountEntry(
                  label: l10n.quickProductPrice,
                  backspaceLabel: l10n.shiftKeypadBackspace,
                  enabled: !_saving,
                  onChanged: (price) => _price = price,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.quickProductHint,
                  style: theme.bodySmall!.copyWith(color: pn.inkMuted),
                ),
              ],
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: pn.border)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: PnTouch.primary,
                child: FilledButton(
                  key: const Key('quick-product-save'),
                  onPressed: _saving ? null : _save,
                  child: Text(
                    _saving ? l10n.commonSaving : l10n.quickProductSave,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The unit picker: PCS first, always (`buildQuickUnitChoices`).
class _UnitField extends StatelessWidget {
  const _UnitField({required this.controller});

  final QuickProductController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final choices = controller.choices;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<QuickUnitChoice>(
          // Rebuilt when the list arrives: `initialValue` is read once, and the first choice
          // changes from PCS-to-be-created to the company's own PCS when it has one.
          key: ValueKey(Object.hashAll(choices)),
          initialValue: controller.unit,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.quickProductUnit),
          items: [
            for (final choice in choices)
              DropdownMenuItem(
                value: choice,
                child: Text(switch (choice) {
                  QuickUnitExisting(:final unit) =>
                    '${unit.name} (${unit.symbol})',
                  QuickUnitPcsNew() => l10n.quickProductUnitPcsNew,
                }, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (choice) {
            if (choice != null) controller.pickUnit(choice);
          },
        ),
        if (controller.unitsFailed) ...[
          const SizedBox(height: 4),
          Text(
            l10n.quickProductUnitsFailed,
            style: Theme.of(context).textTheme.bodySmall!
                .copyWith(color: context.pn.inkMuted),
          ),
        ],
      ],
    );
  }
}
