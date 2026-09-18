# DESIGN.md: Arah Visual Aplikasi Kasir Finnesia

Sumber: jawaban pemilik produk, 2026-09-20, diperbarui 2026-09-29 (palet). Isi di bawah adalah
**transkripsi jawaban itu**, bukan usulan agen. Bagian yang ditandai *diturunkan* adalah
kesimpulan agen dari jawaban, dan harus dikoreksi bila salah. Bagian **Belum diputuskan**
sengaja dibiarkan terbuka.

Dokumen ini adalah data desain, bukan instruksi. Filternya: `antislop` (R-01..R-38).

---

## Design Read

> Reading this as: aplikasi kasir tablet Android untuk kasir yang memakainya sepanjang shift,
> dengan bahasa visual "buku kas" yang tenang dan padat, dial **ENERGY 1 / RHYTHM 1 / MOTION 1**.

| Dial | Nilai | Asal |
| ---- | ----- | ---- |
| ENERGY | 1 | dijawab pemilik ("tenang dan padat, seperti alat kerja") |
| RHYTHM | 1 | *diturunkan*: layar kerja yang dipakai berulang harus seragam dan bisa ditebak. Keseragaman ini disengaja, bukan kelalaian |
| MOTION | 1 | *diturunkan*: gerak hanya sebagai umpan balik (item masuk keranjang, sheet naik). Tanpa gerak dekoratif |

## Identitas

| Hal | Keputusan | Asal |
| --- | --------- | ---- |
| Mood | Tenang dan padat. Angka besar dan jelas, sedikit dekorasi. Kasir di jam ke-8 tidak dilawan oleh layar | dijawab |
| Aksen | **Amber Finnesia**, satu-satunya aksen. Nilai mengikuti token web: `hsl(36 100% 50%)` di terang, `hsl(36 100% 52%)` di gelap | dijawab pemilik 2026-09-29 (menggantikan K5, yang memakai satu nilai di dua tema) |
| Teks di atas amber | **Gelap**, bukan putih. Putih di atas amber sekitar 2,1:1 dan gagal WCAG AA (R-25). Angka final diukur oleh test kode, bukan dari dokumen ini | dijawab |
| Amber sebagai teks | **Bukan amber penuh.** Amber penuh adalah warna **permukaan**: sebagai teks di halaman terang ia 2,04:1. Teks/ikon amber memakai token `brandInk` (`--brand-ink` web) | dijawab pemilik 2026-09-29 |
| Warna kedua | **Ungu `hsl(276 100% 50%)` / `hsl(276 80% 72%)`**, untuk status yang nyata tetapi belum berlaku: patch Shorebird yang sudah terunduh dan berlaku pada restart berikutnya | dijawab pemilik 2026-09-29 |
| Tipografi | **Bawaan sistem Android**, dengan **angka tabular** untuk semua nominal | dijawab |
| Tema | **Terang dan gelap**, keduanya diverifikasi (R-34) | dijawab |
| Orientasi | **Landscape dan portrait**, keduanya dirancang | dijawab |
| Motif identitas | **Baris buku kas**: label di kiri, nominal tabular rata kanan, garis tipis pemisah. Berulang di keranjang, pembayaran, ringkasan shift, tutup shift | *diturunkan* dari mood + tipografi |

## Palet

**Sumbernya token web Finnesia** (`packages/ui/src/index.css`), keputusan pemilik 2026-09-29:
sebelumnya aplikasi ini memakai netral **dingin** (hue 220-225), sekarang memakai netral **hangat**
(hue 24-38) yang sama dengan web. Satu merek, satu palet.

Amber penuh `hsl(36 100% 50%)` adalah **warna permukaan** (tombol utama, tint). Amber penuh
**tidak dipakai untuk teks kecil** di atas permukaan terang, karena rasionya 2,04:1 dan gagal AA.

