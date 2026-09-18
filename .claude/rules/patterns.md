---
description: Pattern rules — pattern-first, reusability, library teruji, baca fungsi utuh, telusuri pemanggil
tools: "*"
alwaysApply: true
paths:
  - "**/*.dart"
  - "**/*.yaml"
  - "**/*.arb"
  - "**/*.kts"
  - "**/*.xml"
---

# Patterns & Reusability Rules — STRICT

> **Repo ini reusable. Duplikasi adalah bug, bukan sekadar bau kode.**

---

## 1. Pattern-First Is Mandatory

Sebelum menulis kode apa pun:

1. **Cari minimal 2 sibling implementation** yang paling mirip dengan yang akan dibuat.
   Baca keduanya **utuh**.
2. **Trace flow end-to-end** yang relevan — dari widget sampai port native.
3. **Periksa sumber konteks lain**, bukan hanya prompt:
   - `packages/pn_pos/lib/` — logika POS yang sudah di-port
   - `packages/pn_types/lib/` — tipe yang sudah ada
   - test yang sudah ada — kontrak yang sudah disepakati
   - `plan/**/*.md` — keputusan yang sudah diambil beserta alasannya
   - repo sumber (`packages/shared/src/pos/`) — perilaku yang sudah terbukti
   - **repo lain yang relevan** — kode yang dibutuhkan bisa ada di `apps/web/src/lib/`, bukan
     hanya di `packages/`. Lihat `.claude/rules/cross-repo.md` §5.1.

**Dilarang** membuat pattern, abstraction, atau komponen baru sebelum memastikan yang
reusable belum tersedia.

### 1.1 Saat mem-port dari JavaScript — periksa semantiknya, jangan asumsikan

Logika POS di repo ini adalah port dari TypeScript, dan **JavaScript punya semantik yang
Dart tidak punya**. Port yang secara sintaks benar tapi mengabaikannya akan lulus setiap
test yang tidak menyentuh kasus itu, dan gagal hanya di jalur uang.

**Sebelum mem-port ekspresi apa pun di bawah ini, jalankan ekspresi sumbernya di Node
terhadap `''`, `0`, `null`, `undefined`, `NaN`, dan `false`:**

| Semantik JS | Padanan Dart yang salah | Akibat nyata di repo ini |
| ----------- | ----------------------- | ------------------------ |
| `a \|\| b` (string) — `''` **falsy** | `??` — hanya `null` yang absen | Nama produk kosong mencetak **baris kosong** di struk pelanggan dan tiket dapur |
| `if (str)` — `''` falsy, `'   '` **truthy** | `!= null` | Outlet/cashier bernama kosong mencetak baris hampa |
| `a && b` (string) — `''` falsy | `!= null` | `''` dianggap id pemilik nyata → **till terkunci** |
| `undefined` vs `null` dibedakan | hanya ada satu nilai kosong | Badge stok bundle yang tidak bisa dicapai |
| `Math.round(-0.5)` = `-0`, `(-1.5)` = `-1` | `.round()` — menjauhi nol | Selisih kas yang dilaporkan beda 1 rupiah dari web app |
| `Math.max(0, NaN)` = `NaN` | ternary `v > 0 ? v : 0` = `0` | NaN disembunyikan sebagai `0` |
| `Math.round(NaN)` = `NaN` | `.round()` **melempar** | **Crash di tengah penjualan** |
| `String(2.0)` = `'2'` | `double.toString()` = `'2.0'` | `2.0 x Rp 10.000` di struk, web app mencetak `2 x` |
| `Array.sort` **stabil** (ES2019+) | `List.sort` **tidak stabil** | Urutan antrian hold acak untuk timestamp yang sama |

**Bukan `Math.min`/`Math.max` tulis tangan.** Pakai `dart:math` `max`/`min`, yang sudah
diverifikasi cocok dengan JS — termasuk `NaN`.

**Dan jangan tulis ulang apa yang sudah ada padanannya:** `dart:math` `max`/`min`,
`firstOrNull` (ada di `dart:core`, bukan `package:collection`), `Uint8List` untuk byte.
Helper tulis tangan untuk hal-hal ini adalah duplikasi stdlib (§2a) **dan** sumber
divergensi halus.

