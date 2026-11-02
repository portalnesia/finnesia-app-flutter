---
description: Aturan Windows — platform pengembangan, branding, distribusi Shorebird dan MSIX
tools: "*"
alwaysApply: true
paths:
  - "**/*.dart"
  - "**/*.yaml"
  - "**/*.arb"
  - "**/*.kts"
  - "**/*.xml"
---

# Windows — Platform Pengembangan Harian dan Distribusi CI

> **Windows dipakai untuk mengembangkan dan menguji aplikasi ini.** `FinnesiaPOS.exe` dibangun
> dan dijalankan di mesin pengembangan.
>
> Jalur CI sekarang membuat rilis Windows dengan Shorebird lalu mengemas MSIX ke draft GitHub
> Release. Upload ke Partner Center tetap manual. Shorebird Windows masih beta dan mendukung x64.

Konteks dan keputusan pemilik: `.claude/rules/architecture.md` §1.1.

> [!IMPORTANT]
> **Jangan tulis "Windows belum dijalankan" atau "belum di-build".** Itu **salah** — aplikasinya
> jalan, dan dipakai setiap hari. Workflow rilis kini terkonfigurasi, tetapi hasilnya harus tetap
> diverifikasi melalui GitHub Actions; konfigurasi saja bukan bukti binary telah teruji.

---

## 1. Kenapa Folder Ini Disentuh Sama Sekali

**Nama aplikasi dan branding diset lebih awal** supaya platform ini tidak jadi kejutan nanti.
Alasan itu tepat: platformnya dipakai untuk pengembangan, dan jalur rilis Shorebird + MSIX kini
dikonfigurasi dalam GitHub Actions; upload Partner Center tetap manual.

Branding yang sudah diset:

| Hal | Nilai | Berkas |
| --- | ----- | ------ |
| Nama binary | `FinnesiaPOS` | `windows/CMakeLists.txt` |
| Judul window dan entri taskbar | `Finnesia POS` | `windows/runner/main.cpp` |
| Version resource | `Finnesia POS`, `Finnesia`, `FinnesiaPOS.exe` | `windows/runner/Runner.rc` |
| Ikon | artwork full-bleed, 6 ukuran | `windows/runner/resources/app_icon.ico` |

---

## 2. `BINARY_NAME` — Tiga Jebakan

### 2.1 Tidak boleh ada spasi

```cmake
set(BINARY_NAME "FinnesiaPOS")   # BENAR
set(BINARY_NAME "Finnesia POS")  # RUSAK — configure step gagal
```

`${BINARY_NAME}` dipakai **tanpa kutip** di `windows/flutter/generated_plugins.cmake`
(`target_link_libraries(${BINARY_NAME} PRIVATE ${plugin}_plugin)`). Nama dengan spasi terpecah
jadi dua argumen CMake.

Nama yang **dibaca manusia** adalah judul window dan version resource, bukan nama binary. Jadi
tidak ada yang hilang dengan membuang spasi di sini.

### 2.2 Harus satu baris, dan formatnya diperiksa `flutter_tools`

`flutter_tools` mencari nama itu dengan regex (`lib/src/cmake.dart`):

```dart
RegExp(r'^\s*set\(BINARY_NAME\s*"(.*)"\s*\)\s*$')
```

Konsekuensi yang mudah terlewat: **komentar tidak boleh berada di dalam baris `set(...)`**, dan
`set(...)` tidak boleh dipecah dua baris. Kalau tidak cocok, `flutter run` dan `flutter build`
tidak menemukan executable-nya.

### 2.3 `Runner.rc` harus ikut berubah

`VALUE "OriginalFilename"` wajib sama dengan `${BINARY_NAME}.exe`. Kalau tidak, Properties di
Explorer berbeda dari berkas di disk.

Ketiganya dipatok oleh test (`apps/pos/test/branding/branding_test.dart`), jadi kesalahan ini
gagal di `flutter test`, bukan di tablet kasir.

### 2.4 Ganti `BINARY_NAME` MEMBATALKAN cache CMake — hapus `build/windows/`

Gejala yang muncul, dan terlihat seperti bug di `CMakeLists.txt` padahal bukan:

```
CMake Error: Error evaluating generator expression:
    $<TARGET_FILE_DIR:pos>
  No target "pos"
```

Sebabnya ada di `build/windows/x64/CMakeCache.txt`:

```
CMAKE_INSTALL_PREFIX:PATH=$<TARGET_FILE_DIR:pos>
```

Flutter menulis **generator expression mentah** ke cache lewat
`set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)`, dan di dalamnya ada
nama target **saat cache itu dibuat**. Setelah `BINARY_NAME` berubah, nama itu tidak ada lagi, dan
configure berikutnya mengevaluasi ekspresi yang menunjuk target yang sudah tidak eksis.

**Perbaikannya: hapus `apps/pos/build/windows/`, lalu build ulang.** Bukan menyunting CMake —
`sumbernya bersih`, dan `grep -rn "TARGET_FILE_DIR:pos\|add_executable(pos\|project(pos" windows/`
mengembalikan kosong. Cache itu untracked dan di-ignore (`.gitignore` → `build/`), jadi tidak ada
yang hilang.

