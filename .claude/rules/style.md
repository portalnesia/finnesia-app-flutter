---
description: Style rules — satu fungsi satu tanggung jawab, penamaan Dart, komentar, error, i18n, copyright
tools: "*"
alwaysApply: true
paths:
  - "**/*.dart"
  - "**/*.yaml"
  - "**/*.arb"
  - "**/*.kts"
  - "**/*.xml"
---

# Style Rules — Clean Code, Atomic, Naming

> **Repo ini Dart + Flutter. Satu concern per perubahan, dan nama menjelaskan maksud.**

---

## 1. Satu Fungsi = Satu Tanggung Jawab

- Kalau sebuah fungsi butuh kata **"dan"** untuk menjelaskan apa yang dilakukannya, **pecah**.
- Fungsi harus bisa dibaca sekaligus — signature sampai closing brace dalam **satu layar**.
- Kalau tidak muat, itu bukan alasan memperbesar layar; itu alasan memecah fungsi.

### 1.1 Hindari flag boolean yang mengubah perilaku

```dart
// DILARANG — fungsi ini melakukan dua hal
Future<void> sync(List<Sale> sales, bool force) { ... }

// BENAR
Future<void> syncIncremental(List<Sale> sales) { ... }
Future<void> syncFull(List<Sale> sales) { ... }
```

Flag boolean adalah tanda paling jelas bahwa ada dua fungsi yang menyamar jadi satu.

### 1.2 Kedalaman bersarang

- Maksimal **3 level** indentasi di dalam satu fungsi. Lebih dari itu, extract atau pakai
  early return.
- **Early return lebih baik** daripada `if` bersarang.

```dart
// DILARANG
void handle(Sale? sale) {
  if (sale != null) {
    if (sale.items.isNotEmpty) {
      if (sale.status == SaleStatus.pending) {
        // ... logika sebenarnya di level 3
      }
    }
  }
}

// BENAR
void handle(Sale? sale) {
  if (sale == null) return;
  if (sale.items.isEmpty) return;
  if (sale.status != SaleStatus.pending) return;
  // ... logika sebenarnya di level 0
}
```

---

## 2. Perubahan Atomik

**Satu concern per perubahan.** Jangan campur:

- refactor dengan fitur baru
- perbaikan bug dengan perubahan gaya
- penambahan fitur dengan perbaikan test yang tidak terkait

**Kenapa.** Kalau ada yang salah, tidak jelas mana penyebabnya. Review juga jadi jauh lebih
sulit karena tidak bisa menilai satu concern sekaligus.

### 2.1 Refactor dan fitur adalah dua perubahan

Kalau saat mengerjakan fitur Anda menemukan kode yang perlu dirapikan:

1. Rapikan dulu sebagai perubahan terpisah (dan verifikasi).
2. Baru tambahkan fitur di atasnya.

---

## 3. Penamaan

- **Nama menjelaskan maksud, bukan tipe.** `remainingStock`, bukan `stockNum`.
- **Boolean diawali kata kerja bantu**: `isReady`, `hasPendingSales`, `canPrint` — bukan
  `ready`, `pending`, `printable`.
- **Fungsi diawali kata kerja**: `printReceipt`, `syncSales`, `resolveTransport` — bukan
  `receipt`, `sales`, `transport`.
- **Hindari singkatan** kecuali yang sudah lazim di domain (`qty`, `sku`, `pos`).
- **Hindari nama yang menyesatkan.** Kalau fungsi bernama `getUser` tapi juga menulis ke cache,
  namanya salah atau fungsinya yang salah.
- **Konsisten.** Kalau satu tempat memakai `outlet`, jangan pakai `store` di tempat lain untuk
  konsep yang sama.

### 3.1 Tabel Konvensi — Dart

