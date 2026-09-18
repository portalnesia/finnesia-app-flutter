---
description: Optimization rules — dilarang I/O dalam loop, bulk contract, transaksi, query budget
tools: "*"
alwaysApply: true
paths:
  - "**/*.dart"
  - "**/*.yaml"
  - "**/*.arb"
  - "**/*.kts"
  - "**/*.xml"
---

# Optimization & Query-Efficiency Rules — STRICT

> **N+1 query, atau I/O di dalam loop = implementasi belum selesai.** Optimasi dimulai dari
> bentuk akses data yang benar, bukan micro-optimization.

---

## 0. Inspect Before Optimizing

Sebelum mengubah kode:

1. Baca flow target end-to-end dan minimal 2 sibling implementation.
2. Hitung jumlah query/network call terhadap ukuran input $n$.
3. Cari bulk method yang sudah ada sebelum menambah API baru.
4. Periksa index untuk filter/order baru yang penting.
5. Tulis test yang memverifikasi **call count**/batch behavior, bukan hanya output.

Prompt bukan sumber pattern tunggal. Existing implementation yang N+1 atau menelan error
adalah **bug**, bukan pattern yang boleh disalin.

---

## 1. No I/O Inside Loops

**DILARANG** memanggil SQLite, HTTP, BLE, atau dependency I/O apa pun di dalam `for`, `map`,
recursion, atau callback per-item.

```dart
// DILARANG
for (final item in sale.items) {
  final product = await db.getProduct(item.productId);  // I/O per item
  final stock = await db.getStock(item.productId);      // I/O per item
}

// DILARANG — tetap N calls, bukan batching
await Future.wait(items.map((item) => api.getProduct(item.productId)));
```

`Future.wait` **tidak** mengubah N+1 menjadi batch. Ia hanya membuat N call berjalan
bersamaan — dan di tablet, itu membuat SQLite/BLE kewalahan lebih cepat.

**Pola wajib:**

1. Kumpulkan dan deduplicate semua ID.
2. Fetch sekali dengan bulk method (`WHERE id IN (...)`).
3. Bangun map `id → entity` di memory.
4. Loop hanya melakukan validasi/kalkulasi **pure in-memory**.
5. Persist dengan batch insert/upsert atau set-based SQL.

Jumlah query untuk batch berukuran $n$ harus $O(1)$ per jenis entity, bukan $O(n)$.

### 1.1 Pengecualian sangat terbatas

I/O dalam loop hanya boleh jika **seluruh** kondisi ini terpenuhi:

- Operasi memang membutuhkan urutan/ketergantungan sekuensial dan tidak bisa dinyatakan
  set-based dengan aman.
- Ukuran loop punya hard limit kecil yang divalidasi.
- Alasan, ceiling, dan kapan harus diperbaiki ditulis sebagai komentar.
- Ada test call-count.

> [!NOTE]
> **Catatan BLE:** menulis per-chunk ke characteristic **bukan** N+1 — itu memang
> protokolnya, dan urutannya wajib. Yang dilarang adalah I/O database/HTTP di dalam loop
> pemrosesan data.

---

## 2. Bulk Contract

Saat menerima collection, sediakan operasi bulk:

| Operasi | Contoh |
| ------- | ------ |
| Read | `getProductsByIds`, `getStockByPairs` |
| Write | `insertBatch`, bulk upsert (`ON CONFLICT`), `DELETE WHERE id IN (?)` |

- **Empty input** → no-op tanpa query.
- **Deduplicate** input IDs sebelum query.
- Hasil bulk yang **kehilangan ID** wajib menghasilkan validation/not-found error — jangan
  diam-diam di-skip.
- **DILARANG** menambah method bulk palsu yang implementasinya hanya loop memanggil method
  single-row.

### 2.1 Batas parameter SQLite

SQLite punya batas jumlah variabel per statement. Untuk input besar:

- **Chunking dilakukan di dalam fungsi bulk**, bukan bocor sebagai per-item call ke pemanggil.
- Ukuran chunk tetap, dan hasilnya digabung.

---

## 3. Transaksi Penjualan — Atomic

Penjualan menyentuh beberapa tabel (header, items, stok, antrian). Semuanya harus **atomic**.

- Bungkus dalam **satu transaksi** SQLite.
- Validasi seluruh data **sebelum** transaksi jika tidak butuh lock.
- Di dalam transaksi: bulk load → batch write → update status.
- **DILARANG** insert/update per row di dalam loop.
- Semua error integritas wajib dikembalikan. Dilarang `catch { /* ignore */ }` untuk operasi
  wajib.
