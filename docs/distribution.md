# Distribusi & Rilis

Diperbarui: 2026-10-05.

Dokumen ini menjelaskan bagaimana Finnesia POS sampai ke perangkat kasir: pipeline CI/CD-nya,
prasyarat manual satu kali yang harus disiapkan sebelum pipeline itu bisa jalan, dan alur
promosi rilis di Play Console.

Tag diberi prefix aplikasi karena repo ini **monorepo** dan akan memuat aplikasi lain:
`pos-v1.2.0` menandakan workflow POS, dan versi yang dibaca adalah `1.2.0`.

> [!IMPORTANT]
> **`pos-v1.2.0` → `1.2.0`. Yang dibuang adalah `pos-` (beserta `v`), bukan hanya `pos-`.**
> Di shell itu satu operasi: `${GITHUB_REF_NAME#pos-v}`.
>
> Huruf `v` tetap ada di nama tag (konvensi repo ini), tapi **tidak boleh** ikut ke nilai versi.
> `flutter build --build-name v1.2.0` akan menaruh `v1.2.0` di `versionName` dan halaman About,
> dan `shorebird release android` mem-parse nilai itu sebagai semver — `pub_semver` menolaknya
> (`FormatException: Could not parse "v1.2.0"`), jadi build gagal. Hal yang sama berlaku untuk
> `msix_version`, yang harus `1.2.0.0`, bukan `v1.2.0.0`.
>
> Dikunci test: `apps/pos/test/branding/distribution_workflows_test.dart`.

Ada **empat artefak**, dan **tiga** di antaranya rilis:

| Artefak | Workflow | Untuk siapa | Pernah dirilis? |
| ------- | -------- | ----------- | --------------- |
| **Rilis native** (`pos-v1.2.0`) | `release-pos.yml`, lalu `publish-to-store.yml` | tablet, lewat Play Store | **ya** — dipromosikan manual |
| **Patch Dart** (`pos-v1.2.0-5`) | `shorebird-patch.yml` | tablet yang sudah terpasang rilis | tidak (OTA, bukan rilis baru) |
| **Staging** (`pos-v1.2.0-staging.3`) | `staging-pos.yml` | tim internal | **tidak pernah** |
| **Windows** (`pos-v1.2.0`) | `windows-pos.yml` | desktop, lewat Microsoft Store | **belum** — paketnya dibangun CI, diunggah manual |

**Store hanya untuk production.** Keputusan pemilik 2026-09-28: Android staging dan Windows
berhenti di GitHub Release saja, dan hanya alur Android production yang mengunggah ke Store
(Play Store) — dan itu lewat `publish-to-store.yml`, **setelah** draft GitHub Release
dipublikasikan manusia (§1.5), bukan di run build. Windows tetap dipaketkan dengan identitas
Store dan diunggah ke Partner Center **oleh pemilik, manual**.

Staging punya dokumen sendiri — rencana, alasan, dan angka yang sudah diukur:
[`plan/staging/README.md`](../plan/staging/README.md). Ringkasnya: ia build type `profile`
(appId **release**, perilaku **debug**), dan hasilnya **APK** yang diunduh tester dari draft
GitHub Release. Ia tidak menyentuh Store sama sekali.

Windows juga punya dokumen sendiri: [`plan/windows-distribution/README.md`](../plan/windows-distribution/README.md).
Ringkasnya, dan tiga hal yang membedakannya dari tiga alur di atas:

- **Tag-nya sama dengan rilis Android** (`pos-v1.2.0` polos), tapi **job-nya terpisah** — jadi
  kegagalan build Windows tidak memblokir rilis Android dan sebaliknya. Satu nomor versi untuk
  satu produk di dua platform. Keduanya menulis **satu** GitHub Release yang sama, dan
  `concurrency` dengan group yang sama membuat keduanya berbaris, bukan berpacu.
- **Tidak ada signing, tidak ada secret.** Microsoft Store menandatangani ulang paket MSIX saat
  sertifikasi, dan `msix:create --store` sendiri tidak menandatangani apa pun. Ini kebalikan
  total dari `release-pos.yml`.
- **CI hanya MEMBANGUN.** `windows-pos.yml` berhenti setelah paket `.msix` masuk ke draft
  GitHub Release; unggahan ke Partner Center dilakukan **manual**, tiga klik. Mengotomatiskan
  unggah menuntut tenant Entra + app registration + role Manager + 4 secret — untuk pekerjaan
  yang terjadi sekali per rilis, dan itu yang membuat pemilik memilih jalur manual.

> [!NOTE]
> **Windows tidak punya varian tester.** Package flight ditolak pemilik, karena flight memakai
> package family yang sama dan anggotanya **tidak pernah** menerima paket dari submission biasa —
> jadi tester yang masuk flight group terkunci ke paket flight. Kanal tester tetap milik Android
> (`staging-pos.yml`). Alasan lengkap: `plan/windows-distribution/README.md` §4.1.

---

## 0. Kenapa Play Console, bukan cuma sideload GitHub

Mulai **30 September 2026**, Google mewajibkan **Android Developer Verification**: APK dari
developer yang belum terverifikasi **tidak bisa di-install atau di-update** di perangkat
Android bersertifikasi di beberapa negara — termasuk **Indonesia**. Ini berlaku untuk semua
jalur distribusi, termasuk sideload langsung (GitHub Releases, dsb), bukan cuma Play Store.

Karena tenant Finnesia POS **self-install di device masing-masing** (bukan tablet yang
di-provision tim Finnesia), track testing Play Console yang butuh registrasi tester manual
(`internal`/`closed`) tidak cukup untuk onboarding tenant baru — perlu **Production**
(bisa "unlisted", tidak publik) supaya install genuinely self-service lewat link.

Mendaftar akun Play Console **Full Distribution** ($25, sekali bayar) menyelesaikan dua hal
sekaligus:

1. Lolos syarat Android Developer Verification (registrasi identitas + package name lewat
   Android Developer Console — akun Play Console yang sama dipakai untuk ini).
