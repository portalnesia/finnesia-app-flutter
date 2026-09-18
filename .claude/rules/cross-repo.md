---
description: Cross-repo rules — logika POS hidup di TypeScript dan Dart, test adalah kontraknya
tools: "*"
alwaysApply: true
paths:
  - "**/*.dart"
  - "**/*.yaml"
  - "**/*.arb"
  - "**/*.kts"
  - "**/*.xml"
---

# Cross-Repo Rules — Anti-Divergensi

> **Perubahan perilaku pada logika POS WAJIB mengubah test di **kedua** repo — sisi
> TypeScript dan sisi Dart — dalam perubahan yang sama. Satu sisi saja = bug,
> bukan "nanti disusul".**

Aturan ini ada karena web app **tetap hidup** — logika POS yang sama berjalan di dua sisi,
TypeScript dan Dart, dan keduanya harus sepakat.

> **Istilah di berkas ini:** **repo sumber** = repo yang memuat implementasi TypeScript dan
> test oraclenya. Path di bawah ditulis relatif terhadap root repo itu.

---

## 1. Kenapa Ini Aturan, Bukan Saran

Web tetap hidup, jadi matematika keranjang, tender, shift, dan ESC/POS ada di **dua tempat
selamanya** — TypeScript dan Dart. Satu salinan diperbaiki, satu tidak, dan bug-nya hanya muncul
di salah satu jalur. Yang lebih buruk, keduanya "jalan" — jadi tidak ada yang sadar ada yang salah.

**Test adalah kontraknya.** Perilaku benar didefinisikan secara eksekutabel di dua bahasa.
Selama kedua test suite memverifikasi perilaku yang sama, duplikasi jadi aman.

---

## 2. Aturan Operasional

### 2.1 Perubahan perilaku

Setiap perubahan yang mengubah **perilaku** (bukan sekadar refactor internal) pada:

`pos-calculations` · `pos-cart` · `pos-cart-gate` · `pos-tender` · `pos-product-stock` ·
`pos-shift` · `escpos` · `pos-shift-report-escpos`

...wajib menyertakan perubahan test di **kedua** repo, di perubahan yang sama.

### 2.2 Perubahan tipe

Tipe yang dipakai bersama (`Product`, `POS*`, `CartLine`, `ShiftSummaryResponse`) berasal dari
`packages/types/src/` di repo sumber. Perubahan di sana berdampak ke **dua** repo.
Sebelum mengubah, daftar seluruh pemakainya — lihat `.claude/rules/patterns.md` §4.

### 2.3 Perubahan UI

**Tidak terikat aturan ini.** UI tidak punya logika uang, dan layout memang sengaja berbeda.
Menyeragamkan UI bukan tujuan.

---

## 3. Angka Oracle — Turunkan, Jangan Ingat

Jangan pernah memakai "jumlah test seluruh repo" sebagai target. Oracle adalah **jumlah
kasus pada modul yang di-port**, dan itu dihitung dari berkasnya sendiri.

Angka yang benar, dihitung ulang dari disk **repo sumber**, bukan dari ingatan. Path di
perintah dan tabel di bawah relatif terhadap root repo sumber:

```bash
cd <repo-sumber> && cat > /tmp/count.awk <<'AWK'
# Counts EXECUTED cases: every it(...) block, plus each ROW of an it.each([...]).
BEGIN { inEach = 0; rows = 0; blocks = 0 }
{
  if (inEach) {
    if ($0 ~ /^[[:space:]]*\]\)/) { inEach = 0; blocks += rows; rows = 0; next }
    if ($0 ~ /^[[:space:]]*\[/) rows++
    next
  }
  if ($0 ~ /it\.each\(\[/) { inEach = 1; rows = 0; next }
  if ($0 ~ /^[[:space:]]*it\(/) blocks++
}
END { print blocks }
AWK
for f in packages/shared/src/pos/*.test.ts \
  apps/web/src/lib/escpos.test.ts \
  apps/web/src/lib/pos-escpos-format.test.ts \
  apps/web/src/lib/pos-print-category.test.ts \
  apps/web/src/lib/pos-receipt.test.ts \
  packages/shared/src/utils/datetime.test.ts \
  packages/shared/src/utils/format.test.ts; do
  [ -f "$f" ] && echo "$(awk -f /tmp/count.awk "$f")  $f"
done
```

