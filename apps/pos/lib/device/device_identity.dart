/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_pos/src/ulid.dart';
import 'package:pn_types/src/native/device_info_port.dart';
import 'package:pn_types/src/native/store_port.dart';

/// Where a fingerprint the app minted itself lives, for a platform that has no identifier.
///
/// A device paired before the platform identifier was used also keeps its value here, because
/// that is the value its `pos_devices` row was keyed on.
const deviceIdKey = 'device_id';

/// `dto.ActivateDeviceDTO` caps `device_name` at 255 — a longer one is a 400, not a warning.
const deviceNameMax = 255;

const defaultDeviceName = 'Tablet Kasir';

/// What the backend needs to register this tablet.
///
/// Both fields are `required` in `dto.ActivateDeviceDTO`. The fingerprint is what ties the
/// tablet to its row in `pos_devices`: activation upserts on `(company_id, device_fingerprint)`,
/// so a fingerprint that changes when the app is reinstalled adds a **new** row instead of
/// updating the old one, and each reinstall consumes a slot from the outlet's limit of ten
/// (`plan/pos-device-registry/01-kontrak-aplikasi-android.md` §3.5).
typedef DeviceIdentity = ({String deviceName, String deviceFingerprint});

/// Builds the identity the activate call sends.
///
/// The fingerprint is the **platform's** identifier for this installation, so it survives an
/// uninstall and an app update — the two events that used to turn one tablet into a new device.
/// It does not survive a factory reset, which is the honest limit of what Android offers.
///
/// [info] is injected so this is testable without a platform plugin. A [StoreException] and a
/// [DeviceInfoException] are both surfaced rather than swallowed, and for the same reason: a
/// failure is not "no identifier yet", and treating it as one would register a device the app
/// can no longer recognise.
Future<DeviceIdentity> buildDeviceIdentity(
  StorePort store,
  DeviceInfoPort info, {
  String? requestedName,
}) async {
  return (
    deviceName: _resolveName(requestedName),
    deviceFingerprint: await _resolveFingerprint(store, info),
  );
}

String _resolveName(String? requested) {
  final trimmed = requested?.trim() ?? '';
  // An empty name fails the DTO's `required`, so fall back rather than send a blank.
  final name = trimmed.isEmpty ? defaultDeviceName : trimmed;
  // Cut by character, not by UTF-16 unit. The backend's `max=255` is
  // `utf8.RuneCountInString`, so the cap is 255 characters; the source's `slice(0, 255)`
  // counts units and can cut an emoji in half, leaving a lone surrogate that is not a name.
  return String.fromCharCodes(name.runes.take(deviceNameMax));
}

/// The fingerprint, in the order that keeps a device's row the same one.
///
/// 1. **What is already stored.** A device paired before the platform identifier was used was
///    registered under this value. Switching to the platform's now would leave that row orphaned
///    and add a second one, which is exactly the duplication this is meant to end.
/// 2. **The platform's identifier.** Survives reinstall and update.
/// 3. **A ULID, minted and stored.** A platform with no identifier at all. Worse across
///    reinstalls, but a working device beats a broken one — and the backend's column is NOT
///    NULL, so sending nothing is not an option.
///
/// A [DeviceInfoException] is deliberately **not** a reason to fall through to step 3. The
/// platform failed, which says nothing about whether it has an identifier; minting a throwaway
/// one would register a second device row for a tablet that already has one.
Future<String> _resolveFingerprint(StorePort store, DeviceInfoPort info) async {
  final existing = await store.read(deviceIdKey);
  // The source tests `if (existing)`, so an empty string is not an identity either.
  if (existing != null && existing.isNotEmpty) return existing;

  final fromPlatform = await info.androidId();
  if (fromPlatform != null && fromPlatform.isNotEmpty) return fromPlatform;

  final minted = ulid();
  await store.write(deviceIdKey, minted);
  return minted;
}