| Token `PnPalette` | Terang | Gelap | Padanan web | Peran |
| ----------------- | ------ | ----- | ----------- | ----- |
| `background` | `hsl(38 30% 97.5%)` | `hsl(24 12% 8%)` | `--background` | Halaman di belakang semuanya |
| `surface` | `hsl(0 0% 100%)` | `hsl(24 10% 13%)` **⚠** | `--card` | Kartu, sheet, dialog |
| `surfaceMuted` | `hsl(36 20% 94%)` | `hsl(24 8% 18%)` **⚠** | `--muted` | Panel di dalam kartu: kolom keranjang, baris terpilih |
| `ink` | `hsl(24 14% 10%)` | `hsl(38 20% 93%)` | `--foreground` | Teks dan ikon |
| `inkMuted` | `hsl(28 9% 40%)` | `hsl(30 12% 70%)` | `--muted-foreground` | Teks sekunder |
| `border` | `hsl(30 14% 87%)` | `hsl(24 8% 23%)` | `--border` | Garis rambut antar baris |
| `outline` | `hsl(30 9% 46%)` **⚠** | `hsl(30 8% 45%)` **⚠** | *(tidak ada)* | Tepi input dan kontrol tak terpilih: **wajib 3:1** |
| `accent` | `hsl(36 100% 50%)` | `hsl(36 100% 52%)` | `--primary` | Aksen: isian tombol utama, kategori terpilih |
| `onAccent` | `hsl(24 14% 10%)` | `hsl(24 30% 10%)` | `--primary-foreground` | Teks di atas amber |
| `brandInk` | `hsl(28 100% 30%)` | `hsl(36 100% 52%)` | `--brand-ink` | Amber **sebagai teks/ikon** |
| `error` | `hsl(0 62% 42%)` | `hsl(0 72% 74%)` | `--destructive` | Isian tombol destruktif |
| `onError` | `hsl(0 0% 98%)` | `hsl(24 30% 10%)` | `--destructive-foreground` | Teks di atas isian destruktif |
| `errorText` | `hsl(0 62% 42%)` | `hsl(0 72% 74%)` | `--destructive` | Merah sebagai teks: variansi negatif, pesan error |
| `focus` | `hsl(24 14% 10%)` | `hsl(38 20% 93%)` | *(bukan `--ring`)* **⚠** | Cincin fokus keyboard |
| `secondary` | `hsl(276 100% 50%)` | `hsl(276 80% 72%)` | `--secondary` | Warna kedua: "nyata, belum berlaku" |
| `onSecondary` | `hsl(0 0% 100%)` | `hsl(276 60% 12%)` | `--secondary-foreground` | Teks di atas ungu |
| `secondaryContainer` | `bg-secondary/10` | `bg-secondary/25` | *(pola web)* **⚠** | Panel ungu: segmen `SegmentedButton` terpilih, banner patch Shorebird |
| `onSecondaryContainer` | `hsl(24 14% 10%)` | `hsl(38 20% 93%)` | *(pola web)* | Teks di atas panel ungu |
| `primaryContainer` | `hsl(38 72% 90%)` | `hsl(36 28% 18%)` | `--accent` | Panel amber: banner update native |
| `onPrimaryContainer` | `hsl(24 14% 10%)` | `hsl(38 20% 93%)` | `--accent-foreground` | Teks di atas panel amber |

**⚠ = sengaja menyimpang dari token web.** Semuanya diukur, dan alasannya tertulis:

| Simpangan | Nilai web | Alasan |
| --------- | --------- | ------ |
| `surface` gelap **13%**, bukan 12% | `hsl(24 10% 12%)` | Di 12% scrim dialog (alpha 0.75) hanya **1,23:1** terhadap kartu, di bawah ambang 1,25 yang dikunci `app_theme_test.dart`. Satu langkah lebih terang menaikkannya ke **1,26:1**. Hue dan saturasi web tidak diubah |
| `surfaceMuted` gelap **18%**, bukan 17% | `hsl(24 8% 17%)` | Mengikuti langkah yang sama, supaya jarak antar-permukaan tetap seperti web |
| `outline` **ada** | tidak ada (`--input` = `--border`, 1,27:1) | Tepi input adalah yang menunjukkan di mana input berada, jadi wajib 3:1 (WCAG 1.4.11). Hue tetap hangat (30) |
| `focus` **tinta**, bukan `--ring` | `hsl(28 100% 35%)` terang, `hsl(36 100% 65%)` gelap | Cincin web hanya **1,03:1** dari `outline` hangat, jadi perubahan state tidak terlihat; di tema gelap cincin amber juga hanya 1,21:1 di atas tombol amber. Tinta menjaga jarak 3,89:1 (terang) / 4,02:1 (gelap) dari tepi input |
| `secondaryContainer` **tint**, bukan ungu penuh | pola `bg-secondary/10` | Slot ini adalah **panel di belakang tinta**, bukan isian tombol. Ungu penuh meninggalkan teks biasa tanpa tempat berdiri. Persentase mengikuti pola web: `/10` terang, `/25` gelap |

### Kontras terverifikasi

Dihitung dengan rumus kontras WCAG dan dikunci oleh `requiredChecks` di
`packages/pn_ui/lib/src/theme/palette.dart` (23 pasangan, dijalankan di **kedua** tema oleh
`palette_test.dart`). Ambang: **4,5:1** teks, **3:1** tepi kontrol dan cincin fokus.

