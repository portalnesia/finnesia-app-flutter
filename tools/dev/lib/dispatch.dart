/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// Which release lane the dispatcher asked for, as the `env` input of
/// `.github/workflows/release-dispatch.yml` (SPEC §2a).
enum DispatchEnv {
  staging('staging', 'staging-pos.yml'),
  production('production', 'release-pos.yml'),
  patch('patch', 'shorebird-patch.yml');

  const DispatchEnv(this.wireName, this.workflow);

  /// The word the workflow input uses. Dart enum names are capitalised because of the lint, and a
  /// capitalized `Staging` would never match a `choice:` list in YAML, so the wire name is spelled
  /// out here instead of derived.
  final String wireName;

  /// The workflow this env runs. `production` has a Windows half too, see [planDispatch].
  final String workflow;
}

/// Which platform build, as the `device` input (SPEC §2a).
enum DispatchDevice {
  android('android'),
  windows('windows'),
  all('all');

  const DispatchDevice(this.wireName);

  final String wireName;
}

/// Whether the run is a trial run or a real release, as the `draft_release` input.
///
/// `no` is the trial run: artifacts and nothing else, no tag, no release, no store upload
/// (SPEC §1.4). `yes` is the real thing: build, tag, draft release.
enum DispatchDraft {
  no('no'),
  yes('yes');

  const DispatchDraft(this.wireName);

  final String wireName;
}

/// One combination of the four dispatcher inputs.
class DispatchRequest {
  const DispatchRequest({
    required this.env,
    required this.device,
    required this.draft,
    this.version = '',
  });

  final DispatchEnv env;
  final DispatchDevice device;
  final DispatchDraft draft;
  final String version;

  @override
  String toString() =>
      'env=$env device=$device draft=$draft version="$version"';
}

/// The combination is refused, and this is why (SPEC §2a, §3.1).
///
/// Thrown rather than returned, because there is nothing to run: a refused combination must stop
/// the dispatcher before any build starts, and an exception is the only thing `bin/dev.dart`
/// already turns into a non-zero exit.
class DispatchRejection implements Exception {
  const DispatchRejection(this.message);

  /// What the workflow log shows. Every refusal names the combination it refused, because "input
  /// tidak valid" leaves the owner guessing which of the four inputs was wrong.
  final String message;

  @override
  String toString() => message;
}

/// What a valid combination does. The reusable workflows are named so a caller can check what it
/// is about to run, and the three booleans are the parts that are easy to get wrong silently.
class DispatchAction {
  const DispatchAction({
    required this.workflows,
    required this.createsTag,
    required this.createsDraftRelease,
    required this.shorebirdRelease,
  });

  /// The reusable workflows to call, android before windows: both write one draft, so the order
  /// decides who writes the title (SPEC §3.3).
  final List<String> workflows;

  /// Whether the dispatcher makes the tag itself, before calling the workflow (SPEC §1.4). False
  /// for every trial run: a tag from a trial run is a lie about what was released.
  final bool createsTag;

  /// Whether a GitHub draft release is written. `patch` is the exception: there is no file to
  /// attach, so the tag `pos-vX.Y.Z-N` is its whole trace (SPEC §3.3).
  final bool createsDraftRelease;

  /// Whether `shorebird release android` runs, which is what registers a production version
  /// slot. A trial run must be false (SPEC §1.4).
  final bool shorebirdRelease;

  @override
  String toString() =>
      'DispatchAction($workflows, tag=$createsTag, draft=$createsDraftRelease, '
      'shorebird=$shorebirdRelease)';
}

/// The 18 rows of SPEC §2a, read as data so the table in the spec and this code cannot drift
/// apart silently: a combination missing here is a combination nothing refuses.
typedef _Row = ({
  DispatchEnv env,
  DispatchDevice device,
  DispatchDraft draft,
  DispatchAction? action,
  String? refusal,
});

