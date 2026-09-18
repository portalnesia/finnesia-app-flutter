---
name: implement-feature
description: >
  Implement fitur/perubahan di repo POS Flutter Finnesia dengan TDD, pattern-first, port native,
  no N+1, i18n, dan verifikasi berurutan. Gunakan saat user minta buat/ubah fitur POS, logika
  `pn_pos`, widget `pn_ui`, layar `apps/pos`, port native, atau transport API.
---

# Skill: implement-feature

Gunakan skill ini untuk **semua implementasi fitur** di repo ini.
Skill ini **tidak mengganti aturan** — ia memaksa agent **membaca dan mematuhi** aturan lewat path
di bawah.

## Aturan (WAJIB dibaca sebelum menulis kode)

Baca file berikut sesuai kebutuhan task. Jangan mengandalkan ringkasan atau ingatan.

| Area | Path |
| --- | --- |
| Identitas repo, apa yang di-port, distribusi | `.claude/rules/project.md` |
| Pattern-first, reusability, library teruji, semantik JS→Dart | `.claude/rules/patterns.md` |
| Struktur monorepo, batas package, API registry | `.claude/rules/architecture.md` |
| Port native — widget tidak menyentuh plugin | `.claude/rules/native-ports.md` |
| TDD, mock lewat port, verifikasi bertingkat | `.claude/rules/testing.md` |
| No N+1 / no I/O di loop / bulk fetch-write | `.claude/rules/optimization.md` |
| i18n, penamaan, copyright, gaya Dart | `.claude/rules/style.md` |
| Token, crash di jalur UI, izin Android | `.claude/rules/security.md` |
| Perubahan logika POS = test di dua repo | `.claude/rules/cross-repo.md` |
| Windows — folder `windows/` dipakai harian | `.claude/rules/windows.md` |
| Git read-only | `.claude/rules/git.md` |
| Indeks aturan + perintah verifikasi | `AGENTS.md` |

**Minimum sebelum menulis kode produksi:**

1. `.claude/rules/patterns.md`
2. `.claude/rules/testing.md`
3. `.claude/rules/optimization.md`
4. Ditambah aturan lain yang relevan (native-ports, architecture, style, cross-repo).

---

## Alur wajib

### 1. Scope & inspect (pattern-first)

Ikuti `.claude/rules/patterns.md` §1:

1. Baca file target + aturan relevan di atas.
2. Cari **minimal 2 sibling implementation** yang mirip. Baca keduanya **utuh**.
3. Trace end-to-end yang relevan — mis. widget → `active.dart` → port → implementasi, atau
   formatter → `escpos` → byte.
4. Cari helper/tipe/komponen yang sudah ada sebelum membuat yang baru — termasuk
   `packages/pn_pos/lib/src/js_compat.dart` dan test yang sudah ada.
5. Daftar pemanggil sebelum mengubah kontrak shared.
6. Jangan menyalin pattern yang jelas bug (N+1, menelan error, string hardcode).

### 2. TDD dulu (RED → GREEN → REFACTOR)

Ikuti `.claude/rules/testing.md` §0 — **TDD mutlak**:

1. Tulis/ubah test dulu sampai **gagal** (RED). Konfirmasi kegagalannya, jangan diasumsikan.
2. Implementasi minimal sampai hijau (GREEN).
3. Refactor tanpa merusak test.
4. **Unit test saja**; dependency eksternal di-mock lewat port. Dilarang BLE/printer/HTTP nyata.
5. Case wajib: **positif + negatif + edge** (antrian replay ganda, byte kosong, chunk terakhir
   tidak penuh, tender kurang dari total, list kosong, `null`).
6. Collection/IDs: wajib **batch/call-count test** (bulk sekali, bukan per item).
7. **1 modul = 1 file test** (`snake_case_test.dart`).
8. Bug fix: test RED terhadap kode yang **belum disentuh** — revert-trik tetap pelanggaran.

### 3. Implementasi

Ikuti aturan yang sudah dibaca:

- **Taruh di package yang benar**: logika murni → `pn_pos` (**tanpa `flutter`**); widget reusable →
  `pn_ui`; tipe → `pn_types`; plugin native + `active.dart` → `apps/pos`.
