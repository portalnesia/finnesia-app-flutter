/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:dev/dispatch.dart';
import 'package:test/test.dart';

/// The 18 rows of SPEC §2a, in its order. [valid] is `true` for the nine rows the
/// dispatcher runs and `false` for the nine it rejects.
const _rows = <({
  int number,
  DispatchEnv env,
  DispatchDevice device,
  DispatchDraft draft,
  bool valid,
  List<String> says,
})>[
  (
    number: 1,
    env: DispatchEnv.staging,
    device: DispatchDevice.android,
    draft: DispatchDraft.no,
    valid: true,
    says: [],
  ),
  (
    number: 2,
    env: DispatchEnv.staging,
    device: DispatchDevice.android,
    draft: DispatchDraft.yes,
    valid: true,
    says: [],
  ),
  (
    number: 3,
    env: DispatchEnv.staging,
    device: DispatchDevice.windows,
    draft: DispatchDraft.no,
    valid: false,
    says: ['staging', 'windows'],
  ),
  (
    number: 4,
    env: DispatchEnv.staging,
    device: DispatchDevice.windows,
    draft: DispatchDraft.yes,
    valid: false,
    says: ['staging', 'windows'],
  ),
  (
    number: 5,
    env: DispatchEnv.staging,
    device: DispatchDevice.all,
    draft: DispatchDraft.no,
    valid: false,
    says: ['staging', 'windows'],
  ),
  (
    number: 6,
    env: DispatchEnv.staging,
    device: DispatchDevice.all,
    draft: DispatchDraft.yes,
    valid: false,
    says: ['staging', 'windows'],
  ),
  (
    number: 7,
    env: DispatchEnv.production,
    device: DispatchDevice.android,
    draft: DispatchDraft.no,
    valid: true,
    says: [],
  ),
  (
    number: 8,
    env: DispatchEnv.production,
    device: DispatchDevice.android,
    draft: DispatchDraft.yes,
    valid: true,
    says: [],
  ),
  (
    number: 9,
    env: DispatchEnv.production,
    device: DispatchDevice.windows,
    draft: DispatchDraft.no,
    valid: true,
    says: [],
  ),
  (
    number: 10,
    env: DispatchEnv.production,
    device: DispatchDevice.windows,
    draft: DispatchDraft.yes,
    valid: true,
    says: [],
  ),
  (
    number: 11,
    env: DispatchEnv.production,
    device: DispatchDevice.all,
    draft: DispatchDraft.no,
    valid: true,
    says: [],
  ),
  (
    number: 12,
    env: DispatchEnv.production,
    device: DispatchDevice.all,
    draft: DispatchDraft.yes,
    valid: true,
    says: [],
  ),
  (
    number: 13,
    env: DispatchEnv.patch,
    device: DispatchDevice.android,
    draft: DispatchDraft.no,
    valid: false,
    says: ['patch', 'versi', 'OTA'],
  ),
  (
    number: 14,
    env: DispatchEnv.patch,
    device: DispatchDevice.android,
    draft: DispatchDraft.yes,
    valid: true,
    says: [],
  ),
  (
    number: 15,
    env: DispatchEnv.patch,
    device: DispatchDevice.windows,
    draft: DispatchDraft.no,
    valid: false,
    says: ['patch', 'windows'],
  ),
  (
    number: 16,
    env: DispatchEnv.patch,
    device: DispatchDevice.windows,
    draft: DispatchDraft.yes,
    valid: false,
    says: ['patch', 'windows'],
  ),
  (
    number: 17,
    env: DispatchEnv.patch,
    device: DispatchDevice.all,
    draft: DispatchDraft.no,
    valid: false,
    says: ['patch', 'windows'],
  ),
  (
    number: 18,
    env: DispatchEnv.patch,
    device: DispatchDevice.all,
    draft: DispatchDraft.yes,
    valid: false,
    says: ['patch', 'windows'],
  ),
];

/// The version each env insists on when `draft release = yes` (SPEC §3.1).
const _shapedVersion = {
  DispatchEnv.staging: '1.2.0-staging.3',
  DispatchEnv.production: '1.2.0',
  DispatchEnv.patch: '1.2.0-5',
};

DispatchRequest request({
  required DispatchEnv env,
  required DispatchDevice device,
  required DispatchDraft draft,
  String version = '',
}) =>
    DispatchRequest(env: env, device: device, draft: draft, version: version);

/// Any refusal, message unchecked: used where the point is that it refuses at all, not why.
Matcher anyRejection() => throwsA(isA<DispatchRejection>());

