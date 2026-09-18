import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L10n
/// returned by `L10n.of(context)`.
///
/// Applications need to include `L10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L10n.localizationsDelegates,
///   supportedLocales: L10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L10n.supportedLocales
/// property.
abstract class L10n {
  L10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L10n of(BuildContext context) {
    return Localizations.of<L10n>(context, L10n)!;
  }

  static const LocalizationsDelegate<L10n> delegate = _L10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @appName.
  ///
  /// In id, this message translates to:
  /// **'Finnesia POS'**
  String get appName;

  /// No description provided for @shiftLoadFailed.
  ///
  /// In id, this message translates to:
  /// **'Belum bisa membaca data shift. Periksa koneksi lalu coba lagi.'**
  String get shiftLoadFailed;

  /// No description provided for @shiftRequiredTitle.
  ///
  /// In id, this message translates to:
  /// **'Buka shift dulu'**
  String get shiftRequiredTitle;

  /// No description provided for @shiftRequiredDesc.
  ///
  /// In id, this message translates to:
  /// **'Hitung uang di laci, lalu masukkan sebagai modal awal sebelum mulai berjualan.'**
  String get shiftRequiredDesc;

  /// No description provided for @shiftOpeningCashLabel.
  ///
  /// In id, this message translates to:
  /// **'Modal awal'**
  String get shiftOpeningCashLabel;

  /// No description provided for @shiftOpenButton.
  ///
  /// In id, this message translates to:
  /// **'Buka shift'**
  String get shiftOpenButton;

  /// No description provided for @shiftKeypadBackspace.
  ///
  /// In id, this message translates to:
  /// **'Hapus angka'**
  String get shiftKeypadBackspace;

  /// No description provided for @shiftOpenUnavailable.
  ///
  /// In id, this message translates to:
  /// **'Belum bisa menghubungi server. Periksa koneksi lalu coba lagi.'**
  String get shiftOpenUnavailable;

  /// No description provided for @shiftOpening.
  ///
  /// In id, this message translates to:
  /// **'Membuka shift…'**
  String get shiftOpening;

  /// No description provided for @shiftOpenTitle.
  ///
  /// In id, this message translates to:
  /// **'Shift masih terbuka'**
  String get shiftOpenTitle;

  /// No description provided for @shiftOpenDesc.
  ///
  /// In id, this message translates to:
  /// **'Sudah ada shift terbuka di outlet ini. Lanjutkan shift itu untuk mulai berjualan.'**
  String get shiftOpenDesc;

  /// No description provided for @shiftOpenStaleDesc.
  ///
  /// In id, this message translates to:
  /// **'Shift ini masih terbuka. Periksa dulu angka di bawah sebelum melanjutkannya.'**
  String get shiftOpenStaleDesc;

  /// No description provided for @shiftNumberLabel.
  ///
  /// In id, this message translates to:
  /// **'Nomor shift'**
  String get shiftNumberLabel;

  /// No description provided for @shiftOpenedAtLabel.
  ///
  /// In id, this message translates to:
  /// **'Dibuka'**
  String get shiftOpenedAtLabel;

  /// No description provided for @shiftCashierLabel.
  ///
  /// In id, this message translates to:
  /// **'Kasir'**
  String get shiftCashierLabel;

  /// No description provided for @shiftHeldTitle.
  ///
  /// In id, this message translates to:
  /// **'Shift dipegang kasir lain'**
  String get shiftHeldTitle;

  /// No description provided for @shiftUnknownCashier.
  ///
  /// In id, this message translates to:
  /// **'kasir lain'**
  String get shiftUnknownCashier;

  /// No description provided for @shiftContinue.
  ///
  /// In id, this message translates to:
  /// **'Lanjutkan shift {number}'**
  String shiftContinue(String number);

  /// No description provided for @shiftHeldDesc.
  ///
  /// In id, this message translates to:
  /// **'Shift {number} dibuka oleh {cashier} dan belum ditutup. Shift itu perlu ditutup dulu sebelum Anda bisa berjualan di outlet ini.'**
  String shiftHeldDesc(String number, String cashier);

  /// No description provided for @tillSearchHint.
  ///
  /// In id, this message translates to:
  /// **'Cari produk atau pindai barcode'**
  String get tillSearchHint;

  /// No description provided for @tillCategoryAll.
  ///
  /// In id, this message translates to:
  /// **'Semua'**
  String get tillCategoryAll;

  /// No description provided for @tillCatalogLoadFailed.
  ///
  /// In id, this message translates to:
  /// **'Belum bisa membaca daftar produk. Periksa koneksi lalu coba lagi.'**
  String get tillCatalogLoadFailed;

  /// No description provided for @tillNoProducts.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada produk'**
  String get tillNoProducts;

  /// No description provided for @tillNoProductsDesc.
  ///
  /// In id, this message translates to:
  /// **'Coba kata kunci atau kategori lain.'**
  String get tillNoProductsDesc;

  /// No description provided for @tillOutOfStock.
  ///
  /// In id, this message translates to:
  /// **'Habis'**
  String get tillOutOfStock;

  /// No description provided for @tillCartTitle.
  ///
  /// In id, this message translates to:
  /// **'Keranjang'**
  String get tillCartTitle;

  /// No description provided for @tillCartEmpty.
  ///
  /// In id, this message translates to:
  /// **'Keranjang kosong'**
  String get tillCartEmpty;

  /// No description provided for @tillCartEmptyDesc.
  ///
  /// In id, this message translates to:
  /// **'Ketuk produk atau pindai barcode untuk menambahkannya.'**
  String get tillCartEmptyDesc;

  /// No description provided for @tillClearCart.
  ///
  /// In id, this message translates to:
  /// **'Kosongkan'**
  String get tillClearCart;

  /// No description provided for @tillClearTitle.
  ///
  /// In id, this message translates to:
  /// **'Kosongkan keranjang?'**
  String get tillClearTitle;

  /// No description provided for @tillClearDesc.
  ///
  /// In id, this message translates to:
  /// **'Semua item di keranjang akan dihapus.'**
  String get tillClearDesc;

  /// No description provided for @tillSubtotal.
  ///
  /// In id, this message translates to:
  /// **'Subtotal'**
  String get tillSubtotal;

  /// No description provided for @tillDiscount.
  ///
  /// In id, this message translates to:
  /// **'Diskon'**
  String get tillDiscount;

  /// No description provided for @tillTotal.
  ///
  /// In id, this message translates to:
  /// **'Total'**
  String get tillTotal;

  /// No description provided for @tillUndo.
  ///
  /// In id, this message translates to:
  /// **'Urungkan'**
  String get tillUndo;

  /// No description provided for @tillLookupFailed.
  ///
  /// In id, this message translates to:
  /// **'Belum bisa mencari produk itu. Periksa koneksi lalu coba lagi.'**
  String get tillLookupFailed;

  /// No description provided for @tillItemCount.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} item}}'**
  String tillItemCount(int count);

  /// No description provided for @tillQtyLess.
  ///
  /// In id, this message translates to:
  /// **'Kurangi jumlah {name}'**
  String tillQtyLess(String name);

  /// No description provided for @tillQtyMore.
  ///
  /// In id, this message translates to:
  /// **'Tambah jumlah {name}'**
  String tillQtyMore(String name);

  /// No description provided for @tillRemoveLine.
  ///
  /// In id, this message translates to:
  /// **'Hapus {name}'**
  String tillRemoveLine(String name);

  /// No description provided for @tillLineRemoved.
  ///
  /// In id, this message translates to:
  /// **'{name} dihapus'**
  String tillLineRemoved(String name);

  /// No description provided for @tillStatusCashier.
  ///
  /// In id, this message translates to:
  /// **'Kasir: {name}'**
  String tillStatusCashier(String name);

  /// No description provided for @tillStatusShift.
  ///
  /// In id, this message translates to:
  /// **'Shift {number}'**
  String tillStatusShift(String number);

  /// No description provided for @tillStatusQueue.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} belum terkirim}}'**
  String tillStatusQueue(int count);

  /// No description provided for @tillStatusQueueFailed.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} belum terkirim, ada yang gagal}}'**
  String tillStatusQueueFailed(int count);

  /// No description provided for @tillCodeNotFound.
  ///
  /// In id, this message translates to:
  /// **'Produk dengan kode {code} tidak ditemukan.'**
  String tillCodeNotFound(String code);

  /// No description provided for @commonRetry.
  ///
  /// In id, this message translates to:
  /// **'Coba lagi'**
  String get commonRetry;

  /// No description provided for @commonLoading.
  ///
  /// In id, this message translates to:
  /// **'Memuat…'**
  String get commonLoading;

  /// No description provided for @bootFailed.
  ///
  /// In id, this message translates to:
  /// **'Data perangkat belum bisa dibuka. Pairing tablet ini tidak dihapus. Coba lagi.'**
  String get bootFailed;

  /// No description provided for @commonCancel.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In id, this message translates to:
  /// **'Tutup'**
  String get commonClose;

  /// No description provided for @commonSave.
  ///
  /// In id, this message translates to:
  /// **'Simpan'**
  String get commonSave;

  /// No description provided for @commonSaving.
  ///
  /// In id, this message translates to:
  /// **'Menyimpan...'**
  String get commonSaving;

  /// No description provided for @commonLoadFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat data'**
  String get commonLoadFailed;

  /// No description provided for @commonSaveFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal menyimpan data'**
  String get commonSaveFailed;