| Konteks | Gaya | Contoh |
| ------- | ---- | ------ |
| Variabel / fungsi / parameter | `lowerCamelCase` | `productName`, `getTotalPrice()` |
| Kelas / enum / typedef / extension | `UpperCamelCase` | `ProductItem`, `PrinterPort` |
| Konstanta | `lowerCamelCase` | `maxChunkBytes` |
| Nama file | `snake_case.dart` | `print_receipt.dart` |
| Nama file test | `snake_case_test.dart` | `offline_queue_test.dart` |
| Field JSON dari API | `snake_case` di map, `lowerCamelCase` di Dart | `created_at` → `createdAt` |
| Private member | `_leadingUnderscore` | `_storageKey` |

> [!IMPORTANT]
> **Konstanta di Dart memakai `lowerCamelCase`**, bukan `UPPER_SNAKE_CASE` — itu konvensi
> `dart format`/linter, dan berbeda dari TypeScript/Rust. Jangan bawa kebiasaan repo lain.

### 3.2 Satu konsep, satu nama — lintas bahasa

Karena logika POS di-port dari TypeScript, penamaan Dart **mengikuti nama di sumbernya**
meski berbeda konvensi huruf:

| TypeScript | Dart |
| ---------- | ---- |
| `remainingStock` | `remainingStock` |
| `POSSale` | `POSSale` |
| `formatShiftReportEscPos` | `formatShiftReportEscPos` |

**Alasannya:** memudahkan pencocokan saat membandingkan dua implementasi. Kalau nama di Dart
dikarang ulang, setiap perbandingan oracle jadi kerja arkeologi.

---

## 4. Komentar

**Komentar menjelaskan _mengapa_, bukan _apa_.**

Kode sudah menjelaskan apa yang dilakukan. Yang tidak terlihat dari kode adalah:

- **Mengapa** keputusan ini diambil
- **Mode kegagalan** apa yang dicegah
- **Batasan** yang tidak terlihat (perangkat tertentu, urutan protokol, batas API)
- **Trade-off** yang disadari

```dart
// DILARANG — mengulang kode
// Tambah 1 ke counter
counter += 1;

// BENAR — menjelaskan alasan
// Harus 1-based: printer thermal menolak nomor urut 0 untuk struk.
// Sudah diverifikasi di web app, jangan diubah ke 0-based.
counter += 1;
```

### 4.1 Yang dilarang

- Kode mati (commented-out code) — hapus saja, git yang menyimpan riwayat.
- `TODO` tanpa konteks. Kalau perlu TODO, tulis: siapa, kenapa, kapan harus selesai.
- `print()` debugging yang tertinggal.
- Komentar yang sudah tidak sesuai kode — **lebih buruk daripada tidak ada komentar**.
- Komentar yang menerjemahkan kode ke bahasa Indonesia baris per baris.

### 4.2 Komentar hasil port

Saat meng-port dari TypeScript, **bawa komentarnya**. Komentar di sumber memuat alasan desain
dan mode kegagalan yang tidak terlihat dari kodenya.

Kalau komentar itu menyebut hal yang tidak berlaku di Flutter (mis. `window.localStorage`),
**tulis ulang alasannya**, jangan dihapus. Alasan itu biasanya tetap berlaku untuk port-nya.

---

## 5. Error Handling

- **Jangan telan error.** `catch (e) {}` tanpa alasan eksplisit adalah bug.
- Kalau sengaja mengabaikan error, **tulis alasannya**:

```dart
try {
  await attachMeta(data);
} catch (_) {
  // Meta hanya untuk pagination; kegagalannya tidak boleh menggagalkan
  // penjualan. Data utama tetap valid.
}
```

- **Pesan error harus actionable untuk kasir**, bukan pesan internal:

```dart
// DILARANG
throw Exception('GATT error 133');

// BENAR
throw PrinterException('Printer tidak merespons. Pastikan printer menyala dan dalam jangkauan.');
```

- **Dart tidak punya checked exception** — jadi tipe error tidak bisa dipaksa compiler.
  Karena itu error yang bisa dipulihkan **wajib** jadi tipe eksplisit, bukan `Exception`
  generik, dan pemanggilnya wajib menangani.