- Transaksi **tidak boleh** mencakup HTTP call — simpan lokal dulu, kirim nanti.

---

## 4. Query Shape, Pagination, dan Index

- **Jangan load seluruh tabel** untuk list. Gunakan cursor pagination, `page_size`, dan
  server-side `q`.
- Filter/sort/agregasi dilakukan **di DB**, bukan setelah mengambil satu page ke memory.
- Order column harus whitelist; raw user SQL dilarang.
- Hindari `SELECT *` bila hanya butuh projection.
- Query baru pada kolom yang sering difilter/diurutkan → **cek index** dan tambahkan bila perlu.
- Jangan menambah cache untuk menyembunyikan query buruk; perbaiki query/batching dahulu.

### 4.1 Index untuk antrian offline

Antrian di-query berdasarkan **status** dan **waktu**. Pastikan ada index yang sesuai — tanpa
itu, replay pada antrian besar akan lambat di tablet.

---

## 5. Query Budget dan Tests

Test untuk collection wajib memastikan:

1. Bulk method dipanggil **tepat sekali** per jenis entity.
2. Single-row method **tidak** dipanggil per item.
3. Batch write dipanggil sekali dengan seluruh rows yang diharapkan.
4. Duplicate input ID di-deduplicate.
5. Missing entity menggagalkan seluruh operasi.
6. Error pada bulk read/write dipropagasikan; **tidak ada commit parsial**.
7. Call count **tetap konstan** saat fixture bertambah dari 1 menjadi banyak item.

**Target query budget** untuk penjualan normal: satu bulk read per jenis entity, satu query
per batch insert/upsert, dan jumlah query **tidak bertambah linear** terhadap jumlah item.

---

## 6. Frontend Performance (Tablet)

Tablet kasir jauh lebih lambat dari laptop. Ini bukan opsional.

### 6.1 Yang wajib

- **Lazy build** untuk list panjang — `ListView.builder`, bukan `Column` dengan seluruh anak
  dibangun sekaligus.
- **Direct import**; tidak ada barrel re-export (lihat `.claude/rules/style.md` §8).
- **DILARANG fetch per baris tabel.** Endpoint harus menyediakan relation/summary atau bulk
  detail.
- **Debounce server search**; request basi harus dibatalkan/diabaikan.
- **Reset cursor** saat search/filter/order berubah.
- Jangan duplikasi server state ke local state tanpa kebutuhan editing.

### 6.2 Yang harus hati-hati

- `const` constructor dan `RepaintBoundary` **hanya** saat ada rerender mahal. Jangan
  cargo-cult — keduanya punya biaya sendiri.
- **Mutation finansial tidak optimistic.** Jangan tampilkan penjualan sebagai "berhasil"
  sebelum tersimpan lokal.
- Virtualisasi list panjang bila memang perlu — tapi ukur dulu.

### 6.3 Yang dilarang

- Menyalin state server ke state lokal tanpa alasan.
- **Re-render seluruh keranjang setiap kali satu item berubah.** Ini yang paling mudah
  terjadi di Flutter: satu `setState` di atas, seluruh subtree ikut dibangun ulang.
- Perhitungan berat (format, agregasi) di dalam `build()` tanpa memoization.

---

## 7. Runtime

- Operasi async harus menghormati cancellation.
- Logging terstruktur; **dilarang log per item** untuk batch besar kecuali debug sampling.
- **Never log secrets** — lihat `.claude/rules/security.md` §1.
- Ukur sebelum menambah cache/concurrency. **Concurrency tidak memperbaiki N+1** — ia hanya
  membuat storage kewalahan lebih cepat.

---

## 8. Completion Gate

- [ ] Tidak ada I/O di dalam loop tanpa pengecualian yang didokumentasikan.
- [ ] Collection read memakai bulk fetch + in-memory map.
- [ ] Collection write memakai batch/set-based operation.
- [ ] Query count $O(1)$ terhadap jumlah item untuk tiap jenis entity.
- [ ] Deduplicate ID sebelum query.
- [ ] Error wajib tidak diabaikan.
- [ ] Pagination/search/filter dilakukan server-side.
- [ ] Index relevan diperiksa.
- [ ] Test memverifikasi call count, batching, missing IDs, dan rollback.
- [ ] List panjang memakai builder, bukan seluruh anak dibangun sekaligus.
- [ ] Mutation finansial tidak optimistic.
- [ ] `dart analyze` → `dart test` → `flutter test` lulus.
