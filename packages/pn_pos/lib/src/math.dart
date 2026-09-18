/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// Internal helpers shared by the POS maths modules.
///
/// Not exported from `pn_pos.dart`: these are implementation details of the ported
/// logic, not part of the package's public surface.
///
/// > [!WARNING]
/// > **Tidak ada yang memakai file ini.** `pos_calculations.dart` dan `pos_tender.dart`
/// > memakai `dart:math` `max` langsung. Dua fungsi di bawah disimpan, bukan dipakai.
/// > Kalau memang tidak dibutuhkan, hapus file ini.
library;

/// `Math.max(a, b)` from JavaScript, for two numbers.
///
/// `num` rather than `double` on purpose. The TypeScript source works in plain
/// numbers, and the port must not silently change integer behaviour — the oracle
/// expects `18000`, not `18000.0`.
///
/// > [!CAUTION]
/// > **Ini BUKAN padanan `Math.max`.** Diverifikasi dengan menjalankan keduanya:
/// > `maxNum(NaN, 0)` mengembalikan `0`, sedangkan `Math.max(NaN, 0)` mengembalikan
/// > `NaN`. Bedanya muncul saat NaN ada di argumen **pertama** — `a > b` bernilai
/// > `false` untuk NaN, jadi fungsi ini mengembalikan `b`.
/// >
/// > `dart:math` `max` justru yang cocok dengan JavaScript: ia mengembalikan `NaN`
/// > bila salah satu argumen NaN. Jadi memakai `dart:math` `max` lebih benar, bukan
/// > sekadar lebih ringkas.
num maxNum(num a, num b) => a > b ? a : b;

/// `Math.min(a, b)` from JavaScript, for two numbers.
///
/// > [!CAUTION]
/// > **Komentar ini sebelumnya salah, dan sudah dikoreksi 2026-09-19.** Klaim lamanya:
/// > *"`dart:math`'s `min` throws on NaN"*. Itu **tidak benar** — dijalankan dan
/// > hasilnya `NaN`, tidak melempar apa pun.
/// >
/// > Yang sebenarnya terjadi justru kebalikannya: `dart:math` `min` **cocok** dengan
/// > `Math.min` JavaScript (mengembalikan `NaN` bila ada argumen NaN), sedangkan
/// > `minNum` **menyimpang** saat NaN ada di argumen pertama — `minNum(NaN, 0)`
/// > mengembalikan `0`, sementara `Math.min(NaN, 0)` mengembalikan `NaN`.
///
/// Jangan menulis klaim tentang perilaku stdlib tanpa menjalankannya dulu.
/// `.claude/rules/patterns.md` §3.1.
num minNum(num a, num b) => a < b ? a : b;
