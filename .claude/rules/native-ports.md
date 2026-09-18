---
description: Native port rules — plugin native hanya lewat port, tiga file per kemampuan
tools: "*"
alwaysApply: true
paths:
  - "**/*.dart"
  - "**/*.yaml"
  - "**/*.arb"
  - "**/*.kts"
  - "**/*.xml"
---

# Native Ports — Jangan Panggil Plugin Native Langsung

> **Setiap panggilan ke native (BLE, SQLite, kamera, launcher) WAJIB lewat port/interface.**
> Ini bukan preferensi gaya — ini yang membuat widget bisa diuji tanpa perangkat.

---

## 1. Aturan Mutlak

### 1.1 DILARANG memanggil plugin native dari widget

```dart
// DILARANG — widget ini tidak bisa dites tanpa printer fisik
import 'package:universal_ble/universal_ble.dart';

Future<void> handlePrint() async {
  final device = await UniversalBle.getBluetoothAvailabilityState();
  await UniversalBle.connect(device);
}
```

```dart
// BENAR
import 'package:pos/native/printer/active.dart';

Future<void> handlePrint() async {
  await printer.print(bytes);
}
```

**Alasannya bukan kerapian.** Plugin native butuh `MethodChannel`, dan `MethodChannel` tidak
ada di `dart test` — jadi setiap widget yang menyentuh plugin langsung **tidak bisa diuji**
tanpa perangkat, dan logika uang yang kebetulan lewat jalur itu ikut tidak bisa diuji.

### 1.2 Setiap kemampuan native punya port

| Kemampuan | Plugin / API | Port | Kontrak ada di |
| --------- | ------------ | ---- | -------------- |
| Cetak BLE | `universal_ble` | `PrinterPort` | `pn_types` |
| Buka URL eksternal | `url_launcher` | `OpenerPort` | `pn_types` |
| Preferensi ringan | `shared_preferences` | `PreferencesPort` | `pn_types` |
| Info perangkat | `device_info_plus` | `DeviceInfoPort` | `pn_types` |
| Versi aplikasi | `package_info_plus` | `AppInfoPort` | `pn_types` |
| Sesi & token | `flutter_secure_storage` | `StorePort` | `pn_types` |
| Deep link | `app_links` | `LinkPort` | `pn_types` |
| Analitik | `firebase_analytics` | `AnalyticsPort` | `pn_types` |
| Crash report | `firebase_crashlytics` | `CrashReportPort` | `pn_types` |
| Patch OTA | `shorebird_code_push` | `UpdaterPort` | `pn_types` |
| Update Play Store | `in_app_update` | `NativeUpdatePort` | `pn_types` |
| HTTP tanpa sesi | `dio` | `PublicHttpPort` | `pn_types` |
| Keranjang tertahan | `sqflite` | `HoldOrderStore` | `pn_pos` |
| Antrian penjualan | `sqflite` | `PendingSaleStore` | `pn_pos` |
| Scan barcode | `mobile_scanner` | `ScannerPort` | `apps/pos` — butuh `Widget` |

Transport HTTP **sudah** punya port-nya: transport seam di `pn_types` — lihat
`.claude/rules/architecture.md` §6.

---

## 2. Struktur Port — TIGA File, DUA Lokasi

Setiap kemampuan native punya kontrak, implementasi nyata, dan fake untuk test — tapi
**tidak semuanya di folder yang sama**, dan pembagiannya bukan selera:

| Berkas | Lokasi | Kenapa di sana |
| ------ | ------ | -------------- |
| `*_port.dart` | `packages/pn_types/lib/src/native/` (atau `pn_pos/lib/src/`) | Kontrak murni tipe. Kalau ia tinggal di `apps/pos`, package lain tidak bisa memakainya — dan `pn_pos` tidak boleh bergantung pada `apps/pos` |
| `*_fake.dart` | sama dengan kontraknya | Fake harus bisa dipakai **semua** package yang menguji lewat port itu, termasuk `pn_pos` dan `pn_types` sendiri |
| `*_<impl>.dart` | `apps/pos/lib/native/<kemampuan>/` | Implementasi nyata mengimpor plugin, dan hanya `apps/pos` yang boleh punya plugin |
| `active.dart` | `apps/pos/lib/native/<kemampuan>/` | Pemilihan implementasi adalah keputusan aplikasi, bukan keputusan tipe |