Semua helper yang tetap dibutuhkan ada di **`packages/pn_pos/lib/src/js_compat.dart`**.
Tambahkan ke sana, jangan buat salinan baru.

---

## 2. Reusability — WAJIB, Bukan Preferensi

### 2.1 Dilarang membuat fungsi duplikat

**DILARANG** membuat 2 fungsi yang:

- isinya identik, atau
- berbeda hanya pada satu nilai/parameter yang bisa dipass, atau
- berbeda hanya pada tipe yang bisa di-generic.

Kalau menemukan diri Anda menyalin-tempel lalu mengubah sedikit, **berhenti**. Itu sinyal ada
abstraksi yang belum ditemukan.

### 2.2 Kalau dua tempat butuh perilaku sama

Pilih salah satu secara sadar:

| Pilihan | Kapan dipakai |
| ------- | ------------- |
| **Extract** ke satu fungsi | perilakunya benar-benar sama, tidak ada variasi |
| **Model hubungan eksplisit** | ada hierarki atau kontrak yang perlu dinyatakan |
| **Pisahkan** | mirip tapi tidak sama — jangan dipaksa satu fungsi |

**Model hubungan eksplisit** berarti:

- **Dart**: `abstract interface class` + implementasi. Kalau dua kelas butuh perilaku sama,
  definisikan kontraknya, bukan dua fungsi terpisah.
- **Base class**: hanya kalau memang ada hierarki "adalah" — bukan sekadar "punya kemiripan".
- **Mixin**: hanya untuk perilaku yang benar-benar orthogonal, bukan untuk menghindari
  inheritance yang tidak nyaman.

### 2.3 Jangan pakai flag boolean untuk menggabungkan dua perilaku

```dart
// DILARANG
Uint8List printReceipt(ReceiptData data, bool isLabel) { ... }

// BENAR
Uint8List printReceipt(ReceiptData data) { ... }
Uint8List printLabel(LabelData data) { ... }
// lalu tarik bagian yang benar-benar sama ke helper di bawahnya
```

Flag boolean yang mengubah perilaku adalah tanda fungsi melakukan dua hal. Pecah.

### 2.4 Duplikasi yang dibiarkan menyimpang

Ini bukan soal estetika. Di repo yang menangani uang:

- Satu salinan diperbaiki, satu tidak.
- Bug-nya muncul hanya di salah satu jalur.
- Yang lebih buruk: keduanya "jalan", jadi tidak ada yang sadar ada yang salah.

**Setiap duplikasi adalah bug yang menunggu waktu.**

> [!IMPORTANT]
> **Di repo ini duplikasi punya dua bentuk, dan keduanya nyata:**
>
> 1. **Di dalam repo ini** — dua fungsi Dart yang mirip. Aturan §2.1 berlaku.
> 2. **Lintas repo** — logika POS yang sama ada di TypeScript **dan** Dart. Ini **tidak bisa
>    dihindari** (web tetap hidup), jadi ia diatur, bukan dilarang. Lihat
>    `.claude/rules/cross-repo.md`.
>
> Jangan tertukar: bentuk 1 adalah bug yang harus diperbaiki; bentuk 2 adalah risiko yang
> harus dikelola dengan test.

### 2.5 Sebelum membuat helper baru

Tanyakan berurutan:

1. Sudah ada helper yang melakukan ini? (cari dulu, jangan mengandalkan ingatan)
2. Kalau ada yang mirip, apakah bisa digeneralisasi tanpa mengorbankan kejelasan?
3. Kalau digeneralisasi, apakah **semua** pemakai lama tetap benar? (lihat §4)
4. Kalau tidak bisa digeneralisasi, apakah ini benar-benar butuh helper terpisah, atau dua
   konsep yang berbeda?

---

## 2a. Jangan Tulis Sendiri Apa yang Sudah Diselesaikan Library — WAJIB

> **Kalau ada library yang teruji dan ter-maintained untuk menyelesaikan sesuatu, pakai itu.
> Kalau bisa mudah, kenapa manual?**
>
> Kode yang ditulis sendiri adalah kode yang harus diuji, diperbaiki, dan dirawat oleh kita.
> Kode library adalah kode yang sudah diuji ribuan orang, sudah melewati edge case yang belum
> kita pikirkan, dan diperbaiki orang lain saat ada bug.

