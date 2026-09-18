/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/native/printer_port.dart';
import 'package:pos/native/printer/printer_ble.dart';
import 'package:universal_ble/universal_ble.dart';

import '../../support/ble_platform_fake.dart';

void main() {
  late FakeBlePlatform ble;

  setUp(() {
    ble = FakeBlePlatform();
    UniversalBle.setInstance(ble);
  });

  Matcher throwsPrinter(PrinterFailure reason) => throwsA(
    isA<PrinterException>().having((e) => e.reason, 'reason', reason),
  );

  BleDevice device(String id, String? name) =>
      BleDevice(deviceId: id, name: name);

  // The calls without their arguments: the order is what matters.
  List<String> verbs() => ble.calls.map((c) => c.split('(').first).toList();

  // How many times the plugin was asked to open a link.
  int connects() => ble.calls.where((c) => c.startsWith('connect(')).length;

  // The bug that broke the tablet in the source: Android's runtime Bluetooth permissions were
  // never requested, so every scan failed and the cashier was told the tablet had no
  // Bluetooth. Declaring them in the manifest is not enough from Android 12.
  group('ensureBluetoothPermission', () {
    test('asks for the permissions when they are not held', () async {
      await ensureBluetoothPermission();

      expect(ble.calls, contains(startsWith('requestPermissions')));
      expect(ble.permissionsHeld, isTrue);
    });

    // Asking is cheap when the grant is held, but it is still a call across the platform
    // channel before every scan and connect; and with no Activity it fails.
    test('does not ask when they are already held', () async {
      ble.permissionsHeld = true;

      await ensureBluetoothPermission();

      // It checked, once, and that was all.
      expect(ble.calls, ['hasPermissions(fineLocation: false)']);
    });

    test('reports permissionDenied when the cashier refuses', () async {
      ble.onRequest = PermissionRequest.refuse;

      await expectLater(
        ensureBluetoothPermission(),
        throwsPrinter(PrinterFailure.permissionDenied),
      );
    });

    // A refusal has no error code of its own, so the exception is not evidence. Only the grant
    // is: a call that returns without granting is still a refusal. This is also the
    // "partially granted is denied" case: the plugin reports "held" only when both
    // BLUETOOTH_SCAN and BLUETOOTH_CONNECT are, and neither alone can find and print.
    test('reports permissionDenied when the request returns but nothing was granted', () async {
      ble.onRequest = PermissionRequest.ignore;

      await expectLater(
        ensureBluetoothPermission(),
        throwsPrinter(PrinterFailure.permissionDenied),
      );
    });

    // The other side of the same rule: an exception from a request that did end with the
    // permissions held (a second request racing the first) must not turn a grant into a failure.
    test('goes ahead when the request threw but the permissions are held after all', () async {
      ble.onRequest = PermissionRequest.grantButThrow;

      await ensureBluetoothPermission();

      expect(ble.permissionsHeld, isTrue);
    });

    // The source's "the permission commands themselves fail" case: the plugin is missing, or
    // the manifest does not declare what it needs. Nothing a cashier can fix.
    test(
      'reports unsupported when the permissions cannot even be checked',
      () async {
        ble.permissionCheckError = StateError('plugin missing');

        await expectLater(
          ensureBluetoothPermission(),
          throwsPrinter(PrinterFailure.unsupported),
        );
        expect(ble.calls, isNot(contains(startsWith('requestPermissions'))));
      },
    );

    // Least privilege (`security.md` §4): the printer needs BLUETOOTH_SCAN and
    // BLUETOOTH_CONNECT, and the manifest declares `neverForLocation`. Asking for fine
    // location would be a permission nobody needs.
    test('never asks for location', () async {
      await ensureBluetoothPermission();

      // `everyElement` is true of an empty list, so first require that something was asked.
      expect(ble.calls, isNotEmpty);
      expect(ble.calls, everyElement(contains('fineLocation: false')));
    });
  });

  group('BlePrinter — scan', () {
    late BlePrinter printer;

    setUp(() {
      printer = BlePrinter();
      ble.permissionsHeld = true;
    });

    Future<List<PrinterDevice>> scan() => printer.scan(duration: Duration.zero);

    group('before it scans', () {
      // The order is the point: scanning without the grant fails inside the plugin and the
      // cashier never sees the Android prompt.
      test(
        'asks for permission, checks Bluetooth, scans, then stops',
        () async {
          ble.permissionsHeld = false;

          await scan();

          expect(verbs(), [
            'hasPermissions',
            'requestPermissions',
            'hasPermissions',
            'getBluetoothAvailabilityState',
            'startScan',
            'stopScan',
          ]);
        },
      );

      test('never scans when the cashier refuses', () async {
        ble.permissionsHeld = false;
        ble.onRequest = PermissionRequest.refuse;

        await expectLater(
          scan(),
          throwsPrinter(PrinterFailure.permissionDenied),
        );
        expect(verbs(), isNot(contains('startScan')));
        expect(verbs(), isNot(contains('getBluetoothAvailabilityState')));
      });

      // BLUETOOTH_SCAN alone cannot connect and BLUETOOTH_CONNECT alone cannot find the
      // printer, so anything short of both is a refusal.
      test('treats a request that granted nothing as a refusal', () async {
        ble.permissionsHeld = false;
        ble.onRequest = PermissionRequest.ignore;

        await expectLater(
          scan(),
          throwsPrinter(PrinterFailure.permissionDenied),
        );
        expect(verbs(), isNot(contains('startScan')));
      });

      test(
        'reports unsupported when the permissions cannot be checked',
        () async {
          ble.permissionCheckError = StateError('plugin missing');

          await expectLater(scan(), throwsPrinter(PrinterFailure.unsupported));
        },
      );

      test(
        'reports bluetoothOff, and never scans, when the radio is off',
        () async {
          ble.availability = AvailabilityState.poweredOff;

          await expectLater(scan(), throwsPrinter(PrinterFailure.bluetoothOff));
          expect(verbs(), isNot(contains('startScan')));
        },
      );

      test(
        'reports unsupported, and never scans, when there is no adapter',
        () async {
          ble.availability = AvailabilityState.unknown;

          await expectLater(scan(), throwsPrinter(PrinterFailure.unsupported));
          expect(verbs(), isNot(contains('startScan')));
        },
      );

      test(
        'reports scanFailed when Bluetooth cannot even be queried',
        () async {
          ble.availabilityError = StateError('channel closed');

          await expectLater(scan(), throwsPrinter(PrinterFailure.scanFailed));
        },
      );
    });

    group('what it finds', () {
      test('returns the devices found, in the order they appeared', () async {
        ble.scanResults = [
          device('AA', 'Printer 1'),
          device('BB', 'Printer 2'),
        ];

        expect(await scan(), [
          const PrinterDevice(address: 'AA', name: 'Printer 1'),
          const PrinterDevice(address: 'BB', name: 'Printer 2'),
        ]);
      });

      // "No printers nearby" is an answer, not a failure. The scan still ran, and stopped.
      test('returns an empty list when nothing is nearby', () async {
        expect(await scan(), isEmpty);
        expect(verbs(), containsAllInOrder(['startScan', 'stopScan']));
      });

      // Many printers do not advertise their service UUID, so filtering would hide the very
      // printer being looked for.
      test('scans with no service filter', () async {
        await scan();

        expect(ble.calls, contains('startScan(filter: none)'));
      });

      // A device with no name at all is noise (most beacons); one whose name is the empty
      // string is still a device, and the pairing list labels it.
      test(
        'drops a device with no name but keeps one whose name is empty',
        () async {
          ble.scanResults = [device('AA', null), device('BB', '')];

          expect(await scan(), [const PrinterDevice(address: 'BB', name: '')]);
        },
      );

      // The same printer advertises many times during a scan.
      test('lists a device once, in its first position, with the latest name it reported', () async {
        ble.scanResults = [
          device('AA', 'Old'),
          device('BB', 'Other'),
          device('AA', 'New'),
        ];

        expect(await scan(), [
          const PrinterDevice(address: 'AA', name: 'New'),
          const PrinterDevice(address: 'BB', name: 'Other'),
        ]);
      });

      // Advertisements alternate: one carries the name, the next may not.
      test('keeps a name that a later advertisement leaves out', () async {
        ble.scanResults = [device('AA', 'Printer'), device('AA', null)];

        expect(await scan(), [
          const PrinterDevice(address: 'AA', name: 'Printer'),
        ]);
      });
    });

    group('how long it scans', () {
      // Scanning draws power, so it is bounded rather than left as a background poll.
      test('scans for the duration it was given, then stops', () async {
        final watch = Stopwatch()..start();

        await printer.scan(duration: const Duration(milliseconds: 80));

        expect(
          watch.elapsed,
          greaterThanOrEqualTo(const Duration(milliseconds: 70)),
        );
        expect(verbs().last, 'stopScan');
      });
    });

    group('when it fails', () {
      UniversalBleException failure(UniversalBleErrorCode code) =>
          UniversalBleException(code: code, message: 'x');

      test(
        'reports permissionDenied when the scan itself is refused',
        () async {
          ble.startScanError = failure(
            UniversalBleErrorCode.bluetoothUnauthorized,
          );

          await expectLater(
            scan(),
            throwsPrinter(PrinterFailure.permissionDenied),
          );
        },
      );

      test(
        'reports bluetoothOff when the scan fails because the radio is off',
        () async {
          ble.startScanError = failure(
            UniversalBleErrorCode.bluetoothNotEnabled,
          );

          await expectLater(scan(), throwsPrinter(PrinterFailure.bluetoothOff));
        },
      );

      test('reports unsupported when the device has no BLE', () async {
        ble.startScanError = failure(
          UniversalBleErrorCode.bluetoothNotAvailable,
        );

        await expectLater(scan(), throwsPrinter(PrinterFailure.unsupported));
      });

      // The old code called every one of these `unsupported`, which put a message meant for
      // a browser in front of a cashier standing at a tablet.
      test('reports scanFailed for a failure it cannot name', () async {
        ble.startScanError = failure(UniversalBleErrorCode.scanFailed);

        await expectLater(scan(), throwsPrinter(PrinterFailure.scanFailed));
      });

      // A scan left running drains the battery until the app is killed.
      test('stops the scan even when it failed', () async {
        ble.startScanError = failure(UniversalBleErrorCode.scanFailed);

        await expectLater(scan(), throwsA(isA<PrinterException>()));

        expect(verbs(), contains('stopScan'));
      });

      // What was found is the answer; failing to stop the radio afterwards is not a reason to
      // throw it away.
      test('keeps what it found when stopping fails', () async {
        ble.scanResults = [device('AA', 'Printer')];
        ble.stopScanError = StateError('already stopped');

        expect(await scan(), [
          const PrinterDevice(address: 'AA', name: 'Printer'),
        ]);
      });
    });
  });

  group('BlePrinter — connect', () {
    late BlePrinter printer;

    setUp(() {
      printer = BlePrinter();
      ble.permissionsHeld = true;
    });

    // How the plugin reports a failed connect: a `PlatformException` whose code is the error
    // enum's index, which `UniversalBle.connect` wraps in a `ConnectionException`.
    PlatformException pluginError(UniversalBleErrorCode code) =>
        PlatformException(code: code.index.toString());

    // Connection events reach the app asynchronously.
    Future<void> settle() => Future<void>.delayed(Duration.zero);

    group('before it connects', () {
      test('asks for permission, checks Bluetooth, opens the link, then sets it up', () async {
        ble.permissionsHeld = false;

        await printer.connect('AA');

        expect(verbs(), [
          'hasPermissions',
          'requestPermissions',
          'hasPermissions',
          'getBluetoothAvailabilityState',
          'connect',
          'requestMtu',
          'discoverServices',
        ]);
      });

      test('never connects when the cashier refuses', () async {
        ble.permissionsHeld = false;
        ble.onRequest = PermissionRequest.refuse;

        await expectLater(
          printer.connect('AA'),
          throwsPrinter(PrinterFailure.permissionDenied),
        );
        expect(connects(), 0);
      });

      test(
        'reports bluetoothOff, and never connects, when the radio is off',
        () async {
          ble.availability = AvailabilityState.poweredOff;

          await expectLater(
            printer.connect('AA'),
            throwsPrinter(PrinterFailure.bluetoothOff),
          );
          expect(connects(), 0);
        },
      );

      test(
        'reports unsupported, and never connects, when there is no adapter',
        () async {
          ble.availability = AvailabilityState.unknown;

          await expectLater(
            printer.connect('AA'),
            throwsPrinter(PrinterFailure.unsupported),
          );
          expect(connects(), 0);
        },
      );

      // Here the fallback is `notConnected`, not the scan's `scanFailed`.
      test(
        'reports notConnected when Bluetooth cannot even be queried',
        () async {
          ble.availabilityError = StateError('channel closed');

          await expectLater(
            printer.connect('AA'),
            throwsPrinter(PrinterFailure.notConnected),
          );
        },
      );
    });

    group('what it returns', () {
      // `pairPrinter` saves this, so the name in the Menu is the one the scan showed.
      test('gives the name a scan showed for that address', () async {
        ble.scanResults = [device('AA', 'Kitchen printer')];
        await printer.scan(duration: Duration.zero);

        expect(
          await printer.connect('AA'),
          const PrinterDevice(address: 'AA', name: 'Kitchen printer'),
        );
      });

      // A printer paired earlier is reconnected by address, with no scan and so no name.
      test('names a device it never scanned by its address', () async {
        expect(
          await printer.connect('AA'),
          const PrinterDevice(address: 'AA', name: 'AA'),
        );
      });
    });

    group('setting up the link', () {
      // Kotlin asks for 512 right after connecting, before service discovery: on some
      // devices the MTU must be settled first. It is a request; the printer may answer less.
      test(
        'asks for a 512 MTU after connecting and before discovering services',
        () async {
          await printer.connect('AA');

          expect(ble.calls, contains('requestMtu(512)'));
          expect(
            verbs(),
            containsAllInOrder(['connect', 'requestMtu', 'discoverServices']),
          );
        },
      );

      // Whatever the outcome the source moves on to discovery. A printer that will not
      // negotiate can still print, in smaller pieces.
      test('still connects when the MTU cannot be negotiated', () async {
        ble.mtuError = StateError('mtu refused');

        expect(
          await printer.connect('AA'),
          const PrinterDevice(address: 'AA', name: 'AA'),
        );
        expect(verbs(), contains('discoverServices'));
      });
    });

    group('one link at a time', () {
      // Android caps GATT connections at about seven per device; every print reconnects
      // by address, so reconnecting to the printer already held must not open another.
      test('opens one link when asked for the same printer twice', () async {
        final first = await printer.connect('AA');
        final second = await printer.connect('AA');

        expect(second, first);
        expect(connects(), 1);
      });

      test(
        'closes the first link before opening one to another printer',
        () async {
          await printer.connect('AA');
          await printer.connect('BB');

          expect(
            ble.calls.where(
              (c) => c.startsWith('connect(') || c.startsWith('disconnect('),
            ),
            ['connect(AA)', 'disconnect(AA)', 'connect(BB)'],
          );
        },
      );

      // The printer went out of range or off: the held link is gone, and asking again must
      // open a new one instead of returning a dead one.
      test('opens a new link when the printer dropped the old one', () async {
        await printer.connect('AA');
        ble.dropConnection('AA');
        await settle();

        await printer.connect('AA');

        expect(connects(), 2);
      });

      // The Android plugin closes the old link before trying the new one, so a failed
      // connect leaves no link — not even the earlier one.
      test(
        'holds no link after a failed connect, not even the earlier one',
        () async {
          await printer.connect('AA');
          ble.connectError = pluginError(
            UniversalBleErrorCode.connectionTimeout,
          );
          await expectLater(
            printer.connect('BB'),
            throwsPrinter(PrinterFailure.notConnected),
          );
          ble.connectError = null;

          await printer.connect('AA');

          expect(connects(), 3);
        },
      );
    });

    group('when it fails', () {
      test(
        'reports permissionDenied when the plugin refuses on permission',
        () async {
          ble.connectError = pluginError(
            UniversalBleErrorCode.bluetoothUnauthorized,
          );

          await expectLater(
            printer.connect('AA'),
            throwsPrinter(PrinterFailure.permissionDenied),
          );
        },
      );

      test(
        'reports bluetoothOff when the plugin says the radio is off',
        () async {
          ble.connectError = pluginError(
            UniversalBleErrorCode.bluetoothNotEnabled,
          );

          await expectLater(
            printer.connect('AA'),
            throwsPrinter(PrinterFailure.bluetoothOff),
          );
        },
      );

      // A printer that is off, out of range, or already claimed by another app all arrive
      // as some connection failure, and the cashier's next move is the same.
      test('reports notConnected for a failure it cannot name', () async {
        ble.connectError = pluginError(UniversalBleErrorCode.connectionTimeout);

        await expectLater(
          printer.connect('AA'),
          throwsPrinter(PrinterFailure.notConnected),
        );
      });

      // A link left open after a failed setup would count against the seven.
      test('closes the link when service discovery fails', () async {
        ble.discoverError = StateError('discovery failed');

        await expectLater(
          printer.connect('AA'),
          throwsPrinter(PrinterFailure.notConnected),
        );
        expect(ble.calls, contains('disconnect(AA)'));
      });

      // Connected, but not to anything that takes ESC/POS: `no_writable_characteristic`.
      test(
        'closes the link when there is nothing writable to print to',
        () async {
          ble.services = [
            BleService('1800', [
              BleCharacteristic('2a00', [CharacteristicProperty.read], []),
            ]),
          ];

          await expectLater(
            printer.connect('AA'),
            throwsPrinter(PrinterFailure.notConnected),
          );
          expect(ble.calls, contains('disconnect(AA)'));
        },
      );
    });
  });

  group('BlePrinter — disconnect', () {
    late BlePrinter printer;

    setUp(() {
      printer = BlePrinter();
      ble.permissionsHeld = true;
    });

    test('closes the link, so the next connect opens a new one', () async {
      await printer.connect('AA');

      await printer.disconnect();

      expect(ble.calls, contains('disconnect(AA)'));
      await printer.connect('AA');
      expect(connects(), 2);
    });

    // `PrinterPort.disconnect`: having nothing to tear down is not a failure.
    test('does nothing, and does not fail, with no link', () async {
      await printer.disconnect();

      expect(ble.calls, isEmpty);
    });

    // It cannot fail, so a caller never needs a catch around it. The link is gone either way.
    test('does not fail when the plugin fails, and forgets the link', () async {
      await printer.connect('AA');
      ble.disconnectError = StateError('already gone');

      await printer.disconnect();

      ble.disconnectError = null;
      await printer.connect('AA');
      expect(connects(), 2);
    });
  });

  group('BlePrinter — write', () {
    late BlePrinter printer;

    setUp(() {
      printer = BlePrinter();
      ble.permissionsHeld = true;
    });

    Uint8List bytesOf(int length) =>
        Uint8List.fromList(List.generate(length, (i) => i % 256));

    List<int> sizes() => ble.writes.map((w) => w.value.length).toList();

    List<int> sent() => ble.writes.expand((w) => w.value).toList();

    Future<void> settle() => Future<void>.delayed(Duration.zero);

    group('what goes out', () {
      test(
        'sends a short document as one write to the characteristic it found',
        () async {
          await printer.connect('AA');

          await printer.write(bytesOf(100));

          expect(ble.writes, hasLength(1));
          expect(ble.writes.single.value, bytesOf(100));
          expect(
            ble.writes.single.service,
            '000018f0-0000-1000-8000-00805f9b34fb',
          );
          expect(
            ble.writes.single.characteristic,
            BleUuidParser.string('2af1'),
          );
        },
      );

      // A write with response, because the next chunk goes out when this one completes.
      test('writes with response when the characteristic offers it', () async {
        await printer.connect('AA');

        await printer.write(bytesOf(10));

        expect(ble.writes.single.withoutResponse, isFalse);
      });

      test(
        'writes without response when that is all the characteristic offers',
        () async {
          ble.services = [
            BleService('49535343-fe7d-4ae5-8fa9-9fafd205e455', [
              BleCharacteristic('ffe1', [
                CharacteristicProperty.writeWithoutResponse,
              ], []),
            ]),
          ];
          await printer.connect('AA');

          await printer.write(bytesOf(400));

          expect(ble.writes, isNotEmpty);
          expect(ble.writes.every((w) => w.withoutResponse), isTrue);
        },
      );

      // Nothing to send is nothing to write; not one empty write.
      test('writes nothing for no bytes, and does not fail', () async {
        await printer.connect('AA');

        await printer.write(Uint8List(0));

        expect(ble.writes, isEmpty);
      });
    });

    // The bug this exists to prevent: the library would offer chunks up to ~509 bytes after a
    // 512 MTU, and printers that stall around 185 truncate the first long receipt.
    group('in chunks', () {
      // `optimization.md` §5: the count is the proof. Output that comes out right from the
      // wrong number of writes is still wrong.
      test(
        'puts 1000 bytes out in exactly 6 writes of at most 180, unchanged',
        () async {
          ble.mtu = 247;
          await printer.connect('AA');
          final document = bytesOf(1000);

          await printer.write(document);

          expect(ble.writes, hasLength(6));
          expect(sizes(), [180, 180, 180, 180, 180, 100]);
          expect(sent(), document);
        },
      );

      test('follows a small negotiated MTU: 23 gives chunks of 20', () async {
        ble.mtu = 23;
        await printer.connect('AA');

        await printer.write(bytesOf(100));

        expect(sizes(), [20, 20, 20, 20, 20]);
      });

      // Recorded as a deviation from the source, which uses 180 here (`provenance.md`).
      // Decided by the manual test; it changes in one place.
      test('uses chunks of 20 when the MTU could not be negotiated', () async {
        ble.mtuError = StateError('mtu refused');
        await printer.connect('AA');

        await printer.write(bytesOf(100));

        expect(sizes(), [20, 20, 20, 20, 20]);
      });
    });

    group('with no link', () {
      test('fails, and writes nothing, before any connect', () async {
        await expectLater(
          printer.write(bytesOf(10)),
          throwsPrinter(PrinterFailure.printFailed),
        );
        expect(ble.writes, isEmpty);
      });

      test('fails after a disconnect', () async {
        await printer.connect('AA');
        await printer.disconnect();

        await expectLater(
          printer.write(bytesOf(10)),
          throwsPrinter(PrinterFailure.printFailed),
        );
        expect(ble.writes, isEmpty);
      });

      test('fails when the printer dropped the link', () async {
        await printer.connect('AA');
        ble.dropConnection('AA');
        await settle();

        await expectLater(
          printer.write(bytesOf(10)),
          throwsPrinter(PrinterFailure.printFailed),
        );
        expect(ble.writes, isEmpty);
      });

      // The source checks for the link before it looks at the bytes.
      test('fails even for no bytes', () async {
        await expectLater(
          printer.write(Uint8List(0)),
          throwsPrinter(PrinterFailure.printFailed),
        );
      });
    });

    group('when a write fails', () {
      // Once one chunk fails, what follows would print a receipt with a hole in it.
      test(
        'stops at once: 3 attempts, the third failing, none after',
        () async {
          await printer.connect('AA');
          ble.failAtWrite = 3;

          await expectLater(
            printer.write(bytesOf(1000)),
            throwsPrinter(PrinterFailure.printFailed),
          );

          expect(ble.writeAttempts, 3);
          expect(ble.writes, hasLength(2));
        },
      );

      // The source turns every rejection into `printFailed`; the cashier's move is the same.
      test('reports printFailed whatever the plugin says', () async {
        await printer.connect('AA');
        ble.failAtWrite = 1;
        ble.writeFailure = UniversalBleException(
          code: UniversalBleErrorCode.bluetoothNotEnabled,
          message: 'x',
        );

        await expectLater(
          printer.write(bytesOf(10)),
          throwsPrinter(PrinterFailure.printFailed),
        );
      });

      // The plugin reports a dropped printer through the connection stream; a failed write is
      // not by itself proof the link is gone, so the link is kept and the next print tries it.
      test('keeps the link', () async {
        await printer.connect('AA');
        ble.failAtWrite = 1;
        await expectLater(printer.write(bytesOf(10)), throwsA(anything));

        await printer.connect('AA');

        expect(connects(), 1);
      });

      test('lets the next write through', () async {
        await printer.connect('AA');
        ble.failAtWrite = 1;
        await expectLater(printer.write(bytesOf(10)), throwsA(anything));

        await printer.write(bytesOf(10));

        expect(ble.writes, hasLength(1));
      });
    });

    // A double tap must not print the receipt twice, and two documents must not interleave
    // their chunks on the wire. The library would queue the second; the source rejects it.
    group('while another write is running', () {
      test(
        'rejects the second, writes nothing for it, then works again',
        () async {
          await printer.connect('AA');
          final hold = Completer<void>();
          ble.holdWrites = hold;

          final first = printer.write(bytesOf(50));
          await settle();
          await expectLater(
            printer.write(bytesOf(50)),
            throwsPrinter(PrinterFailure.printFailed),
          );
          hold.complete();
          await first;

          expect(ble.writes, hasLength(1));
          ble.holdWrites = null;
          await printer.write(bytesOf(50));
          expect(ble.writes, hasLength(2));
        },
      );
    });
  });
}