  /// No description provided for @commonDelete.
  ///
  /// In id, this message translates to:
  /// **'Hapus angka terakhir'**
  String get commonDelete;

  /// No description provided for @commonLanguageId.
  ///
  /// In id, this message translates to:
  /// **'Indonesia'**
  String get commonLanguageId;

  /// No description provided for @commonLanguageEn.
  ///
  /// In id, this message translates to:
  /// **'English'**
  String get commonLanguageEn;

  /// No description provided for @commonLanguageLabel.
  ///
  /// In id, this message translates to:
  /// **'Bahasa'**
  String get commonLanguageLabel;

  /// No description provided for @commonThemeLabel.
  ///
  /// In id, this message translates to:
  /// **'Tema'**
  String get commonThemeLabel;

  /// No description provided for @commonThemeSystem.
  ///
  /// In id, this message translates to:
  /// **'Ikuti sistem'**
  String get commonThemeSystem;

  /// No description provided for @commonThemeLight.
  ///
  /// In id, this message translates to:
  /// **'Terang'**
  String get commonThemeLight;

  /// No description provided for @commonThemeDark.
  ///
  /// In id, this message translates to:
  /// **'Gelap'**
  String get commonThemeDark;

  /// No description provided for @pairingTitle.
  ///
  /// In id, this message translates to:
  /// **'Pasangkan tablet ini'**
  String get pairingTitle;

  /// No description provided for @pairingSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Masukkan kode dari dashboard Finnesia untuk menghubungkan tablet ini ke outlet Anda.'**
  String get pairingSubtitle;

  /// No description provided for @pairingDeviceNameLabel.
  ///
  /// In id, this message translates to:
  /// **'Nama tablet'**
  String get pairingDeviceNameLabel;

  /// No description provided for @pairingDeviceNamePlaceholder.
  ///
  /// In id, this message translates to:
  /// **'Kasir 1'**
  String get pairingDeviceNamePlaceholder;

  /// No description provided for @pairingDeviceNameHint.
  ///
  /// In id, this message translates to:
  /// **'Tampil di dashboard agar setiap tablet mudah dikenali.'**
  String get pairingDeviceNameHint;

  /// No description provided for @pairingCodeLabel.
  ///
  /// In id, this message translates to:
  /// **'Kode pairing'**
  String get pairingCodeLabel;

  /// No description provided for @pairingCodeHint.
  ///
  /// In id, this message translates to:
  /// **'Kode ada di dashboard Finnesia, menu Outlet.'**
  String get pairingCodeHint;

  /// No description provided for @pairingSubmit.
  ///
  /// In id, this message translates to:
  /// **'Pasangkan'**
  String get pairingSubmit;

  /// No description provided for @pairingSubmitting.
  ///
  /// In id, this message translates to:
  /// **'Memasangkan…'**
  String get pairingSubmitting;

  /// No description provided for @pairingScanButton.
  ///
  /// In id, this message translates to:
  /// **'Pindai QR'**
  String get pairingScanButton;

  /// No description provided for @pairingScanTitle.
  ///
  /// In id, this message translates to:
  /// **'Pindai QR pairing'**
  String get pairingScanTitle;

  /// No description provided for @pairingScanHint.
  ///
  /// In id, this message translates to:
  /// **'Arahkan kamera ke QR di dashboard Finnesia.'**
  String get pairingScanHint;

  /// No description provided for @pairingScanDenied.
  ///
  /// In id, this message translates to:
  /// **'Kamera belum diizinkan. Izinkan akses kamera untuk aplikasi ini di Pengaturan, atau ketik kodenya.'**
  String get pairingScanDenied;

  /// No description provided for @pairingScanUnavailable.
  ///
  /// In id, this message translates to:
  /// **'Kamera tidak bisa dipakai. Ketik kode pairing secara manual.'**
  String get pairingScanUnavailable;

  /// No description provided for @pairingInvalidCode.
  ///
  /// In id, this message translates to:
  /// **'Kode terdiri dari 6 huruf atau angka.'**
  String get pairingInvalidCode;

  /// No description provided for @pairingCodeRejected.
  ///
  /// In id, this message translates to:
  /// **'Kode ini tidak dikenali, sudah dipakai, atau sudah kedaluwarsa. Buat kode baru di dashboard.'**
  String get pairingCodeRejected;

  /// No description provided for @pairingUnavailable.
  ///
  /// In id, this message translates to:
  /// **'Tidak bisa terhubung ke server. Periksa koneksi internet, lalu coba lagi.'**
  String get pairingUnavailable;

  /// No description provided for @pairingStorageFailed.
  ///
  /// In id, this message translates to:
  /// **'Data tablet belum bisa disimpan. Coba lagi.'**
  String get pairingStorageFailed;

  /// No description provided for @pairingDeviceLimitReached.
  ///
  /// In id, this message translates to:
  /// **'Outlet ini sudah mencapai batas tablet kasir. Hapus salah satu tablet di dashboard, lalu coba lagi.'**
  String get pairingDeviceLimitReached;

  /// No description provided for @pairingDeviceLimitReachedWithLimit.
  ///
  /// In id, this message translates to:
  /// **'Outlet ini sudah mencapai batas {limit} tablet kasir. Hapus salah satu tablet di dashboard, lalu coba lagi.'**
  String pairingDeviceLimitReachedWithLimit(int limit);

  /// No description provided for @loginTitle.
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Masuk dengan akun Anda untuk mulai berjualan di outlet ini.'**
  String get loginSubtitle;

  /// No description provided for @loginDeviceLabel.
  ///
  /// In id, this message translates to:
  /// **'Perangkat'**
  String get loginDeviceLabel;

  /// No description provided for @loginSubmit.
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get loginSubmit;

  /// No description provided for @loginSubmitting.
  ///
  /// In id, this message translates to:
  /// **'Menunggu login…'**
  String get loginSubmitting;

  /// No description provided for @loginWaiting.
  ///
  /// In id, this message translates to:
  /// **'Selesaikan login di browser yang terbuka. Halaman ini akan lanjut sendiri setelah selesai.'**
  String get loginWaiting;

  /// No description provided for @loginNotPaired.
  ///
  /// In id, this message translates to:
  /// **'Perangkat ini belum dipasangkan. Pasangkan dulu sebelum masuk.'**
  String get loginNotPaired;

  /// No description provided for @loginUnavailable.
  ///
  /// In id, this message translates to:
  /// **'Belum bisa menghubungi server. Periksa koneksi lalu coba lagi.'**
  String get loginUnavailable;

  /// No description provided for @loginExpired.
  ///
  /// In id, this message translates to:
  /// **'Permintaan login sudah kedaluwarsa. Coba masuk lagi.'**
  String get loginExpired;

  /// No description provided for @loginTimeout.
  ///
  /// In id, this message translates to:
  /// **'Waktu login habis. Coba masuk lagi.'**
  String get loginTimeout;

  /// No description provided for @loginRetry.
  ///
  /// In id, this message translates to:
  /// **'Coba lagi'**
  String get loginRetry;

  /// No description provided for @loginResetButton.
  ///
  /// In id, this message translates to:
  /// **'Reset perangkat'**
  String get loginResetButton;

  /// No description provided for @loginResetTitle.
  ///
  /// In id, this message translates to:
  /// **'Reset perangkat?'**
  String get loginResetTitle;

  /// No description provided for @loginResetDesc.
  ///
  /// In id, this message translates to:
  /// **'Tablet ini akan dilepas dari outlet dan dihapus dari dashboard, lalu Anda perlu kode pairing baru untuk menyambungkannya lagi.'**
  String get loginResetDesc;

  /// No description provided for @loginResetHeldOrders.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} keranjang tertahan ikut dihapus.}}'**
  String loginResetHeldOrders(int count);

  /// No description provided for @loginResetConfirm.
  ///
  /// In id, this message translates to:
  /// **'Ya, reset'**
  String get loginResetConfirm;

  /// No description provided for @loginResetCancel.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get loginResetCancel;

  /// No description provided for @loginResetServerFailed.
  ///
  /// In id, this message translates to:
  /// **'Tablet sudah dilepas di sini, tapi server belum bisa dihubungi. Perangkat mungkin masih terdaftar di dashboard.'**
  String get loginResetServerFailed;

  /// No description provided for @loginResetQueueBlocked.
  ///
  /// In id, this message translates to:
  /// **'Reset belum bisa dilakukan: masih ada penjualan yang belum terkirim di tablet ini. Masuk lalu kirim dulu, atau buang di Penjualan tertunda, sebelum mereset.'**
  String get loginResetQueueBlocked;

  /// No description provided for @menuTitle.
  ///
  /// In id, this message translates to:
  /// **'Menu'**
  String get menuTitle;

  /// No description provided for @menuBack.
  ///
  /// In id, this message translates to:
  /// **'Kembali'**
  String get menuBack;

  /// No description provided for @menuAccountSection.
  ///
  /// In id, this message translates to:
  /// **'Akun'**
  String get menuAccountSection;

  /// No description provided for @menuSessionSection.
  ///
  /// In id, this message translates to:
  /// **'Perangkat ini'**
  String get menuSessionSection;

  /// No description provided for @menuCashierLabel.
  ///
  /// In id, this message translates to:
  /// **'Kasir'**
  String get menuCashierLabel;

  /// No description provided for @menuUnknownUser.
  ///
  /// In id, this message translates to:
  /// **'Tidak diketahui'**
  String get menuUnknownUser;

