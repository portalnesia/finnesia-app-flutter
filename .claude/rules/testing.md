---
description: Testing rules — TDD wajib, unit-test-only, struktur test, verifikasi bertingkat
tools: "*"
alwaysApply: true
paths:
  - "**/*.dart"
  - "**/*.yaml"
  - "**/*.arb"
  - "**/*.kts"
  - "**/*.xml"
---

# Testing & Verification Rules — STRICT (TDD ONLY)

> **Kalau melanggar = REJECT.** Tidak ada toleransi.

---

## 0. Prinsip Utama — TDD MUTLAK

**Tulis test dulu (RED) → implementasi minimal (GREEN) → refactor.**

**DILARANG** menulis kode produksi tanpa test yang gagal terlebih dahulu. Agent yang
menghasilkan kode tanpa test = salah, bahkan kalau kodenya benar.

### 0.1 Urutan TDD untuk Bug Fix — WAJIB, TANPA PENGECUALIAN

Laporan bug **BUKAN** pengecualian dari TDD — laporan bug adalah alasan **paling umum**
memakai TDD.

1. Baca laporan/gejala, telusuri kode, bentuk dugaan akar masalah.
2. **SEBELUM mengubah satu baris kode fix apa pun:** tulis test yang meng-encode perilaku
   yang **BENAR**, lalu jalankan terhadap kode yang **belum disentuh sama sekali**.
3. Konfirmasi test itu **benar-benar gagal (RED)** — bukan diasumsikan gagal, bukan
   "pasti gagal karena saya sudah tahu bug-nya di mana".
4. Baru setelah RED dikonfirmasi: implementasikan fix.
5. Jalankan ulang test yang **SAMA**, konfirmasi GREEN.
6. Jalankan regression suite penuh.

**DILARANG KERAS, tanpa pengecualian apa pun** — termasuk saat akar masalah terasa sangat
jelas, termasuk saat ada tekanan waktu, termasuk untuk bug "live"/mendesak:

- Menulis/mengubah fix dulu, baru menulis test setelahnya.
- Menulis fix + test, lalu **revert sementara fix-nya** untuk melihat test gagal, lalu
  mengembalikan fix itu. Ini menghasilkan bukti yang mirip RED asli, tapi **tetap
  pelanggaran** — test harus gagal terhadap kode yang **benar-benar belum pernah disentuh**,
  bukan direkonstruksi lewat revert.
- Alasan "cuma mau double-check fix-nya benar" tidak mengubah apa pun.

**Urutan yang DILARANG — semuanya menghasilkan "bukti RED" yang palsu:**

| # | Yang dilakukan | Kenapa itu pelanggaran |
| - | -------------- | ---------------------- |
| 1 | Implementasi fix dulu, tulis test setelahnya | Test itu belum pernah melihat kode yang salah |
| 2 | Tulis fix + test, lalu **revert fix sementara** untuk melihat test gagal, lalu kembalikan fix | Test itu gagal terhadap kode yang **direkonstruksi**, bukan terhadap kode yang belum pernah disentuh |
| 3 | Laporan bug "live" dibaca, didiagnosis, lalu query langsung diperbaiki | Sama seperti #1, dan justru di sini paling sering terjadi |

Polanya identik: fix sudah ada **sebelum** test yang gagal ada, lalu revert dipakai untuk
mensimulasikan RED yang seharusnya sudah ada dari awal. "Cuma mau double-check fix-nya benar"
tidak mengubah apa pun.

### 0.2 Bug di Repo Ini yang Paling Mahal

**Antrian offline** dan **format struk**. Keduanya menyentuh uang atau bukti transaksi, dan
keduanya **bisa diuji tanpa perangkat** — jadi tidak ada alasan melewati TDD.

### 0.3 Kalau Yang Diuji Adalah Alat Pemeriksa

Berlaku untuk apa pun yang **melaporkan** sesuatu (linter, checker, validator, detector):
hasil **nol temuan tidak membuktikan apa pun** kalau alat itu belum pernah terbukti bisa
menemukan. A detector that never fires is indistinguishable from a broken detector.

