/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/api/http_method.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/native/app_info_fake.dart';
import 'package:pn_types/src/native/device_info_fake.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:pn_types/src/native/public_http_fake.dart';
import 'package:pn_types/src/native/store_fake.dart';
import 'package:pos/device/device_identity.dart';
import 'package:pos/pairing/pairing.dart';
import 'package:pn_types/src/session.dart';
import 'package:pos/session/session_holder.dart';

// Two of the earlier cases asserted that `O` is not a pairing code; that stopped being true
// when the owner decided the client accepts any 0-9A-Z (step 6), so they now use a character
// that really is outside the set. See `plan/api-client/findings.md`.

const canonicalHost = 'https://apps.finnesia.com';

/// The activation response, shaped exactly like the API's envelope.
///
/// `device_token` is the credential the tablet presents on every later POS request. The server
/// returns it here and nowhere else — the database keeps only its hash — so this response is
/// the one chance to keep it.
final activated = jsonEncode({
  'data': {
    'device': {
      'id': '01JDEV',
      'company_id': 'comp_1',
      'outlet_id': 'out_1',
      'name': 'Tablet Kasir 1',
      'activated_at': '2026-09-17T10:00:00Z',
      'created_at': '2026-09-17T10:00:00Z',
      'updated_at': '2026-09-17T10:00:00Z',
    },
    'branding': {
      'app_name': 'Toko Budi',
      'logo_url': 'https://cdn.example.com/logo.png',
      'account_mode': 'self_service',
    },
    'device_token': 'dev_tok_1',
  },
});

/// The deps pairing needs. The session and the device identity share one store, as they do
/// in the app.
PairingDeps depsFor(
  StorePort store,
  FakePublicHttp http, {
  FakeDeviceInfo? deviceInfo,
  FakeAppInfo? appInfo,
}) => (
  store: store,
  http: http,
  session: SessionHolder(store),
  deviceInfo: deviceInfo ?? FakeDeviceInfo(),
  appInfo: appInfo ?? FakeAppInfo(),
  canonicalHost: canonicalHost,
);

FakePublicHttp answering(String body, {int status = 200}) =>
    FakePublicHttp()..respond(TransportResponse(status: status, body: body));

/// The single call a pairing made.
///
/// Asserts there was exactly one: a pairing that sends twice would redeem a single-use code
/// twice, and the second attempt would fail against a code it had already spent.
PublicHttpCall sent(FakePublicHttp http) {
  expect(http.calls, hasLength(1));
  return http.calls.single;
}

/// An enterprise tenant, the only kind that carries a host of its own.
String activatedWithDomain(String? customDomain) => jsonEncode({
  'data': {
    'device': {
      'id': '01JDEV',
      'company_id': 'comp_1',
      'outlet_id': 'out_1',
      'name': 'Tablet Kasir 1',
    },
    'branding': {
      'app_name': 'ERP A',
      'logo_url': 'https://erp.perusahaan.com/logo.png',
      'custom_domain': customDomain,
      'account_mode': 'enterprise',
    },
  },
});

/// The session as pairing left it in the store, read the way the next launch would.
Future<PosSession?> storedSession(FakeStorePort store) =>
    SessionHolder(store).hydrate();

