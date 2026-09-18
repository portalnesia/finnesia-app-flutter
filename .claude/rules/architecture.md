---
description: Architecture rules — pub workspace, batas dependency package, port pattern, registry API
tools: "*"
alwaysApply: true
paths:
  - "**/*.dart"
  - "**/*.yaml"
  - "**/*.arb"
  - "**/*.kts"
  - "**/*.xml"
---

# Architecture — Struktur Monorepo, Batas Package, API Registry

---

## 1. Bentuk Repo

Repo ini **berdiri sendiri** — tidak ada checkout bersama, submodule, atau mekanisme sinkronisasi
dengan repo mana pun. Ia berbentuk **monorepo** (pub workspace), supaya plugin Flutter internal
tidak perlu repo sendiri.

```
finnesia-pos-flutter/
├── pubspec.yaml                    ← workspace root
├── AGENTS.md
├── .claude/rules/*.md
├── .github/copilot-instructions.md
├── .github/workflows/*.yml
├── apps/
│   └── pos/                        ← aplikasi POS (Android + Windows; folder windows/ dipakai harian)
├── packages/
│   ├── pn_types/                   ← tipe murni (padanan @pn/types)
│   ├── pn_pos/                     ← logika POS murni (padanan shared/src/pos)
│   └── pn_ui/                      ← widget reusable (padanan @pn/ui)
├── plugins/                        ← plugin Flutter internal (BLE printer dll.)
├── tools/                          ← skrip repo (mis. rule_lint)
└── plan/
    ├── scaffold/                   ← dokumen scaffold
    └── <fitur>/*.md
```

### 1.1 Kenapa `apps/pos/` dan bukan `app/`

`apps/pos/` adalah nama folder aplikasi. Windows adalah **platform kedua dari app yang sama** —
bukan app baru. Ia dipakai untuk pengembangan dan pengujian harian; yang belum ada adalah jalur
distribusinya, bukan pemakaiannya (`.claude/rules/windows.md`).

Folder `apps/pos/windows/` sudah digenerate `flutter create` dan **sengaja dibiarkan: jangan
dihapus.** Kalau menyentuh `windows/`, baca `.claude/rules/windows.md` lebih dulu.

Branding Windows sudah diset — `BINARY_NAME` = `FinnesiaPOS`, judul window = `Finnesia POS`,
version resource, dan `app_icon.ico` multi-ukuran.

Semua verifikasi (`testing.md` §7) tetap berlaku untuk Android dan untuk `dart test` /
`flutter test`, yang tidak bergantung pada platform. Yang **belum** boleh diklaim: bahwa Windows
punya jalur distribusi yang siap, selama jalur itu belum dibangun.

---

## 2. Dart pub workspaces

Root `pubspec.yaml` mendeklarasikan `workspace:`; setiap member memakai
`resolution: workspace` dan **mendaftar sibling tanpa versi dan tanpa path**:

```yaml
# packages/pn_pos/pubspec.yaml
name: pn_pos
publish_to: none
environment:
  sdk: ^3.6.0
resolution: workspace
dependencies:
  pn_types:            # ← tanpa versi, tanpa path
```

**Verifikasi:** `dart pub get` di root harus menyelesaikan seluruh workspace.

> [!IMPORTANT]
> `plugins/` ditambahkan ke `workspace:` **saat plugin pertama dibuat** — jangan
> mendeklarasikan folder kosong.

### 2.1 `tools/` sengaja BUKAN member workspace

`tools/rule_lint/` punya pubspec sendiri dan **tidak** terdaftar di `workspace:`. Alasannya:
ia harus bisa dijalankan sebelum workspace terbentuk (memeriksa file aturan, yang justru
dibuat paling awal), dan ia tidak boleh menambah dependency apa pun ke graph aplikasi.

---

## 3. Aturan Dependency — Ditegakkan, Bukan Sekadar Ditulis

```
pn_types  →  (tidak ada)
pn_pos    →  pn_types          ← DILARANG flutter
pn_ui     →  flutter, pn_types
apps/pos  →  semuanya
```

| Package | Boleh bergantung pada | DILARANG bergantung pada |
| ------- | --------------------- | ------------------------ |
| `pn_types` | *(tidak ada)* — tipe murni | `flutter`, `pn_*` |
| `pn_pos` | `pn_types` | **`flutter`**, `pn_ui` |
| `pn_ui` | `flutter`, `pn_types` | `pn_pos` |
| `apps/pos` | semuanya | — |

> [!IMPORTANT]
> **`pn_pos` DILARANG mengimpor `flutter`.** Ini bukan formalitas — ini yang membuat test
> logika POS jalan dengan `dart test` (milidetik) alih-alih `flutter test` (detik), dan yang
> mencegah logika uang tercampur dengan widget.

**Cara memeriksa** (harus kosong):

```bash
grep -rn "^import 'package:flutter" packages/pn_pos/lib/
```

### 3.1 Isi `pn_pos`

| Modul (padanan) | Alasan |
| --------------- | ------ |
| `pos-calculations` | matematika murni |
| `pos-cart` | matematika murni |
| `pos-cart-gate` | aturan murni |
| `pos-tender` | matematika murni |
| `pos-product-stock` | aturan murni |
| `pos-shift` | aturan murni |
| `escpos` | byte murni, **nol import** |
| `pos-shift-report-escpos` | byte murni — tapi lihat §3.2 |

### 3.2 Yang TIDAK boleh masuk `pn_pos`

| Modul | Alasan | Taruh di |
| ----- | ------ | -------- |
| `pos-hold` | butuh storage → **port** | `pn_pos` dengan `abstract interface class HoldOrderStore`, implementasi di `apps/pos` |
| `pos-shift-resume` | **jangan di-port sama sekali** — lihat `.claude/rules/project.md` §2.3 | — |

