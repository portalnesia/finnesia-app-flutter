/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:pn_types/src/file_ref.dart';
import 'package:pn_types/src/session.dart';
import 'package:pn_types/src/tenant.dart';
import 'package:test/test.dart';

// The type half of the session model, plus `isSamePairing` (3 cases). The rest — the cache,
// the listeners, the persistence — is `SessionHolder` in `apps/pos`, tested there.

const paired = PosSession(
  baseUrl: 'https://erp.perusahaan.com',
  companyId: 'comp_1',
  outletId: 'out_1',
  deviceName: 'Tablet Kasir 1',
  sessionToken: '',
  branding: PosBranding(appName: 'Toko Budi'),
);

/// A device paired after the registry change, so it holds the token activation issued.
const pairedWithToken = PosSession(
  baseUrl: 'https://erp.perusahaan.com',
  companyId: 'comp_1',
  outletId: 'out_1',
  deviceName: 'Tablet Kasir 1',
  sessionToken: '',
  deviceToken: 'dev_tok_1',
  branding: PosBranding(appName: 'Toko Budi'),
);

/// A paired device with a cashier signed in on it.
const signedIn = PosSession(
  baseUrl: 'https://erp.perusahaan.com',
  companyId: 'comp_1',
  outletId: 'out_1',
  deviceName: 'Tablet Kasir 1',
  sessionToken: 'tok_secret_1',
  sessionRefreshToken: 'refresh_secret_1',
  expiresAt: '2026-09-24T10:00:00Z',
  user: SessionUser(id: 'usr_1', name: 'Budi', email: 'budi@example.com'),
  companies: [
    UserCompany(
      id: 'uc_1',
      userId: 'usr_1',
      companyId: 'comp_1',
      role: 'cashier',
      isActive: true,
    ),
  ],
  branding: PosBranding(appName: 'Toko Budi'),
);

// Through real JSON text, the way the store will hand it back.
PosSession roundTrip(PosSession s) => PosSession.fromJson(
  jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>,
);