**Wajib:** sertakan test yang memberi input **yang diketahui buruk**, dan pastikan alatnya
**menemukan**-nya. Baru setelah itu hasil nol bisa dipercaya.

Contoh nyata di repo ini: `tools/rule_lint` memeriksa bahwa aturan tidak terduplikasi. Test-nya
menyuapkan **teks aturan yang memang duplikat** dan memastikan pemeriksanya **menemukan**
duplikasi itu. Tanpa test itu, "0 duplikasi" hanya berarti "belum pernah dicoba".

> Ini penerapan dari aturan `patterns.md` §3.1: `grep` yang tidak menemukan apa-apa tidak
> membuktikan sesuatu tidak ada — kecuali detector-nya sudah divalidasi.

---

## 1. Cakupan Wajib — Positif, Negatif, Edge

Setiap modul **WAJIB** punya ketiganya. Hanya happy path = **GAGAL** (tidak komprehensif).

- validation gagal (required, format, enum, range)
- not-found / duplicate / conflict
- unauthorized / forbidden
- permission ditolak
- edge: list kosong, qty nol, nilai negatif, overflow pembulatan, no-op, `null`
- **antrian offline:** replay ganda, urutan salah, item hilang
- **printer:** byte kosong, chunk terakhir tidak penuh, koneksi putus di tengah
- **uang:** pembulatan, diskon melebihi subtotal, tender kurang dari total, kembalian nol

---

## 2. Unit Test ONLY

**HARAM** test yang butuh resource eksternal: HTTP nyata, BLE nyata, printer nyata, file
system nyata, jaringan nyata.

Yang dimaksud "eksternal": apa pun yang butuh **perangkat**, **jaringan**, atau **state di
luar proses test**. Semua dependency eksternal **WAJIB di-mock lewat port** — lihat
`.claude/rules/native-ports.md`.

### 2.1 Pengecualian yang Disengaja — In-Memory SQLite untuk Antrian Offline

Unit test dengan storage yang di-mock **tidak pernah mengeksekusi satu baris SQL pun**.
Antrian penjualan adalah data finansial, dan bug idempotensi (replay menggandakan penjualan)
hanya muncul dari SQL yang benar-benar dijalankan — constraint, transaksi, urutan.

Di Dart, `sqflite` butuh platform. Karena itu:

- **Logika antrian** (urutan replay, dedup, penandaan status) dites dengan `dart test`
  terhadap port `HoldOrderStore` yang di-fake **in-memory**.
- **SQL-nya sendiri** dites terhadap **SQLite in-memory** (`sqflite_common_ffi` di
  `flutter test`, atau `sqlite3` langsung). Bukan `sqflite` yang butuh perangkat.

Yang membedakan ini dari "integration test" yang dilarang: tidak ada server, tidak ada
jaringan, tidak ada setup, tidak ada state yang bocor antar-test. Ini SQLite — engine yang
memang dipakai app.

### 2.2 Test Logika Cepat, Test Widget Terpisah

| Yang diuji | Perintah | Kenapa |
| ---------- | -------- | ------ |
| `pn_pos`, `pn_types` | **`dart test`** | tidak butuh Flutter SDK → milidetik |
| `pn_ui`, `apps/pos` | **`flutter test`** | butuh binding Flutter |

**Ini alasan `pn_pos` dilarang mengimpor `flutter`** (`.claude/rules/architecture.md` §3).
Kalau logika uang butuh `flutter test`, artinya ada yang salah taruh.

---

## 3. Struktur Test — 1 Modul = 1 File

**DILARANG** `*_mock_test.dart`, `*_comprehensive_test.dart`, `coverage_extra_test.dart`
terpisah. Gabung semua case dalam **satu file per modul**.