Build ulang dari nol juga **satu-satunya** cara membuktikan rename-nya benar: `flutter build
windows --debug` menghasilkan `build\windows\x64\runner\Debug\FinnesiaPOS.exe`.

---

## 3. Ikon Windows — `flutter_launcher_icons` Tidak Cukup

`flutter_launcher_icons` menulis `.ico` **satu ukuran** (`windows/windows_icon_generator.dart`
memanggil `encodeIco` pada satu gambar hasil resize, default `icon_size: 48`). Windows meminta
shell untuk **enam** ukuran berbeda — taskbar, mode taskbar kecil, daftar Explorer, ikon medium
Explorer, tile besar, dan Alt-Tab. Dengan satu ukuran, sisanya diperbesar dan terlihat kabur.

Karena itu `.ico` ditulis oleh `apps/pos/tool/generate_windows_icon.dart`, dan di config
`flutter_launcher_icons.yaml` **`windows.generate: false`** dengan alasan tertulis di sana.

| Hal | Nilai |
| --- | ----- |
| Ukuran di dalam `.ico` | `16, 24, 32, 48, 64, 256` |
| Batas format | 256 px — `IcoEncoder` melempar di atasnya |
| Interpolasi | `Interpolation.average` (downscale besar dari 1080 px) |
| Sumber | `assets/icon/icon.png` — **full-bleed**, bukan `icon_only.png` |

**Kenapa full-bleed, bukan glyph transparan.** Windows **tidak** memasker ikon aplikasi seperti
adaptive icon Android. `icon_only.png` adalah glyph putih di atas transparan; di tema terang itu
putih di atas putih. `icon.png` membawa latar amber-nya sendiri — sama dengan yang dipakai
`site.webmanifest`.

Menjalankan: `./dev icons` (menjalankan generator Android lalu Windows).

---

## 4. Apa yang Sudah Terverifikasi, dan Apa yang Belum

Daftar di bawah ini adalah keadaan yang diperiksa ke disk — bukan disalin dari dokumen.

**Sudah terverifikasi.** `flutter build windows --debug` **berhasil** —
`apps/pos/build/windows/x64/runner/Debug/FinnesiaPOS.exe` (3,8 MB), bersama
`flutter_windows.dll`, `sqlite3.dll`, `dartjni.dll`, dan plugin `app_links`,
`flutter_secure_storage_windows`, `universal_ble`, `url_launcher_windows` (dibaca dari
`windows/flutter/generated_plugins.cmake` dan dari isi folder `Debug`). Version resource-nya
diperiksa di dalam `.exe` itu sendiri (string Windows disimpan UTF-16LE): `Finnesia POS` 3×,
`FinnesiaPOS.exe` 1×, `FinnesiaPOS` 2×, dan **nol** `pos` telanjang sebagai nama produk. Lokasi
data: `.claude/rules/project.md` §5.1.

**Belum diverifikasi pada build release nyata** — konfigurasi CI sudah ada, tetapi job Windows
belum dijalankan dalam tugas ini. Jangan menyamakan konfigurasi dengan bukti runtime:

| Hal | Keadaan sebenarnya |
| ---- | ----------------- |
| Build **release** | Workflow `windows-pos.yml` memakai `shorebird release windows` pada runner Windows x64; hasil release belum diverifikasi sampai GitHub Actions menjalankannya |
| MSIX sebagai artefak | Workflow mengemas output Shorebird menjadi MSIX dan melampirkannya ke draft GitHub Release; belum ada artifact release yang tersimpan di repo atau diuji pada mesin pengguna |
| **Printer BLE dari aplikasi Windows** | **Belum terbukti.** `universal_ble_plugin.dll` ikut ter-build, tapi belum ada bukti printer pernah terhubung dari app Windows. Dukungan BLE Windows `universal_ble` belum dijalankan sama sekali. Ini fungsi inti POS — lihat `plan/printer/` |
| `identity_name` untuk Microsoft Store | Nilainya dikonfigurasi di `apps/pos/pubspec.yaml` dan harus cocok persis dengan `Package/Identity/Name` dari Partner Center; upload dan sertifikasi tetap manual |
| SQLite di aplikasi yang berjalan | `sqflite` tidak punya implementasi Windows, jadi Windows memakai `sqflite_common_ffi` (`sqlite3.dll` ikut terbundel, diperiksa di folder `Debug`). Jalur file dan bukaan-ulang diuji dengan SQLite FFI sungguhan di `flutter test`; yang belum: aplikasinya sendiri membuka `%APPDATA%\Finnesia\Finnesia POS\finnesia_pos.db` |

Semua pemeriksaan di repo ini untuk Windows bersifat **statis** (test membaca berkas). Itu
disengaja: cukup untuk menangkap nama dan ikon yang salah, dan itu saja yang bisa dijamin test
tanpa perangkat. Test statis **tidak** membuktikan aplikasinya jalan — yang membuktikan itu
adalah pemilik yang menjalankannya.
