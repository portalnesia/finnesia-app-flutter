---
description: Project rules — identitas repo, tech stack, toolchain Android, storage, printer, distribusi
tools: "*"
alwaysApply: true
paths:
  - "**/*.dart"
  - "**/*.yaml"
  - "**/*.arb"
  - "**/*.kts"
  - "**/*.xml"
---

# Project — Identitas, Tech Stack, Hubungan ke Repo Lain

---

## 1. Apa Ini

Aplikasi **POS (Kasir) Finnesia** untuk **tablet Android**, ditulis dengan **Flutter**.

Empat karakter yang menentukan hampir semua keputusan teknis:

1. **Client tambahan, bukan pengganti.** Web app **tetap hidup**. Ini bukan migrasi.
2. **Satu build untuk semua tenant.** Branding dibaca runtime dari `companies.branding_config`.
   Tidak ada build per klien, tidak ada varian APK.
3. **Thin client.** Logika bisnis ada di backend Go milik platform. Repo ini menyajikan UI,
   transport, dan integrasi perangkat.
4. **Pairing mengunci tenant.** Satu perangkat terikat ke satu tenant sampai di-reset dari
   dalam app.

---

## 2. Kenapa Flutter, dan apa harganya

Alasan memilih Flutter adalah **UI native**, bukan kapabilitas native — BLE dan SQLite
sudah tersedia di banyak stack. Yang tidak bisa diberikan stack lain adalah *feel*: rendering,
latensi sentuh, dan scroll grid produk. Aplikasi kasir dipegang sepanjang hari; itu kebutuhan
produk.

Harga yang dibayar, dan harus disadari:

### 2.1 Duplikasi logika POS bersifat PERMANEN

Karena web tetap hidup, matematika keranjang, tender, shift, dan ESC/POS akan ada di **dua
tempat selamanya**. Duplikasi adalah **sumber bug yang paling mahal di repo yang menangani
uang** — dan itu bukan risiko teoretis di sini.

Mitigasinya bukan disiplin, tapi **test**: perilaku yang benar didefinisikan secara
eksekutabel di kedua sisi. Lihat `.claude/rules/cross-repo.md`.

### 2.2 Yang di-port dan yang tidak

**Repo sumber adalah acuannya.** Modul yang di-port diambil langsung dari sana — bukan dari
salinan yang bisa ketinggalan.

| Bagian | Aksi | Sumber (relatif ke root repo sumber) |
| ------ | ---- | ------ |
| Logika POS murni (8 modul) | **port** | `packages/shared/src/pos/` |
| Test logika POS | **port sebagai oracle** | `packages/shared/src/pos/*.test.ts` |
| ESC/POS command builder | **port** | `apps/web/src/lib/escpos.ts` — lihat §2.5 |
| ESC/POS formatter | **port** | `apps/web/src/lib/pos-escpos-format.ts` — lihat §2.5 |
| Tipe (`Product`, `POS*`) | **port sebagian** — hanya yang dipakai POS | `packages/types/src/` |
| API registry | **rancang ulang** — Dart tidak punya template literal types | lihat `.claude/rules/architecture.md` §6 |
| Pairing, native login, session, device | **tulis di repo ini** | tidak ada padanannya di repo sumber |
| BLE printer | **tulis sendiri, sedikit kode** | `universal_ble` (BSD-3) menyediakan scan/connect/write/MTU; **chunking ditulis sendiri** (§6) |
| UI | **tulis sendiri** | layout bebas, fitur sama |
| `pos-shift-resume.ts` | **JANGAN di-port** | lihat §2.3 |

### 2.3 `pos-shift-resume.ts` tidak punya padanan, dan itu benar

Modul itu ada **hanya** untuk menyelesaikan masalah React: state yang dibagi antara gate
(yang bertanya) dan cart (yang merender) tanpa `useState` di komponen. Di Dart tidak ada
masalah itu — `ChangeNotifier` / `ValueNotifier` / state holder biasa sudah cukup.

Mem-port-nya berarti menyalin solusi untuk masalah yang tidak ada. **Dilarang.**

### 2.4 Port perilaku, bukan implementasi

Contoh dari `pos-hold.ts`: setiap accessor-nya defensif, dengan alasan eksplisit —
*"localStorage throws in a private window and in the thumbnailer, and a corrupted entry must
not take the till down mid-shift."*