void main() {
  group('PosSession JSON', () {
    test('a signed-in session survives a round trip through JSON text', () {
      expect(roundTrip(signedIn), signedIn);
    });

    test('a paired session with no cashier survives it too', () {
      expect(roundTrip(paired), paired);
    });

    test('reads a persisted session, leaving what was never set null', () {
      final s = PosSession.fromJson(
        jsonDecode(
              '{"baseUrl":"https://x.example","companyId":"c","outletId":"o","sessionToken":""}',
            )
            as Map<String, dynamic>,
      );

      expect(s.deviceName, isNull);
      expect(s.sessionRefreshToken, isNull);
      expect(s.expiresAt, isNull);
      expect(s.user, isNull);
      expect(s.companies, isNull);
      expect(s.branding, isNull);
    });

    // `session.companies` is null on a device that is paired but not signed in, and an empty
    // list on one where the login returned no memberships. They are different facts.
    test('keeps an empty list of memberships distinct from none', () {
      final s = roundTrip(paired.copyWith(companies: const []));

      expect(s.companies, isEmpty);
      expect(roundTrip(paired).companies, isNull);
    });

    test('rejects a session with no baseUrl', () {
      expect(
        () => PosSession.fromJson(
          jsonDecode('{"companyId":"c","outletId":"o","sessionToken":""}')
              as Map<String, dynamic>,
        ),
        throwsA(isA<TypeError>()),
      );
    });

    test('rejects a session with no sessionToken, even an empty one', () {
      expect(
        () => PosSession.fromJson(
          jsonDecode('{"baseUrl":"https://x","companyId":"c","outletId":"o"}')
              as Map<String, dynamic>,
        ),
        throwsA(isA<TypeError>()),
      );
    });

    // The device token is the credential the tablet presents as `X-Device-Token` on every POS
    // request. Activation returns it once and there is no endpoint to fetch it again, so losing
    // it costs a re-pair: it has to survive the store the way the session token does.
    test('keeps the device token through a round trip', () {
      expect(roundTrip(pairedWithToken).deviceToken, 'dev_tok_1');
    });

    // A device paired before the registry change has no token. That is not an error state to
    // throw on: it is a device that has to pair once more, which the gate decides by reading
    // this as absent.
    test('reads a session that carries no device token as having none', () {
      expect(roundTrip(paired).deviceToken, isNull);
    });

    test('reads a device token of an empty string as no token', () {
      final s = roundTrip(pairedWithToken.copyWith(deviceToken: ''));

      expect(s.deviceToken, isEmpty);
    });
  });

  group('PosBranding', () {
    // These four names come straight from `companies.branding_config` in the activation
    // response, so they keep the wire's snake_case in the persisted session too.
    test('reads the activation response\'s snake_case names', () {
      final b = PosBranding.fromJson(
        jsonDecode(
              '{"app_name":"Toko","custom_domain":"erp.toko.id","account_mode":"managed"}',
            )
            as Map<String, dynamic>,
      );

      expect(b.appName, 'Toko');
      expect(b.customDomain, 'erp.toko.id');
      expect(b.accountMode, 'managed');
    });

    test('leaves every field null for a tenant with no branding set', () {
      final b = PosBranding.fromJson(<String, dynamic>{});

      expect(b.appName, isNull);
      expect(b.customDomain, isNull);
      expect(b.logo, isNull);
    });

    // The logo is a `FileRef` object now, not a URL string: the activation response ships the
    // file's `status` alongside it, and a `pending` or `detached` file must not be rendered.
    test('reads the logo as a file reference', () {
      final b = PosBranding.fromJson(
        jsonDecode(
              '{"app_name":"Toko","logo":{"id":"file_1","name":"logo.png",'
              '"size_bytes":1234,"content_type":"image/png","status":"attached",'
              '"url":"https://cdn.example/logo.png",'
              '"created_at":"2026-01-01T00:00:00Z"}}',
            )
            as Map<String, dynamic>,
      );

      expect(b.logo?.id, 'file_1');
      expect(b.logo?.renderableUrl, 'https://cdn.example/logo.png');
    });

    test('reads a detached logo as nothing to render', () {
      final b = PosBranding.fromJson(
        jsonDecode(
              '{"logo":{"id":"file_1","status":"detached","url":"https://cdn.example/l.png"}}',
            )
            as Map<String, dynamic>,
      );

      expect(b.logo, isNotNull);
      expect(b.logo?.renderableUrl, isNull);
    });

    // A backend that has not shipped the object yet still sends the old string key. It is
    // ignored, so `logo` reads as null and the login falls back to the Finnesia logo — the
    // pairing itself must not fail.
    test('ignores the old logo_url string instead of failing to parse', () {
      final b = PosBranding.fromJson(
        jsonDecode('{"app_name":"Toko","logo_url":"https://cdn.example/l.png"}')
            as Map<String, dynamic>,
      );

      expect(b.appName, 'Toko');
      expect(b.logo, isNull);
    });

    test('survives a round trip with the logo attached', () {
      final s = roundTrip(
        paired.copyWith(
          branding: const PosBranding(
            appName: 'Toko Budi',
            logo: FileRef(
              id: 'file_1',
              status: 'attached',
              url: 'https://u/l.png',
            ),
          ),
        ),
      );

      expect(s.branding?.logo?.renderableUrl, 'https://u/l.png');
    });
  });

  // The default `toString` prints every field, and two of them are bearer tokens. A session
  // that reaches a log line or a crash report must not carry them (`security.md` §1).
  group('PosSession.toString', () {
    test('does not print the session token or the refresh token', () {
      final text = signedIn.toString();

      expect(text, isNot(contains('tok_secret_1')));
      expect(text, isNot(contains('refresh_secret_1')));
    });

    test('does not print the cashier\'s name or email', () {
      final text = signedIn.toString();

      expect(text, isNot(contains('budi@example.com')));
      expect(text, isNot(contains('Budi')));
    });

    // A third credential now lives on the session. It is the one that identifies the tablet to
    // the server, so printing it would let anyone holding a log line act as the device.
    test('does not print the device token', () {
      final text = pairedWithToken.toString();

      expect(text, isNot(contains('dev_tok_1')));
    });

    test('still says which pairing it is, for a debugger', () {
      expect(signedIn.toString(), contains('out_1'));
      expect(signedIn.toString(), contains('https://erp.perusahaan.com'));
    });
  });

  // The same leak by another route: someone logs `session.user` instead of the session.
  group('SessionUser.toString', () {
    test('prints the id and not the name or email', () {
      const user = SessionUser(
        id: 'usr_1',
        name: 'Budi',
        email: 'budi@example.com',
      );

      expect(user.toString(), contains('usr_1'));
      expect(user.toString(), isNot(contains('Budi')));
      expect(user.toString(), isNot(contains('budi@example.com')));
    });
  });

  group('isSamePairing', () {
    // A rotated token replaces the session object; the device is still paired to the same
    // outlet, so a login in flight for it is still valid.
    test(
      'is true for the same pairing even after the session object was replaced',
      () {
        expect(
          isSamePairing(signedIn, signedIn.copyWith(sessionToken: 'rotated')),
          isTrue,
        );
      },
    );

    test('is false once the device has been reset', () {
      expect(isSamePairing(null, signedIn), isFalse);
      expect(isSamePairing(signedIn, null), isFalse);
    });

    test('is false when the device was re-paired somewhere else', () {
      expect(
        isSamePairing(signedIn.copyWith(outletId: 'out_2'), signedIn),
        isFalse,
      );
      expect(
        isSamePairing(signedIn.copyWith(companyId: 'comp_2'), signedIn),
        isFalse,
      );
      expect(
        isSamePairing(
          signedIn.copyWith(baseUrl: 'https://other.example.com'),
          signedIn,
        ),
        isFalse,
      );
    });
  });
}
