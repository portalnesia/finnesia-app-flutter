/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/file_ref.dart';
import 'package:pn_types/src/session.dart';
import 'package:pn_types/src/tenant.dart';
import 'package:pos/app/app_scope.dart';
import 'package:pos/branding/company_avatar.dart';

import '../support/boot_rig.dart';
import '../support/app_harness.dart';

// The header avatar: the company this tablet is paired to, as a 40x40 circle. It is the same
// widget on every screen opened after login, so a cashier reads "which shop am I in" the same
// way everywhere. These tests are of the widget itself; that it reaches every header is the
// call-site tests' business.

final signedIn = paired.copyWith(
  user: const SessionUser(id: 'user_1', name: 'Budi'),
);

UserCompany membership(
  String name, {
  FileRef? logo,
  String companyId = 'comp_1',
}) => UserCompany(
  id: 'uc_1',
  userId: 'user_1',
  companyId: companyId,
  role: 'cashier',
  isActive: true,
  company: CompanyRef(name: name, logo: logo),
);

const attached = FileRef(
  id: 'f1',
  name: 'logo.png',
  status: 'attached',
  url: 'https://cdn.example.com/comp.png',
);

/// The avatar inside a real app scope, so it reads the session the way it does at runtime.
Future<void> pumpAvatar(WidgetTester tester, PosSession session) async {
  final services = await Rig(storedSession(session)).ready();
  await tester.pumpWidget(
    harness(
      AppScope(
        services: services,
        child: const Center(child: CompanyAvatar()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('CompanyAvatar', () {
    testWidgets('is 40 by 40', (tester) async {
      await pumpAvatar(
        tester,
        signedIn.copyWith(companies: [membership('Toko Budi')]),
      );

      expect(tester.getSize(find.byType(CompanyAvatar)), const Size(40, 40));
    });

    testWidgets('shows the initials of a one-word company name', (
      tester,
    ) async {
      await pumpAvatar(
        tester,
        signedIn.copyWith(companies: [membership('Budi')]),
      );

      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('shows the first and last word of a longer name', (
      tester,
    ) async {
      await pumpAvatar(
        tester,
        signedIn.copyWith(companies: [membership('Toko Budi Grosir')]),
      );

      expect(find.text('TG'), findsOneWidget);
    });

    // `"?"` says the name has not arrived. A generic person icon would say the company has no
    // logo, which is a different claim and a wrong one.
    testWidgets('shows a question mark when the company has no name', (
      tester,
    ) async {
      await pumpAvatar(
        tester,
        signedIn.copyWith(companies: [membership('   ')]),
      );

      expect(find.text('?'), findsOneWidget);
    });

    // No membership for the company pairing locked means there is no company to identify, so
    // the header slot stays empty rather than showing a placeholder.
    testWidgets('draws nothing when no membership matches the paired company', (
      tester,
    ) async {
      await pumpAvatar(
        tester,
        signedIn.copyWith(
          companies: [membership('Toko Lain', companyId: 'comp_2')],
        ),
      );

      expect(find.byType(CompanyAvatar), findsOneWidget);
      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('renders the logo when the file is attached', (tester) async {
      await pumpAvatar(
        tester,
        signedIn.copyWith(companies: [membership('Toko Budi', logo: attached)]),
      );

      expect(find.byType(Image), findsOneWidget);
      expect(
        tester.widget<Image>(find.byType(Image)).image,
        isA<NetworkImage>().having(
          (image) => image.url,
          'url',
          'https://cdn.example.com/comp.png',
        ),
      );
      // The circle itself is what is tested here: the initials are drawn by the fallback, and
      // in a test every network fetch answers 400, so the fallback is already what is on screen.
      expect(find.byType(ClipOval), findsOneWidget);
    });

    // A file that is not attached must not reach the network at all, so the initials stand in.
    testWidgets('falls back to the initials for a detached logo', (
      tester,
    ) async {
      await pumpAvatar(
        tester,
        signedIn.copyWith(
          companies: [
            membership(
              'Toko Budi',
              logo: const FileRef(
                id: 'f1',
                name: 'logo.png',
                status: 'detached',
                url: 'https://cdn.example.com/comp.png',
              ),
            ),
          ],
        ),
      );

      expect(find.byType(Image), findsNothing);
      expect(find.text('TB'), findsOneWidget);
    });

    testWidgets('falls back to the initials when the logo fails to load', (
      tester,
    ) async {
      await pumpAvatar(
        tester,
        signedIn.copyWith(companies: [membership('Toko Budi', logo: attached)]),
      );
      await tester.runAsync(() async {});
      await tester.pump();

      expect(find.text('TB'), findsOneWidget);
    });
  });
}