---

## 6. Copyright Header — WAJIB

Setiap awal file kode Dart:

```dart
/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */
```

**Pengecualian:** file yang di-generate (`*.g.dart`, `*.freezed.dart`, `flutter create`
output) — jangan disunting sama sekali.

---

## 7. Multi-Language (i18n) — WAJIB

- **SEMUA** teks antarmuka lewat fungsi terjemahan: label, placeholder, tombol, judul dialog,
  badge, alert, pesan error, toast.
- **DILARANG keras hardcode string bahasa** di widget.
- Nomor, tanggal, dan mata uang mengikuti **locale aktif** — jangan format manual.
- Teks yang berasal dari server dipakai apa adanya.
- Tambahkan translation key baru ke kamus bahasa kalau belum tersedia.

> [!NOTE]
> **Di POS, teks struk juga i18n.** Label struk datang **sudah diterjemahkan** dari pemanggil
> (`formatShiftReportEscPos` menerima `labels`), dan itulah yang membuat formatter tetap
> fungsi murni tanpa language context. **Pertahankan pola itu** — formatter tidak boleh
> mengambil teks sendiri.

### 7.1 Widget Reusable Wajib Prop-Driven

- Terima teks/label lewat parameter (`labels`, `title`, `description`).
- **DILARANG** widget reusable membaca terjemahan sendiri dari context global.
- Widget yang menerima teks dari luar bisa dipakai ulang; yang mengambil sendiri tidak.

---

## 8. No Barrel Re-exports

- Import langsung dari file spesifik.
- Tidak ada `index.dart` yang me-re-export.

```dart
// DILARANG
import 'package:pn_pos/pn_pos.dart';

// BENAR
import 'package:pn_pos/src/tender.dart';
```

**Kenapa:** barrel export menyembunyikan dependency sebenarnya, memperlambat build, dan
membuat circular import lebih mudah terjadi.

> [!NOTE]
> **Pengecualian:** file entry point package (`lib/pn_pos.dart`) yang di-generate `dart create`
> boleh tetap ada sebagai titik masuk publik. Tapi ia tidak boleh tumbuh jadi re-export
> seluruh isi `lib/src/`.

---

## 9. Bahasa Kode

- **Kode dalam bahasa Inggris** — nama variabel, fungsi, tipe, komentar teknis.
- **Teks UI dalam bahasa Indonesia** lewat i18n — tidak hardcode.
- **Dokumen perencanaan dan aturan dalam bahasa Indonesia** — `plan/`, `AGENTS.md`,
  `.claude/rules/`.

---

## 10. Gaya Kode Dart

- **`dart format`** — jangan debat format, biarkan tool.
- **`dart analyze` — 0 issue.** Tidak ada `// ignore:` tanpa alasan tertulis di baris yang sama.
- **Hindari `dynamic`.** Pakai `Object?` lalu persempit tipenya.
- **`const` di mana pun bisa.** Bukan soal performa saja — `const` membuat nilai tidak bisa
  berubah diam-diam.
- **`final` untuk lokal yang tidak di-reassign.**
- **Null-safety dimanfaatkan, bukan dilawan.** Hindari `!` kecuali invariant-nya jelas dan
  ditulis sebagai komentar.
- **`late` hanya kalau benar-benar perlu**, dan alasannya jelas.
- **Prefer `switch` expression** untuk pemetaan nilai, bukan rantai `if/else`.
- **Jangan pakai `print()`** di kode produksi.

---

## 11. Commit Messages

Conventional Commits:

```
feat(pos): tambah layar pembayaran tunai
fix(printer): tangani koneksi putus di tengah chunk
chore: perbarui konfigurasi analyzer
refactor(api): tarik transport ke port terpisah
```

- Scope = nama fitur atau package bila relevan.
- **Perubahan atomik** (§2): satu concern per commit — jangan campur refactor dengan fitur.