```
packages/pn_types/lib/src/native/       ← kontrak + fake, tanpa plugin
├── printer_port.dart          # abstract interface class
├── printer_fake.dart          # implementasi untuk test
├── opener_port.dart
└── opener_fake.dart

apps/pos/lib/native/printer/            ← implementasi nyata + pemilihan
├── printer_ble.dart           # universal_ble diimpor DI SINI, tidak di tempat lain
├── printer_protocol.dart      # logika murni (chunking) — tanpa plugin
└── active.dart                # memilih implementasi
```

**Pengecualian yang disengaja: `ScannerPort`.** Kontraknya ada di
`apps/pos/lib/native/scanner/scanner_port.dart`, karena ia mengembalikan `Widget` — dan
`pn_types` dilarang menyentuh `flutter` (`.claude/rules/architecture.md` §3). Itu satu-satunya
port yang boleh tinggal di `apps/pos`, dan alasannya tertulis di berkasnya.

**Tidak ada berkas stub untuk development.** Flutter tidak punya mode "jalan di browser",
jadi tidak ada `browser.dart`. Menambahkannya berarti menulis stub untuk masalah yang tidak
ada.

### 2.1 `*_port.dart` — kontrak

- **Murni tipe.** Tidak boleh mengimpor `universal_ble` atau plugin apa pun.
- Ini yang diimpor oleh widget **dan** test.

```dart
abstract interface class PrinterPort {
  Future<List<PrinterDevice>> listDevices();
  Future<void> connect(String deviceId);
  Future<void> print(Uint8List bytes);
  Future<void> disconnect();
}
```

> [!IMPORTANT]
> **`Uint8List`, bukan `List<int>`.** ESC/POS adalah byte, dan `Uint8List` adalah tipe byte
> yang benar di Dart. Memakai `List<int>` membuang jaminan rentang 0–255 dan membuat
> konversi menumpuk di batas transport.

### 2.2 `*_<impl>.dart` — implementasi nyata

```dart
class BlePrinter implements PrinterPort {
  @override
  Future<void> print(Uint8List bytes) async { ... }
}
```

### 2.3 `*_fake.dart` — implementasi untuk test

**Ditaruh di `lib/` package pemilik kontrak, bukan di `test/`.** Untuk port `pn_types`, itu
berarti `packages/pn_types/lib/src/native/`; untuk `HoldOrderStore`, itu
`packages/pn_pos/lib/src/`. Alasannya: fake yang tinggal di `test/` tidak bisa dipakai oleh
test package lain (`apps/pos` butuh fake dari `pn_pos`), dan fake yang didefinisikan ulang di
setiap test akan menyimpang.

Fake **wajib merekam pemanggilan** supaya bisa di-assert:

```dart
class FakePrinter implements PrinterPort {
  final printed = <Uint8List>[];

  @override
  Future<void> print(Uint8List bytes) async => printed.add(bytes);

  @override
  Future<List<PrinterDevice>> listDevices() async =>
      [const PrinterDevice(id: 'fake', name: 'Printer (fake)')];

  // ...connect/disconnect mencatat ke list yang sama
}
```

Ini perannya: bukan untuk menjalankan app, tapi untuk **verifikasi di test**. Yang penting
sama — fake harus **terlihat**, supaya tidak ada aksi yang diam-diam tidak terjadi.

### 2.4 `active.dart` — pemilihan

```dart
PrinterPort get printer => _printer;
PrinterPort _printer = BlePrinter();

// Dipanggil sekali saat startup (atau di test) untuk mengganti implementasi.
void setPrinter(PrinterPort impl) => _printer = impl;
```

**Test mengganti lewat `setPrinter(FakePrinter())`**, bukan lewat mock framework. Widget
tetap mengimpor `active.dart` dan tidak tahu apa yang ada di belakangnya.

---

## 3. Kenapa Port, Bukan Flag Boolean

```dart
// DILARANG
Future<void> print(Uint8List bytes, {required bool useNative}) { ... }

// BENAR — dua implementasi dari satu kontrak
final PrinterPort printer = isDevice ? BlePrinter() : FakePrinter();
```

