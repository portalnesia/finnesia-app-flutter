# Copilot Instructions

Repo: **`finnesia-pos-flutter`** — aplikasi **POS (Kasir) Finnesia** untuk tablet Android,
ditulis dengan **Flutter**. Client tambahan, bukan pengganti web app.

- **Satu build untuk semua tenant** — branding runtime, tidak ada varian APK
- **Thin client** — logika bisnis di backend Go milik platform (repo terpisah)
- **Pairing mengunci tenant** — sampai di-reset dari dalam app
- **Printer thermal via BLE/GATT**, bukan SPP
- **Web tetap hidup** — logika POS ada di dua tempat selamanya, dan itu diatur, bukan dilarang

---

## Aturan

**Jangan cari aturan di file ini.** Isi aturan ada di `.claude/rules/*.md`, dan indeksnya ada
di `AGENTS.md`.

1. Baca **`AGENTS.md`** — tabel indeks, satu baris per aturan.
2. Buka file rule yang relevan di **`.claude/rules/`** untuk detailnya.

File ini sengaja **tidak** merangkum isi rule. Ringkasan adalah salinan kedua, dan salinan
kedua akan menyimpang — pernah terjadi: satu aturan hidup di tiga tempat dan salah satunya
sudah tidak sinkron. `tools/rule_lint` memeriksanya otomatis.

---

## Ringkas

| Hal | Di mana |
| --- | ------- |
| Indeks semua aturan | [`AGENTS.md`](../AGENTS.md) |
| Isi aturan | [`.claude/rules/`](../.claude/rules/) |
| Perintah verifikasi | [`AGENTS.md` §Verification](../AGENTS.md) |
| Panduan peran agent | [`.claude/skills/`](../.claude/skills/) |
| Rencana scaffold | [`plan/scaffold/`](../plan/scaffold/) |

Verifikasi sebelum menyatakan selesai:

```bash
dart pub get && dart analyze && dart test && flutter test
dart run tools/rule_lint/bin/rule_lint.dart
```
