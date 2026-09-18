---
description: CBM rules — eksplorasi kode wajib lewat knowledge graph, grep hanya pelengkap
tools: "*"
alwaysApply: true
paths:
  - "**/*.dart"
  - "**/*.yaml"
  - "**/*.arb"
  - "**/*.kts"
  - "**/*.xml"
---

# CBM — Codebase Memory MCP — STRICT

> **Eksplorasi kode WAJIB lewat CBM.** `grep`, `rg`, `find`, dan `glob` bukan cara utama mencari
> simbol, pemanggil, atau alur. **`read` dari disk WAJIB sebelum setiap `edit`/`write`** — untuk
> mengambil `oldText`.

---

## 0. Wajib Pakai CBM

### 0.0 Pembagian tool

| Fase | Pakai | Bukan |
| --- | --- | --- |
| Cari simbol, pemanggil, arsitektur | `search_graph`, `trace_path`, `query_graph`, `get_architecture`, `search_code` | `grep`, `rg`, `find`, `glob` |
| Baca source simbol | `get_code_snippet`; `read` utuh bila menyentuh kontrak shared | `read` sebagai pengganti `get_code_snippet` |
| Sebelum `edit`/`write` | **`read` dari disk** | `source` atau nomor baris dari graph |

`grep` **sah** hanya untuk:

- berkas non-kode (`pubspec.yaml`, `l10n.yaml`, `AndroidManifest.xml`, CMake, workflow)
- `plan/**` dan `.claude/**` — keduanya **tidak ter-index** (§6)
- mengklaim "tidak ada X" (§3.1 `patterns.md`)
- baris di dalam rentang `parse_partial` (§0.3)
- berkas yang tidak ter-index (§0.3)

### 0.1 Deteksi — sebelum bekerja

1. `list_projects` → ambil nama project untuk root repo ini. Nilainya diturunkan dari path root,
   jadi **jangan hardcode**: checkout di path lain menghasilkan nama lain.
2. `index_status` → `status` harus `ready`.
3. Belum ter-index → `index_repository(repo_path=".", mode="fast")` **sekali**.

### 0.2 CBM tidak tersedia atau terkendala

| Keadaan | Tindakan |
| ------- | -------- |
| Tool tidak ada di agent ini (MCP tidak terpasang di mesin/agent) | **Lanjut** dengan `grep` + `read`, dan **sebutkan di kesimpulan** bahwa penelusuran dilakukan manual — kekuatan klaimnya lebih rendah |
| Tool ada, tapi `index_status` bukan `ready`, `index_repository` gagal, error 2× berturut-turut, atau hasil kosong padahal simbol jelas ada | **STOP.** Lapor keadaan + error-nya, tunggu keputusan |

**Dilarang:** menyebut CBM aktif lalu mengerjakan eksplorasi dengan `grep`; diam lalu lanjut dengan
`grep` saat tool ada tapi index rusak.

### 0.3 Coverage gate

`check_index_coverage(paths=[...])` untuk setiap berkas yang akan disentuh.

| `status` | Boleh dikutip? |
| -------- | -------------- |
| `no_recorded_issue` | Ya |
| `partial` | Ya untuk sisanya; **baca source** untuk baris di dalam `ranges` |
| `skipped` / `not_indexed` | Tidak — pakai `grep` atau `read` |

**`freshness` bukan gerbang.** `metadata_changed` hampir selalu menyertai dan tidak memblokir;
hanya `status` yang memblokir.

---

## 1. Tool → Kegunaan

| Ingin | Tool |
| ----- | ---- |
| Simbol, nama diketahui | `search_graph(query=...)` |
| Simbol, cari berdasarkan makna | `search_graph(semantic_query=[...])` |
| Simbol, pola nama persis | `search_graph(name_pattern=".*Printer.*")` |
| Teks di dalam berkas | `search_code(pattern=...)` |
| Berkas berdasarkan nama | `search_code(file_pattern="*printer*.dart", pattern=...)` |
| Source satu simbol | `get_code_snippet(qualified_name=...)` |
| Pemanggil langsung | `trace_path(direction="inbound", depth=1)` |
| Blast radius | `detect_changes(scope="impact", since=<ref>)` |
| Dependensi keluar | `trace_path(direction="outbound")` |
| Orientasi arsitektur | `get_architecture(aspects=["packages"])` |
| Pola multi-hop | `query_graph` (Cypher) |

---

## 2. Mode yang Benar

- **`semantic_query`** — array 2–3 kata kunci **Inggris**. Percayai urutan hasil, bukan skornya.
  Istilah Indonesia tidak dikenali — pakai `query=`.
- **`search_code`** — `pattern` = **isi** berkas; nama berkas masuk ke `file_pattern`. `pattern`
  berisi nama berkas → 0 match, dan itu **bukan** bukti berkas tidak ada.
- **`detect_changes`** — pakai `scope="impact"`, bukan `"files"`. Ia membandingkan **commit**,
  bukan working tree; untuk working tree pakai `git status` / `git diff`.
- **`get_code_snippet`** — pakai `qualified_name` penuh.
- **`trace_path`** — `depth=1` = pemanggil langsung. `callers_total` / `callees_total` adalah
  angka penuh. Test disembunyikan secara default; `include_tests=true` untuk melihatnya.