Ini penerapan §2.1 pada tingkat tertinggi: **menulis sendiri sesuatu yang sudah ada adalah
duplikasi**, dan versinya hampir pasti lebih buruk — bukan karena kita tidak mampu, tapi
karena library itu sudah melewati lebih banyak kasus nyata daripada yang sanggup kita tulis
di satu sesi.

### 2a.0 Urutan keputusan — tanyakan berurutan, berhenti di jawaban pertama yang "ya"

1. **Apakah ini bisa di-generate dari deklarasi?** → pakai codegen (`freezed`,
   `json_serializable`). Lihat §2a.2.
2. **Apakah package `dart:` bawaan sudah punya?** → pakai stdlib (`dart:convert`,
   `dart:math`, `package:collection`). Menulis JSON parser sendiri tidak pernah benar.
3. **Apakah ada library teruji untuk ini?** → pakai library. HTTP client: `dio`, bukan
   `HttpClient` yang dibungkus tangan.
4. **Apakah ini perilaku bisnis yang spesifik repo ini?** → baru tulis sendiri. Ini satu-satunya
   kategori yang memang milik kita: aturan tender, kalkulasi keranjang, format struk.

**Tes cepat:** kalau jawabannya "saya bisa tulis ini dalam 30 menit", tanyakan lagi — apakah
30 menit itu untuk menulis, atau untuk menulis **dan** menemukan semua bug yang sudah
ditemukan library itu? Yang kedua jauh lebih mahal.

### 2a.1 Alat yang sudah diverifikasi untuk repo ini

| Kebutuhan | Pakai | Bukan |
| --------- | ----- | ----- |
| Kelas data (equality, `copyWith`, `toString`) | **`freezed`** | `operator ==` manual |
| JSON serialize/deserialize | **`json_serializable`** | `toJson`/`fromJson` manual |
| Union type (`A \| B`, hasil sukses/gagal) | **`freezed` `sealed class`** | dua field nullable |
| HTTP client | **`dio`** | client `HttpClient` sendiri |
| Utilitas koleksi (`firstWhereOrNull`, `groupBy`, dll.) | **`package:collection`** | loop manual |
| ULID (`client_ref`) | **`package:ulid`** | encoder Crockford tulis tangan |

**Sudah diuji di repo ini, bukan dari dokumentasi:**