  /// No description provided for @menuDeviceLabel.
  ///
  /// In id, this message translates to:
  /// **'Perangkat'**
  String get menuDeviceLabel;

  /// No description provided for @menuOutletLabel.
  ///
  /// In id, this message translates to:
  /// **'Outlet'**
  String get menuOutletLabel;

  /// No description provided for @menuShiftSection.
  ///
  /// In id, this message translates to:
  /// **'Shift'**
  String get menuShiftSection;

  /// No description provided for @menuNoShift.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada shift terbuka'**
  String get menuNoShift;

  /// No description provided for @menuShiftLoadFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat data shift.'**
  String get menuShiftLoadFailed;

  /// No description provided for @menuOutletLoadFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat nama outlet.'**
  String get menuOutletLoadFailed;

  /// No description provided for @menuSignOut.
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get menuSignOut;

  /// No description provided for @menuSignOutTitle.
  ///
  /// In id, this message translates to:
  /// **'Keluar dari akun ini?'**
  String get menuSignOutTitle;

  /// No description provided for @menuSignOutDesc.
  ///
  /// In id, this message translates to:
  /// **'Tablet tetap terpasang di outlet ini, jadi tidak perlu pairing ulang. Anda perlu masuk lagi untuk berjualan.'**
  String get menuSignOutDesc;

  /// No description provided for @menuSignOutConfirm.
  ///
  /// In id, this message translates to:
  /// **'Ya, keluar'**
  String get menuSignOutConfirm;

  /// No description provided for @menuSignOutFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal mengeluarkan sesi. Coba lagi.'**
  String get menuSignOutFailed;

  /// No description provided for @menuSignOutBlocked.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{Anda masih punya {count} penjualan yang belum terkirim. Kirim dulu sebelum keluar.}}'**
  String menuSignOutBlocked(int count);

  /// No description provided for @menuVersion.
  ///
  /// In id, this message translates to:
  /// **'Versi {version} ({build})'**
  String menuVersion(String version, String build);

  /// No description provided for @menuVersionUnknown.
  ///
  /// In id, this message translates to:
  /// **'Versi tidak diketahui'**
  String get menuVersionUnknown;

  /// No description provided for @menuPrinterSection.
  ///
  /// In id, this message translates to:
  /// **'Printer'**
  String get menuPrinterSection;

  /// No description provided for @menuPrinterNone.
  ///
  /// In id, this message translates to:
  /// **'Belum ada printer'**
  String get menuPrinterNone;

  /// No description provided for @menuPrinterUnreadable.
  ///
  /// In id, this message translates to:
  /// **'Printer tersimpan tidak bisa dibaca'**
  String get menuPrinterUnreadable;

  /// No description provided for @menuPrinterPair.
  ///
  /// In id, this message translates to:
  /// **'Sambungkan printer'**
  String get menuPrinterPair;

  /// No description provided for @menuPrinterChange.
  ///
  /// In id, this message translates to:
  /// **'Ganti printer'**
  String get menuPrinterChange;

  /// No description provided for @menuPrinterForget.
  ///
  /// In id, this message translates to:
  /// **'Lupakan printer'**
  String get menuPrinterForget;

  /// No description provided for @menuPrinterForgetTitle.
  ///
  /// In id, this message translates to:
  /// **'Lupakan printer ini?'**
  String get menuPrinterForgetTitle;

  /// No description provided for @menuPrinterForgetDesc.
  ///
  /// In id, this message translates to:
  /// **'Tablet tidak akan mencetak ke printer ini lagi sampai Anda menyambungkan printer.'**
  String get menuPrinterForgetDesc;

  /// No description provided for @menuPrinterForgetConfirm.
  ///
  /// In id, this message translates to:
  /// **'Ya, lupakan'**
  String get menuPrinterForgetConfirm;

  /// No description provided for @menuPrinterForgetFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal melupakan printer. Coba lagi.'**
  String get menuPrinterForgetFailed;

  /// No description provided for @inspectorTitle.
  ///
  /// In id, this message translates to:
  /// **'Inspector request'**
  String get inspectorTitle;

  /// No description provided for @inspectorEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada request yang tercatat.'**
  String get inspectorEmpty;

  /// No description provided for @inspectorClear.
  ///
  /// In id, this message translates to:
  /// **'Hapus semua'**
  String get inspectorClear;

  /// No description provided for @inspectorRefresh.
  ///
  /// In id, this message translates to:
  /// **'Muat ulang'**
  String get inspectorRefresh;

  /// No description provided for @inspectorRequestHeaders.
  ///
  /// In id, this message translates to:
  /// **'Header request'**
  String get inspectorRequestHeaders;

  /// No description provided for @inspectorRequestBody.
  ///
  /// In id, this message translates to:
  /// **'Isi request'**
  String get inspectorRequestBody;

  /// No description provided for @inspectorResponseHeaders.
  ///
  /// In id, this message translates to:
  /// **'Header respons'**
  String get inspectorResponseHeaders;

  /// No description provided for @inspectorResponseBody.
  ///
  /// In id, this message translates to:
  /// **'Isi respons'**
  String get inspectorResponseBody;

  /// No description provided for @menuOpen.
  ///
  /// In id, this message translates to:
  /// **'Menu'**
  String get menuOpen;

  /// No description provided for @contactQuickAddTitle.
  ///
  /// In id, this message translates to:
  /// **'Tambah Pelanggan Baru'**
  String get contactQuickAddTitle;

  /// No description provided for @contactNameLabel.
  ///
  /// In id, this message translates to:
  /// **'Nama Pelanggan'**
  String get contactNameLabel;

  /// No description provided for @contactNamePlaceholder.
  ///
  /// In id, this message translates to:
  /// **'Nama pelanggan...'**
  String get contactNamePlaceholder;

  /// No description provided for @contactPhoneLabel.
  ///
  /// In id, this message translates to:
  /// **'No. Telepon / HP'**
  String get contactPhoneLabel;

  /// No description provided for @contactEmailLabel.
  ///
  /// In id, this message translates to:
  /// **'Email'**
  String get contactEmailLabel;

  /// No description provided for @contactCompanyLabel.
  ///
  /// In id, this message translates to:
  /// **'Nama Perusahaan (opsional)'**
  String get contactCompanyLabel;

  /// No description provided for @contactAddressLabel.
  ///
  /// In id, this message translates to:
  /// **'Alamat'**
  String get contactAddressLabel;

  /// No description provided for @contactCreated.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan berhasil ditambahkan'**
  String get contactCreated;

  /// No description provided for @printerPairTitle.
  ///
  /// In id, this message translates to:
  /// **'Sambungkan Printer'**
  String get printerPairTitle;

  /// No description provided for @printerPairDesc.
  ///
  /// In id, this message translates to:
  /// **'Pastikan printer menyala, lalu pindai untuk mencarinya. Printer yang dipilih akan diingat tablet ini.'**
  String get printerPairDesc;

  /// No description provided for @printerScanButton.
  ///
  /// In id, this message translates to:
  /// **'Pindai printer'**
  String get printerScanButton;

  /// No description provided for @printerScanning.
  ///
  /// In id, this message translates to:
  /// **'Memindai…'**
  String get printerScanning;

  /// No description provided for @printerNoneFound.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada printer ditemukan. Pastikan printer menyala dan dalam jangkauan.'**
  String get printerNoneFound;

  /// No description provided for @printerUnnamed.
  ///
  /// In id, this message translates to:
  /// **'Tanpa nama'**
  String get printerUnnamed;

  /// No description provided for @printerPairing.
  ///
  /// In id, this message translates to:
  /// **'Menyambungkan…'**
  String get printerPairing;

  /// No description provided for @printerPaired.
  ///
  /// In id, this message translates to:
  /// **'Printer tersambung: {name}'**
  String printerPaired(String name);

  /// No description provided for @printerPermissionDenied.
  ///
  /// In id, this message translates to:
  /// **'Akses Bluetooth ditolak. Izinkan Bluetooth untuk Finnesia POS di Pengaturan, lalu coba lagi.'**
  String get printerPermissionDenied;

  /// No description provided for @printerBluetoothOff.
  ///
  /// In id, this message translates to:
  /// **'Bluetooth tablet sedang mati. Nyalakan Bluetooth lalu coba lagi.'**
  String get printerBluetoothOff;

  /// No description provided for @printerScanFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal memindai printer.'**
  String get printerScanFailed;

  /// No description provided for @printerPairFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal menyambungkan ke printer.'**
  String get printerPairFailed;

  /// No description provided for @printerUnsupported.
  ///
  /// In id, this message translates to:
  /// **'Tablet ini tidak punya Bluetooth yang bisa dipakai untuk printer.'**
  String get printerUnsupported;

  /// No description provided for @printerSaveFailed.
  ///
  /// In id, this message translates to:
  /// **'Printer tersambung, tetapi tablet gagal mengingatnya. Coba pilih lagi.'**
  String get printerSaveFailed;

  /// No description provided for @printerNotConnected.
  ///
  /// In id, this message translates to:
  /// **'Printer belum tersambung. Nyalakan printer lalu coba lagi.'**
  String get printerNotConnected;

  /// No description provided for @printerPrintFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal mengirim ke printer.'**
  String get printerPrintFailed;

  /// No description provided for @printerPrintSuccess.
  ///
  /// In id, this message translates to:
  /// **'Laporan terkirim ke printer'**
  String get printerPrintSuccess;

