/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pn_pos/src/permission_viewer.dart';
import 'package:pos/app/app_scope.dart';

/// Which company this tablet is on, as a 40x40 circle at the end of the header.
///
/// On every screen opened after login, not on some of them: a cashier who sees the shop on one
/// screen and not on the next reads the missing one as a fault rather than as a choice.
///
/// The circle is fixed rather than fitted, because [PnTouch.primary] sizes the bar and a header
/// that grows with a logo's aspect ratio moves the whole screen's chrome.
class CompanyAvatar extends StatelessWidget {
  const CompanyAvatar({super.key});

  /// `PnTouch.primary` is 48; the circle is a touch smaller so the bar's height is not driven by
  /// it and the bar keeps the padding it was drawn with.
  static const size = 40.0;

  @override
  Widget build(BuildContext context) {
    // The same membership the permission checks ask about, so the avatar cannot name a different
    // company than the one whose role is being enforced.
    final company = resolvePermissionViewer(
      AppScope.of(context).session.current,
    ).activeUserCompany?.company;

    // Nothing to identify: no membership for the company pairing locked. An empty slot beats a
    // placeholder that claims a company this device is not on.
    if (company == null) return const SizedBox.shrink();

    final initials = _initials(company.name);
    final fallback = CircleAvatar(child: Text(initials));
    final url = company.logo?.renderableUrl;

    return SizedBox(
      width: size,
      height: size,
      child: url == null
          ? fallback
          : ClipOval(
              child: Image.network(
                url,
                width: size,
                height: size,
                // Cover, not contain: an identity mark fills its circle and loses its edges.
                // Letterboxed inside a circle reads as a logo on a background, not as the logo.
                fit: BoxFit.cover,
                semanticLabel: company.name,
                // The same circle with the same initials, so a logo that fails to fetch leaves
                // the header the size it was.
                errorBuilder: (_, _, _) => fallback,
              ),
            ),
    );
  }

  /// One or two letters off the company's own name: the first word's first letter, plus the
  /// last word's when there is one (`"Toko Budi Grosir"` reads `TG`, not `TBG`).
  ///
  /// `"?"` when the name has not arrived. It says the data is missing, which a generic person
  /// icon would not.
  static String _initials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';

    final letters = words.length == 1
        ? words.first.substring(0, 1)
        : '${words.first[0]}${words.last[0]}';
    return letters.toUpperCase();
  }
}
