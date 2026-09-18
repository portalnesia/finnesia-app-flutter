# Finnesia POS (Flutter)

Aplikasi **POS (Kasir) Finnesia** untuk **tablet Android**, ditulis dengan Flutter. Ia client tambahan di
samping web app: logika bisnis ada di backend Go (`finnesia-monorepo/apps/api`), repo ini menyajikan UI,
transport, dan integrasi perangkat (printer BLE, antrian offline).

Dokumen ini untuk **developer yang mau berkontribusi**: dari clone sampai menjalankan dan membangun app.
Aturan kode, arsitektur, dan alasan di baliknya ada di [`AGENTS.md`](./AGENTS.md) dan
[`.claude/rules/`](./.claude/rules/) — baca sebelum membuka PR.

---

## Isi repo

```
finnesia-pos-flutter/
├── apps/pos/        aplikasi POS (Android; folder windows/ ada, belum dipakai)
├── packages/
│   ├── pn_types/    tipe dan client API murni     → diuji dengan `dart test`
│   ├── pn_pos/      logika POS murni (uang, ESC/POS) → `dart test`, DILARANG mengimpor flutter
│   └── pn_ui/       widget reusable               → `flutter test`
├── tools/
│   ├── dev/         perintah singkat (`./dev run`, `./dev check`, ...)
│   └── rule_lint/   pemeriksa berkas aturan
└── plan/            rencana, progres, dan temuan per fitur
```

Ini monorepo **Dart pub workspace**: satu `dart pub get` di root menyelesaikan semua package.

---

## 1. Prasyarat

| Alat | Versi | Catatan |
| ---- | ----- | ------- |
| **Flutter** | **`3.47.4` stable** (membawa Dart `3.13.3`) | Di-pin. Workflow di `.github/workflows/` memakai versi yang sama; versi lain mem-pin Gradle/AGP/Kotlin/NDK yang berbeda |
| **JDK** | 17 | JDK yang lebih baru (mis. JBR Android Studio) juga jalan: Gradle 9.3.1 mendukungnya |
| **Android SDK** | platform **36**, build-tools, **NDK `28.2.13676358`** | Lihat "Memasang NDK" di bawah |
| **Git** | — | — |
| **adb** | dari `platform-tools` | Harus ada di `PATH` |

Gradle akan memasang sendiri SDK Platform 35 dan CMake 3.22.1 pada build pertama (dibutuhkan plugin).
Ia meminta lisensi SDK sudah diterima: jalankan sekali `flutter doctor --android-licenses`.

Versi minimum Android untuk **menjalankan** app: **Android 12 (API 31)**. Ini `minSdk` di
`apps/pos/android/app/build.gradle.kts`, dan ia berlaku untuk AVD, perangkat asli, maupun WSA.

