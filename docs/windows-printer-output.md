# Printer output in the Flutter app

## What can be selected

On Windows, **Menu → Printer** lets the cashier choose between the existing Bluetooth printer path and an installed **Windows printer queue**. The queue list comes from printers registered with Windows; the cashier chooses one by its Windows queue identity. The Bluetooth identity and Windows queue are saved separately, so switching modes does not erase the other selection. Existing installations with a saved Bluetooth printer continue to use Bluetooth by default.

Android remains Bluetooth-only and keeps the existing BLE/ESC/POS path.

## How ordinary Windows printers receive documents

The Windows queue path targets ordinary printers that Windows already exposes as installed print queues, including a wired USB printer with its vendor or class driver installed. Finnesia renders receipts and shift reports as PDF, then sends the PDF to the selected queue through Flutter's Windows printing plugin. The Windows print subsystem and installed driver handle the output; this path does **not** send ESC/POS bytes directly over USB or serial.

Each PDF now renders the same ESC/POS text bytes used by Bluetooth, preserving the receipt/report content, column formatting, order, line breaks, dividers, alignment, emphasis, and footer spacing. The PDF uses embedded Noto Sans Mono, keeps rows within the saved Bluetooth column count, and reduces font size when the driver page is too narrow. A 5 mm safe margin prevents content from reaching the queue's non-printable edges. The page size still comes from the selected Windows queue driver; the PDF does not send a cutter command, so cutting remains controlled by the driver.

The mono font and line metrics closely follow the Bluetooth layout, but the physical BLE printhead and Windows driver can still render glyphs differently. The selected queue continues to use the Windows paper and scaling settings.

## Not available in Flutter yet

The browser POS's other connection choices are not silently treated as Flutter features:

- Direct USB or serial-port selection is not implemented.
- The browser Print Agent is not implemented in this Flutter app.
- A browser print dialog is not applicable to this Windows desktop path and is not offered.
- There is no dedicated test-page action yet; validation must use an actual receipt or shift report.

The Flutter Windows selector therefore offers only Bluetooth and the installed Windows queue, with a note that the other modes are not available here.

## Validation status

Unit and widget tests cover mode selection, preservation of the legacy Bluetooth setting, queue persistence and disappearance, localized queue errors, parsing of Bluetooth layout bytes, PDF column width/wrapping, embedded mono fonts, and submission to a fake queue. These tests prove app-side layout and routing, not paper output.

This change was made in a Linux sandbox with no Windows desktop or physical printer. A Windows build of this change and a real printer job have **not** been verified here. Before rollout, build and run the app on Windows, select an actual installed queue, print both a receipt and a shift report, and check page size, scaling, pagination, and the printer's driver behavior.