  /// No description provided for @printerPrintShiftReport.
  ///
  /// In id, this message translates to:
  /// **'Cetak Laporan'**
  String get printerPrintShiftReport;

  /// No description provided for @posActiveShift.
  ///
  /// In id, this message translates to:
  /// **'Shift Aktif'**
  String get posActiveShift;

  /// No description provided for @posNoActiveShift.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada shift aktif'**
  String get posNoActiveShift;

  /// No description provided for @posShiftNumber.
  ///
  /// In id, this message translates to:
  /// **'Nomor Shift'**
  String get posShiftNumber;

  /// No description provided for @posOpenedAt.
  ///
  /// In id, this message translates to:
  /// **'Dibuka Pada'**
  String get posOpenedAt;

  /// No description provided for @posOpeningCash.
  ///
  /// In id, this message translates to:
  /// **'Kas Awal'**
  String get posOpeningCash;

  /// No description provided for @posTotalSales.
  ///
  /// In id, this message translates to:
  /// **'Total Penjualan'**
  String get posTotalSales;

  /// No description provided for @posTotalTransactions.
  ///
  /// In id, this message translates to:
  /// **'Total Transaksi'**
  String get posTotalTransactions;

  /// No description provided for @posExpectedCash.
  ///
  /// In id, this message translates to:
  /// **'Kas Seharusnya'**
  String get posExpectedCash;

  /// No description provided for @posShiftRequired.
  ///
  /// In id, this message translates to:
  /// **'Shift Diperlukan'**
  String get posShiftRequired;

  /// No description provided for @posShiftRequiredDesc.
  ///
  /// In id, this message translates to:
  /// **'Anda harus membuka shift sebelum dapat bertransaksi.'**
  String get posShiftRequiredDesc;

  /// No description provided for @posShiftAlreadyOpen.
  ///
  /// In id, this message translates to:
  /// **'Shift Masih Terbuka'**
  String get posShiftAlreadyOpen;

  /// No description provided for @posShiftAlreadyOpenDesc.
  ///
  /// In id, this message translates to:
  /// **'Sudah ada shift terbuka di outlet ini. Lanjutkan shift tersebut, atau tutup dulu sebelum memulai yang baru.'**
  String get posShiftAlreadyOpenDesc;

  /// No description provided for @posShiftAlreadyOpenStaleDesc.
  ///
  /// In id, this message translates to:
  /// **'Shift ini masih terbuka. Periksa dulu, lalu lanjutkan atau tutup shift tersebut.'**
  String get posShiftAlreadyOpenStaleDesc;

  /// No description provided for @posContinueShift.
  ///
  /// In id, this message translates to:
  /// **'Lanjutkan Shift {number}'**
  String posContinueShift(String number);

  /// No description provided for @posShiftHeldByAnother.
  ///
  /// In id, this message translates to:
  /// **'Shift Dipegang Kasir Lain'**
  String get posShiftHeldByAnother;

  /// No description provided for @posShiftHeldByAnotherDesc.
  ///
  /// In id, this message translates to:
  /// **'Shift {number} dibuka oleh {cashier} dan belum ditutup. Minta kasir tersebut menutupnya.'**
  String posShiftHeldByAnotherDesc(String number, String cashier);

  /// No description provided for @posShiftHeldByAnotherNoOverride.
  ///
  /// In id, this message translates to:
  /// **'Minta {cashier} menutup shiftnya, atau atasan yang memiliki izin Override Shift Kasir.'**
  String posShiftHeldByAnotherNoOverride(String cashier);

  /// No description provided for @posOverrideCloseShift.
  ///
  /// In id, this message translates to:
  /// **'Tutup Shift (Override)'**
  String get posOverrideCloseShift;

  /// No description provided for @posOverrideCloseNotice.
  ///
  /// In id, this message translates to:
  /// **'Anda akan menutup shift milik {cashier}. Catatan wajib diisi.'**
  String posOverrideCloseNotice(String cashier);

  /// No description provided for @posOverrideNoteRequired.
  ///
  /// In id, this message translates to:
  /// **'Menutup shift kasir lain wajib disertai catatan alasan'**
  String get posOverrideNoteRequired;

  /// No description provided for @posUnknownCashier.
  ///
  /// In id, this message translates to:
  /// **'Tidak diketahui'**
  String get posUnknownCashier;

  /// No description provided for @posOpenShift.
  ///
  /// In id, this message translates to:
  /// **'Buka Shift'**
  String get posOpenShift;

  /// No description provided for @posOpenShiftSuccess.
  ///
  /// In id, this message translates to:
  /// **'Shift berhasil dibuka'**
  String get posOpenShiftSuccess;

  /// No description provided for @posCloseShift.
  ///
  /// In id, this message translates to:
  /// **'Tutup Shift'**
  String get posCloseShift;

  /// No description provided for @posCloseShiftSuccess.
  ///
  /// In id, this message translates to:
  /// **'Shift berhasil ditutup'**
  String get posCloseShiftSuccess;

  /// No description provided for @posShiftSummary.
  ///
  /// In id, this message translates to:
  /// **'Ringkasan Shift'**
  String get posShiftSummary;

  /// No description provided for @posShiftDetail.
  ///
  /// In id, this message translates to:
  /// **'Detail Shift'**
  String get posShiftDetail;

  /// No description provided for @posShiftOpen.
  ///
  /// In id, this message translates to:
  /// **'Shift Terbuka'**
  String get posShiftOpen;

  /// No description provided for @posShiftClosed.
  ///
  /// In id, this message translates to:
  /// **'Shift Tertutup'**
  String get posShiftClosed;

  /// No description provided for @posClosedAt.
  ///
  /// In id, this message translates to:
  /// **'Ditutup Pada'**
  String get posClosedAt;

  /// No description provided for @posOutlet.
  ///
  /// In id, this message translates to:
  /// **'Outlet'**
  String get posOutlet;

  /// No description provided for @posNotes.
  ///
  /// In id, this message translates to:
  /// **'Catatan'**
  String get posNotes;

  /// No description provided for @posTransactions.
  ///
  /// In id, this message translates to:
  /// **'Transaksi'**
  String get posTransactions;

  /// No description provided for @posEmptyTransactions.
  ///
  /// In id, this message translates to:
  /// **'Belum ada transaksi'**
  String get posEmptyTransactions;

  /// No description provided for @posSalesByMethod.
  ///
  /// In id, this message translates to:
  /// **'Penjualan per Metode'**
  String get posSalesByMethod;

  /// No description provided for @posShiftReportTitle.
  ///
  /// In id, this message translates to:
  /// **'LAPORAN TUTUP SHIFT'**
  String get posShiftReportTitle;

  /// No description provided for @posPrintedAt.
  ///
  /// In id, this message translates to:
  /// **'Dicetak'**
  String get posPrintedAt;

  /// No description provided for @receiptTitle.
  ///
  /// In id, this message translates to:
  /// **'Struk Penjualan'**
  String get receiptTitle;

  /// No description provided for @receiptPrint.
  ///
  /// In id, this message translates to:
  /// **'Cetak struk'**
  String get receiptPrint;

  /// No description provided for @receiptSent.
  ///
  /// In id, this message translates to:
  /// **'Struk terkirim ke printer'**
  String get receiptSent;

  /// No description provided for @receiptLoadFailed.
  ///
  /// In id, this message translates to:
  /// **'Struk belum bisa dimuat. Coba lagi.'**
  String get receiptLoadFailed;

  /// No description provided for @receiptPaymentMethod.
  ///
  /// In id, this message translates to:
  /// **'Metode Pembayaran'**
  String get receiptPaymentMethod;

  /// No description provided for @receiptVoided.
  ///
  /// In id, this message translates to:
  /// **'*** TRANSAKSI DIBATALKAN ***'**
  String get receiptVoided;

  /// No description provided for @receiptNoItems.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada rincian barang'**
  String get receiptNoItems;

  /// No description provided for @receiptPaidBy.
  ///
  /// In id, this message translates to:
  /// **'Bayar ({method})'**
  String receiptPaidBy(String method);

  /// No description provided for @posPaymentsByMethod.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran per Metode'**
  String get posPaymentsByMethod;

  /// No description provided for @posTotal.
  ///
  /// In id, this message translates to:
  /// **'Total'**
  String get posTotal;

  /// No description provided for @posDepositSection.
  ///
  /// In id, this message translates to:
  /// **'Setoran'**
  String get posDepositSection;

  /// No description provided for @posCashSalesLabel.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran Tunai'**
  String get posCashSalesLabel;

  /// No description provided for @posTotalDeposit.
  ///
  /// In id, this message translates to:
  /// **'Total Setoran'**
  String get posTotalDeposit;

  /// No description provided for @posNonCashPayments.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran Non Tunai'**
  String get posNonCashPayments;

  /// No description provided for @posNoNonCashPayments.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada pembayaran non tunai di shift ini'**
  String get posNoNonCashPayments;

  /// No description provided for @posProductsSoldTitle.
  ///
  /// In id, this message translates to:
  /// **'Rincian Produk'**
  String get posProductsSoldTitle;

  /// No description provided for @posProductsSoldTotal.
  ///
  /// In id, this message translates to:
  /// **'Total Rincian Produk'**
  String get posProductsSoldTotal;

  /// No description provided for @posCountedCash.
  ///
  /// In id, this message translates to:
  /// **'Kas Dihitung'**
  String get posCountedCash;

  /// No description provided for @posVariance.
  ///
  /// In id, this message translates to:
  /// **'Selisih'**
  String get posVariance;

