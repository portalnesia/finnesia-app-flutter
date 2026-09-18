/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:pn_pos/src/pos_calculations.dart';
import 'package:pn_pos/src/pos_cart.dart';
import 'package:pn_types/src/native/analytics_port.dart';
import 'package:pn_types/src/product.dart';

/// The basket on the till.
///
/// Every change is a call to the pure functions of `pn_pos` (`addToCart`, `setLineQty`,
/// `removeLine`); this only holds the list, says when it changed, and remembers one more thing:
/// the line that was just removed, so a slipped thumb costs a tap and not a re-scan
/// (`plan/ui/README.md` §3.5).
class CartController extends ChangeNotifier {
  CartController({required this._analytics});

  final AnalyticsPort _analytics;

  List<CartLine> _lines = const [];

  // The last removal only, with the place it sat. One level, on purpose: a cashier who removed
  // three lines by mistake is looking at the cart, and the line they meant is the last one.
  ({CartLine line, int index})? _removed;

  /// A view that cannot be changed from outside, so the only way to alter the basket is through
  /// the methods below, which is where listeners are told.
  List<CartLine> get lines => UnmodifiableListView(_lines);

  /// How many pieces, not how many rows: two of one product is two.
  num get itemCount => _lines.fold<num>(0, (sum, line) => sum + line.qty);

  /// The lines are priced at `sell_price`, and a product with none counts as free, as
  /// `pos-page.tsx` does (`p.sell_price ?? 0`): the server is what refuses a sale it cannot price.
  CartTotals get totals => totalsOfLines(_lines);

  bool get canUndoRemove => _removed != null;

  /// Takes a whole basket in place of the one there: what a resumed held basket is.
  ///
  /// The lines get ids of this controller's own. The ones they arrive with come from `addToCart`'s
  /// counter, which starts again at 1 after a restart, so a basket held yesterday would hand its
  /// `line_1` to a cart whose next scan is also `line_1`, and the two would render as one row.
  void replaceAll(List<CartLine> lines) {
    _lines = [
      for (final line in lines)
        line.copyWith(id: 'resumed_${++_resumedSequence}'),
    ];
    _removed = null;
    notifyListeners();
  }

  int _resumedSequence = 0;

  void add(Product product) {
    _lines = addToCart(_lines, product);
    notifyListeners();
    unawaited(_analytics.logEvent('item_added_to_cart'));
  }

  void setQty(String lineId, num qty) {
    if (!_lines.any((line) => line.id == lineId)) return;
    _lines = setLineQty(_lines, lineId, qty);
    notifyListeners();
  }

  void remove(String lineId) {
    final index = _lines.indexWhere((line) => line.id == lineId);
    if (index < 0) return;
    _removed = (line: _lines[index], index: index);
    _lines = removeLine(_lines, lineId);
    notifyListeners();
    unawaited(_analytics.logEvent('item_removed_from_cart'));
  }

  /// Puts back the line that was removed last, where it was (or at the end, if the cart is
  /// shorter now). Does nothing when there is nothing to put back.
  void undoRemove() {
    final removed = _removed;
    if (removed == null) return;
    _removed = null;

    final same = _lines
        .where((line) => line.product.id == removed.line.product.id)
        .firstOrNull;
    if (same != null) {
      // The product was rung up again in the meantime. A second row for one product would
      // print twice on the receipt, so the quantities are joined into the row that is there.
      _lines = setLineQty(_lines, same.id, same.qty + removed.line.qty);
    } else {
      final at = removed.index.clamp(0, _lines.length);
      _lines = [..._lines.take(at), removed.line, ..._lines.skip(at)];
    }
    notifyListeners();
  }

  /// Empties the basket. The screen asks first, so there is no undo for this one.
  void clear() {
    if (_lines.isEmpty) return;
    _lines = const [];
    _removed = null;
    notifyListeners();
    unawaited(_analytics.logEvent('cart_cleared'));
  }
}
