# Printer output in the Flutter app

## What can be selected

On Windows, **Menu → Printer** lets the cashier choose between the existing Bluetooth printer path and an installed **Windows printer queue**. The queue list comes from printers registered with Windows; the cashier chooses one by its Windows queue identity. The Bluetooth identity and Windows queue are saved separately, so switching modes does not erase the other selection. Existing installations with a saved Bluetooth printer continue to use Bluetooth by default.

Android remains Bluetooth-only and keeps the existing BLE/ESC/POS path.

## How ordinary Windows printers receive documents

The Windows queue path targets ordinary printers that Windows already exposes as installed print queues, including a wired USB printer with its vendor or class driver installed. Finnesia renders receipts and shift reports as PDF, then sends the PDF to the selected queue through Flutter's Windows printing plugin. The Windows print subsystem and installed driver handle the output; this path does **not** send ESC/POS bytes directly over USB or serial.

The current PDFs use page-based A4 layouts. They are not a continuous thermal-paper layout, and they do not provide a characters-per-line setting or an automatic cutter command. The Windows UI states that the selected queue prints PDF through its driver.

## Not available in Flutter yet

The browser POS's other connection choices are not silently treated as Flutter features:

- Direct USB or serial-port selection is not implemented.
- The browser Print Agent is not implemented in this Flutter app.
- A browser print dialog is not applicable to this Windows desktop path and is not offered.
- There is no dedicated test-page action yet; validation must use an actual receipt or shift report.

The Flutter Windows selector therefore offers only Bluetooth and the installed Windows queue, with a note that the other modes are not available here.

## Validation status

Unit and widget tests cover mode selection, preservation of the legacy Bluetooth setting, queue persistence and disappearance, localized queue errors, and PDF generation/submission to a fake queue. These tests prove the app-side routing and PDF bytes, not paper output.

This change was made in a Linux sandbox with no Windows desktop or physical printer. A Windows build of this change and a real printer job have **not** been verified here. Before rollout, build and run the app on Windows, select an actual installed queue, print both a receipt and a shift report, and check page size, scaling, pagination, and the printer's driver behavior.