  /// No description provided for @posVarianceNote.
  ///
  /// In id, this message translates to:
  /// **'Catatan selisih wajib diisi bila ada selisih'**
  String get posVarianceNote;

  /// No description provided for @posVarianceReason.
  ///
  /// In id, this message translates to:
  /// **'Alasan Selisih'**
  String get posVarianceReason;

  /// No description provided for @posShiftNotesPlaceholder.
  ///
  /// In id, this message translates to:
  /// **'Catatan shift...'**
  String get posShiftNotesPlaceholder;

  /// No description provided for @posCashier.
  ///
  /// In id, this message translates to:
  /// **'Kasir'**
  String get posCashier;

  /// No description provided for @posLoading.
  ///
  /// In id, this message translates to:
  /// **'Memuat...'**
  String get posLoading;

  /// No description provided for @posCashMovement.
  ///
  /// In id, this message translates to:
  /// **'Mutasi Kas'**
  String get posCashMovement;

  /// No description provided for @posCashMovements.
  ///
  /// In id, this message translates to:
  /// **'Mutasi Kas Laci'**
  String get posCashMovements;

  /// No description provided for @posNoCashMovements.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada mutasi kas'**
  String get posNoCashMovements;

  /// No description provided for @posCashIn.
  ///
  /// In id, this message translates to:
  /// **'Kas Masuk'**
  String get posCashIn;

  /// No description provided for @posCashOut.
  ///
  /// In id, this message translates to:
  /// **'Kas Keluar'**
  String get posCashOut;

  /// No description provided for @posCashDrop.
  ///
  /// In id, this message translates to:
  /// **'Setor Kas'**
  String get posCashDrop;

  /// No description provided for @posAmount.
  ///
  /// In id, this message translates to:
  /// **'Jumlah'**
  String get posAmount;

  /// No description provided for @posCashInTotal.
  ///
  /// In id, this message translates to:
  /// **'Total Kas Masuk'**
  String get posCashInTotal;

  /// No description provided for @posCashOutTotal.
  ///
  /// In id, this message translates to:
  /// **'Total Kas Keluar'**
  String get posCashOutTotal;

  /// No description provided for @posCashMovementReason.
  ///
  /// In id, this message translates to:
  /// **'Keterangan / Barang yang Dibeli'**
  String get posCashMovementReason;

  /// No description provided for @posCashMovementReasonPlaceholder.
  ///
  /// In id, this message translates to:
  /// **'misal: beli galon air minum'**
  String get posCashMovementReasonPlaceholder;

  /// No description provided for @posCashMovementAccount.
  ///
  /// In id, this message translates to:
  /// **'Akun (opsional)'**
  String get posCashMovementAccount;

  /// No description provided for @posCashMovementAccountRequired.
  ///
  /// In id, this message translates to:
  /// **'Akun'**
  String get posCashMovementAccountRequired;

  /// No description provided for @posCashMovementProduct.
  ///
  /// In id, this message translates to:
  /// **'Barang (opsional)'**
  String get posCashMovementProduct;

  /// No description provided for @posCashMovementSelectProduct.
  ///
  /// In id, this message translates to:
  /// **'-- Pilih Barang --'**
  String get posCashMovementSelectProduct;

  /// No description provided for @posCashMovementNoProduct.
  ///
  /// In id, this message translates to:
  /// **'Barang tidak ditemukan'**
  String get posCashMovementNoProduct;

  /// No description provided for @posCashMovementSuccess.
  ///
  /// In id, this message translates to:
  /// **'Mutasi kas berhasil dicatat'**
  String get posCashMovementSuccess;

  /// No description provided for @posSelectTenderAccount.
  ///
  /// In id, this message translates to:
  /// **'Pilih akun kas/bank'**
  String get posSelectTenderAccount;

  /// No description provided for @posSearchTenderAccount.
  ///
  /// In id, this message translates to:
  /// **'Cari akun...'**
  String get posSearchTenderAccount;

  /// No description provided for @posNoTenderAccount.
  ///
  /// In id, this message translates to:
  /// **'Akun tidak ditemukan'**
  String get posNoTenderAccount;

  /// No description provided for @posSearchProduct.
  ///
  /// In id, this message translates to:
  /// **'Cari produk, SKU, atau barcode...'**
  String get posSearchProduct;

  /// No description provided for @posAllCategories.
  ///
  /// In id, this message translates to:
  /// **'Semua'**
  String get posAllCategories;

  /// No description provided for @posNoProducts.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada produk'**
  String get posNoProducts;

  /// No description provided for @posNoProductsDesc.
  ///
  /// In id, this message translates to:
  /// **'Coba kata kunci lain atau pilih kategori lain'**
  String get posNoProductsDesc;

  /// No description provided for @posCatalogLoadFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat katalog. Periksa koneksi lalu coba lagi.'**
  String get posCatalogLoadFailed;

  /// No description provided for @posOutOfStock.
  ///
  /// In id, this message translates to:
  /// **'Habis'**
  String get posOutOfStock;

  /// No description provided for @posNotFound.
  ///
  /// In id, this message translates to:
  /// **'Tidak ditemukan'**
  String get posNotFound;

  /// No description provided for @posCart.
  ///
  /// In id, this message translates to:
  /// **'Keranjang'**
  String get posCart;

  /// No description provided for @posItemCount.
  ///
  /// In id, this message translates to:
  /// **'{count} barang'**
  String posItemCount(int count);

  /// No description provided for @posCartEmpty.
  ///
  /// In id, this message translates to:
  /// **'Keranjang kosong'**
  String get posCartEmpty;

  /// No description provided for @posCartEmptyDesc.
  ///
  /// In id, this message translates to:
  /// **'Scan barcode atau cari produk untuk menambah ke keranjang'**
  String get posCartEmptyDesc;

  /// No description provided for @posClearCart.
  ///
  /// In id, this message translates to:
  /// **'Kosongkan'**
  String get posClearCart;

  /// No description provided for @posClearCartConfirm.
  ///
  /// In id, this message translates to:
  /// **'Kosongkan keranjang?'**
  String get posClearCartConfirm;

  /// No description provided for @posClearCartConfirmDesc.
  ///
  /// In id, this message translates to:
  /// **'Semua barang di keranjang akan dihapus.'**
  String get posClearCartConfirmDesc;

  /// No description provided for @posRemoveItem.
  ///
  /// In id, this message translates to:
  /// **'Hapus Item'**
  String get posRemoveItem;

  /// No description provided for @posQty.
  ///
  /// In id, this message translates to:
  /// **'Qty'**
  String get posQty;

  /// No description provided for @posSubtotal.
  ///
  /// In id, this message translates to:
  /// **'Subtotal'**
  String get posSubtotal;

  /// No description provided for @posDiscount.
  ///
  /// In id, this message translates to:
  /// **'Diskon'**
  String get posDiscount;

  /// No description provided for @posDiscountPercent.
  ///
  /// In id, this message translates to:
  /// **'Diskon (%)'**
  String get posDiscountPercent;

  /// No description provided for @posDiscountAmount.
  ///
  /// In id, this message translates to:
  /// **'Diskon (Rp)'**
  String get posDiscountAmount;

  /// No description provided for @posLineDiscount.
  ///
  /// In id, this message translates to:
  /// **'Diskon Baris'**
  String get posLineDiscount;

  /// No description provided for @posBillDiscount.
  ///
  /// In id, this message translates to:
  /// **'Diskon Nota'**
  String get posBillDiscount;

  /// No description provided for @posTax.
  ///
  /// In id, this message translates to:
  /// **'Pajak'**
  String get posTax;

  /// No description provided for @posGrandTotal.
  ///
  /// In id, this message translates to:
  /// **'Grand Total'**
  String get posGrandTotal;

  /// No description provided for @posViewCart.
  ///
  /// In id, this message translates to:
  /// **'Lihat Keranjang'**
  String get posViewCart;

  /// No description provided for @posTransactionDetail.
  ///
  /// In id, this message translates to:
  /// **'Detail Transaksi'**
  String get posTransactionDetail;

  /// No description provided for @posAddTransactionDetail.
  ///
  /// In id, this message translates to:
  /// **'Tambah detail transaksi'**
  String get posAddTransactionDetail;

  /// No description provided for @posCustomer.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan'**
  String get posCustomer;

  /// No description provided for @posNoCustomer.
  ///
  /// In id, this message translates to:
  /// **'Tanpa Pelanggan'**
  String get posNoCustomer;

  /// No description provided for @posSearchCustomer.
  ///
  /// In id, this message translates to:
  /// **'Cari pelanggan...'**
  String get posSearchCustomer;

  /// No description provided for @posAddContactNamed.
  ///
  /// In id, this message translates to:
  /// **'Tambah Kontak \"{q}\"'**
  String posAddContactNamed(String q);

  /// No description provided for @posCustomerMemo.
  ///
  /// In id, this message translates to:
  /// **'Catatan Pelanggan'**
  String get posCustomerMemo;

  /// No description provided for @posCustomerMemoPlaceholder.
  ///
  /// In id, this message translates to:
  /// **'misal: Budi, take away'**
  String get posCustomerMemoPlaceholder;

  /// No description provided for @posTableNumber.
  ///
  /// In id, this message translates to:
  /// **'No. Meja'**
  String get posTableNumber;

  /// No description provided for @posTableNumberPlaceholder.
  ///
  /// In id, this message translates to:
  /// **'misal: 12'**
  String get posTableNumberPlaceholder;