| Paket | Versi | Bukti |
| ----- | ----- | ----- |
| `freezed` | `4.0.1` | `build_runner build` EXIT=0; `copyWith`, `==`, `sealed` + `switch` benar |
| `freezed_annotation` | `3.1.0` | — |
| `json_serializable` | `6.14.1` | `fromJson` benar |
| `json_annotation` | `4.12.0` | — |
| `url_launcher` | `6.3.2` (`_android 6.3.33`) | `flutter pub add` resolve bersih; APK debug dan rilis terbangun dengannya; `launchUrl` diuji lewat `UrlLauncherPlatform` palsu (seam resmi plugin), 6 test. Peluncuran nyata belum diuji di perangkat |
| `flutter_secure_storage` | `11.2.0` | resolve bersih (membawa `jni`, `ffi`, `hooks`, `code_assets`); APK debug dan rilis terbangun; Gradle memasang SDK Platform 35 dan CMake 3.22.1 otomatis. Diuji lewat `TestFlutterSecureStoragePlatform` bawaan plugin (16 test). Keystore nyata belum diuji di perangkat |
| `dio` | `5.11.1` | resolve bersih; `Interceptor` (`onRequest`/`onResponse`/`onError`) diuji dengan `Dio` sungguhan dan `HttpClientAdapter` palsu di `apps/pos` (54 test, tanpa jaringan) |
| `shared_preferences` | `2.5.5` (`_android 2.4.28`) | `flutter pub add` resolve bersih; APK debug terbangun dengannya. Diuji lewat seam resmi plugin, `SharedPreferencesAsyncPlatform.instance` + `InMemorySharedPreferencesAsync` (`shared_preferences_platform_interface 2.4.2`), 7 test tanpa storage nyata. `SharedPreferencesAsync()` meminta platform **saat dibuat**, jadi pembungkusnya dibuat malas. Storage nyata belum diuji di perangkat |
| `flutter_localizations` + `intl` | SDK · `0.20.3` | `gen_l10n` (`l10n.yaml`, `flutter: generate: true`) menghasilkan `L10n` di pub workspace ini; analyzer bersih; ICU plural dan placeholder bertipe diuji (`apps/pos/test/l10n`) |
| `ulid` | `2.2.0` | `dart pub get` bersih di `pn_pos`; 13 test lulus dengan `dart test`; pure Dart (`dart:math`), tanpa Flutter |
| `sqflite` | `2.4.4` (`_android 2.4.4`) | `flutter pub add` resolve bersih; `flutter build apk --debug` berhasil. Toko keranjang tertahan (`SqliteHoldOrderStore`) diuji terhadap SQLite lewat `sqflite_common_ffi`. Di Android dipakai lewat `databaseFactorySqflitePlugin`, bukan `databaseFactory` global (yang melempar `StateError` sebelum plugin terdaftar). Penyimpanan di perangkat nyata belum diuji |
| `sqflite_common_ffi` | `2.4.3` (`sqlite3 3.6.0`) | Dependency **biasa**, bukan dev: Windows tidak punya `sqflite` dan memakainya di runtime (`sqlite3.dll` terbundel, diperiksa di build Windows). SQLite jalan di `flutter test` di mesin ini tanpa pemasangan tambahan |
| `path_provider` | `2.1.6` | `flutter pub add` resolve bersih; APK debug dan build Windows berhasil. Satu-satunya cara lokasi berkas kita sama dengan plugin lain (`project.md` §5.1). Diuji lewat direktori yang disuntikkan |
| `package_info_plus` | `10.2.1` (`_platform_interface 4.1.0`) | `flutter pub add` resolve bersih; `flutter build apk --debug` berhasil. Diuji lewat seam resmi plugin, `PackageInfoPlatform.instance`, 2 test. Plugin menyimpan hasil bacaannya selama proses hidup, jadi platform yang gagal hanya bisa diuji **sebelum** yang menjawab. Pembacaan nyata di perangkat belum diuji |
| `device_info_plus` | `13.2.0` (`_platform_interface 8.1.0`) | `flutter pub add` resolve bersih; `flutter build apk --debug` dan `flutter build windows --debug` berhasil. Diuji lewat seam milik plugin, `DeviceInfoPlugin.setMockInitialValues`, 3 test; platform yang gagal diuji dengan plugin asli tanpa handler (`MissingPluginException`). Pembacaan nyata di perangkat belum diuji |

`freezed` berjalan di **pure Dart tanpa Flutter** — diverifikasi dengan `sealed class` +
`switch` exhaustive + `copyWith` di package tanpa dependency Flutter. Jadi ia boleh dipakai
di `pn_pos`, yang dilarang menyentuh `flutter`.

> [!IMPORTANT]
> **Verifikasi sebelum pakai, jangan setelah.** "Library ini populer" bukan bukti — ia bisa
> saja belum mendukung versi Dart kita. Jalankan `dart pub get` **dan** codegen sekali di
> package nyata sebelum menulis kode yang bergantung padanya, lalu catat hasilnya di tabel
> di atas. Library yang belum diverifikasi di repo ini statusnya **belum boleh dipakai**.

### 2a.2 Yang DILARANG

```dart
// DILARANG — ini semua bisa di-generate
class Tender {
  final String method;
  final num amount;

  Map<String, Object?> toJson() => {'method': method, 'amount': amount};

  @override
  bool operator ==(Object other) =>
      other is Tender && other.method == method && other.amount == amount;

  @override
  int get hashCode => Object.hash(method, amount);
}
```

```dart
// BENAR
@freezed
abstract class Tender with _$Tender {
  const factory Tender({required String method, required num amount}) = _Tender;

  factory Tender.fromJson(Map<String, dynamic> json) => _$TenderFromJson(json);
}
```

### 2a.3 Union type — DILARANG dua field nullable

TypeScript punya `{ a } | { b }`. Terjemahan yang salah adalah dua field yang keduanya
nullable, karena type system lalu **tidak menjamin salah satunya terisi**, dan pemanggil
akan memakai `!` di jalur uang — yang dilarang `.claude/rules/security.md` §2.