### 3.3 Dua helper yang wajib ikut, kalau `pos-shift-report-escpos` di-port

Modul itu **bukan** nol-import. Ia memakai `formatCurrency` dan `formatDateTime` dari
`packages/shared/src/utils/`. Kalau ia di-port tanpa keduanya, hasilnya bukan port —
hasilnya implementasi baru yang kebetulan mirip.

Keduanya sudah diverifikasi **DOM-free** (tidak menyentuh `window`, `document`,
`localStorage`, `navigator`), jadi keduanya boleh masuk `pn_pos`. Ikutkan test-nya.

---

## 4. Port Pattern

Widget **dilarang** memanggil plugin native langsung. Selalu lewat port. Itu yang membuat
widget bisa diuji tanpa perangkat.

Port ditulis dengan `abstract interface class` sebagai kontrak, implementasi nyata di berkas
terpisah, fake untuk test, dan `active.dart` yang memilih implementasi. Tidak ada berkas stub
untuk development di browser: Flutter tidak punya mode itu, dan fake di sini ada untuk
**verifikasi**, bukan untuk menjalankan app.

Detail: `.claude/rules/native-ports.md`.

---

## 5. Printer — Transport, Bukan Format

| Lapisan | Siapa yang mengerjakan |
| ------- | ---------------------- |
| Format byte ESC/POS | **formatter yang di-port** dari `apps/web/src/lib/` di repo sumber |
| Scan, connect, write, MTU | **`universal_ble`** (BSD-3) — jangan ditulis manual |
| Chunking (cap **180**) | **ditulis sendiri** — paketnya tidak menyediakan ini |
| Urutan tulis | `await` di atas `write`, yang sudah punya antrian global sendiri |
| Pemilihan perangkat & koneksi | port `PrinterPort`, implementasi di `apps/pos` |

**Library BLE-nya `universal_ble`, bukan `flutter_blue_plus`.** `flutter_blue_plus` 2.x
**berlisensi komersial berbayar** untuk organisasi for-profit, dan `connect()` mewajibkannya;
build-nya juga mengirim *ping* lisensi di tiap build, termasuk di CI. Hanya versi ≤ 1.36.8 yang
BSD, dan itu tidak dirawat. Dua klaim tentang paket itu juga **terbukti salah** diukur ke
source-nya: `splitWrite` **bukan API**, dan paketnya **tidak** meminta izin Bluetooth.

**Yang tidak dipinjam dari paket: cap chunk 180.** `flutter_blue_plus` disebut menyediakan chunk
`mtuNow - 3` maks 512 — nilai itu berbahaya untuk printer di repo ini, dan sumbernya
(`PrinterPlugin.kt`) membatasi **180**. Chunking ditulis sendiri (± 10 baris), dan angkanya
mengikuti sumber, bukan default library.

Detail: `plan/printer/README.md` §1 dan §3.3.

---

## 6. API Registry — Dirancang Ulang, Bukan Disalin

### 6.1 Kenapa tidak bisa disalin apa adanya

Registry web bergantung pada **template literal types** TypeScript:

```ts
type NestedKeys<T> = { ... }
export type EndpointKey = NestedKeys<typeof endpoints>
```

**Dart tidak punya fitur ini.** Klaim "port registry-nya" akan gagal.

### 6.2 Yang tetap bisa dicapai

| Properti | Web (TS) | Flutter (Dart) |
| -------- | -------- | -------------- |
| Tambah endpoint = tambah 1 entri registry | ✅ | ✅ **bisa** |
| Tidak ada file request/hook/tipe baru | ✅ | ✅ **bisa** |
| Path & method terpusat | ✅ | ✅ **bisa** |
| Key & payload divalidasi **compiler** | ✅ | ❌ **tidak bisa** |

Yang hilang hanya **type-safety pada key**. Mitigasinya **test**, bukan compiler:
`registry_test.dart` memverifikasi setiap key terdaftar, path unik, dan method valid.

### 6.3 Yang di-port dari `api.base.ts`

| Fitur | Port? | Catatan |
| ----- | ----- | ------- |
| `applyPathParams` (`:id`) | ✅ | sama persis |
| Query string | ✅ | sama persis |
| `ResponseData` / `ApiErrorTypes` | ✅ | padanannya di `pn_types` |
| `parseRetryAfter` (429) | ✅ | perilaku kasir harus sama |
| Transport seam | ✅ | versi Flutter: bearer + client HTTP |
| CSRF (`_finid_csrf`) | ❌ | POS pakai **bearer**, CSRF tidak berlaku |
| `localStorage` company id | ❌ | pakai port store |

### 6.4 Yang tidak boleh terjadi

**Dilarang** membuat satu fungsi atau method per endpoint. Itu membatalkan seluruh alasan
registry ini ada. Tambah endpoint = tambah **satu entri**, tanpa file baru.

> [!NOTE]
> Keputusan antara `Map<String, Endpoint<dynamic>>` + cast, versus registry **per-domain**
> yang mengembalikan tipe konkret, **belum final**. Ambil saat implementasi dengan kode nyata
> di tangan, bukan sekarang.

---

## 7. Melos — Belum Sekarang

Melos menyelesaikan versioning dan `pub get` massal. Tapi pub workspaces **sudah**
menyelesaikan resolusi dependency, dan jumlah package saat ini 4–5.

**Keputusan: tunda.** Tambahkan kalau salah satu ini benar terjadi:
jumlah package > 8, **atau** butuh publish ke registry internal, **atau** butuh versioning
terkoordinasi antar package. Sampai saat itu, `dart pub get` di root sudah cukup.