  /// No description provided for @posQueueNumber.
  ///
  /// In id, this message translates to:
  /// **'No. Antrian'**
  String get posQueueNumber;

  /// No description provided for @posQueueNumberPlaceholder.
  ///
  /// In id, this message translates to:
  /// **'misal: 45'**
  String get posQueueNumberPlaceholder;

  /// No description provided for @posHoldOrder.
  ///
  /// In id, this message translates to:
  /// **'Tahan'**
  String get posHoldOrder;

  /// No description provided for @posHoldLabel.
  ///
  /// In id, this message translates to:
  /// **'Nama/Keterangan'**
  String get posHoldLabel;

  /// No description provided for @posHoldLabelPlaceholder.
  ///
  /// In id, this message translates to:
  /// **'mis. Bu Sri, meja 4'**
  String get posHoldLabelPlaceholder;

  /// No description provided for @posHoldSuccess.
  ///
  /// In id, this message translates to:
  /// **'Transaksi ditahan'**
  String get posHoldSuccess;

  /// No description provided for @posHeldOrders.
  ///
  /// In id, this message translates to:
  /// **'Transaksi Ditahan'**
  String get posHeldOrders;

  /// No description provided for @posNoHeldOrders.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada transaksi ditahan'**
  String get posNoHeldOrders;

  /// No description provided for @posResumeOrder.
  ///
  /// In id, this message translates to:
  /// **'Lanjutkan'**
  String get posResumeOrder;

  /// No description provided for @posDropOrder.
  ///
  /// In id, this message translates to:
  /// **'Buang'**
  String get posDropOrder;

  /// No description provided for @posPay.
  ///
  /// In id, this message translates to:
  /// **'Bayar'**
  String get posPay;

  /// No description provided for @posPaying.
  ///
  /// In id, this message translates to:
  /// **'Memproses...'**
  String get posPaying;

  /// No description provided for @posPayment.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran'**
  String get posPayment;

  /// No description provided for @posAddTender.
  ///
  /// In id, this message translates to:
  /// **'Tambah Metode'**
  String get posAddTender;

  /// No description provided for @posRemoveTender.
  ///
  /// In id, this message translates to:
  /// **'Hapus metode'**
  String get posRemoveTender;

  /// No description provided for @posTenderMethodCASH.
  ///
  /// In id, this message translates to:
  /// **'Tunai'**
  String get posTenderMethodCASH;

  /// No description provided for @posTenderMethodTRANSFER.
  ///
  /// In id, this message translates to:
  /// **'Transfer'**
  String get posTenderMethodTRANSFER;

  /// No description provided for @posTenderMethodEDC.
  ///
  /// In id, this message translates to:
  /// **'EDC'**
  String get posTenderMethodEDC;

  /// No description provided for @posTenderMethodQRIS.
  ///
  /// In id, this message translates to:
  /// **'QRIS'**
  String get posTenderMethodQRIS;

  /// No description provided for @posTenderMethodKOMPLIMEN.
  ///
  /// In id, this message translates to:
  /// **'Komplimen'**
  String get posTenderMethodKOMPLIMEN;

  /// No description provided for @posTenderAmount.
  ///
  /// In id, this message translates to:
  /// **'Jumlah Pembayaran'**
  String get posTenderAmount;

  /// No description provided for @posTenderReference.
  ///
  /// In id, this message translates to:
  /// **'Memo'**
  String get posTenderReference;

  /// No description provided for @posCashTendered.
  ///
  /// In id, this message translates to:
  /// **'Bayar'**
  String get posCashTendered;

  /// No description provided for @posExactAmount.
  ///
  /// In id, this message translates to:
  /// **'Uang Pas'**
  String get posExactAmount;

  /// No description provided for @posPaidAmount.
  ///
  /// In id, this message translates to:
  /// **'Terbayar'**
  String get posPaidAmount;

  /// No description provided for @posRemaining.
  ///
  /// In id, this message translates to:
  /// **'Sisa'**
  String get posRemaining;

  /// No description provided for @posChangeDue.
  ///
  /// In id, this message translates to:
  /// **'Kembalian'**
  String get posChangeDue;

  /// No description provided for @posConfirmPayment.
  ///
  /// In id, this message translates to:
  /// **'Selesaikan'**
  String get posConfirmPayment;

  /// No description provided for @posTenderOverpaidNonCash.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran non-tunai tidak boleh melebihi total belanja. Kembalian hanya dari tunai.'**
  String get posTenderOverpaidNonCash;

  /// No description provided for @posTenderEmptyCart.
  ///
  /// In id, this message translates to:
  /// **'Keranjang masih kosong'**
  String get posTenderEmptyCart;

  /// No description provided for @posInsufficientCash.
  ///
  /// In id, this message translates to:
  /// **'Uang kurang'**
  String get posInsufficientCash;

  /// No description provided for @posPaymentSuccess.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran berhasil'**
  String get posPaymentSuccess;

  /// No description provided for @posChangeTitle.
  ///
  /// In id, this message translates to:
  /// **'Kembalian'**
  String get posChangeTitle;

  /// No description provided for @posNewSale.
  ///
  /// In id, this message translates to:
  /// **'Transaksi Baru'**
  String get posNewSale;

  /// No description provided for @posReceiptNumber.
  ///
  /// In id, this message translates to:
  /// **'No. Transaksi'**
  String get posReceiptNumber;

  /// No description provided for @posReceiptTemporary.
  ///
  /// In id, this message translates to:
  /// **'SEMENTARA'**
  String get posReceiptTemporary;

  /// No description provided for @posQueuedRef.
  ///
  /// In id, this message translates to:
  /// **'Kode'**
  String get posQueuedRef;

  /// No description provided for @posOfflineNotSaved.
  ///
  /// In id, this message translates to:
  /// **'Belum terkirim ke server. Penjualan sudah tersimpan di tablet ini dan akan dikirim otomatis begitu ada koneksi.'**
  String get posOfflineNotSaved;

  /// No description provided for @posCheckoutStorageFailed.
  ///
  /// In id, this message translates to:
  /// **'Penjualan tidak bisa disimpan di tablet ini. Uang belum tercatat — jangan serahkan barang. Coba lagi.'**
  String get posCheckoutStorageFailed;

  /// No description provided for @queueTitle.
  ///
  /// In id, this message translates to:
  /// **'Penjualan tertunda'**
  String get queueTitle;

  /// No description provided for @queueSendNow.
  ///
  /// In id, this message translates to:
  /// **'Kirim sekarang'**
  String get queueSendNow;

  /// No description provided for @queueEmpty.
  ///
  /// In id, this message translates to:
  /// **'Semua penjualan sudah terkirim.'**
  String get queueEmpty;

  /// No description provided for @queueLoadFailed.
  ///
  /// In id, this message translates to:
  /// **'Antrian tidak bisa dibaca. Periksa penyimpanan tablet ini, lalu coba lagi.'**
  String get queueLoadFailed;

  /// No description provided for @queueStatusPending.
  ///
  /// In id, this message translates to:
  /// **'Menunggu'**
  String get queueStatusPending;

  /// No description provided for @queueStatusFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal'**
  String get queueStatusFailed;

  /// No description provided for @queueRetry.
  ///
  /// In id, this message translates to:
  /// **'Ulangi'**
  String get queueRetry;

  /// No description provided for @queueDiscard.
  ///
  /// In id, this message translates to:
  /// **'Buang'**
  String get queueDiscard;

  /// No description provided for @queueDiscardTitle.
  ///
  /// In id, this message translates to:
  /// **'Buang penjualan ini?'**
  String get queueDiscardTitle;

  /// No description provided for @queueDiscardDesc.
  ///
  /// In id, this message translates to:
  /// **'Barang sudah keluar dari toko. Membuang tanpa mengirim membuat catatan kas berkurang dari uang yang sebenarnya diterima.'**
  String get queueDiscardDesc;

  /// No description provided for @menuQueueTitle.
  ///
  /// In id, this message translates to:
  /// **'Penjualan tertunda'**
  String get menuQueueTitle;

  /// No description provided for @menuQueueCount.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} menunggu dikirim}}'**
  String menuQueueCount(int count);

  /// No description provided for @menuQueueEmpty.
  ///
  /// In id, this message translates to:
  /// **'Semua sudah terkirim.'**
  String get menuQueueEmpty;

  /// No description provided for @posCheckoutRejected.
  ///
  /// In id, this message translates to:
  /// **'Penjualan tidak tercatat'**
  String get posCheckoutRejected;

  /// No description provided for @posPaymentFailed.
  ///
  /// In id, this message translates to:
  /// **'Penjualan belum bisa dikirim. Coba lagi.'**
  String get posPaymentFailed;

  /// No description provided for @tillDetailAdd.
  ///
  /// In id, this message translates to:
  /// **'Tambah detail transaksi'**
  String get tillDetailAdd;

  /// No description provided for @tillDetailCustomer.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan: {name}'**
  String tillDetailCustomer(String name);

  /// No description provided for @tillDetailMemo.
  ///
  /// In id, this message translates to:
  /// **'Catatan: {memo}'**
  String tillDetailMemo(String memo);

  /// No description provided for @tillDetailTable.
  ///
  /// In id, this message translates to:
  /// **'Meja: {number}'**
  String tillDetailTable(String number);

  /// No description provided for @tillDetailQueue.
  ///
  /// In id, this message translates to:
  /// **'Antrian: {number}'**
  String tillDetailQueue(String number);