| Berkas | Kasus |
| ------ | ----- |
| `apps/web/src/lib/pos-escpos-format.test.ts` | 38 |
| `packages/shared/src/pos/pos-tender.test.ts` | 26 |
| `packages/shared/src/pos/pos-cart.test.ts` | 25 |
| `packages/shared/src/pos/pos-hold.test.ts` | 16 |
| `packages/shared/src/pos/pos-shift.test.ts` | 16 |
| `packages/shared/src/pos/pos-cart-gate.test.ts` | 15 |
| `packages/shared/src/utils/datetime.test.ts` | 15 |
| `apps/web/src/lib/escpos.test.ts` | 12 |
| `apps/web/src/lib/pos-print-category.test.ts` | 9 |
| `packages/shared/src/pos/pos-shift-resume.test.ts` | 6 — **tidak di-port** (`.claude/rules/project.md` §2.3) |
| `apps/web/src/lib/pos-receipt.test.ts` | 6 |
| `packages/shared/src/utils/format.test.ts` | 6 |
| `packages/shared/src/pos/pos-product-stock.test.ts` | 5 |
| `packages/shared/src/pos/pos-calculations.test.ts` | 4 |
| **Total** | **199** |

**Oracle yang harus di-port = 199 − 6 = 193 kasus.**

> [!IMPORTANT]
> **Hitung kasus, bukan baris.** Perintah penghitung yang salah — `grep -cE '^\s*it\(|^\s*it\.each\('`
> — mencocokkan `it.each(` sebagai **satu baris** dan melewatkan setiap baris tabel di dalamnya.
> Satu berkas dengan 21 blok `it()` plus satu `it.each([...])` berisi 4 baris dihitung 22,
> padahal sebenarnya **25**. Perintah `awk` di atas menghitung setiap baris tabel sebagai satu
> kasus.
>
> **Ikutkan seluruh dependensi modul, bukan hanya modul yang sudah terdaftar.** Sebuah formatter
> bisa mengimpor helper dari modul lain:
>
> ```ts
> import { posReceiptLines } from './pos-receipt'
> import type { PrintableLine } from './pos-print-category'
> ```
>
> Keduanya murni (tidak menyentuh `window`/`document`/React, dan test-nya juga tidak), jadi
> keduanya **wajib ikut di-port** — 15 kasus tambahan (9 + 6) yang tidak muncul kalau daftar
> modul diambil dari judul dokumen saja.
>
> **Angka di dokumen bukan oracle.** Turunkan ulang dari perintah setiap kali daftar modul
> berubah. Angka yang salah membuat pekerjaan dianggap selesai padahal ada modul yang terlewat,
> dan itu tidak terlihat dari suite yang hijau.

---

## 4. Membaca Oracle dengan Benar

Port test itu **wajib**, tapi mem-port test bukan tujuan akhirnya. Yang dijaga adalah
**perilakunya**.

- **Test boleh berubah bentuk.** `describe`/`it` jadi `group`/`test`, `expect` jadi
  `expect(...)` — itu mekanis. Yang tidak boleh berubah: input dan ekspektasinya.
- **Kalau sebuah test tidak bisa di-port, itu temuan.** Artinya test itu bergantung pada
  sesuatu yang tidak ada di Flutter. Catat alasannya; jangan hapus diam-diam, dan jangan
  ubah ekspektasinya supaya lulus.
- **Test yang lulus karena ekspektasinya dilonggarkan adalah test yang gagal.** Kalau oracle
  TypeScript mengharapkan `0` dan Dart menghasilkan `1`, yang salah adalah Dart.
- **Kalau oracle-nya sendiri tampak salah**, jangan perbaiki hanya di Dart. Perbaiki di
  sumbernya (TypeScript), lalu port perbaikannya. Lihat §2.1.

### 4.1 Verifikasi Diferensial — Lebih Kuat dari Oracle

Oracle memverifikasi **ekspektasi yang sudah ditulis seseorang**. Ia tidak bisa menangkap
perilaku yang tidak pernah di-assert — dan justru di situ bug port bersembunyi, karena
port yang salah tetap lulus setiap test yang tidak menyentuh bagian itu.

