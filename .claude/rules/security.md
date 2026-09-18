---
description: Security rules — jangan log token, jangan crash di jalur UI, least privilege, data finansial
tools: "*"
alwaysApply: true
paths:
  - "**/*.dart"
  - "**/*.yaml"
  - "**/*.arb"
  - "**/*.kts"
  - "**/*.xml"
---

# Security Rules — Secrets, Error Boundaries, Least Privilege

---

## 1. Never Log Secrets

**DILARANG** menulis `session_token`, `refresh_token`, atau isi header `Authorization` ke
log, console, atau crash report — dalam kondisi apa pun, **termasuk saat debugging**.

Yang **boleh** ada di log diagnostik: endpoint, status code, durasi, id perangkat.
Yang **tidak boleh**: token, isi header auth, kredensial pairing, isi payload login.

```dart
// DILARANG
debugPrint('request headers: ${request.headers}');

// BENAR
debugPrint('POST /api/v1/pos/sales/checkout → 201 in 240ms');
```

> [!IMPORTANT]
> **Ini bukan formalitas.** Log di Android bisa dibaca tool lain di perangkat, ikut ke crash
> report, dan tertinggal di `logcat` setelah sesi selesai. Token yang bocor lewat log tidak
> bisa ditarik kembali.

### 1.1 Token Hanya ke Host yang Terkunci

Host terkunci saat pairing (`.claude/rules/project.md` §1). Token **hanya** dikirim ke host
itu. Tidak ada redirect yang boleh membawa token ke host lain — kalau sebuah request
di-redirect, token-nya **tidak** ikut.

---

## 2. Jangan Panic di Jalur yang Bisa Dipicu UI

**Panic di Android = app tertutup di tangan kasir.**

Padanannya di Dart:

- **DILARANG** membiarkan exception yang tidak tertangani naik ke jalur UI. Di Flutter, itu
  jadi red screen — di tablet kasir, itu berarti transaksi berhenti.
- **DILARANG** memakai `!` (null assertion) pada nilai yang bisa `null` di jalur uang.
  Kalau invariant-nya benar-benar terjamin, **tulis alasannya sebagai komentar**.
- Semua operasi yang bisa gagal mengembalikan tipe error yang bisa ditangani pemanggil, bukan
  `Exception` generik (lihat `.claude/rules/style.md` §5).

```dart
// DILARANG — crash di tangan kasir
final sale = response.data as POSSale;

// BENAR — pemanggil memutuskan apa yang ditampilkan
final sale = switch (response) {
  Success(:final data) => data,
  Failure(:final error) => throw CheckoutException(error.userMessage),
};
```

### 2.1 Pesan Error Harus Actionable untuk Kasir

Bukan pesan internal, bukan stack trace.

```dart
// DILARANG
throw Exception('FormatException: Unexpected character at line 1');

// BENAR
throw CheckoutException('Koneksi ke server terputus. Penjualan disimpan dan akan dikirim ulang.');
```

---

## 3. Blocking I/O Tidak di Main Thread

- Operasi BLE, file, dan jaringan **DILARANG** memblokir main thread.
- Di Dart, I/O yang benar sudah async — yang harus dijaga adalah **tidak** memakai operasi
  sinkron yang berat di jalur render (`File.readAsBytesSync()` di dalam `build()`, dsb).
- Callback BLE harus **pendek**; jangan melakukan I/O di dalamnya.

---

## 4. Least Privilege — Izin Android

- Izin Android dideklarasikan di `AndroidManifest.xml`, dan harus **sesempit mungkin**.
- **Jangan menambahkan izin yang belum benar-benar dipakai.** Izin yang tidak dipakai tetap
  terlihat user saat instalasi dan saat review Play Store.
- Scope URL HTTP sesempit mungkin — host berasal dari **pairing**, bukan dari input bebas.
- Kalau sebuah izin dibutuhkan, tulis di komentar **untuk apa** — supaya tidak ada yang
  menghapusnya karena terlihat tidak terpakai, dan tidak ada yang menambahkannya karena
  terlihat "aman".

---

## 5. Data Finansial Tidak Boleh Hilang

Ini bukan aturan kripto, tapi konsekuensi keamanan yang paling mahal di repo ini:

- Antrian penjualan disimpan **sebelum** dikirim, bukan sesudah (`.claude/rules/project.md` §5).
- Reset Perangkat **DILARANG** bila antrian belum kosong.
- Operasi antrian **idempoten** — replay tidak boleh menggandakan penjualan.

Uang sudah diterima saat transaksi masuk antrian. Kehilangan data di sini bukan bug
tampilan; itu kerugian nyata bagi merchant.

---

## 6. Checklist

- [ ] Tidak ada token/header auth di log, `debugPrint`, atau pesan error?
- [ ] Token hanya dikirim ke host hasil pairing?
- [ ] Tidak ada `!` di jalur uang tanpa alasan tertulis?
- [ ] Exception di jalur UI tertangani, tidak jadi red screen?
- [ ] Pesan error bisa ditindaklanjuti kasir?
- [ ] Izin Android yang ditambahkan benar-benar dipakai, dan ada komentar alasannya?
- [ ] Antrian disimpan sebelum dikirim?