const _stagingAndroid = DispatchAction(
  workflows: ['staging-pos.yml'],
  createsTag: false,
  createsDraftRelease: false,
  shorebirdRelease: false,
);

const _rows = <_Row>[
  // staging: android only. `staging-pos.yml` builds an APK and nothing else, so `windows` and
  // `all` have nothing to call (SPEC §2a rows 3-6).
  (
    env: DispatchEnv.staging,
    device: DispatchDevice.android,
    draft: DispatchDraft.no,
    action: _stagingAndroid,
    refusal: null,
  ),
  (
    env: DispatchEnv.staging,
    device: DispatchDevice.android,
    draft: DispatchDraft.yes,
    action: DispatchAction(
      workflows: ['staging-pos.yml'],
      createsTag: true,
      createsDraftRelease: true,
      shorebirdRelease: false,
    ),
    refusal: null,
  ),
  (
    env: DispatchEnv.staging,
    device: DispatchDevice.windows,
    draft: DispatchDraft.no,
    action: null,
    refusal: 'staging tidak punya varian windows '
        '(staging-pos.yml hanya membangun APK); pakai device=android',
  ),
  (
    env: DispatchEnv.staging,
    device: DispatchDevice.windows,
    draft: DispatchDraft.yes,
    action: null,
    refusal: 'staging tidak punya varian windows '
        '(staging-pos.yml hanya membangun APK); pakai device=android',
  ),
  (
    env: DispatchEnv.staging,
    device: DispatchDevice.all,
    draft: DispatchDraft.no,
    action: null,
    refusal: 'staging tidak punya varian windows, pakai device=android',
  ),
  (
    env: DispatchEnv.staging,
    device: DispatchDevice.all,
    draft: DispatchDraft.yes,
    action: null,
    refusal: 'staging tidak punya varian windows, pakai device=android',
  ),

  // production android: the only lane that touches Shorebird, and only when it is a real release
  // (SPEC §2a rows 7-8).
  (
    env: DispatchEnv.production,
    device: DispatchDevice.android,
    draft: DispatchDraft.no,
    action: DispatchAction(
      workflows: ['release-pos.yml'],
      createsTag: false,
      createsDraftRelease: false,
      shorebirdRelease: false,
    ),
    refusal: null,
  ),
  (
    env: DispatchEnv.production,
    device: DispatchDevice.android,
    draft: DispatchDraft.yes,
    action: DispatchAction(
      workflows: ['release-pos.yml'],
      createsTag: true,
      createsDraftRelease: true,
      shorebirdRelease: true,
    ),
    refusal: null,
  ),

  // production windows: `windows-pos.yml` needs no secret and no store upload, so there is
  // nothing here that a trial run could damage (SPEC §2a rows 9-10).
  (
    env: DispatchEnv.production,
    device: DispatchDevice.windows,
    draft: DispatchDraft.no,
    action: DispatchAction(
      workflows: ['windows-pos.yml'],
      createsTag: false,
      createsDraftRelease: false,
      shorebirdRelease: false,
    ),
    refusal: null,
  ),
  (
    env: DispatchEnv.production,
    device: DispatchDevice.windows,
    draft: DispatchDraft.yes,
    action: DispatchAction(
      workflows: ['windows-pos.yml'],
      createsTag: true,
      createsDraftRelease: true,
      shorebirdRelease: false,
    ),
    refusal: null,
  ),
  (
    env: DispatchEnv.production,
    device: DispatchDevice.all,
    draft: DispatchDraft.no,
    action: DispatchAction(
      workflows: ['release-pos.yml', 'windows-pos.yml'],
      createsTag: false,
      createsDraftRelease: false,
      shorebirdRelease: false,
    ),
    refusal: null,
  ),
  (
    env: DispatchEnv.production,
    device: DispatchDevice.all,
    draft: DispatchDraft.yes,
    action: DispatchAction(
      workflows: ['release-pos.yml', 'windows-pos.yml'],
      createsTag: true,
      createsDraftRelease: true,
      // The android half of `all` builds the AAB through `shorebird release android`, so `all`
      // registers a production slot exactly like `android` does. A baseline for a version that is
      // about to reach Play, not an accident (SPEC §2a row 12, §1.4).
      shorebirdRelease: true,
    ),
    refusal: null,
  ),

  // patch: android only, and never as a trial run. A patch acts on a release that already exists:
  // without a target version it has no base, and with one it pushes OTA to production tablets
  // (SPEC §2a row 13).
  (
    env: DispatchEnv.patch,
    device: DispatchDevice.android,
    draft: DispatchDraft.no,
    action: null,
    refusal: 'patch butuh versi target: tanpa target tidak punya base release, '
        'dengan target ia mendorong OTA ke tablet production',
  ),
  (
    env: DispatchEnv.patch,
    device: DispatchDevice.android,
    draft: DispatchDraft.yes,
    action: DispatchAction(
      workflows: ['shorebird-patch.yml'],
      createsTag: true,
      createsDraftRelease: false,
      shorebirdRelease: false,
    ),
    refusal: null,
  ),
  (
    env: DispatchEnv.patch,
    device: DispatchDevice.windows,
    draft: DispatchDraft.no,
    action: null,
    refusal: 'patch tidak punya varian windows '
        '(shorebird-patch.yml tidak punya build windows); pakai device=android',
  ),
  (
    env: DispatchEnv.patch,
    device: DispatchDevice.windows,
    draft: DispatchDraft.yes,
    action: null,
    refusal: 'patch tidak punya varian windows '
        '(shorebird-patch.yml tidak punya build windows); pakai device=android',
  ),
  (
    env: DispatchEnv.patch,
    device: DispatchDevice.all,
    draft: DispatchDraft.no,
    action: null,
    refusal: 'patch tidak punya varian windows, pakai device=android',
  ),
  (
    env: DispatchEnv.patch,
    device: DispatchDevice.all,
    draft: DispatchDraft.yes,
    action: null,
    refusal: 'patch tidak punya varian windows, pakai device=android',
  ),
];