```dart
// DILARANG — pemanggil bisa `built.tenders!` dan crash
class BuildResult {
  final List<Tender>? tenders;
  final Problem? problem;
}
```

```dart
// BENAR — switch exhaustive, tidak ada `!`
@freezed
sealed class TenderBuildResult with _$TenderBuildResult {
  const factory TenderBuildResult.ok(List<POSTenderDTO> tenders) = TenderBuildOk;
  const factory TenderBuildResult.failed(TenderProblem problem) = TenderBuildFailed;
}

final payload = switch (result) {
  TenderBuildOk(:final tenders) => tenders,
  TenderBuildFailed(:final problem) => throw CheckoutException(problem.message),
};
```

### 2a.4 Yang TETAP ditulis tangan

Alat generate **tidak menggantikan** keputusan desain, dan library tidak tahu aturan bisnis
kita. Tetap tulis sendiri:

- **Validasi** dan aturan bisnis (mis. "change tidak boleh melebihi cash")
- **Enum dengan nilai wire** dan `tryParse` (freezed tidak menghasilkan ini)
- **Fungsi kalkulasi** — matematika tidak bisa di-generate
- **Doc comment** yang menjelaskan *mengapa*, terutama alasan desain yang tidak terlihat
dari kode

**Tesnya:** kalau isi kode hanya bergantung pada **daftar field**, itu bisa di-generate.
Kalau bergantung pada **perilaku**, tulis sendiri.

### 2a.5 Kapan `freezed` berlebihan

Jangan pakai `freezed` untuk sesuatu yang bukan data:

- **Port/interface** — itu `abstract interface class`, bukan kelas data
- **State holder** dengan logika (`ChangeNotifier`) — perilaku, bukan data
- **Objek yang hanya punya satu field dan tidak pernah dibandingkan atau di-serialize**

Menggunakan `freezed` di situ menambah file generated tanpa manfaat. Tanyakan: apakah tipe ini
pernah dibandingkan, di-copy, atau di-serialize? Kalau tidak, tidak perlu.

> [!NOTE]
> **§2a.5 adalah pengecualian untuk freezed, bukan untuk §2a secara keseluruhan.** Memilih
> tidak memakai `freezed` untuk sebuah port tidak berarti boleh menulis HTTP client sendiri.
> Prinsip "pakai library teruji" tetap berlaku penuh.

---

## 3. Read The Whole Function — WAJIB

- `grep`/`search` **hanya** untuk menemukan lokasi.
- Hasil grep, potongan beberapa baris, atau cuplikan outline **DILARANG** dijadikan dasar
  menyimpulkan perilaku.
- **WAJIB** membaca setiap fungsi dari **signature sampai closing brace**, termasuk seluruh
  komentar.

Komentar di repo ini memuat alasan desain dan mode kegagalan yang tidak terlihat dari kodenya.
Melewatinya berarti kehilangan konteks yang paling penting.

**Dilarang:**

- Menyimpulkan isi sebuah file dari hasil grep pada file itu.
- Menyimpulkan sebuah endpoint/field "tidak ada" dari satu pola grep.
- Menyimpulkan perilaku sebuah fungsi dari cara pemanggilnya, atau sebaliknya.

Kalau file panjang, baca bagian yang relevan **utuh** — jangan menebak dari nama fungsi.

### 3.1 Negative Search Is Not Proof

**Sebelum mengklaim sesuatu tidak ada, buktikan bahwa pencariannya akan menemukannya kalau
memang ada.**

Hasil nol dari grep, linter, atau analyzer **bukan bukti**. Alat yang tidak pernah menyala
tidak bisa dibedakan dari alat yang rusak. Validasi detector-nya dulu — lihat
`.claude/rules/testing.md` §0.3.

**Wajib sebelum menyimpulkan sesuatu tidak ada:**

1. **Tentukan cakupan pencarian lebih dulu, lalu sebutkan cakupan itu bersama hasilnya.**
   "Tidak ada di `packages/`" bukan "tidak ada di repo". Kode yang sama pentingnya bisa
   tinggal di `apps/` atau `packages/pn_pos/lib/src/`.