  /// No description provided for @tillDetailDone.
  ///
  /// In id, this message translates to:
  /// **'Selesai'**
  String get tillDetailDone;

  /// No description provided for @tillDetailSelectCustomer.
  ///
  /// In id, this message translates to:
  /// **'Pilih pelanggan'**
  String get tillDetailSelectCustomer;

  /// No description provided for @tillDetailClearCustomer.
  ///
  /// In id, this message translates to:
  /// **'Hapus pelanggan'**
  String get tillDetailClearCustomer;

  /// No description provided for @tillDetailCustomerNone.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada pelanggan ditemukan.'**
  String get tillDetailCustomerNone;

  /// No description provided for @tillDetailCustomerFailed.
  ///
  /// In id, this message translates to:
  /// **'Belum bisa membaca daftar pelanggan. Periksa koneksi lalu coba lagi.'**
  String get tillDetailCustomerFailed;

  /// No description provided for @tillDetailCreateFailed.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan belum bisa disimpan. Coba lagi.'**
  String get tillDetailCreateFailed;

  /// No description provided for @tillDetailCreateNoAnswer.
  ///
  /// In id, this message translates to:
  /// **'Belum bisa menghubungi server. Periksa koneksi lalu coba lagi.'**
  String get tillDetailCreateNoAnswer;

  /// No description provided for @tillDetailNameRequired.
  ///
  /// In id, this message translates to:
  /// **'Nama pelanggan belum diisi.'**
  String get tillDetailNameRequired;

  /// No description provided for @uiPrevious.
  ///
  /// In id, this message translates to:
  /// **'Sebelumnya'**
  String get uiPrevious;

  /// No description provided for @uiNext.
  ///
  /// In id, this message translates to:
  /// **'Berikutnya'**
  String get uiNext;

  /// No description provided for @menuShiftDetail.
  ///
  /// In id, this message translates to:
  /// **'Detail shift'**
  String get menuShiftDetail;

  /// No description provided for @menuShiftHistory.
  ///
  /// In id, this message translates to:
  /// **'Riwayat shift'**
  String get menuShiftHistory;

  /// No description provided for @shiftHistoryTitle.
  ///
  /// In id, this message translates to:
  /// **'Riwayat Shift'**
  String get shiftHistoryTitle;

  /// No description provided for @shiftHistoryAll.
  ///
  /// In id, this message translates to:
  /// **'Semua'**
  String get shiftHistoryAll;

  /// No description provided for @shiftHistoryEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada shift.'**
  String get shiftHistoryEmpty;

  /// No description provided for @shiftHistoryLoadFailed.
  ///
  /// In id, this message translates to:
  /// **'Riwayat shift belum bisa dimuat. Periksa koneksi, lalu coba lagi.'**
  String get shiftHistoryLoadFailed;

  /// No description provided for @saleDetailTitle.
  ///
  /// In id, this message translates to:
  /// **'Detail penjualan'**
  String get saleDetailTitle;

  /// No description provided for @saleDetailLoadFailed.
  ///
  /// In id, this message translates to:
  /// **'Detail penjualan belum bisa dibaca. Periksa koneksi, lalu coba lagi.'**
  String get saleDetailLoadFailed;

  /// No description provided for @saleDetailVoided.
  ///
  /// In id, this message translates to:
  /// **'Penjualan ini dibatalkan.'**
  String get saleDetailVoided;

  /// No description provided for @saleDetailCashier.
  ///
  /// In id, this message translates to:
  /// **'Kasir'**
  String get saleDetailCashier;

  /// No description provided for @saleDetailNoItems.
  ///
  /// In id, this message translates to:
  /// **'Rincian barang tidak tersedia untuk penjualan ini.'**
  String get saleDetailNoItems;

  /// No description provided for @saleDetailUnknownProduct.
  ///
  /// In id, this message translates to:
  /// **'Barang tidak dikenal'**
  String get saleDetailUnknownProduct;

  /// No description provided for @saleDetailTax.
  ///
  /// In id, this message translates to:
  /// **'Pajak'**
  String get saleDetailTax;

  /// No description provided for @saleDetailPayments.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran'**
  String get saleDetailPayments;

  /// No description provided for @saleDetailTendered.
  ///
  /// In id, this message translates to:
  /// **'Uang diterima'**
  String get saleDetailTendered;

  /// No description provided for @saleDetailNotes.
  ///
  /// In id, this message translates to:
  /// **'Catatan'**
  String get saleDetailNotes;

  /// No description provided for @shiftDetailTitle.
  ///
  /// In id, this message translates to:
  /// **'Detail shift'**
  String get shiftDetailTitle;

  /// No description provided for @shiftDetailOpen.
  ///
  /// In id, this message translates to:
  /// **'Terbuka'**
  String get shiftDetailOpen;

  /// No description provided for @shiftDetailClosed.
  ///
  /// In id, this message translates to:
  /// **'Ditutup'**
  String get shiftDetailClosed;

  /// No description provided for @shiftDetailNone.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada shift yang terbuka. Buka shift dari layar kasir.'**
  String get shiftDetailNone;

  /// No description provided for @shiftDetailHeldDesc.
  ///
  /// In id, this message translates to:
  /// **'Shift {number} dibuka oleh {cashier}. Rinciannya hanya tampil untuk kasir itu, atau atasan dengan izin Override Shift Kasir.'**
  String shiftDetailHeldDesc(String number, String cashier);

  /// No description provided for @shiftDetailLoadFailed.
  ///
  /// In id, this message translates to:
  /// **'Rincian shift belum bisa dibaca. Periksa koneksi, lalu coba lagi.'**
  String get shiftDetailLoadFailed;

  /// No description provided for @shiftDetailClosedAtLabel.
  ///
  /// In id, this message translates to:
  /// **'Ditutup pada'**
  String get shiftDetailClosedAtLabel;

  /// No description provided for @shiftDetailOutletLabel.
  ///
  /// In id, this message translates to:
  /// **'Outlet'**
  String get shiftDetailOutletLabel;

  /// No description provided for @shiftDetailFiguresTitle.
  ///
  /// In id, this message translates to:
  /// **'Hitungan kas'**
  String get shiftDetailFiguresTitle;

  /// No description provided for @shiftDetailTransactions.
  ///
  /// In id, this message translates to:
  /// **'Jumlah transaksi'**
  String get shiftDetailTransactions;

  /// No description provided for @shiftDetailTotalSales.
  ///
  /// In id, this message translates to:
  /// **'Total penjualan'**
  String get shiftDetailTotalSales;

  /// No description provided for @shiftDetailOpeningCash.
  ///
  /// In id, this message translates to:
  /// **'Modal awal'**
  String get shiftDetailOpeningCash;

  /// No description provided for @shiftDetailCashIn.
  ///
  /// In id, this message translates to:
  /// **'Kas masuk'**
  String get shiftDetailCashIn;

  /// No description provided for @shiftDetailCashOut.
  ///
  /// In id, this message translates to:
  /// **'Kas keluar'**
  String get shiftDetailCashOut;

  /// No description provided for @shiftDetailCashDrop.
  ///
  /// In id, this message translates to:
  /// **'Setoran'**
  String get shiftDetailCashDrop;

  /// No description provided for @shiftDetailCashOutAndDrop.
  ///
  /// In id, this message translates to:
  /// **'Kas keluar dan setoran'**
  String get shiftDetailCashOutAndDrop;

  /// No description provided for @shiftDetailExpectedCash.
  ///
  /// In id, this message translates to:
  /// **'Kas yang seharusnya ada'**
  String get shiftDetailExpectedCash;

  /// No description provided for @shiftDetailCountedCash.
  ///
  /// In id, this message translates to:
  /// **'Kas terhitung'**
  String get shiftDetailCountedCash;

  /// No description provided for @shiftDetailVarianceShort.
  ///
  /// In id, this message translates to:
  /// **'Kurang {amount}'**
  String shiftDetailVarianceShort(String amount);

  /// No description provided for @shiftDetailVarianceOver.
  ///
  /// In id, this message translates to:
  /// **'Lebih {amount}'**
  String shiftDetailVarianceOver(String amount);

  /// No description provided for @shiftDetailVarianceNone.
  ///
  /// In id, this message translates to:
  /// **'Pas'**
  String get shiftDetailVarianceNone;

  /// No description provided for @shiftDetailVarianceLabel.
  ///
  /// In id, this message translates to:
  /// **'Selisih'**
  String get shiftDetailVarianceLabel;

  /// No description provided for @shiftDetailByMethodTitle.
  ///
  /// In id, this message translates to:
  /// **'Penjualan per metode'**
  String get shiftDetailByMethodTitle;

  /// No description provided for @shiftDetailNoSales.
  ///
  /// In id, this message translates to:
  /// **'Belum ada penjualan di shift ini.'**
  String get shiftDetailNoSales;

  /// No description provided for @shiftDetailNotes.
  ///
  /// In id, this message translates to:
  /// **'Catatan'**
  String get shiftDetailNotes;

  /// No description provided for @shiftDetailTabFigures.
  ///
  /// In id, this message translates to:
  /// **'Ringkasan'**
  String get shiftDetailTabFigures;

  /// No description provided for @shiftDetailTabSales.
  ///
  /// In id, this message translates to:
  /// **'Transaksi'**
  String get shiftDetailTabSales;

  /// No description provided for @shiftDetailTabMovements.
  ///
  /// In id, this message translates to:
  /// **'Mutasi kas'**
  String get shiftDetailTabMovements;

