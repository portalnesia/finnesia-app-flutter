---
description: Git rules — whitelist read-only, larangan keras menulis state
tools: "*"
alwaysApply: true
paths:
  - "**/*.dart"
  - "**/*.yaml"
  - "**/*.arb"
  - "**/*.kts"
  - "**/*.xml"
---

# Git Rules — STRICT

> **Read-only git DIIZINKAN. Semua command git yang menulis/mengubah state DILARANG KERAS.**
> Tidak ada toleransi, tidak ada pengecualian.

Aturan ini berlaku mutlak di repo ini. Ia tidak boleh dilonggarkan, disesuaikan, atau dianggap
"hampir sama" dengan aturan mana pun di tempat lain — salinan yang menyimpang adalah salinan yang
membusuk.

## 0. Aturan Mutlak

### 0.1 Diizinkan — read-only, TANPA perlu izin user, HARUS persis salah satu dari whitelist ini

- `git status`
- `git diff` (semua varian read-only; tidak boleh dipakai untuk `git apply` atau di-pipe ke command yang menulis)
- `git log` (termasuk `--oneline`, `-n`, `--stat`, `-- <path>`, dll)
- `git show` (termasuk `git show <ref>:<path>`)
- `git blame`
- `git branch` (list saja — TANPA `-D`/`-d`/`-m`/`-M`)
- `git remote -v`
- `git tag` (list saja — TANPA `-d`)
- `git ls-files`
- `git rev-parse`
- `git describe`
- `git --version`

Command di atas boleh dipakai kapan saja untuk orientasi — cek file apa yang berubah,
bandingkan versi, cek branch aktif.

### 0.2 DILARANG KERAS — apa pun yang menulis/memodifikasi state

Apa pun yang **tidak** ada di whitelist §0.1 = dilarang. Termasuk:

- `git add`, `git rm --cached`, `git restore`, `git checkout -- <file>`, `git checkout <branch>`
- **Seluruh keluarga `git stash`** — `stash`, `stash push`, `stash pop`, `stash apply`, `stash drop`,
  **termasuk `stash list` dan `stash show`**. Keluarga ini dilarang penuh supaya tidak ada celah
  "cuma mau lihat dulu" yang berlanjut ke `push`/`pop`/`drop`. Alasan lengkapnya di §1.
- `git commit`, `git push`, `git reset`, `git clean` (termasuk `-n`/dry-run — nama command-nya
  sendiri sudah destruktif), `git gc`, `git prune`
- `git branch -D`/`-d`/`-m`, `git rebase`, `git merge`, `git cherry-pick`, `git apply`, `git am`
- Command di luar whitelist §0.1 yang belum dibahas di sini. **Kalau ragu, anggap dilarang** —
  jangan diinterpretasikan sendiri.

Kalau sebuah task tampaknya membutuhkan operasi git yang menulis (commit, push, stash, reset),
**berhenti dan tanyakan user** — kecuali user sudah eksplisit memintanya di prompt saat itu
(mis. task "buatkan commit" atau "push branch ini"). Jangan melakukannya atas inisiatif sendiri
dengan alasan apa pun.

## 1. Mengapa Aturan Ini Seketat Ini

`git stash` terlihat seperti operasi baca-tulis yang aman. Ia bukan — dan kerusakannya tidak bisa
dibatalkan. Empat langkah berikut semuanya tampak wajar saat dijalankan, dan bersama-sama mereka
menghancurkan pekerjaan yang belum di-commit:

1. `git rm --cached` pada 2 berkas — mengubah index
2. `git stash push --keep-index` pada repo dengan puluhan berkas uncommitted milik user
3. `git stash pop` → gagal sebagian, meninggalkan **conflict marker** di dalam berkas source
4. `git stash drop` → **menghapus satu-satunya cadangan** saat konflik belum selesai

Hasilnya: pekerjaan user rusak, dan test berhenti dengan `[setup failed]` karena marker
`<<<<<<<` tertinggal di dalam berkas source. Marker itu bukan komentar — ia kode yang tidak bisa
di-parse.

Yang wajib diingat:

- **Niat baik tidak mengurangi risiko.** "Cuma mau cek baseline" tetap bisa menghancurkan
  working tree.
- **`git stash` pada repo dengan uncommitted work bukan operasi reversible yang aman.** Pop bisa
  konflik, dan konflik menulis marker ke dalam berkas source.
- **`git stash drop` adalah titik tanpa kembali.** Jangan pernah drop saat masih ada konflik.
- **Read-only genuine (status/diff/log/show/blame) tidak pernah jadi masalah** di sini — yang
  jadi masalah adalah `stash`, yang cuma *terdengar* seperti operasi aman. Karena itu whitelist
  §0.1 ditulis per-command, bukan sebagai kategori umum "read-only" yang bisa disalahartikan
  mencakup `stash list`.

## 2. Yang Boleh Dilakukan Sebagai Gantinya

| Kebutuhan | Jangan | Pakai ini |
| --------- | ------ | --------- |
| Cek apakah failure sudah ada sebelum perubahan | `git stash` | Laporkan failure beserta output lengkap, minta user memutuskan |
| Lihat isi file di commit lain | `stash` + `checkout` | `git show <ref>:<path>` |
| Bandingkan working tree dengan HEAD | — | `git diff` |
| Bandingkan dua commit/branch | — | `git diff <ref1> <ref2>`, `git log`, `git show` |
| Butuh commit/push/reset | — | Tanya user dulu |

## 3. Verifikasi Sebelum Menjalankan Command Git Apa Pun

Cocokkan dulu terhadap whitelist §0.1 **persis** — bukan "kelihatannya read-only":

- **Command berantai:** `cd x && git status` — command git-nya sendiri tetap harus dicek.
- **Pipe:** `git log ... | grep ...` — boleh, `git log` ada di whitelist.
- **Subshell:** `$(git rev-parse ...)` — boleh, `git rev-parse` ada di whitelist.
- **Cek FLAG-nya juga, bukan cuma nama command dasarnya.** `git branch` boleh; `git branch -D` tidak.
- `git fetch` dan `git pull` **tidak** ada di whitelist — tetap butuh izin user dulu.

## 4. Catatan Khusus Repo Ini

- **Tidak ada submodule dan tidak ada remote tambahan.** Repo ini berdiri sendiri.
- Perubahan yang dibutuhkan repo lain dikerjakan **di repo itu**, bukan lewat git dari sini.
  Lihat `.claude/rules/cross-repo.md`.
- Karena tidak ada mekanisme sinkronisasi otomatis, satu-satunya cara kode dari repo lain masuk
  ke sini adalah **salin manual yang disengaja** — dan salinan itu wajib tercatat di
  `.claude/rules/cross-repo.md` §5.

## 5. Sanksi

Menjalankan command git yang **menulis/memodifikasi state** tanpa instruksi eksplisit user =
**langsung dianggap merusak task**, terlepas dari apakah kerusakan benar-benar terjadi.
Command read-only di luar whitelist §0.1 juga tetap butuh izin dulu — kalau memang rutin
dibutuhkan, minta user menambahkannya ke whitelist ini, jangan dijalankan duluan lalu tanya
belakangan.
