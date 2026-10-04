# AGENTS.md

Project rules for AI coding assistants (Copilot, Claude, Cursor, Zed, dll.) di repo
**`finnesia-pos-flutter`**.

---

## Project Overview

Aplikasi **POS (Kasir) Finnesia** untuk **tablet Android**, ditulis dengan **Flutter**.

- **Client tambahan, bukan pengganti.** Web app **tetap hidup**.
- **Satu build untuk semua tenant.** Branding dibaca runtime; tidak ada varian APK.
- **Thin client.** Logika bisnis ada di backend Go milik platform (repo terpisah). Repo ini
  menyajikan UI, transport, dan integrasi perangkat.
- **Pairing mengunci tenant** sampai di-reset dari dalam app.

Konsekuensi yang harus disadari: karena web tetap hidup, logika POS (keranjang, tender,
shift, ESC/POS) ada di **dua tempat selamanya** — TypeScript dan Dart. Itu **tidak bisa
dihindari**, jadi ia diatur lewat rule 7, bukan dilarang.

Alasan pemilihan Flutter, apa yang di-port, dan apa yang **tidak** di-port:
[`project.md`](.claude/rules/project.md).

---

## Rules

Semua isi aturan ada di `.claude/rules/`. Tabel ini **indeks** — satu baris per aturan,
tanpa menyalin isinya.

| # | Aturan | Detail |
| - | ------ | ------ |
| 0 | Git — read-only diizinkan, menulis dilarang | [git.md](.claude/rules/git.md) |
| 1 | Pattern-first & reusability; duplikasi adalah bug | [patterns.md](.claude/rules/patterns.md) |
| 2 | Baca fungsi utuh; grep hanya untuk menemukan lokasi | [patterns.md](.claude/rules/patterns.md) |
| 3 | Daftar semua pemanggil sebelum mengubah fungsi shared | [patterns.md](.claude/rules/patterns.md) |
| 4 | Pakai library teruji, jangan tulis sendiri (freezed, dio, stdlib) | [patterns.md](.claude/rules/patterns.md) |
| 5 | Struktur monorepo & batas dependency package | [architecture.md](.claude/rules/architecture.md) |
| 6 | Native ports — widget tidak menyentuh plugin langsung | [native-ports.md](.claude/rules/native-ports.md) |
| 7 | Perubahan logika POS wajib mengubah test di kedua repo | [cross-repo.md](.claude/rules/cross-repo.md) |
| 8 | TDD — test dulu, RED sebelum GREEN | [testing.md](.claude/rules/testing.md) |
| 9 | No N+1, tidak ada I/O di dalam loop | [optimization.md](.claude/rules/optimization.md) |
| 10 | Clean code, atomic, penamaan, i18n, copyright | [style.md](.claude/rules/style.md) |
| 11 | Jangan log token; jangan crash di jalur UI | [security.md](.claude/rules/security.md) |
| 12 | Windows dipakai untuk pengembangan; distribusinya belum ada | [windows.md](.claude/rules/windows.md) |
| 13 | Eksplorasi kode wajib lewat CBM; grep hanya pelengkap | [cbm.md](.claude/rules/cbm.md) |

> [!IMPORTANT]
> **Kalau sebuah aturan berubah, hanya file di `.claude/rules/` yang disentuh.**
> `AGENTS.md` dan `.github/copilot-instructions.md` **tidak boleh** ikut berubah — kalau ikut
> berubah, berarti isinya terduplikasi, dan itu bug. Diperiksa otomatis oleh
> `tools/rule_lint` (§Verification).

---

## Peran Agent

Pekerjaan ber-agent di repo ini dibagi per peran. Dokumennya **terpisah dari aturan** di
`.claude/rules/` dan tidak dirangkum di sini — baca sesuai peran yang kamu jalankan:

| Peran | Skill |
| ----- | ----- |
| Developer — mengeksekusi satu lane | [`.claude/skills/developer/SKILL.md`](.claude/skills/developer/SKILL.md) |
| Senior engineer — menyapu + menulis spesifikasi | [`.claude/skills/senior-engineer/SKILL.md`](.claude/skills/senior-engineer/SKILL.md) |
| Project manager (Paseo) — orkestrasi lane | [`.claude/skills/orchestrator-paseo/SKILL.md`](.claude/skills/orchestrator-paseo/SKILL.md) |

Alurnya: `PO → PM → senior → developer`.

---

## Tech Stack

Dart 3.13.3 · Flutter 3.47.4 stable · Dart pub workspaces · Android (arm64, armv7, x86_64
emulator) untuk dirilis · Windows untuk pengembangan harian — folder `apps/pos/windows/` ada dan
**jangan dihapus** · `sqflite` untuk antrian offline · `universal_ble` untuk
printer BLE · TDD unit test, dependency eksternal di-mock lewat port.

**Jangan tulis sendiri apa yang sudah diselesaikan library teruji** — `freezed` untuk kelas
data dan union type, `json_serializable` untuk JSON, `dio` untuk HTTP. Versi yang sudah
diverifikasi di repo ini ada di [`patterns.md`](.claude/rules/patterns.md) §2a.1.

Versi toolchain Android yang di-pin Flutter, dan dua blocker build yang **tidak** terdeteksi
`flutter doctor`: [`project.md`](.claude/rules/project.md) §3.

Eksplorasi kode memakai CBM (codebase-memory MCP). Batasnya yang terukur — metrik loop tidak
berguna untuk Dart, `plan/` dan `.claude/` tidak ter-index — ada di
[`cbm.md`](.claude/rules/cbm.md) §6.

---

## Verification

**Full suite dijalankan sekali di akhir task**, bukan tiap microstep — alasan dan tingkatannya:
[`testing.md`](.claude/rules/testing.md) §7.

```bash
dart pub get
dart format .
dart analyze
dart test
flutter test
dart run tools/rule_lint/bin/rule_lint.dart
```

`./dev check` menjalankan urutan yang sama plus `gen-check` dan `guard`
(`no-flutter-imports`) — lihat `tools/dev/lib/dev.dart`. Pakai itu kalau tidak ingin
menulis enam perintah.

`flutter build apk --debug` / `flutter build windows --debug` hanya bila menyentuh
native/plugin (`testing.md` §7.2).