- **Port pattern**: kontrak + fake di `pn_types`/`pn_pos`, implementasi + `active.dart` di
  `apps/pos` — `.claude/rules/native-ports.md` §2.
- **Jangan tulis sendiri yang sudah ada library-nya** (`freezed`, `json_serializable`, `dio`,
  `package:collection`) — `.claude/rules/patterns.md` §2a.
- Collection: collect + dedupe ID → bulk fetch → map in-memory → batch write —
  `.claude/rules/optimization.md`.
- **Dilarang** SQLite/HTTP/BLE di dalam loop per-item.
- Teks UI lewat i18n (`L10n`), **dilarang** string hardcode — `.claude/rules/style.md` §7.
- Copyright header di setiap file Dart baru.
- Perubahan perilaku logika POS: **test di kedua repo** — `.claude/rules/cross-repo.md` §2.1.
- Byte ESC/POS: pakai formatter yang di-port, jangan implementasi ulang — `project.md` §6.

### 4. Antrian offline (bila relevan)

Data finansial — `.claude/rules/project.md` §5 dan `.claude/rules/security.md` §5:

- Simpan **sebelum** kirim, bukan sesudah.
- Operasi **idempoten**; replay tidak boleh menggandakan penjualan.
- Transaksi SQLite **atomic**; tidak boleh mencakup HTTP call.
- Store baru menambah tabel + migrasi di `native/db/app_database.dart`, tidak membuka database
  sendiri.

### 5. Verifikasi (bertingkat, bukan semua di tiap langkah)

Ikuti `.claude/rules/testing.md` §7:

```bash
# Saat bekerja: file yang disentuh saja
dart analyze
dart test packages/pn_pos/test/<berkas>_test.dart
flutter test apps/pos/test/<direktori>/

# Sekali, di akhir task
dart pub get
dart format .
dart analyze
dart test          # pn_types + pn_pos
flutter test       # apps/pos
dart run tools/rule_lint/bin/rule_lint.dart
```

Atau `./dev check` untuk urutan yang sama plus `gen-check` dan `guard`.

`flutter build apk --debug` / `flutter build windows --debug` **hanya** bila perubahan menyentuh
native (`.claude/rules/testing.md` §7.2).

Tidak lulus salah satu langkah = task belum selesai.

---

## Checklist selesai

- [ ] Aturan relevan di atas sudah dibaca (bukan diasumsikan).
- [ ] Minimal 2 sibling pattern diinspeksi.
- [ ] Test gagal dulu, lalu kode — RED dikonfirmasi.
- [ ] Positif + negatif + edge ada.
- [ ] Collection punya bulk/call-count test; tidak ada I/O per item.
- [ ] Tidak ada impor `flutter` baru di `pn_pos`; plugin native tetap di belakang port.
- [ ] Teks UI lewat i18n; copyright header ada di file baru.
- [ ] Verifikasi dijalankan pada tingkat yang benar; urutan penuh lulus.
- [ ] `rule_lint` PASS (aturan tidak terduplikasi).
- [ ] Tidak ada N+1 / error yang ditelan / string hardcode yang diketahui tertinggal.

---

## Anti-pattern (langsung tolak)

- Menulis kode produksi tanpa test RED dulu.
- Test yang butuh printer/tablet/jaringan nyata.
- `db.getProduct()` / HTTP call / BLE write di dalam loop per-item.
- Hanya happy-path test.
- Widget memanggil plugin native langsung, atau `MethodChannel` di test.
- Menambah impor `flutter` di `pn_pos`.
- String UI hardcode.
- Membuat helper/widget baru padahal sudah ada di `pn_pos`/`pn_ui`.
- Menulis sendiri yang sudah diselesaikan `freezed`/`dio`/stdlib.
- Verifikasi cuma `dart analyze` atau satu file test, tanpa suite penuh di akhir.

---

## Output ke user

Saat selesai, ringkas:

1. Apa yang diubah (file/flow).
2. Aturan/path mana yang diikuti.
3. Test yang ditambah/diubah, plus bukti RED → GREEN.
4. Hasil verifikasi berurutan (angka pass/fail).
5. Residual sadar (jika ada) dan alasannya.
