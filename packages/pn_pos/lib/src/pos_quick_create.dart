/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pn_types/src/master_data.dart';

import 'permissions.dart';

part 'pos_quick_create.freezed.dart';

/// Adding a product or a customer from the till.
///
/// Ported from `apps/web/src/lib/pos-quick-create.ts` (finnesia-monorepo). Two deliberate
/// differences: the web picker's value for "PCS, not created yet" is a magic string
/// (`'__pcs_new__'`) in a list of strings; here it is its own case of a sealed type, so a picker
/// cannot send it as an id by mistake. And the permission pairs are asked through [Permissions]
/// rather than a list of codes the caller loops over.

/// The same pair the server route `POST /pos/products` accepts: the till's own create-only
/// permission, or the master permission of whoever already manages products.
const quickProductPermissions = ['pos.quick_create', 'master.product.manage'];

/// The same pair the server route `POST /pos/customers` accepts.
const quickCustomerPermissions = ['pos.quick_create', 'master.contact.manage'];

/// Whether the till offers "New product". Anyone else would fill the form in and meet a 403.
bool canQuickAddProduct(Permissions permissions) =>
    quickProductPermissions.any(permissions.can);

/// Whether the customer picker offers "Add customer".
bool canQuickAddCustomer(Permissions permissions) =>
    quickCustomerPermissions.any(permissions.can);

const _pcs = 'PCS';

/// The company's own PCS, matched by symbol whatever its case. Null when it has none.
Unit? findPcsUnit(List<Unit> units) {
  for (final unit in units) {
    if (unit.symbol.toUpperCase() == _pcs) return unit;
  }
  return null;
}

/// One row of the quick-add product form's unit picker.
@freezed
sealed class QuickUnitChoice with _$QuickUnitChoice {
  /// A unit the company already has.
  const factory QuickUnitChoice.existing(Unit unit) = QuickUnitExisting;

  /// PCS, which this company does not have yet. Never sent as an id: a product posted without a
  /// unit gets PCS, which the server creates on the first save.
  const factory QuickUnitChoice.pcsNew() = QuickUnitPcsNew;
}

/// The picker always offers PCS, first: the company's own PCS when it has one (even when it is
/// not on the loaded page), otherwise the to-be-created PCS. The other units follow in list
/// order.
List<QuickUnitChoice> buildQuickUnitChoices(List<Unit> units, Unit? pcs) => [
      defaultQuickUnit(pcs),
      for (final unit in units)
        if (unit.id != pcs?.id) QuickUnitChoice.existing(unit),
    ];

/// What the picker starts on: PCS, whichever kind the company has.
QuickUnitChoice defaultQuickUnit(Unit? pcs) => pcs == null
    ? const QuickUnitChoice.pcsNew()
    : QuickUnitChoice.existing(pcs);

/// What goes in `unit_id`: nothing for PCS to be created, the id otherwise.
String? quickUnitPayload(QuickUnitChoice choice) => switch (choice) {
      QuickUnitExisting(:final unit) => unit.id,
      QuickUnitPcsNew() => null,
    };