> [!IMPORTANT]
> **`flutter doctor` hijau tidak berarti build akan jalan.** Ia memeriksa *keberadaan* toolchain, bukan
> kecocokan versi yang dibutuhkan Flutter 3.47.4. NDK tidak pernah disebutnya. Kalau build pertama gagal,
> lihat [Troubleshooting](#troubleshooting).

### Memasang NDK

Flutter 3.47.4 mewajibkan NDK `28.2.13676358`. Tanpa itu **setiap** build Android gagal, bukan hanya yang
butuh kode native.

```bash
# Linux / macOS
sdkmanager "ndk;28.2.13676358"
```

Di Windows dengan `cmdline-tools` terbaru, `sdkmanager.bat` adalah wrapper usang yang **crash**
(`NTSTATUS 0xC0000409`). Pakai CLI barunya langsung:

```bash
"<ANDROID_SDK>/cmdline-tools/latest/bin/android.exe" sdk install --sdk="<ANDROID_SDK>" "ndk;28.2.13676358"
```

Detail dan buktinya: [`plan/scaffold/00-environment.md`](./plan/scaffold/00-environment.md) §3.

---

## 2. Clone dan setup

```bash
git clone https://github.com/portalnesia/finnesia-pos-flutter.git
cd finnesia-pos-flutter
./dev setup          # = dart pub get, menyelesaikan seluruh workspace
```

Windows PowerShell / `cmd`: `.\dev setup`. Bagian berikutnya menjelaskan `dev`.

Pastikan semuanya hijau sebelum mengubah apa pun:

```bash
./dev check          # semua yang dijalankan CI, dalam urutan CI (butuh beberapa menit)
```

---

## 3. Perintah singkat: `./dev`

Dart tidak punya `scripts` di `pubspec.yaml` seperti `bun run`, jadi repo ini punya skrip kecil di
[`tools/dev`](./tools/dev). Apa pun yang Anda ketik setelah nama tugas **diteruskan apa adanya** ke alat di bawahnya.

| Perintah | Yang dijalankan |
| -------- | --------------- |
| `./dev setup` | `dart pub get` di root |
| `./dev run [flag flutter]` | `flutter run` dari `apps/pos`, mis. `./dev run -d emulator-5554` |
| `./dev build [debug\|release] [flag flutter]` | `flutter build apk`, bawaan `debug`, mis. `./dev build release --build-name 1.2.3` |
| `./dev reverse [opsi adb]` | `adb reverse tcp:4000 tcp:4000` (untuk backend lokal, lihat §5) |
| `./dev gen [flag build_runner]` | `build_runner build` di setiap package yang punya kode generated |
| `./dev l10n [flag flutter]` | meregenerasi teks layar (`flutter gen-l10n`) setelah mengubah `apps/pos/lib/l10n/*.arb`. Hasilnya, `app_localizations*.dart`, ikut di-commit |
| `./dev gen-check [package]` | apakah kode generated (freezed/json, dan teks layar dari `.arb`) sudah mutakhir? Meregenerasi, membandingkan, lalu **mengembalikan berkas**: tidak mengubah apa pun. Ikut dalam `./dev check` |
| `./dev guard` | gagal bila `pn_types` atau `pn_pos` mengimpor `flutter` |
| `./dev test [package]` | seluruh test, atau satu: `pn_types`, `pn_pos`, `pn_ui`, `pos` |
| `./dev check` | pub get, format, analyze, kode generated mutakhir, tanpa impor flutter di `pn_types`/`pn_pos`, semua test, rule_lint (urutan CI) |
| `./dev help` | daftar ini |

- **Windows:** `.\dev ...` (PowerShell dan `cmd`). Di Git Bash, Linux, dan macOS: `./dev ...`
  (di Linux/macOS pastikan berkasnya executable: `chmod +x dev`).
- Bisa dipanggil dari direktori mana pun di dalam repo.
- Skrip ini tidak wajib: setiap tugas hanya membungkus perintah biasa, yang tercetak sebelum dijalankan.

---

## 4. Menjalankan app (development)

Pilih satu target. Semuanya berakhir di perintah yang sama:

```bash
flutter devices                 # daftar target yang terlihat, dengan id-nya
./dev run -d <id-perangkat>     # hot reload: tekan r, hot restart: R, keluar: q
```

Build debug memasang app sebagai **`com.finnesia.pos.debug`** (label *Finnesia POS (debug)*), terpisah dari
build rilis `com.finnesia.pos`. Keduanya bisa terpasang bersamaan dan tidak berbagi data.

### A. Emulator (AVD)

1. Android Studio → **Device Manager** → **Create Device**.
2. Pilih profil **Tablet** (mis. Pixel Tablet) dan system image **API 31 atau lebih baru**, `x86_64`.
   Image *Google APIs* cukup; app tidak butuh Google Play.
3. Nyalakan akselerasi hardware: Windows Hypervisor Platform / Hyper-V (Windows), KVM (Linux).
4. Jalankan dari Android Studio, atau dari terminal:

```bash
flutter emulators               # daftar AVD
flutter emulators --launch <id-emulator>
flutter devices                 # emulator muncul sebagai emulator-5554
./dev run -d emulator-5554
```

> Emulator **tidak bisa** dipakai untuk menguji printer BLE.

### B. Perangkat asli (USB atau nirkabel)

Perangkat harus **Android 12 atau lebih baru**.

1. Aktifkan **Developer options**: *Settings → About tablet → ketuk **Build number** 7 kali*.
2. Di *Developer options* nyalakan **USB debugging**.
3. Colokkan lewat USB, terima dialog *Allow USB debugging* di perangkat, lalu periksa:

```bash
adb devices                     # harus tertulis "device", bukan "unauthorized"
```

**Nirkabel (Android 11+):** di *Developer options* nyalakan **Wireless debugging** → *Pair device with pairing code*, lalu:

```bash
adb pair <ip>:<port-pairing>        # masukkan kode pairing yang tampil di perangkat
adb connect <ip>:<port-debugging>   # port di layar utama Wireless debugging (berbeda dari port pairing)
```

Lalu `./dev run -d <id>`. Ini satu-satunya target yang bisa menguji **printer BLE** dan Keystore nyata.
Untuk backend lokal di perangkat asli, jalankan `./dev reverse` (§5).

### C. Windows Subsystem for Android (WSA / WSABuilds)

Microsoft menghentikan WSA pada **5 Maret 2025**. Build komunitas
[WSABuilds](https://github.com/MustardChef/WSABuilds) melanjutkannya (varian GApps, root, dan NoGApps).
WSA melaporkan SDK 33 (dokumentasi Microsoft), jadi memenuhi `minSdk` 31.

1. Pasang build WSABuilds sesuai panduannya (Windows 11).
2. Buka aplikasi **Windows Subsystem for Android** → **Advanced settings** → nyalakan **Developer mode**.
3. **Jalankan satu aplikasi Android dulu** supaya VM-nya hidup (panduan Microsoft). VM mati sendiri
   setelah tidak aktif sekitar 7 menit dan koneksi adb ikut putus; opsi *Subsystem resources* di
   pengaturan WSA bisa dibuat terus menyala.
4. Sambungkan adb, lalu jalankan:

```bash
adb connect 127.0.0.1:58526
flutter devices                      # muncul sebagai 127.0.0.1:58526
./dev run -d 127.0.0.1:58526
```

Yang perlu diketahui:

- WSA berjalan di x86_64 dan jendelanya bisa diubah ukurannya, jadi berguna untuk menguji tata letak
  tablet, tetapi inputnya mouse dan keyboard, bukan sentuhan.
- Jangan mengandalkannya untuk printer BLE, Keystore, atau perilaku vendor: itu **uji manual di tablet asli**
  ([`testing.md`](./.claude/rules/testing.md) §8).
- Sebagian build dengan GApps dilaporkan crash di Windows 11 setelah Juni 2025 (issue #593 di repo
  WSABuilds). App ini tidak butuh Google Play, jadi varian **NoGApps** adalah jalan keluar.
- `adb reverse` (untuk backend lokal) belum diverifikasi di WSA oleh repo ini.

---

## 5. Backend yang dituju

Ada **dua env aplikasi** (debug, release) dan **tiga env endpoint**:

| Env endpoint | Alamat | Bisa dipilih di |
| ------------ | ------ | --------------- |
| `staging` (bawaan debug) | `https://apps-dev.finnesia.com` | debug |
| `production` | `https://apps.finnesia.com` | debug dan release (satu-satunya untuk release) |
| `lokal` | `http://localhost:4000` | debug |

- **Debug memilih endpoint di layar pairing, sebelum pairing.** Setelah pairing, alamat dikunci ke tenant
  (`custom_domain` bila ada) dan tidak bisa diganti sampai perangkat di-reset dari dalam app.
- Build **release tidak memuat** host staging maupun lokal sama sekali. Tidak ada `--dart-define` untuk mengubahnya.
- Detail dan alasannya: [`plan/api-client/README.md`](./plan/api-client/README.md) §13.

> [!WARNING]
> **Kode pairing terikat ke env tempat ia dibuat.** Kode dari dashboard staging **tidak bisa** ditebus di
> production, dan sebaliknya. Gejalanya identik dengan "kode salah atau kedaluwarsa": backend sengaja tidak
> membedakan. Kalau pairing gagal, pastikan env yang dipilih di app sama dengan dashboard tempat kode dibuat.

### Backend lokal (`lokal`)

Backend berjalan di komputer Anda pada port 4000, sedangkan `localhost` di dalam tablet adalah **tablet itu
sendiri**. Teruskan port-nya lewat adb:

```bash
./dev reverse                  # adb reverse tcp:4000 tcp:4000
./dev reverse -s <serial>      # bila lebih dari satu perangkat terhubung (lihat `adb devices`)
```

Ini juga berlaku untuk emulator: alamat `10.0.2.2` diizinkan oleh konfigurasi jaringan debug, tetapi app
selalu memakai `http://localhost:4000`. HTTP polos hanya diizinkan untuk `localhost` dan `10.0.2.2`, dan
hanya di build debug (`android/app/src/debug/`).

### Login

Login membuka **browser sistem** dan app menunggu hasilnya (polling). Setelah login selesai, kembali ke app
secara manual. Kembali otomatis lewat tautan aplikasi (Android App Links) belum dikerjakan di sisi app.

---

## 6. Build

```bash
./dev build                   # APK debug
./dev build release           # APK rilis, ditandatangani (lihat di bawah)
```

Hasilnya di `apps/pos/build/app/outputs/flutter-apk/`:

```bash
adb install -r apps/pos/build/app/outputs/flutter-apk/app-debug.apk
```

### Build rilis dan signing

Build rilis membaca `apps/pos/android/keystore.properties`. Berkas itu **tidak ada di repo** dan **tidak boleh
di-commit** (juga `*.jks`, `*.keystore`, `.env`; semuanya ada di `.gitignore`). Tanpa berkas itu, build rilis
**gagal dengan sengaja** (`Keystore file not set`): lebih baik gagal daripada mengirim APK yang tertandatangani
kunci debug. Build debug tidak membutuhkannya.

```properties
keyAlias=<alias>
password=<password store dan key, sama>
storeFile=<path absolut dengan slash biasa, mis. /srv/keys/upload-keystore.jks>
```

Keystore rilis dipegang pemilik repo. **Jangan membuat keystore baru:** identitas penandatangan harus
tetap sama, kalau tidak app tidak bisa diinstal sebagai upgrade. Untuk kontribusi biasa Anda tidak butuh build
rilis; CI membuatnya.

### Rilis lewat CI

Push tag `v*` menjalankan [`release-pos.yml`](./.github/workflows/release-pos.yml): verifikasi, lalu APK rilis
(`arm64` dan `armv7`), lalu **draft** GitHub Release yang baru bisa diunduh setelah dipublikasikan. Versi dan
`versionCode` diturunkan dari tag; `pubspec.yaml` tetap `0.1.0+1`.

---

## 7. Test dan verifikasi

```bash
./dev test                 # semua package
./dev test pn_pos          # satu package: pn_types | pn_pos | pn_ui | pos
./dev check                # urutan yang sama dengan workflow CI
```

- `pn_types` dan `pn_pos` diuji dengan `dart test` (milidetik, tanpa Flutter). `pn_ui` dan `apps/pos` dengan
  `flutter test`. Test **tidak** memakai perangkat, jaringan, atau plugin native: semuanya lewat port dan fake.
- **TDD:** test dulu dan lihat ia gagal, baru kodenya. Detail dan alasannya: [`testing.md`](./.claude/rules/testing.md).
- **CI (`ci.yml`) sedang nonaktif** karena batas menit GitHub Actions: berkasnya diganti nama menjadi
  `.github/workflows/ci.yml.disabled` (isinya utuh; ganti nama kembali untuk mengaktifkan). Artinya tidak ada yang
  menjalankan pemeriksaan untuk Anda, jadi **`./dev check` wajib hijau sebelum membuka PR** (ia mencakup setiap langkah pemeriksaan di `ci.yml.disabled`). `release-pos.yml` tetap
  aktif untuk tag `v*` dan menjalankan analyze dan test sebelum membangun.
- Skrip `dev` punya test sendiri (`cd tools/dev && dart test`) yang **tidak** dijalankan CI. Ubah `tools/dev`? Jalankan itu.

### Kode generated

`*.freezed.dart` dan `*.g.dart` **ikut di-commit**. Setelah mengubah model `freezed` / `json_serializable`:

```bash
./dev gen
```

lalu commit hasilnya. Pemeriksaan otomatisnya (membangun ulang di `pn_types`, `pn_pos`, dan `apps/pos`, gagal bila
berbeda dari yang di-commit; `pn_ui` belum punya kode generated) kini dilakukan `./dev gen-check`, yang juga jadi
bagian `./dev check`. Ia tidak memakai `git` dan tidak mengubah berkas: perbedaan baris baru (CRLF/LF) diabaikan.

---

## 8. Berkontribusi

Bacalah [`AGENTS.md`](./AGENTS.md); ia indeks ke aturan lengkap di `.claude/rules/`. Yang paling sering menjebak:

- **Native lewat port.** Widget tidak boleh memanggil plugin (BLE, penyimpanan, browser) langsung. Buat port,
  implementasi nyata, dan fake yang merekam pemanggilan dan punya jalur error
  ([`native-ports.md`](./.claude/rules/native-ports.md)).
- **`pn_pos` tidak boleh mengimpor `flutter`.** Itu yang membuat logika uang bisa diuji secepat itu.
- **Jangan pernah mencatat token** (log, `print`, pesan error) dan jangan mengirimnya ke host selain hasil
  pairing ([`security.md`](./.claude/rules/security.md)).
- **Jangan tulis sendiri apa yang sudah ada di library teruji** (`freezed`, `dio`, `dart:math`, ...);
  daftar versi yang sudah diverifikasi ada di [`patterns.md`](./.claude/rules/patterns.md) §2a.1.
- **Semua teks antarmuka lewat terjemahan** (i18n), tanpa string bahasa yang ditulis langsung di widget.
- Setiap berkas Dart yang ditulis tangan diawali **header hak cipta** ([`style.md`](./.claude/rules/style.md) §6).
  Berkas generated tidak.
- Tanpa barrel export: impor langsung dari berkas yang dimaksud.
- Kode dan komentar teknis dalam **bahasa Inggris**; dokumen (`plan/`, `README`, aturan) dalam **bahasa Indonesia**.
- **Commit** memakai Conventional Commits: `feat(pos): ...`, `fix(printer): ...`, dan satu concern per commit.
- Perubahan **perilaku logika POS** (keranjang, tender, shift, ESC/POS) wajib disertai test yang menetapkan
  perilakunya ([`cross-repo.md`](./.claude/rules/cross-repo.md)).

Rencana dan progres per fitur ada di [`plan/`](./plan/): `scaffold`, `api-client`, `printer`.

---

## Troubleshooting

| Gejala | Penyebab dan jalan keluar |
| ------ | ------------------------- |
| `Package ndk not found` / `sdkmanager.bat ... exit value -1073740791` | NDK `28.2.13676358` belum terpasang dan auto-installnya crash. Pasang manual, lihat [Memasang NDK](#memasang-ndk) |
| `Could not close incremental caches ... Storage ... is already registered` | Bug kompilasi inkremental Kotlin pada kombinasi toolchain ini. Workaround `kotlin.incremental=false` sudah ada di `apps/pos/android/gradle.properties`; **jangan dihapus** |
| Build gagal karena kehabisan memori | `android/gradle.properties` memakai heap Gradle 8 GB (`-Xmx8G`). Turunkan sementara di lokal, jangan di-commit |
| `adb devices` kosong atau `unauthorized` | Kabel/mode USB, atau dialog *Allow USB debugging* belum diterima; cabut, colok ulang, terima. Bila perlu `adb kill-server` |
| `flutter devices` tidak menampilkan WSA | VM WSA mati (idle ± 7 menit) atau Developer mode mati. Jalankan satu app Android, lalu `adb connect 127.0.0.1:58526` lagi |
| Pairing selalu ditolak | Env app tidak sama dengan env dashboard tempat kode dibuat (§5). Kode pairing sekali pakai dan kedaluwarsa |
| App tidak bisa menghubungi backend lokal | `./dev reverse` belum dijalankan, atau backend tidak mendengarkan di port 4000. HTTP polos hanya diizinkan untuk `localhost` dan `10.0.2.2` |
| Build rilis: `Keystore file not set` | `apps/pos/android/keystore.properties` tidak ada. Disengaja; lihat [Build rilis](#build-rilis-dan-signing) |
| `dart test` gagal di root: `No test files were passed` | Di root workspace tidak ada `test/`. Jalankan per package (`./dev test`) |