---

## 3. Urutan Kerja

1. Deteksi (§0.1). Tidak siap → ikuti §0.2.
2. `check_index_coverage` untuk berkas target (§0.3).
3. Cari lewat CBM (§1). **`grep` dan `read` bukan alat pencarian di langkah ini.**
4. `get_code_snippet`; `read` utuh bila fungsinya menyentuh kontrak shared.
5. `trace_path(inbound, depth=1)` untuk seluruh pemanggil — ini yang diminta `patterns.md` §4.
6. Sebelum `edit`/`write`: `read` dari disk, ambil `oldText` persis (§5).

---

## 4. Hierarki Bukti

Mencari = CBM. **Membuktikan = source.**

1. Source yang dibaca langsung dari disk
2. Hasil eksekusi (`dart analyze`, `dart test`, `flutter test`)
3. `grep` atas working tree
4. CBM graph

Graph **mengarahkan**; ia bukan dasar tunggal untuk klaim perilaku. Graph dan disk berbeda →
**disk yang benar, selalu.**

---

## 5. Menulis

Nomor baris dari graph adalah posisi **saat index dibuat**, bukan posisi berkas sekarang. Berkas
yang bergeser di tengah sesi membuat `oldText` cocok di **lokasi yang salah**, tanpa peringatan.

**Sebelum setiap `edit`:**

1. `read` berkas target dari disk.
2. Salin `oldText` persis dari hasil `read`, termasuk indentasi.
3. Jangan pakai nomor baris sebagai patokan.
4. `oldText` sekecil mungkin tapi unik.
5. Setelah `edit`, `read` ulang area yang diubah.
6. Berkas yang disentuh agent lain → `read` ulang tepat sebelum edit.

**CBM menemukan, `read` memastikan, `edit` menulis.**

---

## 6. Yang TIDAK Bisa Dikerjakan CBM di Repo Ini

Empat batas ini terukur pada index yang aktif. Membacanya lebih murah daripada menemukannya
sendiri satu per satu.

### 6.1 Metrik loop tidak berguna untuk Dart

`loop_count`, `transitive_loop_depth`, `linear_scan_in_loop`, dan `alloc_in_loop` mengembalikan
**nol fungsi Dart** di repo ini. Yang muncul hanya `main` di `packages/pn_pos/tool/compare_cases.py`
dan `wWinMain` di `apps/pos/windows/`.

**Konsekuensi:** audit N+1 **tidak boleh** mengandalkan metrik ini. Ikuti `.claude/rules/optimization.md`
§0 — baca fungsinya dari signature sampai closing brace, hitung jumlah call terhadap ukuran input
$n$, lalu kunci dengan test call-count. `query_graph` tetap berguna untuk pola relasi lain, bukan
untuk menemukan I/O dalam loop.

### 6.2 `plan/` dan `.claude/` tidak ter-index

Keduanya ada di daftar `not_indexed` dengan alasan `gitignore` dan skip-list. Aturan yang menyitir
`plan/printer/README.md`, `plan/scaffold/*`, atau berkas `.claude/**` **wajib dibaca langsung** —
CBM tidak akan pernah mengembalikannya.

### 6.3 Berkas generated ikut ter-index

`*.freezed.dart` dan `*.g.dart` ada di graph dan muncul di hasil pencarian. Saring dengan
`file_path` sebelum menyimpulkan; kelas di berkas generated **tidak boleh** disunting tangan
(`style.md` §6).

### 6.4 `windows/` ephemeral ikut ter-index

`apps/pos/windows/flutter/ephemeral/**` adalah output `flutter build`, bukan kode repo. Ia muncul
di hasil CBM dan di laporan `parse_partial`. Jangan dikutip sebagai perilaku aplikasi.

### 6.5 `parse_partial` hampir selalu satu direktif

Dari 27 berkas yang ditandai `parse_partial`: 7 berkas C++ di `windows/`, dan **19 dari 20**
sisanya menunjuk baris yang isinya `library;` — direktif Dart tanpa konstruksi apa pun, jadi tidak
ada yang hilang dari graph di situ. Satu pengecualian nyata:
`packages/pn_types/test/api/registry_test.dart:373-375`.

Tetap `read` baris yang ditandai sebelum mengutipnya; §0.3 melarang mengutip dari baris `partial`.

---

## 7. Gate

- [ ] `list_projects` + `index_status` dijalankan; nama project diambil, bukan ditebak.
- [ ] `check_index_coverage` diperiksa untuk setiap berkas yang disentuh.
- [ ] Tidak ada klaim yang bersumber dari `skipped`, `not_indexed`, atau baris `partial`.
- [ ] Eksplorasi memakai CBM — bukan `grep` yang disebut "sudah dicek CBM".
- [ ] Terkendala → §0.2 diikuti; `grep` hanya setelah dinyatakan eksplisit.
- [ ] Pemanggil diperoleh lewat `trace_path` inbound `depth=1`, bukan ditebak.
- [ ] `oldText` diambil dari `read` disk, bukan dari graph.
- [ ] Klaim "tidak ada X" diverifikasi dengan pembacaan utuh, bukan hasil nol.