2. **Kecualikan direktori besar di sisi pencarian**, bukan setelahnya:
   `grep -rn --exclude-dir=.dart_tool --exclude-dir=build <pola> <path>`. Pipe seperti
   `grep -r ... | grep -v .dart_tool` tetap menelusuri seluruh direktori itu lalu membuang
   hasilnya — lambat, dan hasilnya sama saja.
3. **Hasil nol hanya sah setelah alatnya terbukti bisa menyala** (`testing.md` §0.3). Tunjukkan
   pola yang **memang ada** pada perintah yang sama; kalau tidak, perintahnya belum terbukti
   apa pun.

Kalau tiga syarat itu tidak terpenuhi, yang boleh dikatakan adalah **"belum saya temukan"** —
bukan "tidak ada".

---

## 4. Trace Every Caller Before Fixing — WAJIB

Repo ini reusable: **keanehan di satu fungsi belum berarti bug-nya ada di fungsi itu.**

Sebelum mengubah fungsi yang dipakai lebih dari satu tempat:

1. **Daftar seluruh pemanggilnya.** Semua, bukan yang mudah ditemukan.
2. **Nyatakan konvensi** yang tiap pemanggil kirim dan harapkan.
3. **Putuskan sadar**: apakah keanehan itu berlaku di semua pemanggilan, atau hanya sebagian?

**Kalau hanya sebagian** → perbaikannya **bukan** di fungsi shared, melainkan di **pemanggil
yang salah konvensi**.

**Kalau di semua** → baru fungsi shared-nya yang salah.

### 4.1 Klaim "fungsi ini salah" butuh bukti

Klaim bahwa kode shared salah **wajib** disertai bukti dari pemanggil lain yang **setuju**
dengan implementasi sekarang.

Tanpa bukti itu, yang salah kemungkinan besar **asumsi kita**, bukan kodenya.

### 4.2 Jangan tambah pemakai baru sebelum konvensi jelas

**Dilarang** menambah pemakai baru ke sebuah helper sebelum konvensi helper itu dipastikan
dari seluruh pemakainya.

Menambah pemakai ke helper yang konvensinya belum jelas = menyebarkan asumsi yang belum
diverifikasi.

---

## 5. No N+1 / No I/O in Loops

- SQLite, HTTP, BLE, dan I/O lain **DILARANG** dipanggil di dalam loop per-item.
- **`Future.wait(items.map(...))` tetap N+1** — ia hanya membuat N call berjalan bersamaan,
  bukan batching. Di tablet, itu membuat storage kewalahan lebih cepat.
- **Alur koleksi wajib:** collect + deduplicate IDs → bulk fetch → map in memory →
  batch/set-based write.

```dart
// DILARANG
for (final item in items) {
  final product = await db.getProduct(item.productId); // I/O di dalam loop
  results.add(item.withProduct(product));
}

// BENAR
final ids = items.map((i) => i.productId).toSet();
final products = await db.getProductsByIds(ids);       // satu query
final byId = {for (final p in products) p.id: p};
final results = items.map((i) => i.withProduct(byId[i.productId])).toList();
```

- Test wajib memverifikasi bulk method dipanggil **sekali** dan jumlah query tetap **konstan**
  saat item bertambah.

> [!NOTE]
> **Catatan khusus BLE:** menulis ke characteristic per-chunk memang loop, tapi itu bukan
> N+1 — itu memang protokolnya. Yang dilarang adalah I/O database/HTTP di dalam loop
> pemrosesan data.

---

## 6. Completion Gate

Sebelum menyatakan sebuah task selesai, periksa:

- [ ] Sudah baca minimal 2 sibling implementation sebelum menulis?
- [ ] Tidak ada fungsi duplikat baru?
- [ ] Semua pemanggil fungsi yang diubah sudah didaftar dan diperiksa?
- [ ] Sudah baca fungsi yang diubah dari signature sampai closing brace?
- [ ] Tidak ada I/O di dalam loop?
- [ ] Copyright header ada di file baru?
- [ ] Verifikasi sudah dijalankan pada tingkat yang benar (`.claude/rules/testing.md` §7 —
      berkas yang disentuh per microstep, urutan penuh sekali di akhir)?

Kalau ada yang belum, task **belum** selesai.