Matcher rejected(List<String> says) => throwsA(
      isA<DispatchRejection>().having(
        (e) => e.message,
        'message',
        predicate<String>((m) {
          for (final word in says) {
            if (!m.contains(word)) {
              return false;
            }
          }
          return true;
        }),
      ),
    );

void main() {
  group('the 18 combinations of SPEC §2a', () {
    test('there are 18 of them, nine valid and nine rejected', () {
      expect(_rows, hasLength(18));
      expect(_rows.where((r) => r.valid), hasLength(9));
      expect(_rows.where((r) => !r.valid), hasLength(9));
    });

    for (final row in _rows) {
      // A version that suits the env, so a rejection here can only come from the combination
      // itself and not from the version gate (which has its own group below).
      final label = 'row ${row.number}: ${row.env.name} / ${row.device.name} / '
          '${row.draft.name}';
      final shaped = _shapedVersion[row.env]!;

      test(label, () {
        final call = () => planDispatch(request(
              env: row.env,
              device: row.device,
              draft: row.draft,
              version: row.draft == DispatchDraft.yes ? shaped : '',
            ));

        if (row.valid) {
          expect(call, returnsNormally);
        } else {
          expect(call, rejected(row.says));
        }
      });
    }
  });

  group('what each valid combination runs', () {
    DispatchAction actionFor(
            DispatchEnv env, DispatchDevice device, DispatchDraft draft) =>
        planDispatch(request(
          env: env,
          device: device,
          draft: draft,
          version: draft == DispatchDraft.yes ? _shapedVersion[env]! : '',
        ));

    test('staging runs staging-pos.yml, and only android is valid there', () {
      expect(
        actionFor(DispatchEnv.staging, DispatchDevice.android, DispatchDraft.no)
            .workflows,
        ['staging-pos.yml'],
      );
    });

    test('production android runs release-pos.yml', () {
      expect(
        actionFor(DispatchEnv.production, DispatchDevice.android,
                DispatchDraft.yes)
            .workflows,
        ['release-pos.yml'],
      );
    });

    test('production windows runs windows-pos.yml', () {
      expect(
        actionFor(DispatchEnv.production, DispatchDevice.windows,
                DispatchDraft.yes)
            .workflows,
        ['windows-pos.yml'],
      );
    });

    // `all` is one version number written by two workflows into one draft, so they queue behind
    // the same concurrency group (SPEC §1.1, §3.4).
    test('production all runs both, android first', () {
      expect(
        actionFor(DispatchEnv.production, DispatchDevice.all, DispatchDraft.yes)
            .workflows,
        ['release-pos.yml', 'windows-pos.yml'],
      );
    });

    test('patch runs shorebird-patch.yml', () {
      expect(
        actionFor(DispatchEnv.patch, DispatchDevice.android, DispatchDraft.yes)
            .workflows,
        ['shorebird-patch.yml'],
      );
    });

    // `draft release = no` is the trial run: artifacts and nothing else. A tag or a draft made by
    // a trial run is not a trial run.
    test('draft release = no creates neither a tag nor a draft', () {
      const valid = [
        (DispatchEnv.staging, DispatchDevice.android),
        (DispatchEnv.production, DispatchDevice.android),
        (DispatchEnv.production, DispatchDevice.windows),
        (DispatchEnv.production, DispatchDevice.all),
      ];
      for (final (env, device) in valid) {
        final action = actionFor(env, device, DispatchDraft.no);
        expect(action.createsTag, isFalse,
            reason: '${env.name}/${device.name}');
        expect(action.createsDraftRelease, isFalse,
            reason: '${env.name}/${device.name}');
      }
    });

    // patch has no file to attach: the tag `pos-vX.Y.Z-N` is its trace (SPEC §3.3).
    test('patch tags but writes no draft release', () {
      final action = actionFor(
          DispatchEnv.patch, DispatchDevice.android, DispatchDraft.yes);
      expect(action.createsTag, isTrue);
      expect(action.createsDraftRelease, isFalse);
    });

    test('every other valid combination with yes tags and drafts', () {
      expect(
        actionFor(
                DispatchEnv.staging, DispatchDevice.android, DispatchDraft.yes)
            .createsTag,
        isTrue,
      );
      expect(
        actionFor(
                DispatchEnv.staging, DispatchDevice.android, DispatchDraft.yes)
            .createsDraftRelease,
        isTrue,
      );
      expect(
        actionFor(DispatchEnv.production, DispatchDevice.windows,
                DispatchDraft.yes)
            .createsDraftRelease,
        isTrue,
      );
    });
  });

  group('the draft release gate of SPEC §3.1', () {
    test('draft release = yes without a version is refused for every env', () {
      // Android only, because that is the one device patch has: patch on windows is refused by
      // the matrix instead (rows 15, 16, 18), and that refusal is the right one to show.
      for (final env in DispatchEnv.values) {
        expect(
          () => planDispatch(request(
              env: env,
              device: DispatchDevice.android,
              draft: DispatchDraft.yes)),
          rejected(['draft release = yes', 'version']),
          reason: env.name,
        );
      }
    });

    // Every combination that needs a version refuses an empty one, whichever env asks.
    test('every env refuses an empty version where one is required', () {
      for (final env in DispatchEnv.values) {
        for (final draft in DispatchDraft.values) {
          final needsVersion =
              draft == DispatchDraft.yes || env == DispatchEnv.patch;
          if (!needsVersion) continue;
          expect(
            () => planDispatch(request(
                env: env, device: DispatchDevice.android, draft: draft)),
            anyRejection(),
            reason: '${env.name}/${draft.name}',
          );
        }
      }
    });

    test('the refusal names the version input, not just the switch', () {
      expect(
        () => planDispatch(request(
          env: DispatchEnv.staging,
          device: DispatchDevice.android,
          draft: DispatchDraft.yes,
        )),
        rejected(['draft release = yes butuh version']),
      );
    });

    test('patch without a version is refused for both draft values', () {
      expect(
        () => planDispatch(request(
          env: DispatchEnv.patch,
          device: DispatchDevice.android,
          draft: DispatchDraft.yes,
        )),
        rejected(['version']),
      );
      expect(
        () => planDispatch(request(
          env: DispatchEnv.patch,
          device: DispatchDevice.android,
          draft: DispatchDraft.no,
        )),
        rejected(['patch']),
      );
    });

    // With `no` there is no release and no tag, so the version never becomes a name and its
    // shape is nobody's business. Validating it here would refuse a run that does no harm.
    test('version is ignored when draft release = no, however it looks', () {
      for (final env in [DispatchEnv.staging, DispatchEnv.production]) {
        expect(
          planDispatch(request(
            env: env,
            device: DispatchDevice.android,
            draft: DispatchDraft.no,
            version: 'not-a-version',
          )).workflows,
          isNotEmpty,
          reason: '${env.name}/android/no',
        );
      }
    });

    test('version is ignored when it is empty and draft release = no', () {
      expect(
        planDispatch(request(
          env: DispatchEnv.production,
          device: DispatchDevice.all,
          draft: DispatchDraft.no,
        )).workflows,
        hasLength(2),
      );
    });

    for (final env in DispatchEnv.values) {
      final good = _shapedVersion[env]!;

      test('${env.name} accepts its own version shape with yes', () {
        expect(
          planDispatch(request(
            env: env,
            device: DispatchDevice.android,
            draft: DispatchDraft.yes,
            version: good,
          )).workflows,
          isNotEmpty,
        );
      });

      test('${env.name} refuses another env\'s version shape with yes', () {
        for (final other in DispatchEnv.values) {
          if (other == env) continue;
          expect(
            () => planDispatch(request(
              env: env,
              device: DispatchDevice.android,
              draft: DispatchDraft.yes,
              version: _shapedVersion[other]!,
            )),
            rejected([env.name, _shapedVersion[env]!]),
            reason:
                '${env.name} must not take $other\'s ${_shapedVersion[other]}',
          );
        }
      });

      test('${env.name} refuses junk for a version with yes', () {
        for (final junk in ['', 'v1.2.0', '1.2', '1.2.0-', 'x.y.z']) {
          expect(
            () => planDispatch(request(
              env: env,
              device: DispatchDevice.android,
              draft: DispatchDraft.yes,
              version: junk,
            )),
            anyRejection(),
            reason: 'version "$junk" must not pass for $env',
          );
        }
      });
    }
  });

  // The Shorebird trap (SPEC §1.4): `shorebird release` records the version, and a second
  // release for the same version fails. A trial run that called it would spend the production
  // version slot before production used it. So a trial run never calls it.
  group('the Shorebird matrix', () {
    test('only a full production android release registers a Shorebird release',
        () {
      expect(
        usesShorebirdRelease(request(
          env: DispatchEnv.production,
          device: DispatchDevice.android,
          draft: DispatchDraft.yes,
          version: '1.2.0',
        )),
        isTrue,
      );
    });

    // `all` is the android half plus the windows half, and the AAB in that one shared draft is
    // what `shorebird release android` builds (SPEC §2a row 12, §1.4). Dropping this would be a
    // second version trap: no baseline for a production version that is about to be published.
    test('production all with yes registers one too: it builds the same AAB',
        () {
      expect(
        usesShorebirdRelease(request(
          env: DispatchEnv.production,
          device: DispatchDevice.all,
          draft: DispatchDraft.yes,
          version: '1.2.0',
        )),
        isTrue,
      );
    });

    test('a production trial run registers nothing', () {
      expect(
        usesShorebirdRelease(request(
          env: DispatchEnv.production,
          device: DispatchDevice.android,
          draft: DispatchDraft.no,
          version: '1.2.0',
        )),
        isFalse,
      );
      expect(
        usesShorebirdRelease(request(
          env: DispatchEnv.production,
          device: DispatchDevice.all,
          draft: DispatchDraft.no,
          version: '1.2.0',
        )),
        isFalse,
      );
    });

    test('staging and patch never register a Shorebird release', () {
      for (final env in [DispatchEnv.staging, DispatchEnv.patch]) {
        for (final device in DispatchDevice.values) {
          for (final draft in DispatchDraft.values) {
            expect(
              usesShorebirdRelease(request(
                env: env,
                device: device,
                draft: draft,
                version: _shapedVersion[env]!,
              )),
              isFalse,
              reason: '${env.name}/${device.name}/${draft.name}',
            );
          }
        }
      }
    });

    test('no refused combination registers one either', () {
      for (final row in _rows.where((r) => !r.valid)) {
        expect(
          usesShorebirdRelease(request(
            env: row.env,
            device: row.device,
            draft: row.draft,
            version: _shapedVersion[row.env]!,
          )),
          isFalse,
          reason: 'row ${row.number}',
        );
      }
    });

    test('the action of a production android trial run says so itself', () {
      expect(
        planDispatch(request(
          env: DispatchEnv.production,
          device: DispatchDevice.android,
          draft: DispatchDraft.no,
        )).shorebirdRelease,
        isFalse,
      );
    });
  });

  // The dispatcher passes the four inputs as flags, so the parsing is part of the gate: a typo in
  // the workflow must be refused, not guessed.
  group('parsing what the dispatcher passes', () {
    test('reads --env --device --draft --version', () {
      final parsed = parseDispatchRequest([
        '--env',
        'production',
        '--device',
        'all',
        '--draft',
        'yes',
        '--version',
        '1.2.0',
      ]);
      expect(parsed.env, DispatchEnv.production);
      expect(parsed.device, DispatchDevice.all);
      expect(parsed.draft, DispatchDraft.yes);
      expect(parsed.version, '1.2.0');
    });

    test('reads --flag=value too', () {
      final parsed = parseDispatchRequest(
          ['--env=staging', '--device=android', '--draft=no']);
      expect(parsed.env, DispatchEnv.staging);
      expect(parsed.draft, DispatchDraft.no);
      expect(parsed.version, isEmpty);
    });

    test('refuses a flag it does not know', () {
      expect(
        () => parseDispatchRequest([
          '--env',
          'staging',
          '--device',
          'android',
          '--draft',
          'no',
          '--tag',
          'pos-v1.2.0',
        ]),
        rejected(['tag']),
      );
    });

    test('refuses a value outside the choice list, by name', () {
      expect(
        () => parseDispatchRequest(
            ['--env', 'dev', '--device', 'android', '--draft', 'no']),
        rejected(['dev', 'staging, production, patch']),
      );
      expect(
        () => parseDispatchRequest(
            ['--env', 'staging', '--device', 'linux', '--draft', 'no']),
        rejected(['linux', 'android, windows, all']),
      );
      expect(
        () => parseDispatchRequest(
            ['--env', 'staging', '--device', 'android', '--draft', 'true']),
        rejected(['true', 'no, yes']),
      );
    });

    test('refuses a missing flag, by name, and lists the choices', () {
      expect(
        () => parseDispatchRequest(['--device', 'android', '--draft', 'no']),
        rejected(['--env', 'staging, production, patch']),
      );
      expect(
        () => parseDispatchRequest(['--env', 'staging', '--draft', 'no']),
        rejected(['--device', 'android, windows, all']),
      );
      expect(
        () => parseDispatchRequest(['--env', 'staging', '--device', 'android']),
        rejected(['--draft', 'no, yes']),
      );
    });

    test('refuses a flag that ends without its value', () {
      expect(
        () => parseDispatchRequest(
            ['--env', 'staging', '--device', 'android', '--draft']),
        rejected(['--draft']),
      );
    });

    test('--version is optional and may be empty', () {
      expect(
        parseDispatchRequest([
          '--env',
          'staging',
          '--device',
          'android',
          '--draft',
          'no',
          '--version',
          ''
        ]).version,
        isEmpty,
      );
    });
  });
}