```dart
// test/pos_tender_test.dart
void main() {
  group('pos tender', () {
    test('menghitung kembalian tunai', () { ... });                 // positif
    test('menolak tender kurang dari total', () { ... });           // negatif
    test('tidak menggandakan penjualan saat replay', () { ... });   // edge — finansial
    test('mempertahankan urutan saat replay', () { ... });          // edge
    test('tidak menghapus penjualan yang gagal terkirim', () { ... }); // edge — finansial
  });
}
```

Konvensi penamaan Dart: `snake_case_test.dart`, file di `test/` yang sejajar dengan `lib/`.

---

## 4. Mocking — WAJIB lewat Port

| Yang di-mock | Caranya |
| ------------ | ------- |
| HTTP | fake `ApiTransport` (transport seam) |
| BLE / printer | fake `PrinterPort` |
| SQLite / storage | fake `HoldOrderStore` (in-memory), atau SQLite in-memory (§2.1) |
| URL launcher / OS | fake port masing-masing |

**DILARANG:**

- Memakai plugin Flutter langsung di test (`MethodChannel` nyata).
- Memakai `shared_preferences` asli di test.
- Test yang butuh printer atau tablet fisik — itu **uji manual**, dicatat terpisah.

---

## 5. Test Transport Seam

Karena seam adalah satu-satunya tempat POS berbeda dari web, test-nya wajib:

- [ ] URL absolut ke host tenant (bukan relatif)
- [ ] `Authorization: Bearer` ada
- [ ] **Tidak ada** CSRF header
- [ ] Token **hanya** dikirim ke host yang terkunci
- [ ] Token **tidak pernah** muncul di log

---

## 6. Query-Count dan Batch Test — WAJIB untuk Collection

Setiap fungsi yang menerima collection/IDs wajib punya test yang membuktikan:

- bulk read dipanggil **tepat satu kali** per tipe entity
- single-row read **tidak** dipanggil per item
- bulk write dipanggil sekali, bukan insert/update di dalam loop
- duplicate IDs di-deduplicate sebelum pemanggilan storage
- fixture 1 item dan banyak item punya **jumlah pemanggilan yang tetap**
- error batch dipropagasikan; **tidak ada commit parsial**

Test output saja **tidak cukup** kalau implementasinya masih O(n) query. N+1 yang tetap
menghasilkan output benar adalah test yang belum lengkap. Detail: `.claude/rules/optimization.md`.

---

## 7. Verifikasi — Bertingkat, BUKAN Semua di Tiap Langkah

> **Full test suite di tiap microstep = laptop pemilik meledak.** Terukur: `flutter test` di
> `apps/pos` saja **6–12 menit** di mesin ini. Menjalankannya untuk perubahan satu baris adalah
> pemborosan. **Tiga tingkat di bawah ini wajib diikuti.**

Tiga tingkat. Yang dijalankan tergantung seberapa jauh pekerjaannya:

| Tingkat | Kapan | Yang dijalankan | Biaya terukur |
| ------- | ----- | --------------- | ------------- |
| **Per microstep** | setiap habis mengubah kode | `dart analyze` + **berkas test yang disentuh saja** | detik |
| **Per fase selesai** | satu fase/tabel di `progress.md` habis | direktori test yang relevan (mis. `flutter test test/branding/`) | < 1 menit |
| **Sekali di akhir** | seluruh task selesai, sebelum melapor | urutan penuh di §7.1 | menit |

### 7.1 Urutan penuh — SEKALI, di akhir task

1. `dart pub get` (root workspace) — resolusi sukses
2. `dart format .` — terformat
3. `dart analyze` — **0 issue**
4. `dart test` di `packages/pn_types` dan `packages/pn_pos`
5. `flutter test` di `apps/pos`
6. `dart run tools/rule_lint/bin/rule_lint.dart` — aturan tidak terduplikasi

**Jangan lompat urutan** di tingkat ini. Kalau langkah 3 gagal, perbaiki dulu.

**Tidak ada satu pun langkah di atas yang butuh perangkat, SDK Android, atau jaringan.** Yang
membedakan tingkatannya hanya **biaya waktu**, bukan jenis verifikasinya.