- **Yang di-port:** kontraknya — *storage gagal tidak boleh menjatuhkan till; kembalikan list kosong.*
- **Yang TIDAK di-port:** `window.localStorage`. Di Flutter implementasinya ada di belakang
  port (`HoldOrderStore`), dan bisa SQLite atau file.

### 2.5 Print stack — tiga formatter, bukan satu

`escpos.ts` dan formatter struk ada di **`apps/web/src/lib/`**, bukan di
`packages/shared/src/pos/`. Itu tempatnya sekarang, dan itulah yang dipakai web app.

| Modul | Isi | Test |
| ----- | --- | ---- |
| `escpos.ts` | command builder (init, align, bold, font size, feed, cut) | 12 |
| `pos-escpos-format.ts` | **3** formatter: `formatReceiptEscPos`, `formatCategoryTicketEscPos`, `formatShiftReportEscPos` | 38 |

**Penting:** ketiga formatter itu harus di-port — jangan hanya satu.

Konsekuensinya untuk repo ini: **port ketiganya**, dari repo sumber.

**Tidak ada yang perlu dipindahkan.** `apps/web/src/lib/` adalah tempat yang sah dan sudah
dipakai produksi; port langsung dari sana. Detail: `.claude/rules/cross-repo.md` §5.1.

---

## 3. Tech Stack

| Lapisan | Teknologi |
| ------- | --------- |
| Bahasa | **Dart 3.13.3** |
| Framework | **Flutter 3.47.4** stable |
| Target | **Android** (arm64 + armv7 wajib; x86_64 untuk emulator) untuk dirilis. **Windows** dipakai untuk pengembangan dan pengujian harian, dan build `--debug`-nya terverifikasi — tapi jalur distribusinya belum ada (`.claude/rules/windows.md`). |
| Monorepo | **Dart pub workspaces** — `dart pub get` di root menyelesaikan semuanya |
| Logika POS | `packages/pn_pos` — **tanpa Flutter**, diuji dengan `dart test` |
| Storage lokal | SQLite (`sqflite`) untuk antrian offline |
| Printer | `universal_ble` (BLE/GATT), ESC/POS dari formatter yang di-port |
| HTTP | bearer token ke host tenant |
| Test | **TDD unit test** (`dart test` / `flutter test`). Dependency eksternal di-mock lewat port |

### 3.1 Toolchain Android yang di-pin Flutter 3.47.4

Dibaca dari `packages/flutter_tools/lib/src/android/gradle_utils.dart` dan
`packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt`:

| Konstanta | Nilai |
| --------- | ----- |
| Gradle | `9.3.1` |
| AGP | `9.1.0` |
| Kotlin | `2.4.0` |
| compileSdk / targetSdk | `36` |
| minSdk | `24` |
| ndkVersion | **`28.2.13676358`** |

> [!IMPORTANT]
> **`flutter doctor` hijau tidak berarti build akan jalan.** Doctor memeriksa **keberadaan**
> toolchain, bukan **kecocokan versi** yang dibutuhkan template. Dua blocker di repo ini
> (`flutter doctor` tidak menyebut NDK sama sekali) hanya muncul lewat build sungguhan.
> Perbaikannya ada di `plan/scaffold/00-environment.md` §3 dan §4 — jangan dihapus dari
> `android/gradle.properties`.

### 3.2 Java — biarkan `JAVA_HOME` apa adanya

Flutter memakai Gradle 9.3.1, yang mendukung JDK 25, dan `flutter doctor` justru otomatis
memilih JBR Android Studio.

**Tidak ada tindakan.** Biarkan `JAVA_HOME` menunjuk Liberica JDK 17.

---

## 4. Auth

App **tidak pernah menyentuh OIDC provider.** Backend yang menukar kode, lalu app mengambil
token lewat polling.

- `session_token` + `session_refresh_token`
- Rotasi lewat response header `X-Session-Token` + `X-Session-Expires`
- **Bearer, bukan cookie** → CSRF tidak berlaku di sini
- **Jangan pernah log token** — lihat `.claude/rules/security.md` §1

---

## 5. Antrian Offline — Data Finansial

Uang sudah diterima saat penjualan masuk antrian. Transaksi **tidak boleh hilang**.