/// The version shape each env insists on when `draft release = yes` (SPEC §3.1).
///
/// A version only becomes a tag name in that case, so this is where the shape matters: `version`
/// is the tag, and a tag that does not match the workflow's own tag pattern triggers nothing at
/// all, on the next run and on this one.
final _versionShapes = <DispatchEnv, RegExp>{
  DispatchEnv.staging: RegExp(r'^\d+\.\d+\.\d+-staging\.\d+$'),
  DispatchEnv.production: RegExp(r'^\d+\.\d+\.\d+$'),
  DispatchEnv.patch: RegExp(r'^\d+\.\d+\.\d+-\d+$'),
};

/// The example of each shape, used in the refusal so the owner sees the target, not just a regex.
const _versionExamples = <DispatchEnv, String>{
  DispatchEnv.staging: 'X.Y.Z-staging.N (mis. 1.2.0-staging.3)',
  DispatchEnv.production: 'X.Y.Z polos (mis. 1.2.0)',
  DispatchEnv.patch: 'X.Y.Z-N (mis. 1.2.0-5)',
};

/// What [request] does, or throws [DispatchRejection] with the reason.
///
/// Three gates, in this order:
///
/// 1. the combination (the 18 rows of SPEC §2a), because "there is no such workflow" is more
///    useful than "your version looks wrong";
/// 2. an empty version where one is required (SPEC §3.1);
/// 3. the version shape, only when it is going to be read as a tag name.
///
/// The shape is not checked for `draft release = no`: nothing reads it there, so refusing it would
/// refuse a run that does no harm.
DispatchAction planDispatch(DispatchRequest request) {
  final row = _rows.firstWhere(
    (row) =>
        row.env == request.env &&
        row.device == request.device &&
        row.draft == request.draft,
    orElse: () => throw const DispatchRejection(
      'kombinasi env/device/draft release tidak ada di matriks dispatcher',
    ),
  );

  if (row.action == null) {
    throw DispatchRejection(row.refusal!);
  }

  // `patch` without a version is refused whichever way the draft switch points: there is no patch
  // target to act on (SPEC §3.1).
  if (request.version.isEmpty) {
    if (request.draft == DispatchDraft.yes) {
      throw const DispatchRejection(
        'draft release = yes butuh version: tanpa version tidak ada nama tag, '
        'jadi tidak ada yang bisa dibuat',
      );
    }
    if (request.env == DispatchEnv.patch) {
      throw const DispatchRejection(
        'patch butuh versi target: tanpa version tidak punya base release',
      );
    }
  }

  if (request.draft == DispatchDraft.yes) {
    final shape = _versionShapes[request.env]!;
    if (!shape.hasMatch(request.version)) {
      throw DispatchRejection(
        'version untuk ${request.env.wireName} harus '
        '${_versionExamples[request.env]}, bukan "${request.version}"',
      );
    }
  }

  return row.action!;
}

