/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

// DOC_INFO_1W: three UTF-16 string pointers.
final class _DocInfo1 extends Struct {
  external Pointer<Utf16> docName;
  external Pointer<Utf16> outputFile;
  external Pointer<Utf16> datatype;
}

typedef _OpenPrinterNative = Int32 Function(
  Pointer<Utf16>,
  Pointer<IntPtr>,
  Pointer<Void>,
);
typedef _OpenPrinter = int Function(
  Pointer<Utf16>,
  Pointer<IntPtr>,
  Pointer<Void>,
);
typedef _HandleNative = Int32 Function(IntPtr);
typedef _Handle = int Function(int);
typedef _StartDocNative = Uint32 Function(IntPtr, Uint32, Pointer<_DocInfo1>);
typedef _StartDoc = int Function(int, int, Pointer<_DocInfo1>);
typedef _WriteNative = Int32 Function(
  IntPtr,
  Pointer<Void>,
  Uint32,
  Pointer<Uint32>,
);
typedef _Write = int Function(int, Pointer<Void>, int, Pointer<Uint32>);

/// A spooler call that returned failure; [step] names the winspool function.
class WindowsSpoolerException implements Exception {
  const WindowsSpoolerException(this.step);

  final String step;

  @override
  String toString() => 'WindowsSpoolerException: $step failed';
}

/// Hands [bytes] to the Windows spooler queue [printerName] with the RAW datatype, so the
/// printer receives the ESC/POS commands instead of a page the driver rendered.
void writeRawToWindowsQueue({
  required String printerName,
  required String documentName,
  required Uint8List bytes,
}) {
  final winspool = DynamicLibrary.open('winspool.drv');
  final openPrinter = winspool.lookupFunction<_OpenPrinterNative, _OpenPrinter>(
    'OpenPrinterW',
  );
  final closePrinter = winspool.lookupFunction<_HandleNative, _Handle>(
    'ClosePrinter',
  );
  final startDoc = winspool.lookupFunction<_StartDocNative, _StartDoc>(
    'StartDocPrinterW',
  );
  final endDoc = winspool.lookupFunction<_HandleNative, _Handle>(
    'EndDocPrinter',
  );
  final startPage = winspool.lookupFunction<_HandleNative, _Handle>(
    'StartPagePrinter',
  );
  final endPage = winspool.lookupFunction<_HandleNative, _Handle>(
    'EndPagePrinter',
  );
  final writePrinter = winspool.lookupFunction<_WriteNative, _Write>(
    'WritePrinter',
  );

  using((arena) {
    final handle = arena<IntPtr>();
    if (openPrinter(
          printerName.toNativeUtf16(allocator: arena),
          handle,
          nullptr,
        ) ==
        0) {
      throw const WindowsSpoolerException('OpenPrinter');
    }
    final printer = handle.value;
    try {
      final doc = arena<_DocInfo1>()
        ..ref.docName = documentName.toNativeUtf16(allocator: arena)
        ..ref.outputFile = nullptr
        ..ref.datatype = 'RAW'.toNativeUtf16(allocator: arena);
      if (startDoc(printer, 1, doc) == 0) {
        throw const WindowsSpoolerException('StartDocPrinter');
      }
      try {
        if (startPage(printer) == 0) {
          throw const WindowsSpoolerException('StartPagePrinter');
        }
        try {
          final buffer = arena<Uint8>(bytes.length);
          buffer.asTypedList(bytes.length).setAll(0, bytes);
          final written = arena<Uint32>();
          var offset = 0;
          while (offset < bytes.length) {
            final ok = writePrinter(
              printer,
              (buffer + offset).cast(),
              bytes.length - offset,
              written,
            );
            if (ok == 0 || written.value == 0) {
              throw const WindowsSpoolerException('WritePrinter');
            }
            offset += written.value;
          }
        } finally {
          endPage(printer);
        }
      } finally {
        endDoc(printer);
      }
    } finally {
      closePrinter(printer);
    }
  });
}