Ini penerapan `.claude/rules/patterns.md` §2.2: **model hubungannya secara eksplisit**. Dua
implementasi dari satu `abstract interface class` — bukan satu fungsi dengan percabangan, dan
bukan dua fungsi yang mirip.

Keuntungan tambahan:

- **Test** menyuntikkan implementasi ketiga tanpa menyentuh yang asli.
- **Menambah platform** = menambah satu file, bukan menyunting semua pemanggil.

---

## 4. Fake Tidak Boleh Terlalu Permisif

Fake yang selalu sukses menyembunyikan bug.

| Perilaku | Boleh? | Catatan |
| -------- | ------ | ------- |
| Merekam pemanggilan | ✅ | **Wajib** — supaya bisa di-assert |
| Mengembalikan data realistis | ✅ | mis. daftar perangkat fake |
| Mengembalikan sukses diam | ⚠️ | hanya kalau memang tidak ada yang bisa diverifikasi |
| **Mensimulasikan error** | ✅ | wajib ada, untuk menguji jalur gagal |
| **Mensimulasikan delay** | ✅ | berguna untuk menguji loading state |

**Yang penting:** setiap fake punya jalur error yang bisa dinyalakan. Port tanpa test jalur
gagal berarti jalur gagal itu belum pernah dieksekusi — lihat `.claude/rules/testing.md` §1.

---

## 5. Yang Tetap Boleh Dipanggil Langsung

Beberapa hal memang tersedia di `dart test` dan tidak perlu port:

| API | Kenapa aman |
| --- | ----------- |
| `DateTime.now()` | tapi **inject** kalau nilainya masuk perhitungan uang |
| `Random` | inject kalau dipakai untuk apa pun yang perlu direproduksi |
| Operasi `String`/`List`/`Map` | murni |
| `intl` formatting | murni — tapi **locale harus eksplisit**, jangan baca platform |
| `dart:convert` | murni |

**Tapi hati-hati:** `DateTime.now()` di dalam fungsi perhitungan membuat test-nya
non-deterministik. Kalau waktu mempengaruhi hasil (kapan shift dibuka, urutan antrian),
**terima waktu sebagai parameter**, jangan ambil sendiri.

---

## 6. Checklist

Sebelum menambah kemampuan native baru:

- [ ] `*_port.dart` dibuat, murni tipe, tanpa impor plugin
- [ ] Implementasi nyata ada di file terpisah
- [ ] `*_fake.dart` ada, merekam pemanggilan, **punya jalur error**
- [ ] `active.dart` memilih implementasi, dan bisa diganti dari test
- [ ] Tidak ada impor plugin di luar folder port
- [ ] Widget mengimpor dari `active.dart`, bukan dari implementasi nyata
- [ ] Test memakai fake port, bukan `MethodChannel` mock

---

## 7. Cara Memeriksa Pelanggaran

```bash
# Impor plugin native yang bocor ke luar folder implementasi.
# .dart_tool/ dan build/ DIKECUALIKAN DI SISI PENCARIAN, bukan disaring dengan pipe:
# keduanya memuat salinan generated yang besar, dan pipe tetap menelusurinya.
grep -rn --include="*.dart" \
  --exclude-dir=.dart_tool --exclude-dir=build --exclude-dir=windows --exclude-dir=android \
  -e "package:universal_ble" -e "package:sqflite" -e "package:url_launcher" \
  -e "package:shared_preferences" -e "package:mobile_scanner" \
  apps/pos/lib packages/*/lib | grep -v "/native/"

# Widget yang menyentuh MethodChannel langsung
grep -rn --include="*.dart" --exclude-dir=.dart_tool --exclude-dir=build \
  "MethodChannel" apps/pos/lib packages/*/lib
```

Hasilnya harus **kosong**, kecuali berkas di dalam folder implementasi masing-masing.

> [!NOTE]
> **Perintah di atas juga harus dibuktikan bisa menyala** (`.claude/rules/testing.md` §0.3).
> Sebelum mempercayai hasil kosong, jalankan terhadap berkas yang **diketahui** mengimpor
> plugin — mis. `apps/pos/lib/native/printer/printer_ble.dart` — dan pastikan grep-nya
> menemukannya. Hasil nol dari perintah yang belum pernah terbukti bisa menemukan tidak
> membuktikan apa pun.
