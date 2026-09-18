/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/pos.dart';
import 'package:pos/l10n/app_localizations.dart';

/// What a payment method is called on screen.
///
/// Takes the **wire** string, not the enum: a recorded sale or a closed shift can carry a `GIRO`
/// that [POSTenderMethod] no longer has (`pos.dart`), and it has to be printed as it is, not lost
/// to a failed parse.
String tenderMethodLabel(L10n l10n, String wire) =>
    switch (POSTenderMethod.tryParse(wire)) {
      POSTenderMethod.cash => l10n.posTenderMethodCASH,
      POSTenderMethod.transfer => l10n.posTenderMethodTRANSFER,
      POSTenderMethod.edc => l10n.posTenderMethodEDC,
      POSTenderMethod.qris => l10n.posTenderMethodQRIS,
      POSTenderMethod.komplimen => l10n.posTenderMethodKOMPLIMEN,
      null => wire,
    };