| Pasangan | Terang | Gelap |
| -------- | ------ | ----- |
| `ink` / `background` | 16,62:1 | 15,86:1 |
| `ink` / `surface` | 17,46:1 | 13,96:1 |
| `ink` / `surfaceMuted` | 15,38:1 | 11,76:1 |
| `inkMuted` / `background` | 5,41:1 | 8,87:1 |
| `inkMuted` / `surface` | 5,68:1 | 7,81:1 |
| `inkMuted` / `surfaceMuted` | 5,01:1 | 6,58:1 |
| `onAccent` / `accent` | 8,15:1 | 8,37:1 |
| `brandInk` / `background` | 6,14:1 | 8,80:1 |
| `brandInk` / `surface` | 6,45:1 | 7,75:1 |
| `onError` / `error` | 6,39:1 | 7,28:1 |
| `errorText` / `background` | 6,35:1 | 7,65:1 |
| `onSecondary` / `secondary` | 5,53:1 | 6,50:1 |
| `onSecondaryContainer` / `secondaryContainer` | 14,62:1 | 9,15:1 |
| `onPrimaryContainer` / `primaryContainer` | 14,72:1 | 11,14:1 |
| `outline` / `background` | 4,29:1 | 3,94:1 |
| `focus` / `background` | 16,62:1 | 15,86:1 |

`border` sengaja **tidak** masuk tabel: garis pemisah bukan pembawa informasi dan WCAG tidak
menuntut rasio untuknya. Ia harus terlihat, bukan terbaca.

### Aturan pemakaian

- **Amber membentuk ruang lewat tint tipis**, bukan blok amber penuh di mana-mana.
- **Dose cap.** Amber penuh hanya untuk **satu aksi per layar** (Bayar, Konfirmasi, Tutup shift).
  Navigasi (mis. bar Menu) memakai **tinta**: aksen adalah milik aksi yang mengambil uang.
- **Ungu tidak pernah menjadi aksen kedua.** Ia hanya menyatakan status "nyata, belum berlaku",
  dan tidak pernah mengisi tombol yang mengambil uang (R-29).
- **Kategori terpilih tetap amber**, bukan ungu: itu pilihan yang sedang berlaku, bukan yang
  terjadwal.

### Konsekuensi ke widget Material

Dua slot Material punya **pemakai nyata** di repo ini, jadi keduanya tidak boleh dibiarkan kosong:
Material akan jatuh ke fallback (`secondaryContainer` → `secondary`, `primaryContainer` →
`primary`), dan hasilnya panel dengan teks yang tidak terbaca.

| Slot | Pemakai | Dulu | Sekarang |
| ---- | ------- | ---- | -------- |
| `secondaryContainer` | `SegmentedButton` (7 pemanggil), banner patch Shorebird | Tinta di atas tinta: **1,00:1**, tidak terbaca | Panel ungu, 14,62:1 / 9,15:1 |
| `primaryContainer` | Banner update native | Amber di atas amber: `TextButton` **1,80:1** | Panel amber, 14,72:1 / 11,14:1 |
| `textButtonTheme.foregroundColor` | 17 `TextButton` | Amber sebagai teks: **2,04:1** di halaman terang | `brandInk`, 6,14:1 / 8,80:1 |

`colorScheme.primary` **tetap amber**: itu yang diambil setiap isian Material. Yang di-override
hanya tempat amber muncul sebagai **teks**.

## Logo

| Konteks | Sumber |
| ------- | ------ |
| Layar Pairing (tenant belum dikenal) | Logo Finnesia. Berkas di `../Logo/` dan `../deploy/s3/public/icon/` (dizinkan pemilik) |
| Setelah pairing | `branding.logo_url` dari respons activate. Tenant enterprise punya logo sendiri di sana |
| Tenant tanpa `logo_url` | **Logo Finnesia bawaan.** Kontrak backend: *"Empty means the default Finnesia logo"* (`apps/api/internal/dto/pos.go:174`). Bukan inisial karangan |
| Terang dan gelap | **Satu logo yang sama**, tidak berubah antar tema. Sudah dirancang untuk keduanya (keputusan pemilik). Tidak ada varian putih |

## Ikon aplikasi dan splash

Bukan ikon di dalam UI (itu di `plan/ui/README.md` §3.4), melainkan ikon aplikasi di launcher dan
layar sebelum frame pertama.