### 7.2 Build native — hanya bila native/plugin berubah

`flutter build apk` / `flutter build windows` dijalankan **hanya** bila perubahan menyentuh:

- `apps/pos/android/**` atau `apps/pos/windows/**`
- dependency di `pubspec.yaml` (plugin native baru/naik versi)
- resource native (ikon, splash, manifest, `gradle.properties`)

Perubahan **Dart murni tidak memerlukannya.** Mengubah `version:` atau `msix_config:` bukan
perubahan native — tidak ada plugin yang berubah karenanya.

Kalau build native memang perlu, **jalankan sekali**, dan catat hasilnya. Jangan diulang per
microstep.

### 7.3 Yang tetap wajib di tiap langkah, tanpa kecuali

Pelonggaran di atas **tidak** menyentuh tiga hal ini:

- **TDD** — test ditulis dan **dikonfirmasi RED** sebelum implementasi (§0.1). Ini justru makin
  penting: suite penuh tidak lagi berjalan sebagai jaring di tiap langkah.
- **Probe** — test baru dibuktikan bisa merah (§0.3).
- **`dart analyze` bersih** setelah setiap perubahan.

**Jangan hanya mengandalkan `build`.** Build yang lolos tidak membuktikan analyzer bersih,
test lulus, atau aturan tidak terduplikasi.

---

## 8. Known Limitations — Tetap Mock, Jangan Perangkat

Beberapa hal memang tidak bisa di-unit-test. **Itu bukan alasan memakai perangkat di test** —
itu alasan mencatatnya sebagai uji manual.

| Hal | Kenapa tidak bisa di-test | Cara verifikasi |
| --- | ------------------------- | --------------- |
| BLE chunking nyata | butuh printer fisik | uji manual akhir sprint |
| Rantai `onCharacteristicWrite` | butuh printer fisik | uji manual akhir sprint |
| Perilaku OEM Android | beda per vendor dan versi | uji manual di tablet |
| Performa di tablet | bergantung perangkat | uji manual |
| Touch & viewport | butuh layar sentuh | uji manual |

Yang **bisa** dan **harus** di-test: format byte ESC/POS, logika chunking (dengan byte array),
idempotensi antrian, urutan replay, transport seam, parsing respons, perhitungan uang.

---

## 9. Checklist Sebelum Menyatakan Selesai

- [ ] **TDD: test gagal dulu sebelum kode?** (dikonfirmasi, bukan diasumsikan)
- [ ] Bug fix punya test yang **dikonfirmasi RED** terhadap kode yang belum disentuh?
- [ ] Alat pemeriksa punya test yang membuktikan ia **bisa** menemukan? (§0.3)
- [ ] 1 modul = 1 file test?
- [ ] Ada **positif + negatif + edge** (bukan hanya happy path)?
- [ ] Semua dependency eksternal di-mock lewat port?
- [ ] Antrian offline punya test in-memory yang membuktikan idempotensi?
- [ ] Collection flow punya bulk/call-count test?
- [ ] `dart analyze` **0 issue**?
- [ ] `dart test` dan `flutter test` PASS (bukan cuma satu test)?
- [ ] `rule_lint` PASS?
- [ ] Tidak ada test yang di-skip tanpa alasan tertulis?

---

## 10. Sanksi

| Pelanggaran | Konsekuensi |
| ----------- | ----------- |
| Kode tanpa test | **REVERT** |
| Hanya test positif | **REJECT** — minta tambah negatif/edge |
| HTTP/BLE/printer nyata di test | **REJECT** |
| Mock plugin langsung, bukan port | **REJECT** |
| 2 file test per modul | **REJECT** — gabung jadi 1 |
| **Bug fix tanpa RED yang dikonfirmasi lebih dulu** | **REJECT** — termasuk yang disertai revert-trik |
| Antrian offline tanpa test idempotensi | **REJECT** |
| Alat pemeriksa tanpa test yang membuktikan ia bisa gagal | **REJECT** |