  /// No description provided for @shiftDetailSaleVoided.
  ///
  /// In id, this message translates to:
  /// **'Dibatalkan'**
  String get shiftDetailSaleVoided;

  /// No description provided for @shiftDetailMoreFailed.
  ///
  /// In id, this message translates to:
  /// **'Belum bisa memuat lebih banyak. Ketuk untuk mencoba lagi.'**
  String get shiftDetailMoreFailed;

  /// No description provided for @shiftDetailNoMovements.
  ///
  /// In id, this message translates to:
  /// **'Belum ada kas masuk atau keluar di shift ini.'**
  String get shiftDetailNoMovements;

  /// No description provided for @closeShiftTitle.
  ///
  /// In id, this message translates to:
  /// **'Tutup shift'**
  String get closeShiftTitle;

  /// No description provided for @closeShiftLoadFailed.
  ///
  /// In id, this message translates to:
  /// **'Angka shift belum bisa dibaca. Periksa koneksi, lalu coba lagi.'**
  String get closeShiftLoadFailed;

  /// No description provided for @closeShiftOverrideNotice.
  ///
  /// In id, this message translates to:
  /// **'Anda menutup shift milik {cashier}. Catatan wajib diisi.'**
  String closeShiftOverrideNotice(String cashier);

  /// No description provided for @closeShiftNotesLabel.
  ///
  /// In id, this message translates to:
  /// **'Catatan'**
  String get closeShiftNotesLabel;

  /// No description provided for @closeShiftNoteNeededVariance.
  ///
  /// In id, this message translates to:
  /// **'Drawer tidak sama dengan hitungan. Tulis alasannya sebelum menutup.'**
  String get closeShiftNoteNeededVariance;

  /// No description provided for @closeShiftNoteNeededOverride.
  ///
  /// In id, this message translates to:
  /// **'Anda bukan pemegang shift ini. Tulis alasan menutupnya sebelum menutup.'**
  String get closeShiftNoteNeededOverride;

  /// No description provided for @closeShiftNoteOptional.
  ///
  /// In id, this message translates to:
  /// **'Boleh dikosongkan'**
  String get closeShiftNoteOptional;

  /// No description provided for @closeShiftButton.
  ///
  /// In id, this message translates to:
  /// **'Tutup shift'**
  String get closeShiftButton;

  /// No description provided for @closeShiftClosing.
  ///
  /// In id, this message translates to:
  /// **'Menutup shift…'**
  String get closeShiftClosing;

  /// No description provided for @closeShiftDone.
  ///
  /// In id, this message translates to:
  /// **'Shift ditutup.'**
  String get closeShiftDone;

  /// No description provided for @closeShiftRefused.
  ///
  /// In id, this message translates to:
  /// **'Shift belum bisa ditutup.'**
  String get closeShiftRefused;

  /// No description provided for @closeShiftUncertain.
  ///
  /// In id, this message translates to:
  /// **'Belum ada jawaban pasti dari server, jadi shift mungkin sudah tertutup. Periksa dulu sebelum mencoba menutup lagi.'**
  String get closeShiftUncertain;

  /// No description provided for @shiftCloseBlockedByQueue.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} penjualan di outlet ini belum terkirim. Ketuk untuk membuka Penjualan tertunda.}}'**
  String shiftCloseBlockedByQueue(int count);

  /// No description provided for @cashMovementTitle.
  ///
  /// In id, this message translates to:
  /// **'Catat kas masuk atau keluar'**
  String get cashMovementTitle;

  /// No description provided for @cashMovementAmount.
  ///
  /// In id, this message translates to:
  /// **'Jumlah'**
  String get cashMovementAmount;

  /// No description provided for @cashMovementReasonRequired.
  ///
  /// In id, this message translates to:
  /// **'Alasan (wajib)'**
  String get cashMovementReasonRequired;

  /// No description provided for @cashMovementReasonHint.
  ///
  /// In id, this message translates to:
  /// **'Misalnya: beli galon air'**
  String get cashMovementReasonHint;

  /// No description provided for @cashMovementAccount.
  ///
  /// In id, this message translates to:
  /// **'Akun'**
  String get cashMovementAccount;

  /// No description provided for @cashMovementAccountRequired.
  ///
  /// In id, this message translates to:
  /// **'Akun (wajib)'**
  String get cashMovementAccountRequired;

  /// No description provided for @cashMovementAccountNone.
  ///
  /// In id, this message translates to:
  /// **'Pilih akun'**
  String get cashMovementAccountNone;

  /// No description provided for @cashMovementAccountSearch.
  ///
  /// In id, this message translates to:
  /// **'Cari akun'**
  String get cashMovementAccountSearch;

  /// No description provided for @cashMovementAccountEmpty.
  ///
  /// In id, this message translates to:
  /// **'Akun tidak ditemukan.'**
  String get cashMovementAccountEmpty;

  /// No description provided for @cashMovementAccountFailed.
  ///
  /// In id, this message translates to:
  /// **'Akun belum bisa dibaca. Periksa koneksi, lalu coba lagi.'**
  String get cashMovementAccountFailed;

  /// No description provided for @cashMovementSettingsFailed.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan kas belum bisa dibaca, jadi catatan belum bisa disimpan. Periksa koneksi, lalu coba lagi.'**
  String get cashMovementSettingsFailed;

  /// No description provided for @cashMovementDone.
  ///
  /// In id, this message translates to:
  /// **'Kas tercatat.'**
  String get cashMovementDone;

  /// No description provided for @cashMovementRefused.
  ///
  /// In id, this message translates to:
  /// **'Catatan kas belum bisa disimpan.'**
  String get cashMovementRefused;

  /// No description provided for @cashMovementUncertain.
  ///
  /// In id, this message translates to:
  /// **'Belum ada jawaban pasti dari server, jadi catatan ini mungkin sudah tersimpan. Periksa daftar Mutasi kas sebelum mencoba lagi.'**
  String get cashMovementUncertain;

  /// No description provided for @tillHold.
  ///
  /// In id, this message translates to:
  /// **'Tahan'**
  String get tillHold;

  /// No description provided for @tillHoldTitle.
  ///
  /// In id, this message translates to:
  /// **'Tahan keranjang'**
  String get tillHoldTitle;

  /// No description provided for @tillHoldNameLabel.
  ///
  /// In id, this message translates to:
  /// **'Nama (boleh kosong)'**
  String get tillHoldNameLabel;

  /// No description provided for @tillHoldNameHint.
  ///
  /// In id, this message translates to:
  /// **'Misalnya: Meja 4'**
  String get tillHoldNameHint;

  /// No description provided for @tillHoldDone.
  ///
  /// In id, this message translates to:
  /// **'Keranjang ditahan.'**
  String get tillHoldDone;

  /// No description provided for @tillHoldNotStored.
  ///
  /// In id, this message translates to:
  /// **'Keranjang belum bisa disimpan di tablet ini, jadi tidak ditahan. Isinya tetap di layar.'**
  String get tillHoldNotStored;

  /// No description provided for @tillResumeNotStored.
  ///
  /// In id, this message translates to:
  /// **'Keranjang yang sedang tampil belum bisa disimpan, jadi keranjang lain tidak dibuka. Isinya tetap di layar.'**
  String get tillResumeNotStored;

  /// No description provided for @tillHeld.
  ///
  /// In id, this message translates to:
  /// **'Ditahan'**
  String get tillHeld;

  /// No description provided for @tillHeldCount.
  ///
  /// In id, this message translates to:
  /// **'Ditahan ({count})'**
  String tillHeldCount(int count);

  /// No description provided for @heldTitle.
  ///
  /// In id, this message translates to:
  /// **'Keranjang ditahan'**
  String get heldTitle;

  /// No description provided for @heldEmpty.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada keranjang yang ditahan.'**
  String get heldEmpty;

  /// No description provided for @heldResume.
  ///
  /// In id, this message translates to:
  /// **'Lanjutkan'**
  String get heldResume;

  /// No description provided for @heldDrop.
  ///
  /// In id, this message translates to:
  /// **'Buang'**
  String get heldDrop;

  /// No description provided for @heldDropTitle.
  ///
  /// In id, this message translates to:
  /// **'Buang keranjang ini?'**
  String get heldDropTitle;

  /// No description provided for @heldDropDesc.
  ///
  /// In id, this message translates to:
  /// **'Isi keranjang {label} akan hilang dan tidak bisa dikembalikan.'**
  String heldDropDesc(String label);

  /// No description provided for @updateReadyMessage.
  ///
  /// In id, this message translates to:
  /// **'Pembaruan siap. Restart aplikasi untuk menerapkannya.'**
  String get updateReadyMessage;

  /// No description provided for @nativeUpdateReadyMessage.
  ///
  /// In id, this message translates to:
  /// **'Versi baru siap dipasang.'**
  String get nativeUpdateReadyMessage;

  /// No description provided for @nativeUpdateAction.
  ///
  /// In id, this message translates to:
  /// **'Pasang'**
  String get nativeUpdateAction;
}

class _L10nDelegate extends LocalizationsDelegate<L10n> {
  const _L10nDelegate();

  @override
  Future<L10n> load(Locale locale) {
    return SynchronousFuture<L10n>(lookupL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_L10nDelegate old) => false;
}

L10n lookupL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return L10nEn();
    case 'id':
      return L10nId();
  }

  throw FlutterError(
    'L10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