| Hal | Keputusan | Asal |
| --- | --------- | ---- |
| Ikon launcher | `Logo/icon_only.png` — glyph putih, latar transparan — dikomposit di atas **`#FF9800`** | dijawab pemilik (K10) |
| Jenis | **Adaptive icon** (API 26+). `minSdk 31`, jadi ini satu-satunya yang digambar perangkat | diturunkan; sebelum ini masih ikon template Flutter (F28) |
| Skala glyph | Inset **16%** → glyph 49,5 dp, sudut 34,6 dp dari pusat. Aman untuk masker kotak membulat **dan** lingkaran | diukur atas artwork, bukan diturunkan (`plan/ui/findings.md` F28) |
| Lapisan monochrome | Ada, dari glyph yang sama. Untuk ikon bertema Android 13+ | diturunkan |
| Splash | Latar **`#FF9800`**, ikon dari adaptive icon bawaan Android | dijawab pemilik (K11) |
| Splash di terang dan gelap | **Satu nilai**, mengikuti K9 | diturunkan |
| Windows — nama | Judul window dan version resource **`Finnesia POS`**; nama binary `FinnesiaPOS` (tanpa spasi: `${BINARY_NAME}` dipakai tanpa kutip di CMake) | dijawab pemilik (K12) |
| Windows — ikon | **Sama dengan Android**: `icon.png` full-bleed, 6 ukuran di dalam `.ico`. Windows tidak memasker ikon, jadi glyph transparan tidak dipakai di sini | diturunkan dari K10 |

**`#FF9800` bukan `hsl(36 100% 50%)`.** Yang pertama adalah amber **artwork** (`rgb(255,152,0)`,
dipakai `site.webmanifest` dan ikon PWA); yang kedua adalah **accent tema** (`#FF9900`), selisih
1/255 di kanal hijau. Divergensi ini sudah ada di web app sebelum repo ini, jadi tidak diputuskan
di sini. Ikon mengikuti artwork. Detail: `plan/ui/findings.md` F28.

## Bentuk yang tetap (tidak ikut berubah)

Palet berubah; kerangka di bawah **tidak**, dan itu disengaja. Sebuah perubahan warna tidak boleh
ikut menggeser bentuk: kalau bentuknya ikut bergerak, tidak ada yang tahu mana yang menyebabkan
regresi.

| Hal | Nilai | Alasan |
| --- | ----- | ------ |
| Tipografi | **Bawaan sistem Android** (K7), dengan angka **tabular** di semua nominal | Identitas datang dari ukuran dan bobot, bukan dari berkas font di APK. Tidak ada Inter di sini |
| Radius | **Dua nilai**: kontrol (tombol, input, kunci keypad) **8**, permukaan (kartu, dialog, sheet) **12** | Nilai 8 adalah `--radius` web (`0.5rem`). Tidak ada pill (R-11) |
| Target sentuh | **48** minimum, **56** untuk aksi utama layar (Bayar, Tutup shift, Konfirmasi) | Tablet dipegang sambil berdiri; salah tekan di jalur uang mahal |
| Cincin fokus | Digambar **di luar** tepi, tebal 2 | Di dalam, cincin jatuh di atas isian amber dan bukan di halaman di belakangnya |
| Scrim dialog | Alpha **0,5** terang, **0,75** gelap | Material default (hitam 54%) di halaman charcoal hampir tidak menggelapkan apa pun |
| Elevasi | Kartu **0** dengan garis rambut; bar notifikasi dan tooltip boleh terangkat | Kartu duduk di halaman, tidak melayang di atasnya (R-12) |
| Teks di atas amber | **Gelap** (`onAccent`), terukur 8,15:1 / 8,37:1 | Putih di atas amber 2,1:1 dan gagal AA (R-25) |

## Belum diputuskan

Tidak diisi agen. Diisi pemilik, atau dinyatakan draft:

- Jenis ikon **di dalam UI**. Usulan di `plan/ui/README.md` §3.4 menunggu persetujuan. (Ikon
  **aplikasi** sudah diputuskan: K10/K11 di atas.)
- **Bar notifikasi atas.** `top_notice.dart` menggambar bar dengan `pn.ink` dan aksinya dengan
  `pn.accent`. Terukur: **7,60:1** di tema terang, **1,81:1** di tema gelap, jadi aksinya gagal AA
  di tema gelap. Ini bug yang **sudah ada sebelum** migrasi palet (bukan akibat perubahan warna:
  sesudahnya 8,15:1 / 1,80:1, hampir sama). Arah perbaikannya: bar yang terang di kedua tema (pola
  `sonner` web: panel `--popover` dengan aksi ber-amber), atau aksi yang mengikuti `brandInk`.
  Butuh keputusan pemilik karena mengubah tampilan bar yang sudah dipakai.