2. Jadi jalur distribusi native jangka panjang, dengan auto-update bawaan Play Store.

GitHub Releases (APK) **tetap dipertahankan** sebagai jalur cadangan/instalasi awal sebelum
Play Store siap — bukan diganti sepenuhnya.

Sumber: [Understanding Android developer verification](https://support.google.com/android-developer-console/answer/16561738?hl=en),
[FAQ — Android developer verification](https://developer.android.com/developer-verification/guides/faq).

---

## 1. Alur pipeline (`release-pos.yml`)

Trigger: `push` tag `pos-v*` **polos** (rilis native), atau `workflow_dispatch` lewat
[`release-dispatch.yml`](../.github/workflows/release-dispatch.yml) (§1.2).

```
git tag pos-v1.2.0 && git push origin pos-v1.2.0
        │
        ▼
release-pos.yml (job tunggal)        ← TIDAK ada upload ke Store di run ini
        │
        ├─ dart analyze · dart test · flutter test   (gagal → rilis tidak dibangun)
        ├─ build APK (--release, arm64+arm)  ──┐
        └─ build AAB (--release / shorebird)  ──┴──► GitHub Release (DRAFT): APK + AAB
                                                          │
                                       ANDA menekan Publish │ (gerbang manusia)
                                                          ▼
                                       publish-to-store.yml → Play Console, track `internal`
```

- **APK** → attach ke GitHub Release sebagai **draft** (tidak otomatis publik — harus
  di-publish manual dari dashboard GitHub). Dipakai untuk sideload/fallback.
- **AAB** → attach ke draft **bersama APK**. AAB adalah bukti tersimpan apa yang benar-benar
  dikirim ke Play nanti.
- **Upload ke Play bukan urusan run build.** Ia berjalan di run terpisah,
  `publish-to-store.yml`, hanya setelah manusia menekan Publish, dan hanya untuk tag polos: ia mengunduh AAB dari asset release
  dengan `gh release download`, lalu meng-upload ke track `internal` dengan `status: completed`
  (`§1.1`). Tidak ada Shorebird di sana.
- Pengaman host non-produksi (`.claude/rules/security.md`) hanya diperiksa di APK, bukan
  diulang untuk AAB — alasannya ada di komentar workflow-nya: keduanya dibangun dari source
  dan versi yang identik, jadi memeriksa AAB terpisah memeriksa hal yang sama dua kali.

### 1.1 Upload ke Play (`publish-to-store.yml`) — satu-satunya jalan ke store

```
git tag pos-v1.2.0 && git push origin pos-v1.2.0
        │
        ▼
release-pos.yml → draft GitHub Release (APK + AAB)
        │
        ▼   ANDA menekan Publish di halaman Releases
publish-to-store.yml  (on: release types: [published])
        ├─ gh release download <tag> --pattern '*.aab'
        └─ upload-google-play: track internal, status completed
```

| | Nilai yang berlaku |
| --- | --- |
| Trigger | `release: types: [published]` — **bukan** pembuatan draft. Draft yang belum dipublikasikan memicu apa pun |
| Filter tag | Dua lapis. **Job-level** (`if:`), hanya prefix: tag harus diawali `pos-v`, karena event `release` tidak mendukung filter tag di `on:`. **Langkah shell `tag`**, bentuk persisnya: hanya `pos-vX.Y.Z` polos yang boleh lanjut. Setiap langkah yang menyentuh Play atau asset release memakai `if: steps.tag.outputs.plain == 'true'` |
| Yang diunduh | AAB dari **asset release**, bukan artifact Actions (artifact hidup 30 hari dan butuh `run-id` + token lintas run) |
| Track | `internal`, `status: completed`. Tidak ada pilihan track di CI — lihat §3 |
| Secret | `PLAY_SERVICE_ACCOUNT_JSON` saja. `SHOREBIRD_TOKEN` tidak dibutuhkan: Shorebird sudah selesai di run build, dan tidak ada OTA yang boleh ikut terkirim tanpa dilihat |
| Yang tidak pernah naik | Release staging (`pos-vX.Y.Z-staging.N`); tag patch (`-N`) tidak membuat GitHub release sama sekali |

> [!NOTE]
> Bentuk tag **tidak bisa** ditulis di `if:`. Bahasa ekspresi GitHub Actions hanya punya
> `contains`, `startsWith`, `endsWith`, `format`, `join`, `toJSON`, `fromJSON`, `hashFiles` —
> tidak ada `replace`, tidak ada split, tidak ada regex. Dulu `if:` memakai
> `!contains(replace(tag, 'pos-v', ''), '-')`, dan GitHub menolak mengurai filenya: **push pertama
> ke `main` gagal sebelum workflow apa pun jalan** (2026-10-06).
>
> Satu-satunya jalan keluar yang bisa dibaca, yaitu memeriksa seluruh tag dengan
> `!contains(tag, '-')`, **tidak benar**: prefix `pos-v` sendiri mengandung hyphen, jadi filter itu
> menolak segala tag POS, termasuk tag polos yang justru harus naik. Karena itu pemeriksaan pindah
> ke shell (`[[ "$TAG" =~ ^pos-v[0-9]+\.[0-9]+\.[0-9]+$ ]]`), tempat operator `=~` memang ada.
>
> Tag yang tidak lolos menghasilkan `::notice::`, **bukan** `exit 1`: staging dan patch juga
> menghasilkan rilis, jadi run merah untuk keadaan normal itu noise yang melatih mengabaikan merah.
>
> Test penjaganya ada di
> [`distribution_workflows_test.dart`](../apps/pos/test/branding/distribution_workflows_test.dart):
> setiap fungsi yang dipanggil di keenam file workflow di-assert ada di daftar fungsi resmi GitHub,
> dan regex gerbangnya diuji pada semua empat bentuk tag.

### 1.2 Dispatcher manual (`release-dispatch.yml`) — pintu kedua

Dispatcher **tidak membangun apa pun**. Ia memvalidasi kombinasi input, membuat tag kalau
diminta, lalu memanggil workflow yang sudah ada sebagai reusable workflow (logika build tidak
digabung di sana).

| Input | Nilai |
| --- | --- |
| `aplikasi` | `pos` (hanya itu) |
| `env` | `staging` · `production` · `patch` |
| `device` | `android` · `windows` · `all` |
| `draft release` | `no` = uji coba, artifact saja · `yes` = build + tag + draft release |
| `version` | Wajib bila `draft release = yes` (jadi nama tag). `staging`: `X.Y.Z-staging.N` · `production`: `X.Y.Z` · `patch`: `X.Y.Z-N` |

**Gerbang lebih dulu.** Kombinasi yang tidak ada di matriks ditolak di job `validate` **sebelum**
build jalan, lewat `dart run tools/dev/bin/dev.dart dispatch …`: `::error::` di stderr (annotation
GitHub) plus exit 64. Valid keluar 0 tanpa output. Sumber kebenaran aturan ini adalah fungsi
Dart murni `tools/dev/lib/dispatch.dart` yang diuji `dart test`, bukan rantai `if:` YAML — YAML
tidak bisa diuji di repo ini, jadi aturan akan lapuk diam-diam saat input bertambah.

Kombinasi yang ditolak: `staging` + `windows`/`all` (tidak ada varian windows untuk staging),
`patch` + `windows`/`all`, dan `patch` + `draft release = no` (patch adalah aksi terhadap rilis
yang sudah ada; uji-coba tanpa target tidak punya base, dengan target mendorong OTA ke tablet
production). `draft release = yes` tanpa `version` ditolak untuk semua env.

| env | `device` | draft `no` | draft `yes` |
| --- | --- | --- | --- |
| staging | android | artifact saja, `version` diabaikan | tag `pos-vX.Y.Z-staging.N` + draft berisi APK |
| production | android | **APK saja**, tanpa AAB, tanpa `shorebird release` | tag `pos-vX.Y.Z` + draft berisi APK + AAB; upload ke Play menyusul setelah Publish |
| production | windows | MSIX artifact saja | tag `pos-vX.Y.Z` + draft berisi MSIX |
| production | all | APK + MSIX artifact saja | satu draft berisi APK + AAB + MSIX |
| patch | android | **ditolak** | tag `pos-vX.Y.Z-N`, kirim patch ke base `X.Y.Z`, tanpa draft release |

> [!IMPORTANT]
> Uji-coba production android sengaja **APK saja, tanpa AAB, tanpa `shorebird release`**, dan
> itu struktural, bukan sekadar pilihan. Shorebird menolak dua release untuk versi yang sama:
> kalau uji-coba menjalankan `shorebird release` dengan versi 1.2.0, versi itu tercatat di
> Shorebird dan rilis production 1.2.0 yang sebenarnya **gagal**. Run uji-coba memakan slot
> versi production. Deteksi "versi sudah dipakai Shorebird" tidak bisa dilakukan lokal (repo
> tidak punya akses API Shorebird tanpa network); perlindungannya dua lapis yang jujur:
> struktural (uji-coba tidak pernah memanggil `shorebird release`) plus fail-fast dari Shorebird
> sendiri, yang pesannya menyebut versi yang bentrok.

Dispatcher **menambah** pintu masuk, tidak mengganti: `on.push.tags` tetap ada di keempat workflow
lama, dan eksklusivitas pola tag tetap dikunci test — satu `git push --tags` tidak boleh pernah
memicu dua workflow.

### 1.3 Alur staging (`staging-pos.yml`) — bukan rilis

```
git tag pos-v1.2.0-staging.3 && git push origin pos-v1.2.0-staging.3
        │
        ▼
staging-pos.yml (job tunggal)
        │
        ├─ dart analyze · dart test · flutter test
        ├─ tulis keystore.properties dari secrets (upload key — sama dengan rilis)
        ├─ build APK (--profile, arm64+arm)  ──────────────► GitHub Artifact (arsip 30 hari)
        ├─ pengaman: APK harus punya host staging
        └─ draft GitHub Release              ──────────────► asset: APK staging
```

Perbedaan yang perlu disadari, dan tidak ada yang opsional:

| | Rilis native | Staging |
| --- | --- | --- |
| Build mode | `--release` | **`--profile`** |
| Artefak | APK + AAB | **APK saja** |
| appId | `com.finnesia.pos` | `com.finnesia.pos` (sama) |
| Label launcher | `Finnesia POS` | **`Finnesia POS (tester)`** |
| Host yang dijawab | `apps.finnesia.com` saja | **keduanya** (`apps.finnesia.com` + `apps-dev.finnesia.com`) |
| Signing | upload key, dari secrets CI | **upload key yang sama**, dari secrets CI |
| Store | track `internal`, **dipromosikan** | **tidak ada** |
| GitHub Release | ya (draft, berisi APK **dan** AAB) | **ya (draft, berisi APK saja)** |
| Shorebird | ya (baseline di run build) | **tidak** |

- **Kenapa `--profile`:** build type itu milik Flutter sendiri, dibuat dari debug. Ia sudah
  membawa appId polos dan `dart.vm.product=false` — yang terakhir itulah yang menyalakan host
  staging, pemilih endpoint, dan inspector, **tanpa satu baris kode Dart berubah**.
- **Kenapa APK, bukan AAB:** AAB tidak bisa dipasang di perangkat. Selama ada upload Play itu
  tidak masalah; tanpa upload Play satu-satunya gunanya adalah diunggah manual ke Play Console
  oleh manusia. APK bisa dipasang tester langsung dari asset release.
- **Kenapa dua host:** host production ada di `src/main/` (di-merge semua build type), host
  staging ada di `src/profile/` (hanya dibaca build profile). Manifest merging **menambah**
  filter, jadi hasilnya dua. Diukur dari manifest hasil merge, bukan diasumsikan.
- **Kenapa tanpa Shorebird:** keputusan pemilik — tester harus menguji build native, dan patch
  OTA bisa menutupi bug native. Harganya nyata: tiap perbaikan Dart ke tester = build native
  baru + unggah ulang.
- **Kenapa appId-nya sama dengan production:** ia **bukan app lain**. Konsekuensinya yang harus
  disadari: staging dan production **tidak bisa terpasang berdampingan** di satu perangkat, dan
  yang membedakan keduanya di launcher adalah label `(tester)`.

**Membangunnya secara manual** (tanpa menunggu CI — mis. untuk mencoba di emulator, atau
memeriksa sendiri sebelum membuat tag):

```bash
./dev build staging            # APK profile → apps/pos/build/app/outputs/flutter-apk/
```

`./dev build staging` adalah nama yang enak diketik untuk build type `profile` — appId polos,
perilaku debug, host staging hidup. Ia menghasilkan **APK**, sama seperti yang dibangun CI:

```bash
cd apps/pos && flutter install --profile    # pasang APK profile yang baru dibangun
```

Dua hal yang perlu disadari saat membangun lokal:

- **`keystore.properties` harus ada** di `apps/pos/android/`, sama seperti build rilis. Tanpa
  itu build gagal dengan "Keystore file not set" — disengaja.
- **APK lokal dan APK CI ditandatangani kunci yang sama**, jadi tidak ada uninstall paksa saat
  bergantian. Itu efek dari `named("profile")` di `build.gradle.kts`.

#### Yang di-sign CI, dan yang bukan

**Menandatangani APK** dilakukan **CI.** `ANDROID_KEY_BASE64` / `ANDROID_KEY_ALIAS` /
`ANDROID_KEY_PASSWORD` → `keystore.properties` di `apps/pos/android/`, sama seperti
`release-pos.yml`. Tanpa berkas itu build **gagal** ("Keystore file not set"), bukan diam-diam
memakai debug key.

Signing-nya lewat **upload key yang sama** dengan rilis, karena `profile` diarahkan ke
`signingConfigs.release` (`build.gradle.kts`). Itu disengaja: kalau staging memakai debug key,
APK yang dibangun lokal dan yang dibangun CI akan berbeda penandatangan — dan tiap unggahan
berikutnya memaksa uninstall dulu di tablet tester.

**Kenapa satu kunci saja, bukan kunci staging terpisah.** Staging **bukan app lain**: ia memakai
`applicationId` yang sama (`com.finnesia.pos`), jadi ia adalah **upgrade** dari install
production di tablet yang sama, bukan app kedua. Kunci berbeda tidak menambah isolasi apa pun
untuk app yang sama — tapi menambah satu fingerprint lagi yang harus dicantumkan di
`assetlinks.json` untuk package yang sama. Jadi `staging-pos.yml` memakai **tiga secret yang
persis sama** dengan `release-pos.yml`, tanpa satu pun yang baru.

`deploy/android-files/staging.der` **bukan** kunci staging, walaupun namanya begitu. Ia
sertifikat **publik** tanpa private key (`openssl pkey` → *"Could not find private key"*). Ia
tidak bisa dipakai menandatangani, dan memang tidak perlu (`plan/staging/README.md` §10.1).

Yang perlu diperhatikan sejak upload Play dicabut: **link tester adalah asset release GitHub**,
bukan link Play Console. Tidak ada batas 60 hari dan tidak ada cap 100 pengguna lagi — yang
membatasi siapa yang bisa memasang adalah akses ke repo ini, karena release asset di repo
publik bisa diunduh siapa saja yang tahu URL-nya.

### 1.4 Cara menjalankan dan memverifikasinya

Dispatcher adalah cara paling murah untuk mencoba sebelum menyentuh tag, karena tidak
menulis apa pun di luar Actions.

**Menolak kombinasi di dalam repo, tanpa runner.** Aturan matriksnya adalah fungsi Dart murni
`tools/dev/lib/dispatch.dart`, jadi bisa dijalankan lokal persis seperti di workflow:

```bash
dart run tools/dev/bin/dev.dart dispatch --env staging --device windows --draft yes --version 1.2.0
# ::error:: staging tidak punya varian windows, pakai device=android   (stderr, exit 64)

dart run tools/dev/bin/dev.dart dispatch --env production --device android --draft yes --version 1.2.0
# exit 0, tanpa output
```

**Urutan verifikasi di GitHub Actions (manual, butuh runner).** Untuk `production` /
`android` / `draft release = yes`:

1. Cek run `Release Dispatch` hijau, dan job `validate` tidak memunculkan annotation `::error::`.
2. Cek tag `pos-v1.2.0` **ada dan menunjuk commit yang di-dispatch**. Job `tag` membuatnya
   eksplisit dari `context.sha` justru supaya draft tidak menempel pada commit default branch
   yang salah.
3. Cek draft GitHub Release berisi **dua** asset: `.apk` dan `.aab`. Kalau AAB tidak ada,
   `shorebird release android` tidak jalan.
4. **Anda** menekan Publish. Baru saat itu run `Publish to Store` jalan.
5. Cek `Publish to Store` hijau, lalu AAB-nya benar-benar muncul di Play Console track
   `internal` dengan status `completed`.

**Yang tidak bisa diverifikasi tanpa runner.** Repo ini tidak punya harness workflow dan
`actionlint` tidak terpasang, jadi YAML hanya bisa dibuktikan dengan grep lewat
`distribution_workflows_test.dart`. Yang tetap perlu satu run nyata:

- apakah `workflow_call` benar-benar ter-resolve dan secret eksplisit benar-benar sampai ke
  callee;
- apakah tag yang dibuat dispatcher benar-benar commit yang di-dispatch (langkah 2 di atas);
- apakah `gh release download` menemukan AAB di asset release;
- apakah upload Play benar-benar berhasil (langkah 5).

Urutan run yang cukup dan paling murah: satu `production`/`android`/`no` (artifact saja, tanpa
efek samping) untuk memeriksa langkah 1-3, lalu satu `staging`/`android`/`yes` untuk memeriksa
nama draft, lalu satu Publish sungguhan untuk langkah 5. Tidak ada test yang menggantikan tiga
run itu.

---

## 2. Prasyarat manual (sekali saja)

Pipeline **akan gagal** sampai langkah-langkah ini selesai. Ini bukan bug — Play Developer
API memang menolak package yang belum pernah punya release sama sekali, dan service account
tidak bisa dibuat sebelum ada Play Console account.

### 2.1 Daftar akun Play Console

- [play.google.com/console/signup](https://play.google.com/console/signup) → pilih akun
  **personal**, bayar $25 sekali. Ini otomatis mencakup registrasi Android Developer
  Verification (§0) — tidak ada pendaftaran terpisah yang perlu dilakukan.

### 2.2 Buat app di Play Console

- Package name: **`com.finnesia.pos`** (harus persis sama dengan `applicationId` di
  `apps/pos/android/app/build.gradle.kts`).

### 2.3 Upload manual pertama

- Build AAB sekali secara lokal (`flutter build appbundle --release` di `apps/pos`), lalu
  upload manual ke track **Internal testing** lewat web UI Play Console.
- **Wajib** — tanpa ini, publish lewat API (langkah CI) akan gagal dengan error semacam
  "package tidak ditemukan" karena Play API tidak bisa membuat release pertama untuk
  package yang benar-benar baru.

### 2.4 Buat Service Account untuk Play Developer API

> [!IMPORTANT]
> **"Setup → API access" sudah TIDAK ADA di Play Console.** Versi dokumen ini sebelumnya
> menunjuk ke sana dan itu menyesatkan. Google sudah menghapus langkah "link developer account
> ke GCP project" — dokumentasinya sekarang berbunyi: *"You no longer need to link your
> developer account to a Google Cloud Project in order to access the Google Play Developer
> API."*
>
> Penggantinya: service account di-invite sebagai **user** di Play Console, lewat halaman
> **Users and permissions**.

Finnesia POS sudah punya **GCP project** dari setup Firebase (`plan/firebase/`, langkah F0)
— pakai project yang sama, tidak perlu bikin baru.

**Langkah 1 — aktifkan API di GCP.** Buka [Google Play Developer API di Cloud
Console](https://console.developers.google.com/apis/api/androidpublisher.googleapis.com/)
untuk project itu, lalu klik **Enable**. Tanpa ini, semua panggilan API ditolak.

**Langkah 2 — buat service account dan key-nya.**

1. [Google Cloud Console](https://console.cloud.google.com/iam-admin/serviceaccounts) →
   project yang sama dengan Firebase → **Create service account**. Beri nama, tanpa perlu
   grant role apa pun di GCP.
2. Buka service account itu → tab **Keys** → **Add key → Create new key → JSON**. Unduh
   berkasnya.
3. Catat **email** service account-nya (`nama@project.iam.gserviceaccount.com`) — dipakai di
   langkah berikutnya.

**Langkah 3 — invite service account itu ke Play Console.**

1. Buka halaman **[Users and permissions](https://play.google.com/console/users-and-permissions)**
   (atau dari sidebar Play Console: **Users and permissions**). **Bukan** "Setup".
2. **Invite new users** → tempel **email service account** dari langkah 2.
3. Di bagian **App permissions**, pilih `com.finnesia.pos`, lalu centang izin yang dibutuhkan:
   - **Release apps to testing tracks** — untuk upload AAB ke track `internal`
     (`publish-to-store.yml`). Satu-satunya workflow yang memakai izin ini.
   - Tambahkan izin lain yang Anda perlukan (mis. production release kalau nanti dipromosikan
     manual dari dashboard).

   Sejak 2026-09-28 tidak ada lagi izin untuk Internal app sharing: `staging-pos.yml` tidak
   mengunggah ke Play sama sekali.
4. **Invite user**. Service account langsung aktif — tidak ada email konfirmasi.

> [!NOTE]
> Kalau **Users and permissions** pun tidak terlihat, kemungkinan akun Anda bukan
> **admin** di Play Console — hanya admin yang bisa mengundang user. Itu izin level akun,
> bukan app; minta pemilik akun yang mengerjakan langkah ini.

**Langkah 4 — simpan key-nya sebagai secret.**

Salin **seluruh isi** berkas JSON dari langkah 2 → GitHub Secret
`PLAY_SERVICE_ACCOUNT_JSON` (Settings → Secrets and variables → Actions).

> [!WARNING]
> **Service account tanpa izin akan gagal di step upload, bukan di step auth.** Gejalanya
> "package not found" atau "permission denied" pada `upload-google-play` — bukan error
> kredensial. Kalau itu muncul padahal key-nya benar, periksa Langkah 3 lebih dulu.
> Ini hanya berlaku untuk `publish-to-store.yml`; workflow lain tidak menyentuh Play.

### 2.5 Ringkasan secret yang dibutuhkan CI

| Secret | Isi | Dipakai untuk |
| ------ | --- | -------------- |
| `ANDROID_KEY_BASE64` | base64 satu baris dari `upload-keystore.jks` | signing APK+AAB (rilis **dan** staging) |
| `ANDROID_KEY_ALIAS` | alias di dalam keystore | signing |
| `ANDROID_KEY_PASSWORD` | password keystore | signing |
| `PLAY_SERVICE_ACCOUNT_JSON` | isi JSON key service account (§2.4) | upload AAB ke Play (track `internal`) — **hanya `publish-to-store.yml`** |
| `SHOREBIRD_TOKEN` | API key dari Shorebird console (Account → API keys) | `shorebird release android` di CI — **rilis saja** |

Tiga yang pertama sudah ada (keystore yang sama dengan rilis sebelumnya
— `.claude/rules/project.md` §7.1). `PLAY_SERVICE_ACCOUNT_JSON` dan `SHOREBIRD_TOKEN` baru.

`staging-pos.yml` memakai **tiga** yang pertama dan **tidak** memakai
`PLAY_SERVICE_ACCOUNT_JSON` maupun `SHOREBIRD_TOKEN` — ia tidak menyentuh Store sama sekali.

`windows-pos.yml` **tidak memakai satu secret pun**. Ia tidak butuh signing (Store
menandatangani ulang) dan tidak butuh kredensial Partner Center sejak unggahnya manual.

`publish-to-store.yml` memakai **hanya** `PLAY_SERVICE_ACCOUNT_JSON`, plus `GITHUB_TOKEN` bawaan
untuk `gh release download`. Ia tidak memakai `SHOREBIRD_TOKEN`: Shorebird sudah selesai di run
build, dan tidak ada OTA yang boleh ikut terkirim tanpa dilihat.

> [!NOTE]
> **Secret Entra tidak lagi dipakai.** `AZURE_AD_TENANT_ID`, `AZURE_AD_APPLICATION_CLIENT_ID`,
> `AZURE_AD_APPLICATION_SECRET`, `SELLER_ID`, dan variabel `MSSTORE_PRODUCT_ID` hanya dibutuhkan
> kalau unggah Windows dikembalikan ke otomatis. Kalau belum pernah dibuat, tidak ada yang perlu
> dikerjakan.

---

## 3. Promosi rilis — kenapa CI cuma ke `internal`

CI **tidak** memilih track. Setiap rilis dari tag selalu masuk ke `internal`, lalu
**dipromosikan manual** ke track berikutnya lewat Play Console (tombol "Promote release") —
**bukan** di-build ulang per track. Artifact yang sudah divalidasi di `internal` harus jadi
artifact yang sama persis yang jalan di `production`.

```
internal (setelah draft di-Publish, `publish-to-store.yml`)
   │  promote manual, kapan pun siap
   ▼
closed (butuh 12 tester opt-in, 14 hari BERTURUT-TURUT — SEKALI, bukan tiap rilis)
   │  apply "Production access" di dashboard setelah syarat di atas terpenuhi
   ▼
production, set "unlisted" (tidak muncul di pencarian, tapi installable lewat link)
```

- **Internal testing**: cap 100 tester, tanpa review, live dalam menit. Tidak dihitung
  menuju syarat Production.
- **Closed testing**: inilah yang menyumbang ke syarat 12-tester/14-hari untuk akun
  **personal** baru (dikurangi dari 20 tester per Desember 2024). Sekali lolos, status
  "Production access" itu **permanen** untuk akun — tidak diulang tiap rilis berikutnya.
- **Production (unlisted)**: opsi publish tanpa listing publik. Track ini yang dipakai
  jangka panjang untuk model self-install tenant — tenant baru cukup dapat link, install
  sendiri, update berikutnya otomatis lewat Play Store.

Setelah akun sudah punya Production access, rilis berikutnya tinggal di-promote langsung
dari `internal` ke `production` tanpa lewat `closed` lagi.

Sumber: [Set up an open, closed, or internal test](https://support.google.com/googleplay/android-developer/answer/9845334?hl=en),
[App testing requirements for new personal developer accounts](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en).

---

## 4. OTA (Shorebird)

### 4.1 Empat pola tag, saling eksklusif, dengan prefix aplikasi

`shorebird init` sudah dijalankan di `apps/pos` — `apps/pos/shorebird.yaml` (berisi
`app_id`) sudah ada dan tercatat di git. **Satu** app Shorebird; staging tidak memakainya.

Repo ini **monorepo** dan akan memuat aplikasi lain, jadi tag diberi prefix aplikasi: `pos-`
menandakan workflow POS, dan versi yang dibaca adalah `1.2.0` — baik `pos-` maupun `v` tidak ikut
ke nilai versi. Aplikasi lain memakai prefix sendiri dan tidak menyentuh workflow ini.

Ada **empat** pola tag (Windows ikut tag polos, job terpisah), semuanya
`pos-vMAJOR.MINOR.PATCH`-berbasis supaya tetap satu skema penomoran versi — bedanya cuma
akhiran:

| Tag | Workflow | Apa yang terjadi | `versionCode` naik? |
| --- | -------- | ----------------- | -------------------- |
| `pos-v1.2.0` (polos) | `release-pos.yml` | Rilis native: APK **dan** AAB → asset **draft** GitHub Release, **dan** `shorebird release android` mendaftarkan versi ini sebagai target patch. Upload AAB ke Play track `internal` **tidak** terjadi di sini: ia berjalan di `publish-to-store.yml` setelah draft dipublikasikan | Ya |
| `pos-v1.2.0` (polos, job lain) | `windows-pos.yml` | MSIX → **draft GitHub Release yang sama**; unggah ke Partner Center manual | Ya (nomor sama) |
| `pos-v1.2.0-5` (`-N` nomor patch) | `shorebird-patch.yml` | Kirim patch Dart-only ke rilis `pos-v1.2.0` yang **sudah ada** — tidak ada build native baru, tidak ada upload Play | **Tidak sama sekali** |
| `pos-v1.2.0-staging.3` (`-staging.N`) | `staging-pos.yml` | APK staging (`--profile`) → draft GitHub Release. **Tidak pernah membangun AAB**, jadi tidak ada Play dan tidak ada Shorebird | Nilai sama dengan rilis versi itu |

Keempat pattern trigger (`on.push.tags`) sengaja dibuat **saling eksklusif** supaya satu tag
yang di-push tidak pernah memicu lebih dari satu workflow, dan tidak pernah lolos ke workflow
yang salah. Dua di antaranya (`release-pos.yml`, `windows-pos.yml`) memang memicu di tag yang
sama — itu disengaja, karena Windows ikut satu nomor versi dan menulis satu GitHub Release
yang sama. Eksklusivitas itu **tidak berubah** ketika dispatcher ditambahkan: `release-dispatch.yml`
menambah pintu `workflow_dispatch` + `workflow_call`, dan tidak menyentuh satu karakter pun
dari pola `on.push.tags` yang ada.

Pola positifnya ditulis lebar (`...*`) dan eksklusinya ditulis eksplisit sebagai negasi
(`!...`), bukan diserahkan pada asumsi bahwa GitHub meng-anchor pola ke seluruh nama ref:

| Workflow | Pola |
| --- | --- |
| `release-pos.yml` | `pos-v[0-9]+.[0-9]+.[0-9]+*` lalu `!pos-v[0-9]+.[0-9]+.[0-9]+-*` |
| `windows-pos.yml` | sama dengan `release-pos.yml` |
| `shorebird-patch.yml` | `pos-v[0-9]+.[0-9]+.[0-9]+-[0-9]+*` lalu `!pos-v[0-9]+.[0-9]+.[0-9]+-staging.*` |
| `staging-pos.yml` | `pos-v[0-9]+.[0-9]+.[0-9]+-staging.[0-9]+*` |

Urutan penting: negasi harus **setelah** pola positifnya, karena pola positif yang menyusul
negasi akan memasukkan ref itu kembali. Eksklusivitas keempatnya dikunci test
(`apps/pos/test/branding/distribution_workflows_test.dart`), termasuk tag yang harus memicu
**nol** workflow (mis. `pos-v1.2.0-rc.1`, atau `v1.2.0` tanpa prefix).

> [!NOTE]
> **Ini menutup lubang lama.** Pola sebelumnya ditulis tanpa `$` dan tanpa negasi, jadi
> `v1.2.0-5-beta` akan ikut memicu workflow rilis native. Sekarang bentuk yang tidak dikenal
> diabaikan, bukan dipublikasikan.

**Kenapa ini penting, bukan sekadar rapi:** kalau perubahan Dart-only dikirim lewat
`release-pos.yml` (tag polos baru) alih-alih `shorebird-patch.yml`, `versionCode` tetap
naik walau isinya cuma Dart — dan banner Play In-App Update (§5) akan salah muncul untuk
sesuatu yang sebenarnya bukan update native. Aturannya sederhana: **tag polos = ada
perubahan native (atau memang sengaja mau rilis native baru). Tag `-N` = Dart-only,
lewat Shorebird saja. Tag `-staging.N` = artefak internal, bukan rilis.**

### 4.1.1 Guard: menolak tag `-N` yang ternyata menyentuh native

`shorebird-patch.yml` **tidak percaya begitu saja** bahwa sebuah tag `-N` benar-benar
Dart-only. Sebelum mengirim patch, ia membandingkan (`git diff --name-only`) commit yang
di-tag terhadap tag rilis native dasarnya (`pos-v1.2.0` untuk tag `pos-v1.2.0-5`), dan **gagal
dengan pesan jelas** kalau ada perubahan di:

- `apps/pos/android/**` — kode/konfigurasi native diedit langsung.
- `pubspec.lock` (root) — dependency apa pun naik/turun versi atau ditambah, di package
  mana pun di workspace, yang bisa diam-diam membawa plugin native baru tanpa menyentuh
  `apps/pos/pubspec.yaml` sama sekali.

Ini **heuristik**, bukan bukti mutlak — tapi menangkap kelas kesalahan paling umum: kasus
"saya kira ini cuma Dart, ternyata ikut kebawa perubahan lain". Shorebird sendiri juga
punya pengaman serupa (asset-diff check, ditolak kecuali `--allow-asset-diffs`), tapi itu
baru ketahuan **setelah** build — guard ini gagal lebih awal dan menyebut persis berkas
mana yang mencurigakan.

**Prasyarat guard ini:** tag rilis native dasarnya (`pos-v1.2.0`) harus sudah ada di git
(sudah pernah di-push lewat `release-pos.yml`) — kalau belum, workflow gagal dengan pesan
"tag rilis native dasar tidak ditemukan", bukan diam-diam lanjut.

### 4.2 Notifikasi update dalam app

App sekarang memakai `package:shorebird_code_push` (`apps/pos/pubspec.yaml`) lewat port
`UpdaterPort` (`packages/pn_types/lib/src/native/updater_port.dart`,
`.claude/rules/native-ports.md`), sama seperti port native lain di repo ini.

Begitu app selesai boot, `PosApp` (`apps/pos/lib/app/pos_app.dart`) memanggil
`updater.checkForUpdate()` sekali — tidak memblokir apa pun, fire-and-forget. Kalau
statusnya `restartRequired` (patch sudah selesai diunduh, tinggal restart), muncul
**banner dalam app** — padanan langsung dari notifikasi update Play Store/Telegram yang
pemilik sebut, hanya saja ini jalan lewat Shorebird sendiri dan **tidak bergantung sama
sekali pada Play Console** sudah siap atau belum.

Banner ini murni informasional (`_UpdateBanner`) — tidak me-restart app sendiri (tidak
ada cara cross-platform yang bersih tanpa plugin tambahan), patch-nya sudah otomatis
aktif begitu app kebetulan direstart (buka ulang, ganti shift, dll).

**"Production saja" terjamin tanpa guard tambahan**: `checkForUpdate()` milik
`shorebird_code_push` sendiri menjawab `unavailable` pada build apa pun yang bukan hasil
`shorebird release` (debug, atau `flutter build` biasa) — `ShorebirdUpdaterPort`
memetakan itu ke `upToDate`, jadi banner tidak pernah muncul di luar rilis production
tanpa perlu `kReleaseMode` check manual di kode app.

### 4.3 Cara kirim patch Dart-only

```bash
git tag pos-v1.2.0-5   # base rilis pos-v1.2.0 sudah ada, ini patch ke-5 di atasnya
git push origin pos-v1.2.0-5
```

`shorebird-patch.yml` (§4.1) menjalankan `shorebird patch android
--release-version=1.2.0+1002000` (base version + build number, dihitung otomatis dari
tag) — **tanpa** lewat Play Store atau review apa pun, didistribusikan lewat server
Shorebird sendiri, aktif setelah restart app berikutnya. Hanya kode Dart yang bisa
di-patch — perubahan plugin native, permission Android, atau upgrade Flutter SDK tetap
wajib lewat rilis native (`release-pos.yml`), dan guard di §4.1.1 menolaknya lebih awal
kalau tercampur. Sama seperti `shorebird release`, Shorebird **tidak pernah** aktif di
build debug/profile — patch OTA murni fitur build release.

### 4.4 Mematikan Shorebird sepenuhnya

Kalau suatu saat diputuskan berhenti pakai Shorebird (kembali ke rilis native 100%):

1. Hapus file **`.github/workflows/shorebird-patch.yml`** sepenuhnya — seluruh isinya
   khusus Shorebird, tidak ada bagian yang perlu dipertahankan.
2. Di `release-pos.yml`: hapus step **"Setup Shorebird"** dan **"Build release AAB
   (shorebird release android)"**, ganti dengan `flutter build appbundle --release`
   biasa — caranya sudah ditulis persis sebagai komentar tepat di atas kedua step itu,
   tinggal copy-paste. Tidak ada bagian lain di workflow itu yang perlu diubah.

Di sisi app, cukup berhenti mengoper `updater:` ke `PosApp` di `main.dart` (atau hapus
`shorebird_code_push` dari `pubspec.yaml` dan folder `apps/pos/lib/native/updater/`
sekalian) — `updater` bersifat opsional (`UpdaterPort?`), jadi tidak ada tempat lain
yang wajib diubah.

`staging-pos.yml` **tidak perlu diubah** oleh ini: ia tidak pernah memakai Shorebird, dan
build `--profile` sudah dipetakan ke `upToDate` oleh `ShorebirdUpdaterPort` sendiri.

Sumber: [GitHub Integration | Shorebird](https://docs.shorebird.dev/code-push/ci/github/),
[API Keys | Shorebird](https://docs.shorebird.dev/account/api-keys/),
[Create a Release | Shorebird](https://docs.shorebird.dev/code-push/release/).

---

## 5. Notifikasi update native (Play In-App Update)

Ini **berbeda** dari §4 — jangan disamakan. Dua sistem terpisah, dua port terpisah,
dan keduanya **tidak bisa saling salah tampil** — dijaga di dua lapis: saat CI (§4.1.1,
tag `-N` ditolak kalau menyentuh native) dan saat runtime (`versionCode` yang tidak
pernah berubah lewat patch Shorebird, dibuktikan test-nya):

| | §4 Shorebird | §5 ini |
| --- | --- | --- |
| Yang diperbarui | Kode Dart saja | APK/AAB baru (native) |
| Sumber sinyal | Server Shorebird | `versionCode` yang Play Store sudah publikasikan |
| Port | `UpdaterPort` | `NativeUpdatePort` |
| Butuh Play Console live? | Tidak | **Ya** — baru benar-benar memicu begitu app live di track apa pun |

**Kenapa tidak bisa tertukar, dijamin secara struktur, bukan cuma disiplin kode:** patch
Shorebird **tidak pernah mengubah `versionCode` APK yang ter-install**. `NativeUpdatePort`
hanya baca `versionCode` yang Play Store tahu — jadi patch Dart-only **tidak mungkin**
terdeteksi sebagai "ada update native" oleh API Play sama sekali. Dibuktikan dengan test
(`pos_app_test.dart`, grup "the native update banner"): drive sisi Shorebird ke
`restartRequired`, banner native tetap tidak muncul.

> [!NOTE]
> **Hazard lama di sini sudah tidak berlaku, dan alasannya berubah.** Catatan sebelumnya
> mengkhawatirkan tablet tester yang memasang staging dari Play Console ditawari **build
> production** oleh `NativeUpdatePort`, karena appId-nya sama dan artefak app sharing tidak
> pernah masuk track.
>
> Sejak 2026-09-28 staging **tidak lagi lewat Play**: APK-nya diunduh dari release asset dan
> dipasang sebagai sideload. `package:in_app_update` menyatakan hanya bekerja untuk app yang
> terpasang lewat Play Store, jadi jalur itu hilang.
>
> Yang **belum diukur**, dan sisa satu-satunya: tablet yang **sudah** punya production dari Play
> lalu ditimpa APK staging (appId dan kunci sama, jadi itu memang sebuah upgrade). Installer of
> record-nya berubah jadi sideload, dan yang diharapkan adalah banner itu berhenti menyala —
> tapi itu belum diuji di perangkat.

### 5.1 Implementasi

- Package: `in_app_update` (wrapper `package:in_app_update` untuk Play Core
  `AppUpdateManager`) — `apps/pos/pubspec.yaml`.
- Port: `NativeUpdatePort` (`packages/pn_types/lib/src/native/native_update_port.dart`),
  implementasi nyata `PlayNativeUpdatePort`
  (`apps/pos/lib/native/native_update/native_update_play.dart`), sama pola dengan port
  native lain di repo ini.
- Mode **Flexible**, bukan Immediate: download di background, cashier tidak diinterupsi
  mid-transaksi. Begitu selesai unduh, muncul banner in-app dengan tombol **"Pasang"** —
  beda dari banner Shorebird (§4.2) yang murni informasional, ini punya aksi karena
  memasang APK baru = restart app, dan itu harus keputusan kasir, bukan otomatis.
- **Tidak bisa diuji lokal** — `package:in_app_update` sendiri menyatakan ini hanya jalan
  pada app yang terpasang **lewat** Play Store. Sebelum Play Console live, `checkForUpdate()`
  akan selalu gagal dengan aman (ditangkap, dipetakan ke `upToDate`) — kodenya sudah siap,
  tinggal "diam" sampai app live di track apa pun (`internal` sudah cukup untuk memicunya,
  tidak perlu `production`).

Sumber: [in_app_update | Dart package](https://pub.dev/packages/in_app_update).
