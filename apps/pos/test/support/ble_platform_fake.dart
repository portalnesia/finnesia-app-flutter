/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';
import 'dart:typed_data';

import 'package:universal_ble/universal_ble.dart';

/// What the fake does when asked to request the Bluetooth permissions.
enum PermissionRequest {
  /// The cashier taps "Allow": the permissions are held, the call returns.
  grant,

  /// The cashier refuses. The real plugin fails with code `failed` and a
  /// "Permissions denied: …" message — there is no dedicated code for a refusal
  /// (`plan/printer/findings.md` F23).
  refuse,

  /// The call returns normally but nothing was granted.
  ignore,

  /// The permissions end up held, but the call throws anyway.
  grantButThrow,
}

/// The plugin's platform, faked for `BlePrinter` tests: installed with
/// `UniversalBle.setInstance(fake)`, which is what the package offers for this.
///
/// It is **not** a `PrinterPort` fake (that is `FakePrinter` in `pn_types`); it stands in for
/// the BLE plugin underneath the real `BlePrinter`, so the code that talks to the plugin is
/// what gets tested. Anything a test did not set up throws, so an unexpected call is a
/// failure and not a silent success.
class FakeBlePlatform extends UniversalBlePlatform {
  /// Every call received, in order, with the arguments that matter to a test.
  final calls = <String>[];

  /// Whether the Bluetooth permissions are held right now.
  bool permissionsHeld = false;

  /// What [requestPermissions] does.
  PermissionRequest onRequest = PermissionRequest.grant;

  /// Makes [hasPermissions] itself fail — the plugin is missing, or the manifest does not
  /// declare what it needs.
  Object? permissionCheckError;

  /// What [getBluetoothAvailabilityState] answers.
  AvailabilityState availability = AvailabilityState.poweredOn;

  /// Makes [getBluetoothAvailabilityState] fail.
  Object? availabilityError;

  /// What a scan finds. Emitted **inside** [startScan], after it is recorded, so a caller that
  /// starts listening only after `startScan` returns misses them — as it would on a device.
  List<BleDevice> scanResults = [];

  /// Makes [startScan] fail before it finds anything.
  Object? startScanError;

  /// Makes [stopScan] fail.
  Object? stopScanError;

  /// Addresses with a link up right now.
  final connected = <String>{};

  /// Makes [connect] fail. The real plugin's failures reach `UniversalBle.connect` as a
  /// `PlatformException` whose code is the error enum's index, which it wraps in a
  /// `ConnectionException` (`findings.md` F29) — so a test passes one of those.
  Object? connectError;

  /// Makes [disconnect] fail.
  Object? disconnectError;

  /// The MTU [requestMtu] negotiates.
  int mtu = 247;

  /// Makes [requestMtu] fail.
  Object? mtuError;

  /// What service discovery finds: a printer service with one writable characteristic.
  List<BleService> services = [
    BleService('000018f0-0000-1000-8000-00805f9b34fb', [
      BleCharacteristic('2af1', [CharacteristicProperty.write], []),
    ]),
  ];

  /// Makes [discoverServices] fail.
  Object? discoverError;

  /// Every write that went through, in order. A failed write is not here: it put nothing on
  /// paper.
  final writes =
      <
        ({
          String service,
          String characteristic,
          Uint8List value,
          bool withoutResponse,
        })
      >[];

  /// How many writes were attempted, the failed one included.
  int writeAttempts = 0;

  /// Makes the write with this number (1 = the first attempt) fail.
  int? failAtWrite;

  /// What a failing write throws.
  Object writeFailure = StateError('write failed');

  /// While set, every write waits for it before finishing — a write that is still running.
  Completer<void>? holdWrites;

  /// The printer goes out of range or off: the link drops without the app asking.
  void dropConnection(String deviceId) {
    connected.remove(deviceId);
    updateConnection(deviceId, false);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError(
    'FakeBlePlatform: ${invocation.memberName} was not set up',
  );

  @override
  Future<bool> hasPermissions({bool withAndroidFineLocation = false}) async {
    calls.add('hasPermissions(fineLocation: $withAndroidFineLocation)');
    if (permissionCheckError != null) throw permissionCheckError!;
    return permissionsHeld;
  }

  @override
  Future<void> requestPermissions({
    bool withAndroidFineLocation = false,
  }) async {
    calls.add('requestPermissions(fineLocation: $withAndroidFineLocation)');
    switch (onRequest) {
      case PermissionRequest.grant:
        permissionsHeld = true;
      case PermissionRequest.refuse:
        throw UniversalBleException(
          code: UniversalBleErrorCode.failed,
          message: 'Permissions denied: android.permission.BLUETOOTH_SCAN',
        );
      case PermissionRequest.ignore:
        break;
      case PermissionRequest.grantButThrow:
        permissionsHeld = true;
        throw UniversalBleException(
          code: UniversalBleErrorCode.operationInProgress,
          message: 'Permission request already in progress',
        );
    }
  }

  @override
  Future<AvailabilityState> getBluetoothAvailabilityState() async {
    calls.add('getBluetoothAvailabilityState');
    if (availabilityError != null) throw availabilityError!;
    return availability;
  }

  @override
  Future<void> startScan({
    ScanFilter? scanFilter,
    PlatformConfig? platformConfig,
  }) async {
    calls.add('startScan(filter: ${scanFilter == null ? 'none' : 'set'})');
    if (startScanError != null) throw startScanError!;
    scanResults.forEach(updateScanResult);
  }

  @override
  Future<void> stopScan() async {
    calls.add('stopScan');
    if (stopScanError != null) throw stopScanError!;
  }

  @override
  Future<void> connect(
    String deviceId, {
    Duration? connectionTimeout,
    bool autoConnect = false,
    ConnectionPlatformConfig? platformConfig,
  }) async {
    calls.add('connect($deviceId)');
    if (connectError != null) throw connectError!;
    connected.add(deviceId);
    updateConnection(deviceId, true);
  }

  @override
  Future<void> disconnect(String deviceId) async {
    calls.add('disconnect($deviceId)');
    if (disconnectError != null) throw disconnectError!;
    // `UniversalBle.disconnect` waits for this event; without it a test waits out the
    // plugin's 60-second timeout.
    connected.remove(deviceId);
    updateConnection(deviceId, false);
  }

  @override
  Future<BleConnectionState> getConnectionState(String deviceId) async =>
      connected.contains(deviceId)
      ? BleConnectionState.connected
      : BleConnectionState.disconnected;

  @override
  Future<int> requestMtu(String deviceId, int expectedMtu) async {
    calls.add('requestMtu($expectedMtu)');
    if (mtuError != null) throw mtuError!;
    return mtu;
  }

  @override
  Future<List<BleService>> discoverServices(
    String deviceId,
    bool withDescriptors,
  ) async {
    calls.add('discoverServices');
    if (discoverError != null) throw discoverError!;
    return services;
  }

  @override
  Future<void> writeValue(
    String deviceId,
    String service,
    String characteristic,
    Uint8List value,
    BleOutputProperty bleOutputProperty,
  ) async {
    calls.add('writeValue');
    writeAttempts++;
    final hold = holdWrites;
    if (hold != null) await hold.future;
    if (failAtWrite == writeAttempts) throw writeFailure;
    writes.add((
      service: service,
      characteristic: characteristic,
      // A copy: the caller's chunk is a view into its document.
      value: Uint8List.fromList(value),
      withoutResponse: bleOutputProperty == BleOutputProperty.withoutResponse,
    ));
  }
}