| Aturan | Kenapa |
| ------ | ------ |
| **SQLite**, bukan `shared_preferences` | Preferensi bisa dibersihkan sistem |
| Reset Perangkat **ditolak** bila antrian tidak kosong | Reset akan menghapus penjualan |
| Operasi **idempoten** | Replay setelah koneksi pulih tidak boleh menggandakan penjualan |
| Jumlah antrian tampil di layar kasir | Kasir harus tahu ada yang belum tersinkron |

Detail query, batching, dan atomicity: `.claude/rules/optimization.md`.

---

### 5.1 Di mana data disimpan: satu aturan, tidak ada lokasi buatan sendiri

Lokasi ditentukan dari disk dan dari sumber plugin, bukan dari kebiasaan. **Satu lokasi karangan
sendiri sudah cukup untuk memecah data**: `%APPDATA%\Finnesia POS` berbeda dari
`%APPDATA%\Finnesia\Finnesia POS\` yang sudah dipakai plugin lain, dan berkas aplikasi jadi
terpisah dari berkas plugin yang seharusnya sekandang.

| Data | Siapa | Windows | Android |
| ---- | ----- | ------- | ------- |
| Sesi, token, identitas perangkat | `flutter_secure_storage` | `%APPDATA%\<CompanyName>\<ProductName>\flutter_secure_storage.dat` | `shared_prefs/`, terenkripsi (Keystore) |
| Bahasa, tema | `shared_preferences` | `%APPDATA%\<CompanyName>\<ProductName>\shared_preferences.json` | `shared_prefs/FlutterSharedPreferences.xml` |
| Keranjang tertahan (dan antrian offline nanti) | SQLite, `openAppDatabase` | `%APPDATA%\<CompanyName>\<ProductName>\finnesia_pos.db` | `files/finnesia_pos.db` |

`<CompanyName>` dan `<ProductName>` dibaca `path_provider` dari `Runner.rc`, jadi menamai ulang aplikasi
memindahkan semuanya bersama.

**Aturan:** berkas yang dipegang aplikasi sendiri ditaruh di **application support directory**
(`getApplicationSupportDirectory()`), di semua platform. **Dilarang** menulis nama folder sendiri atau
membaca `APPDATA`/`HOME` langsung. Yang dipegang plugin (Keystore, `shared_prefs/` di Android) tidak
dipindah: itu lokasi standar platformnya, tetap di penyimpanan privat aplikasi, dan `allowBackup="false"`
menjaga tidak ada yang meninggalkan perangkat. Android: hapus data aplikasi atau uninstall menghapus semuanya
sekaligus, dan itu yang diharapkan.

Store baru **tidak** membuka database sendiri: ia menambah tabel dan migrasi di `native/db/app_database.dart`.

## 6. Printer

- **BLE/GATT**, bukan SPP.
- **Byte ESC/POS berasal dari formatter yang di-port** — jangan diimplementasi ulang.
- Paketnya (`universal_ble`) menyediakan scan, connect, write, dan `requestMtu`. **Chunking dan
  cap 180 ditulis sendiri** — paketnya tidak menyediakannya, dan cap 180 berasal dari sumber
  (`PrinterPlugin.kt`), bukan dari default library.
- Urutan tulis dijaga oleh `await` di atas `write`, yang sudah punya antrian global sendiri.
  **Jangan** menulis antrian tulis manual di atasnya.
- Yang dikerjakan repo ini adalah **transport**-nya, bukan format struknya.

Detail: `.claude/rules/architecture.md` §5 dan `.claude/rules/testing.md` §8.

---

## 7. Distribusi

| Hal | Keputusan |
| --- | --------- |
| Output | APK ke tablet (sideload) **dan** AAB ke Play Console internal track. Mechanism-nya: `release-pos.yml` membangun keduanya lalu melampirkan keduanya sebagai asset **draft** GitHub Release; upload ke Play baru jalan setelah draft itu **dipublikasikan** manusia, di workflow `publish-to-store.yml` (AAB diambil dari asset release, `track: internal`, `status: completed`). Tidak ada Shorebird di run itu |
| Trigger | tag `pos-v*` polos (rilis production) · tag `pos-v*-staging.N` (staging) · tag `pos-v*-N` (patch OTA) · **plus** `workflow_dispatch` lewat `release-dispatch.yml` (dispatcher menambah pintu masuk; trigger tag tetap ada dan tidak berubah) |
| CI | GitHub Actions — `release-dispatch.yml` (dispatcher manual: validasi kombinasi dulu, baru panggil workflow di bawah), `release-pos.yml` (APK + AAB → draft GitHub Release, Shorebird baseline), `publish-to-store.yml` (upload AAB ke Play `internal`, hanya setelah draft dipublikasikan), `staging-pos.yml` (**APK** profile), `windows-pos.yml` (MSIX → draft yang sama), `shorebird-patch.yml` (patch OTA). `ci.yml` **dinonaktifkan sementara** (batas menit), berkasnya `ci.yml.disabled`; penggantinya `./dev check` |
| Signing | GitHub Secrets — **tidak ada berkas sensitif di repo** |

**Yang TIDAK masuk repo:** `keystore.properties`, `key.properties`, `*.jks`, `.env`.

### 7.1 Keystore — satu identitas, jangan dibuat ulang

Keystore rilis **sudah ada** dan **tidak** dibuat ulang:

| Berkas | Lokasi |
| ------ | ------ |
| `upload-keystore.jks` | `finnesia/deploy/android-files/` — di luar repo ini |
| `keystore.properties` | idem (sumbernya), disalin ke `apps/pos/android/` saat build lokal |
| `keystore.b64` | idem — base64 untuk GitHub Secret `ANDROID_KEY_BASE64` |

**Alias `upload`, satu `password` untuk store dan key.** `storeFile` ditulis absolut dengan
forward slash (mis. `/srv/keys/upload-keystore.jks`), bukan `\` dan bukan relatif.
`apps/pos/android/app/build.gradle.kts` membaca berkas ini lewat
`rootProject.file("keystore.properties")`, jadi lokasinya adalah `apps/pos/android/`, bukan
`apps/pos/android/app/`.

**Ekstensi `.jks` menyesatkan — isinya PKCS12.** Diverifikasi dari magic bytes (`30 82`,
bukan `fe ed fe ed`) dan dari `keytool -list -v`: PKCS12, RSA 2048-bit, `SHA256withRSA`,
sertifikat v3, berlaku sampai 2054. JDK 17 `keytool -genkeypair` tanpa `-storetype` sudah
menulis PKCS12 secara default, jadi berkas ini lahir modern.

**Karena itu: jangan buat ulang, dan jangan rename ke `.p12`.** Format dideteksi dari isi,
bukan ekstensi, jadi nama itu kosmetik dan tidak ada yang rusak. Rename tidak memberi manfaat
apa pun.

> [!NOTE]
> `keytool -list -storetype JKS` pada berkas ini **berhasil** dan mencetak
> `Keystore type: JKS`. Itu keytool menggemakan tipe yang diminta, bukan format
> sebenarnya. Percayai magic bytes.

> [!IMPORTANT]
> **Jangan buat keystore baru.** APK yang sudah beredar ditandatangani dengan keystore ini,
> dan identitas penandatangan tidak boleh berubah. Keystore berbeda = aplikasi berbeda: tidak
> bisa install sebagai upgrade, dan data kasir di tablet tidak ikut pindah. Fingerprint yang
> harus cocok:
>
> ```
> SHA-256 52:B2:E9:A0:D2:12:08:44:0E:D6:F3:6D:A4:53:4E:87:30:20:83:FC:1E:14:B1:19:1E:B3:8B:CA:26:FD:CB:81
> Owner   CN=Putu Aditya, OU=Finnesia POS, O=Finnesia, L=Mataram, ST=NTB, C=ID
> ```
>
> Verifikasi APK, bukan keystore-nya — `keytool -printcert -jarfile` **mengembalikan kosong**
> karena hanya membaca skema v1 (JAR), sementara Flutter menandatangani dengan v2:
>
> ```bash
> "$ANDROID_HOME/build-tools/<ver>/apksigner" verify --print-certs \
>   apps/pos/build/app/outputs/flutter-apk/app-release.apk
> ```

**Release tanpa keystore gagal, dan itu disengaja.** Tanpa `keystore.properties`, build
release berhenti dengan `SigningConfig "release" is missing required property "storeFile"`.
Template `flutter create` menandatangani release dengan **debug key**; itu diganti, karena
APK yang beredar dengan identitas debug bukan hal yang bisa ditarik kembali.