/// Whether this run calls `shorebird release android`, which is what spends a production version
/// slot (SPEC §1.4: Shorebird refuses a second release for the same version, so a trial run that
/// called it would make the real production release fail afterwards).
///
/// A total function on purpose, so a caller can ask before validating: a refused combination has
/// no run at all, and the answer there is `false` without an exception to catch.
bool usesShorebirdRelease(DispatchRequest request) {
  try {
    return planDispatch(request).shorebirdRelease;
  } on DispatchRejection {
    return false;
  }
}

/// Reads the four inputs out of [args], as the dispatcher passes them: `--env staging --device
/// android --draft no --version 1.2.0`, or the `--flag=value` form.
///
/// The parsing is part of the gate, not a convenience: a flag the workflow gets wrong must be
/// refused with its own name in the message, because the person reading the log cannot see the
/// workflow file from there.
DispatchRequest parseDispatchRequest(List<String> args) {
  const flags = {'--env', '--device', '--draft', '--version'};
  final values = <String, String>{};

  for (var i = 0; i < args.length; i++) {
    final argument = args[i];
    final equals = argument.indexOf('=');
    final flag = equals > 0 ? argument.substring(0, equals) : argument;

    if (!flags.contains(flag)) {
      throw DispatchRejection(
        'flag "$argument" tidak dikenal untuk dispatch; yang ada: '
        '${flags.join(', ')}',
      );
    }

    String value;
    if (equals > 0) {
      value = argument.substring(equals + 1);
    } else {
      if (i + 1 >= args.length) {
        throw DispatchRejection('flag "$flag" tidak punya nilai');
      }
      value = args[++i];
    }
    values[flag] = value;
  }

  final env = _choice(values, '--env', DispatchEnv.values, (v) => v.wireName);
  final device =
      _choice(values, '--device', DispatchDevice.values, (v) => v.wireName);
  final draft =
      _choice(values, '--draft', DispatchDraft.values, (v) => v.wireName);

  return DispatchRequest(
    env: env!,
    device: device!,
    draft: draft!,
    version: values['--version'] ?? '',
  );
}

T? _choice<T>(
  Map<String, String> values,
  String flag,
  List<T> allowed,
  String Function(T) wireName,
) {
  final value = values[flag];
  final choices = allowed.map(wireName).join(', ');
  if (value == null) {
    throw DispatchRejection(
        'flag "$flag" wajib diisi (salah satu dari: $choices)');
  }
  for (final candidate in allowed) {
    if (wireName(candidate) == value) {
      return candidate;
    }
  }
  throw DispatchRejection(
    'nilai "$value" untuk $flag tidak dikenal; yang bisa: $choices',
  );
}