**Untuk modul yang outputnya byte atau nilai murni** (ESC/POS, formatter, kalkulasi),
jalankan **kedua implementasi atas input yang sama** dan bandingkan outputnya:

1. Generator kasus di sisi Dart, generator yang sama di sisi TypeScript — nama kasus
   identik, sehingga bisa dipasangkan satu per satu.
2. Bandingkan output, bukan sekadar "keduanya jalan".
3. **Validasi pembandingnya bisa gagal** sebelum mempercayai hasilnya (`testing.md` §0.3).

Sudah dipakai untuk `escpos` (46 kasus, semua byte-identik) dan `pos-escpos-format`
(50 kasus, semua byte-identik). Perintah dan alatnya: `plan/scaffold/provenance.md`
§`pos-escpos-format`.

**Dua jebakan yang menghasilkan false positive, dan keduanya bukan soal kode yang di-port.**
**Samakan dulu waktu dan zona kedua sisi; baru bandingkan.**

| Jebakan | Kenapa terjadi | Penyelesaian |
| ------- | -------------- | ------------ |
| Zona waktu host berbeda | Dart dan Node membaca zona host lewat mekanisme berbeda. Di Windows, Dart membaca zona OS (`Etc/UTC`) sementara Node me-resolve ke `Asia/Singapore` — selisih 8 jam di setiap baris tanggal. **`TZ=Asia/Jakarta` tidak berpengaruh pada Dart di Windows** | Jalankan Node dengan `TZ=UTC`, atau samakan zona eksplisit di kedua sisi |
| Jam dinding ikut terukur | Fungsi yang memanggil `new Date()` sendiri (mis. tiket kategori) berbeda antar-proses yang mulai beda menit | Bekukan clock di kedua sisi — jangan bandingkan dua proses yang berjalan di waktu berbeda |

**Keduanya muncul sebagai "mismatch" yang terlihat seperti bug port.** Periksa waktu dan
zona lebih dulu sebelum menuduh kodenya: selisih 8 jam dan selisih satu menit bukan bug.

---

## 5. Provenance — Salinan Manual Wajib Tercatat

Tidak ada submodule dan tidak ada mekanisme sync otomatis. Kode yang berasal dari repo lain
masuk lewat **salin manual yang disengaja**, dan setiap salinan wajib bisa ditelusuri.

Untuk setiap modul yang di-port, catat di `plan/`:

| Yang dicatat | Contoh |
| ------------ | ------ |
| Berkas sumber (relatif ke root repo sumber) | `packages/shared/src/pos/pos-tender.ts` |
| Berkas tujuan | `packages/pn_pos/lib/src/tender.dart` |
| Commit/versi sumber | hash atau tanggal pembacaan |
| Perbedaan yang disengaja | "buang `window.localStorage`, ganti `HoldOrderStore`" |

**Tidak ada perbedaan yang tidak tercatat.** Salinan yang menyimpang tanpa catatan adalah
duplikasi yang sudah mulai membusuk — dan tidak ada yang tahu.

### 5.1 Print stack — di mana sumbernya

`escpos.ts` dan `pos-escpos-format.ts` hidup di **`apps/web/src/lib/`** di repo sumber,
**bukan** di `packages/shared/src/pos/`. Itu tempatnya sekarang, dan itu yang dipakai web app.

| Lokasi | Isi | Test |
| ------ | --- | ---- |
| `apps/web/src/lib/escpos.ts` | command builder (init, align, bold, font size, feed, cut) | 12 |
| `apps/web/src/lib/pos-escpos-format.ts` | `formatReceiptEscPos`, `formatCategoryTicketEscPos`, `formatShiftReportEscPos` | 38 |

`pos-escpos-format.ts` mengimpor `escpos` secara relatif (`./escpos`), dan web app sudah
memakainya di produksi (`pos-print-controls.tsx`, `pos-shift-report-ticket.tsx`).
**Tidak ada yang perlu dipindahkan** — port langsung dari `apps/web/src/lib/`.

> [!NOTE]
> `apps/web/src/lib/` adalah lokasi yang sah. Jangan mengarang alasan untuk memindahkan
> berkas itu ke `packages/shared/src/pos/`; pemindahan bukan prasyarat port apa pun, dan
> `packages/shared/src/pos/` tidak punya `index` yang perlu diperbarui.