void main() {
  group('buildActivatePayload', () {
    test('builds the three fields dto.ActivateDeviceDTO requires', () async {
      final payload = await buildActivatePayload(
        'AB3K7M',
        FakeStorePort(),
        FakeDeviceInfo(),
      );

      expect(payload, isNotNull);
      expect(payload!.code, 'AB3K7M');
      expect(payload.deviceName, isNotEmpty);
      expect(payload.deviceFingerprint, isNotEmpty);
    });

    // The fingerprint the backend upserts on is the platform's, so a reinstall updates the
    // tablet's row instead of adding one.
    test('sends the platform identifier as the fingerprint', () async {
      final payload = await buildActivatePayload(
        'AB3K7M',
        FakeStorePort(),
        FakeDeviceInfo(id: 'android-abc'),
      );

      expect(payload!.deviceFingerprint, 'android-abc');
    });

    test('normalizes the code before sending it', () async {
      // Codes are displayed in capitals but typed on whatever keyboard the tablet is set to.
      final payload = await buildActivatePayload(
        ' ab3-k7m ',
        FakeStorePort(),
        FakeDeviceInfo(),
      );

      expect(payload!.code, 'AB3K7M');
    });

    test('returns null for a code that is not six characters', () async {
      expect(
        await buildActivatePayload('AB3K7', FakeStorePort(), FakeDeviceInfo()),
        isNull,
      );
    });

    test('returns null for a code using a letter outside A-Z', () async {
      expect(
        await buildActivatePayload('AB3ÉK7', FakeStorePort(), FakeDeviceInfo()),
        isNull,
      );
    });

    test('returns null for an empty code', () async {
      expect(
        await buildActivatePayload('', FakeStorePort(), FakeDeviceInfo()),
        isNull,
      );
    });

    test('reports the same device on a second pairing', () async {
      final store = FakeStorePort();
      final info = FakeDeviceInfo(id: 'android-abc');
      final first = await buildActivatePayload('AB3K7M', store, info);
      final second = await buildActivatePayload('AB3K7M', store, info);

      expect(second!.deviceFingerprint, first!.deviceFingerprint);
    });

    // A device paired before the platform identifier was used keeps the value its server row
    // was keyed on, or re-pairing would orphan that row and add a second one.
    test(
      'keeps the fingerprint a device was already registered under',
      () async {
        final store = FakeStorePort({
          deviceIdKey: '01J8ZQ000000000000000000AB',
        });

        final payload = await buildActivatePayload(
          'AB3K7M',
          store,
          FakeDeviceInfo(id: 'android-abc'),
        );

        expect(payload!.deviceFingerprint, '01J8ZQ000000000000000000AB');
      },
    );

    test('sends the device name the cashier chose', () async {
      final payload = await buildActivatePayload(
        'AB3K7M',
        FakeStorePort(),
        FakeDeviceInfo(),
        deviceName: 'Kasir Depan',
      );

      expect(payload!.deviceName, 'Kasir Depan');
    });

    test('never sends a device name the DTO would reject', () async {
      final payload = await buildActivatePayload(
        'AB3K7M',
        FakeStorePort(),
        FakeDeviceInfo(),
        deviceName: 'x' * 500,
      );

      expect(payload!.deviceName.length, lessThanOrEqualTo(deviceNameMax));
    });
  });

  group('pairDevice — the activate call', () {
    test('POSTs to the canonical activate path', () async {
      final http = answering(activated);
      await pairDevice('AB3K7M', depsFor(FakeStorePort(), http));

      final call = sent(http);
      expect(call.baseUrl, canonicalHost);
      expect(call.request.path, '/api/v1/pos/devices/activate');
      expect(call.request.method, HttpMethod.post);
    });

    test('sends the fields the DTO requires, as JSON', () async {
      final http = answering(activated);
      await pairDevice(
        ' ab3-k7m ',
        depsFor(FakeStorePort(), http),
        deviceName: 'Kasir Depan',
      );

      final request = sent(http).request;
      final body = jsonDecode(request.body!) as Map<String, dynamic>;
      expect(
        body.keys,
        containsAll(['code', 'device_fingerprint', 'device_name']),
      );
      expect(body['code'], 'AB3K7M');
      expect(body['device_name'], 'Kasir Depan');
      // The platform identifier, not a value the app minted: that is what survives a reinstall.
      expect(body['device_fingerprint'], 'fake_android_id');
      expect(request.headers['Content-Type'], 'application/json');
    });

    // Optional on the server (`dto.ActivateDeviceDTO`): an admin reads them in the device list to
    // tell an Android tablet from a Windows till. Display-only, so nothing here can fail a pairing.
    test('says what the device is, and which build of the app', () async {
      final http = answering(activated);
      final deviceInfo = FakeDeviceInfo()
        ..description = (
          platform: 'android',
          osVersion: '14',
          deviceModel: 'samsung SM-X110',
        );

      await pairDevice(
        'AB3K7M',
        depsFor(
          FakeStorePort(),
          http,
          deviceInfo: deviceInfo,
          appInfo: FakeAppInfo(answer: (version: '1.4.2', build: '37')),
        ),
      );

      final body = jsonDecode(sent(http).request.body!) as Map<String, dynamic>;
      expect(body['platform'], 'android');
      expect(body['os_version'], '14');
      expect(body['device_model'], 'samsung SM-X110');
      expect(body['app_version'], '1.4.2+37');
    });

    test('leaves out what the platform could not say', () async {
      final http = answering(activated);
      final deviceInfo = FakeDeviceInfo()
        ..description = (
          platform: 'windows',
          osVersion: null,
          deviceModel: '  ',
        );

      await pairDevice(
        'AB3K7M',
        depsFor(
          FakeStorePort(),
          http,
          deviceInfo: deviceInfo,
          appInfo: FakeAppInfo(answer: null),
        ),
      );

      final body = jsonDecode(sent(http).request.body!) as Map<String, dynamic>;
      expect(body['platform'], 'windows');
      expect(body.containsKey('os_version'), isFalse);
      expect(body.containsKey('device_model'), isFalse);
      expect(body.containsKey('app_version'), isFalse);
    });

    test('sends the version alone when the build has no number', () async {
      final http = answering(activated);

      await pairDevice(
        'AB3K7M',
        depsFor(
          FakeStorePort(),
          http,
          appInfo: FakeAppInfo(answer: (version: '1.4.2', build: '')),
        ),
      );

      final body = jsonDecode(sent(http).request.body!) as Map<String, dynamic>;
      expect(body['app_version'], '1.4.2');
    });

    // The server answers 400 to anything over these (`validate:"max=..."`), and a pairing that a
    // long model name turns into a 400 would leave the tablet unable to join at all.
    test('cuts each field to what the server accepts', () async {
      final http = answering(activated);
      final deviceInfo = FakeDeviceInfo()
        ..description = (
          platform: 'p' * 40,
          osVersion: 'o' * 80,
          deviceModel: 'm' * 200,
        );

      await pairDevice(
        'AB3K7M',
        depsFor(
          FakeStorePort(),
          http,
          deviceInfo: deviceInfo,
          appInfo: FakeAppInfo(answer: (version: 'v' * 40, build: '1')),
        ),
      );

      final body = jsonDecode(sent(http).request.body!) as Map<String, dynamic>;
      expect((body['platform'] as String).length, 32);
      expect((body['os_version'] as String).length, 64);
      expect((body['app_version'] as String).length, 32);
      expect((body['device_model'] as String).length, 128);
    });

    test('rejects with a PairingException instance', () async {
      final http = FakePublicHttp()..fail(TransportException('network down'));

      final error = await pairDevice(
        'AB3K7',
        depsFor(FakeStorePort(), http),
      ).then<Object?>((_) => null, onError: (Object e) => e);

      expect(error, isA<PairingException>());
    });

    test('reports invalidCode for a code that is not six characters', () async {
      final http = answering(activated);

      await expectLater(
        pairDevice('AB3K7', depsFor(FakeStorePort(), http)),
        throwsA(isPairingFailure(PairingFailure.invalidCode)),
      );
      // A code that cannot exist must not become a request.
      expect(http.calls, isEmpty);
    });

    test('reports invalidCode for a code using a letter outside A-Z', () async {
      final http = answering(activated);

      await expectLater(
        pairDevice('AB3ÉK7', depsFor(FakeStorePort(), http)),
        throwsA(isPairingFailure(PairingFailure.invalidCode)),
      );
      expect(http.calls, isEmpty);
    });

    test('reports invalidCode for a code with symbols', () async {
      await expectLater(
        pairDevice('AB3@K7', depsFor(FakeStorePort(), answering(activated))),
        throwsA(isPairingFailure(PairingFailure.invalidCode)),
      );
    });

    // The pairing-side twin of step 6's decision: I, L, O, 0 and 1 are not in the alphabet
    // the backend draws from, but the client still sends them. The server says no, and that is
    // a `codeRejected`, not a code the app refuses to try.
    test('sends a code containing I, L, O, 0 or 1 like any other', () async {
      final http = answering(activated);

      await pairDevice('IL0O11', depsFor(FakeStorePort(), http));

      expect(jsonDecode(sent(http).request.body!)['code'], 'IL0O11');
    });

    test('normalizes case and separators before validating', () async {
      await pairDevice(
        'ab3-k7m',
        depsFor(FakeStorePort(), answering(activated)),
      );
      await pairDevice(
        'AB3 K7M',
        depsFor(FakeStorePort(), answering(activated)),
      );
    });

    // Nothing was going to be sent, so nothing about this device should be written either.
    test('leaves the store untouched when the code is invalid', () async {
      final store = FakeStorePort();

      await expectLater(
        pairDevice('AB3K7', depsFor(store, answering(activated))),
        throwsA(isPairingFailure(PairingFailure.invalidCode)),
      );

      expect(store.operations, isEmpty);
    });

    // 401 is what `invalidPairingCode()` returns for unknown, used, and expired alike — the
    // backend will not say which, so neither can the app. What it does say is that the code is
    // the problem, not the connection.
    test(
      'reports codeRejected when the API says the code is no good',
      () async {
        final http = answering('{"error":true}', status: 401);

        await expectLater(
          pairDevice('AB3K7M', depsFor(FakeStorePort(), http)),
          throwsA(isPairingFailure(PairingFailure.codeRejected)),
        );
      },
    );

    test('reports unavailable when the API fails for a reason that is not the code', () async {
      final http = answering('{"error":true}', status: 500);

      await expectLater(
        pairDevice('AB3K7M', depsFor(FakeStorePort(), http)),
        throwsA(isPairingFailure(PairingFailure.unavailable)),
      );
    });

    test('reports unavailable when the request itself fails', () async {
      final http = FakePublicHttp()..fail(TransportException('network down'));

      await expectLater(
        pairDevice('AB3K7M', depsFor(FakeStorePort(), http)),
        throwsA(isPairingFailure(PairingFailure.unavailable)),
      );
    });

    test('reports unavailable when the response body is not the shape the API promises', () async {
      final http = answering('{"data":{"device":{}}}');

      await expectLater(
        pairDevice('AB3K7M', depsFor(FakeStorePort(), http)),
        throwsA(isPairingFailure(PairingFailure.unavailable)),
      );
    });

    // The outlet already holds its maximum number of tablets, and this one is not among them.
    // A generic "that did not work" would send the cashier to try another code, when the real
    // fix is on the dashboard.
    test(
      'reports the outlet limit, with the number, when the server names it',
      () async {
        final http = answering(
          '{"data":null,"error":{"name":"unprocessible_entity","code":720,'
          '"key":"pos_device_limit_reached","params":{"limit":10}}}',
          status: 422,
        );

        final error = await pairDevice(
          'AB3K7M',
          depsFor(FakeStorePort(), http),
        ).then<Object?>((_) => null, onError: (Object e) => e);

        expect(error, isA<PairingException>());
        expect(
          (error! as PairingException).reason,
          PairingFailure.deviceLimitReached,
        );
        expect((error as PairingException).deviceLimit, 10);
      },
    );

    // The number is optional. Without it the screen says the outlet is full and leaves the
    // number out, rather than printing a placeholder.
    test(
      'reports the outlet limit without a number when params are absent',
      () async {
        final http = answering(
          '{"data":null,"error":{"code":720,"key":"pos_device_limit_reached"}}',
          status: 422,
        );

        final error = await pairDevice(
          'AB3K7M',
          depsFor(FakeStorePort(), http),
        ).then<Object?>((_) => null, onError: (Object e) => e);

        expect(
          (error! as PairingException).reason,
          PairingFailure.deviceLimitReached,
        );
        expect((error as PairingException).deviceLimit, isNull);
      },
    );

    // 422 is also what a duplicate fingerprint or a truncated name returns, and both arrive with
    // code 720. Without the key there is no way to tell them apart, so the app must NOT claim
    // the outlet is full — that would send the cashier to delete a tablet for nothing.
    test(
      'does not claim the outlet is full for a 422 without the key',
      () async {
        final http = answering(
          '{"data":null,"error":{"code":720,"description":"duplicate"}}',
          status: 422,
        );

        await expectLater(
          pairDevice('AB3K7M', depsFor(FakeStorePort(), http)),
          throwsA(isPairingFailure(PairingFailure.unavailable)),
        );
      },
    );

    // A 401 stays what it always was: the code is the problem.
    test(
      'still reports codeRejected for a 401, not a device problem',
      () async {
        final http = answering('{"error":true}', status: 401);

        await expectLater(
          pairDevice('AB3K7M', depsFor(FakeStorePort(), http)),
          throwsA(isPairingFailure(PairingFailure.codeRejected)),
        );
      },
    );
  });

  group('pairDevice — the session it leaves behind', () {
    test(
      'locks the canonical host when the tenant has no custom domain',
      () async {
        final store = FakeStorePort();
        await pairDevice('AB3K7M', depsFor(store, answering(activated)));

        expect((await storedSession(store))!.baseUrl, canonicalHost);
      },
    );

    test(
      'locks the tenant custom domain when the response carries one',
      () async {
        final store = FakeStorePort();
        await pairDevice(
          'AB3K7M',
          depsFor(store, answering(activatedWithDomain('erp.perusahaan.com'))),
        );

        expect(
          (await storedSession(store))!.baseUrl,
          'https://erp.perusahaan.com',
        );
      },
    );

    test('keeps the branding so the login screen shows the tenant, not the product', () async {
      final store = FakeStorePort();
      await pairDevice('AB3K7M', depsFor(store, answering(activated)));

      final branding = (await storedSession(store))!.branding!;
      expect(branding.appName, 'Toko Budi');
      expect(branding.logoUrl, 'https://cdn.example.com/logo.png');
      expect(branding.accountMode, 'self_service');
    });

    test('stores the company and outlet the code resolved to, and no session token', () async {
      final store = FakeStorePort();
      await pairDevice('AB3K7M', depsFor(store, answering(activated)));

      final session = (await storedSession(store))!;
      // Pairing registers the device; the credential only arrives at login.
      expect(session.companyId, 'comp_1');
      expect(session.outletId, 'out_1');
      expect(session.sessionToken, '');
      expect(session.deviceName, 'Tablet Kasir 1');
    });

    // The device token is returned by this call and by no other. Losing it costs a re-pair,
    // and without it the server cannot write presence for this tablet.
    test('keeps the device token the activation returned', () async {
      final store = FakeStorePort();
      await pairDevice('AB3K7M', depsFor(store, answering(activated)));

      expect((await storedSession(store))!.deviceToken, 'dev_tok_1');
    });

    // A device paired against a backend that predates the registry gets no token. That is not
    // a failed pairing: the tablet works, it just has no device identity until it pairs again.
    test(
      'pairs without a device token when the response carries none',
      () async {
        final store = FakeStorePort();
        final body = jsonEncode({
          'data': {
            'device': {
              'id': '01JDEV',
              'company_id': 'comp_1',
              'outlet_id': 'out_1',
              'name': 'Tablet Kasir 1',
            },
            'branding': {'app_name': 'Toko Budi'},
          },
        });

        await pairDevice('AB3K7M', depsFor(store, answering(body)));

        final session = (await storedSession(store))!;
        expect(session.outletId, 'out_1');
        expect(session.deviceToken, isNull);
      },
    );

    // The transport reads "empty string" as no token, so storing one would be a lie the next
    // request silently acts on. An empty token is absence, not a credential.
    test('reads an empty device token as none', () async {
      final store = FakeStorePort();
      final body = jsonEncode({
        'data': {
          'device': {'company_id': 'comp_1', 'outlet_id': 'out_1'},
          'branding': <String, dynamic>{},
          'device_token': '',
        },
      });

      await pairDevice('AB3K7M', depsFor(store, answering(body)));

      expect((await storedSession(store))!.deviceToken, isNull);
    });

    // A token of the wrong type is a body the API did not promise. It must not become the
    // string "7" and be sent as a credential on every request afterwards.
    test('reads a device token that is not a string as none', () async {
      final store = FakeStorePort();
      final body = jsonEncode({
        'data': {
          'device': {'company_id': 'comp_1', 'outlet_id': 'out_1'},
          'branding': <String, dynamic>{},
          'device_token': 7,
        },
      });

      await pairDevice('AB3K7M', depsFor(store, answering(body)));

      expect((await storedSession(store))!.deviceToken, isNull);
    });

    test('makes the session readable straight after pairing', () async {
      final deps = depsFor(FakeStorePort(), answering(activated));
      await pairDevice('AB3K7M', deps);

      // The transport reads the session synchronously, so pairing has to fill the cache and
      // not only the store — otherwise the first request after pairing still looks unpaired.
      expect(deps.session.current?.outletId, 'out_1');
    });

    test(
      'leaves the stored fingerprint alone, so the device row is the same one',
      () async {
        final store = FakeStorePort();
        await pairDevice('AB3K7M', depsFor(store, answering(activated)));
        final fingerprint = store.values[deviceIdKey];

        await pairDevice('AB3K7M', depsFor(store, answering(activated)));
        expect(store.values[deviceIdKey], fingerprint);
      },
    );
  });

  // README §13.4: the source forces `https://` in front of whatever the tenant's domain is, so
  // a tenant reachable only over http — a dev tenant with a domain of its own, and the only
  // way to test one — is locked to a URL that fails TLS. Every case here is the base URL the
  // session ends up locked to.
  group('pairDevice — the host the session locks to', () {
    const cases = <String, String>{
      'erp.perusahaan.com': 'https://erp.perusahaan.com',
      'https://erp.perusahaan.com': 'https://erp.perusahaan.com',
      'http://dev.tenant.test': 'http://dev.tenant.test',
      'http://localhost:4001': 'http://localhost:4001',
      'erp.perusahaan.com:8443': 'https://erp.perusahaan.com:8443',
      // Whatever the server stored, the origin has no trailing slash.
      'https://erp.perusahaan.com/': 'https://erp.perusahaan.com',
      'erp.perusahaan.com///': 'https://erp.perusahaan.com',
      ' erp.perusahaan.com ': 'https://erp.perusahaan.com',
      // A scheme is case-insensitive, and the URL is used as written.
      'HTTPS://erp.perusahaan.com': 'https://erp.perusahaan.com',
      'HTTP://dev.tenant.test': 'http://dev.tenant.test',
      // A domain that is not one falls back to the host the device paired against, rather
      // than a session that points at a host nobody controls.
      '': canonicalHost,
      '   ': canonicalHost,
      'https://': canonicalHost,
      'http://': canonicalHost,
      '/': canonicalHost,
      'erp perusahaan.com': canonicalHost,
    };

    for (final MapEntry(key: domain, value: expected) in cases.entries) {
      test('custom_domain ${jsonEncode(domain)} locks $expected', () async {
        final store = FakeStorePort();
        await pairDevice(
          'AB3K7M',
          depsFor(store, answering(activatedWithDomain(domain))),
        );

        expect((await storedSession(store))!.baseUrl, expected);
      });
    }

    test('a custom_domain of null locks the canonical host', () async {
      final store = FakeStorePort();
      await pairDevice(
        'AB3K7M',
        depsFor(store, answering(activatedWithDomain(null))),
      );

      expect((await storedSession(store))!.baseUrl, canonicalHost);
    });
  });

  // A 200 that is not an activation must not leave a half-read session behind: it would
  // point the device at no tenant, and the pairing screen would never show again.
  group('pairDevice — a response it cannot use', () {
    final unusable = <String, String>{
      'not JSON': 'upstream connect error',
      'an empty body': '',
      'JSON that is not an object': '[1,2]',
      'no data envelope':
          '{"device":{"company_id":"c","outlet_id":"o"},"branding":{}}',
      'no branding': '{"data":{"device":{"company_id":"c","outlet_id":"o"}}}',
      'no device': '{"data":{"branding":{}}}',
      'an empty company id':
          '{"data":{"device":{"company_id":"","outlet_id":"o"},"branding":{}}}',
      'an empty outlet id':
          '{"data":{"device":{"company_id":"c","outlet_id":""},"branding":{}}}',
      'a numeric company id':
          '{"data":{"device":{"company_id":7,"outlet_id":"o"},"branding":{}}}',
      'branding fields of the wrong type':
          '{"data":{"device":{"company_id":"c","outlet_id":"o"},'
          '"branding":{"app_name":5,"custom_domain":true}}}',
    };

    for (final MapEntry(key: what, value: body) in unusable.entries) {
      test('reports unavailable, and saves nothing, for $what', () async {
        final store = FakeStorePort();
        final deps = depsFor(store, answering(body));

        await expectLater(
          pairDevice('AB3K7M', deps),
          throwsA(isPairingFailure(PairingFailure.unavailable)),
        );

        expect(deps.session.current, isNull);
        expect(store.values.containsKey(sessionKey), isFalse);
      });
    }

    test(
      'does not retry: a single-use code is redeemed by one request',
      () async {
        final http = FakePublicHttp()..fail(TransportException('timeout'));

        await expectLater(
          pairDevice('AB3K7M', depsFor(FakeStorePort(), http)),
          throwsA(isPairingFailure(PairingFailure.unavailable)),
        );

        expect(http.calls, hasLength(1));
      },
    );

    test('saves no session when the server says no', () async {
      final store = FakeStorePort();
      final deps = depsFor(store, answering('{"error":true}', status: 401));

      await expectLater(
        pairDevice('AB3K7M', deps),
        throwsA(isPairingFailure(PairingFailure.codeRejected)),
      );

      expect(deps.session.current, isNull);
      expect(store.values.containsKey(sessionKey), isFalse);
    });
  });

  // A failing storage is not a pairing failure and is not swallowed into one: the cashier's
  // advice is different (the tablet is broken, not the code), and both ends of the pairing
  // depend on it.
  group('pairDevice — a store that fails', () {
    test(
      'stops before any request when the fingerprint cannot be read',
      () async {
        final store = FakeStorePort()
          ..failNext(StoreException('disk unreadable'));
        final http = answering(activated);

        await expectLater(
          pairDevice('AB3K7M', depsFor(store, http)),
          throwsA(isA<StoreException>()),
        );

        // Registering a device whose fingerprint may not be the one it already has would
        // orphan its row on the server.
        expect(http.calls, isEmpty);
      },
    );

    // The code is single-use and the server has already spent it by now, so this is the
    // one failure that costs the cashier a fresh code — and it must at least be visible.
    test(
      'lets a StoreException from saving the session reach the caller',
      () async {
        final store = FakeStorePort();
        final failing = FailsWritingKey(store, sessionKey);

        await expectLater(
          pairDevice('AB3K7M', depsFor(failing, answering(activated))),
          throwsA(isA<StoreException>()),
        );
      },
    );
  });
}

/// A store that works, except that writing [key] fails: the disk that fills up between the
/// fingerprint and the session. `FakeStorePort.failNext` cannot aim at the third operation.
class FailsWritingKey implements StorePort {
  FailsWritingKey(this.inner, this.key);

  final FakeStorePort inner;
  final String key;

  @override
  Future<String?> read(String key) => inner.read(key);

  @override
  Future<void> write(String key, String value) => key == this.key
      ? Future.error(StoreException('disk full'))
      : inner.write(key, value);

  @override
  Future<void> remove(String key) => inner.remove(key);
}

/// A [PairingException] with this [reason].
Matcher isPairingFailure(PairingFailure reason) =>
    isA<PairingException>().having((e) => e.reason, 'reason', reason);
