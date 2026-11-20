/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/foundation.dart';
import 'package:pn_pos/src/pos_quick_create.dart';
import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/api/endpoints/master.dart';
import 'package:pn_types/src/api/endpoints/pos.dart';
import 'package:pn_types/src/pos.dart';
import 'package:pn_types/src/product.dart';
import 'package:pos/state/loadable.dart';
import 'package:pos/till/quick_create.dart';

/// One page of the unit picker. A company's units are a short list next to its products, and the
/// company PCS is read on its own in case it is not on this page.
const _unitPageSize = 50;

/// The product a cashier adds from the till: a name, a price and a unit, nothing else.
///
/// The behaviour of `pos-quick-add-product-dialog.tsx` (finnesia-monorepo). The full product form
/// asks for type, accounts and stock rules, which a cashier serving a queue cannot answer; the
/// server saves this one without stock tracking (`NON_INVENTORY`) and the catalogue owner
/// completes it later.
///
/// The unit always starts on PCS. When the company has no PCS yet, the choice says it will be
/// created, and the request goes without a unit so the server creates it in the same save.
class QuickProductController extends ChangeNotifier {
  QuickProductController({required this.client});

  final ApiClient client;

  final _creating = QuickCreateRunner<Product>();

  List<QuickUnitChoice> _choices = const [QuickUnitChoice.pcsNew()];
  QuickUnitChoice? _picked;
  bool _isLoadingUnits = false;
  bool _unitsFailed = false;
  bool _opened = false;
  bool _disposed = false;

  /// What the unit picker offers, PCS first.
  ///
  /// Before the units have arrived, and when they could not be read, only PCS to be created: a
  /// product posted without a unit is always safe, since the server uses the company PCS or
  /// creates it.
  List<QuickUnitChoice> get choices => _choices;

  /// The unit the product will be saved with: the one the cashier picked, or the first choice.
  QuickUnitChoice get unit => _picked ?? _choices.first;

  bool get isLoadingUnits => _isLoadingUnits;

  /// Whether the unit list could not be read. The form says so, and still saves with PCS.
  bool get unitsFailed => _unitsFailed;

  void pickUnit(QuickUnitChoice choice) {
    _picked = choice;
    notifyListeners();
  }

  /// Reads the units once: the company PCS by symbol, and the picker's page.
  ///
  /// A first attempt that failed is retried by opening again: the flag is set on success.
  Future<void> open() async {
    if (_opened || _isLoadingUnits) return;
    _isLoadingUnits = true;
    _unitsFailed = false;
    notifyListeners();
    try {
      // `Future.wait` and not a record's `.wait`: the record form reports a failure as a
      // `ParallelWaitError`, which is neither an `ApiError` nor a `TransportException` and would
      // read as a bug (`shift_controller.dart`). Two different reads, not one per item.
      final [found, page] = await Future.wait([
        MasterApi.unitsList(client, query: {'q': 'PCS', 'page_size': 10}),
        MasterApi.unitsList(client, query: {'page_size': _unitPageSize}),
      ]);
      _choices = buildQuickUnitChoices(page, findPcsUnit(found));
      _opened = true;
    } on Object catch (error) {
      _unitsFailed = true;
      if (!isServerOrNetworkFailure(error)) rethrow;
    } finally {
      _isLoadingUnits = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// Saves the product. A name of nothing but spaces is refused here, before it leaves; one save
  /// goes out at a time ([QuickCreateRunner]).
  Future<QuickCreateOutcome<Product>> create({
    required String name,
    required int sellPrice,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return const QuickCreateInvalid();
    final unitId = quickUnitPayload(unit);
    return _creating.run(
      () => PosApi.productsCreate(
        client,
        POSQuickProductDTO(name: trimmed, sellPrice: sellPrice, unitId: unitId),
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
