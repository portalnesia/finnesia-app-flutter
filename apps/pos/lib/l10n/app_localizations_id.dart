// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class L10nId extends L10n {
  L10nId([String locale = 'id']) : super(locale);

  @override
  String get appName => 'Finnesia POS';

  @override
  String get shiftLoadFailed =>
      'Belum bisa membaca data shift. Periksa koneksi lalu coba lagi.';

  @override
  String get shiftRequiredTitle => 'Buka shift dulu';

  @override
  String get shiftRequiredDesc =>
      'Hitung uang di laci, lalu masukkan sebagai modal awal sebelum mulai berjualan.';

  @override
  String get shiftOpeningCashLabel => 'Modal awal';

  @override
  String get shiftOpenButton => 'Buka shift';

  @override
  String get shiftKeypadBackspace => 'Hapus angka';

  @override
  String get shiftOpenUnavailable =>
      'Belum bisa menghubungi server. Periksa koneksi lalu coba lagi.';

  @override
  String get shiftOpening => 'Membuka shift…';

  @override
  String get shiftOpenTitle => 'Shift masih terbuka';

  @override
  String get shiftOpenDesc =>
      'Sudah ada shift terbuka di outlet ini. Lanjutkan shift itu untuk mulai berjualan.';

  @override
  String get shiftOpenStaleDesc =>
      'Shift ini masih terbuka. Periksa dulu angka di bawah sebelum melanjutkannya.';

  @override
  String get shiftNumberLabel => 'Nomor shift';

  @override
  String get shiftOpenedAtLabel => 'Dibuka';

  @override
  String get shiftCashierLabel => 'Kasir';

  @override
  String get shiftHeldTitle => 'Shift dipegang kasir lain';

  @override
  String get shiftUnknownCashier => 'kasir lain';

  @override
  String shiftContinue(String number) {
    return 'Lanjutkan shift $number';
  }

  @override
  String shiftHeldDesc(String number, String cashier) {
    return 'Shift $number dibuka oleh $cashier dan belum ditutup. Shift itu perlu ditutup dulu sebelum Anda bisa berjualan di outlet ini.';
  }

  @override
  String get tillSearchHint => 'Cari produk atau pindai barcode';

  @override
  String get tillCategoryAll => 'Semua';

  @override
  String get tillCatalogLoadFailed =>
      'Belum bisa membaca daftar produk. Periksa koneksi lalu coba lagi.';

  @override
  String get tillNoProducts => 'Tidak ada produk';

  @override
  String get tillNoProductsDesc => 'Coba kata kunci atau kategori lain.';

  @override
  String get tillOutOfStock => 'Habis';

  @override
  String get tillCartTitle => 'Keranjang';

  @override
  String get tillCartEmpty => 'Keranjang kosong';

  @override
  String get tillCartEmptyDesc =>
      'Ketuk produk atau pindai barcode untuk menambahkannya.';

  @override
  String get tillClearCart => 'Kosongkan';

  @override
  String get tillClearTitle => 'Kosongkan keranjang?';

  @override
  String get tillClearDesc => 'Semua item di keranjang akan dihapus.';

  @override
  String get tillSubtotal => 'Subtotal';

  @override
  String get tillDiscount => 'Diskon';

  @override
  String get tillTotal => 'Total';

  @override
  String get tillUndo => 'Urungkan';

  @override
  String get tillLookupFailed =>
      'Belum bisa mencari produk itu. Periksa koneksi lalu coba lagi.';

  @override
  String tillItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count item',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String tillQtyLess(String name) {
    return 'Kurangi jumlah $name';
  }

  @override
  String tillQtyMore(String name) {
    return 'Tambah jumlah $name';
  }

  @override
  String tillRemoveLine(String name) {
    return 'Hapus $name';
  }

  @override
  String tillLineRemoved(String name) {
    return '$name dihapus';
  }

  @override
  String tillStatusCashier(String name) {
    return 'Kasir: $name';
  }

  @override
  String tillStatusShift(String number) {
    return 'Shift $number';
  }

  @override
  String tillStatusQueue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count belum terkirim',
    );
    return '$_temp0';
  }

  @override
  String tillStatusQueueFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count belum terkirim, ada yang gagal',
    );
    return '$_temp0';
  }

  @override
  String tillCodeNotFound(String code) {
    return 'Produk dengan kode $code tidak ditemukan.';
  }

  @override
  String get commonRetry => 'Coba lagi';

  @override
  String get commonLoading => 'Memuat…';

  @override
  String get bootFailed =>
      'Data perangkat belum bisa dibuka. Pairing tablet ini tidak dihapus. Coba lagi.';

  @override
  String get commonCancel => 'Batal';

  @override
  String get commonClose => 'Tutup';

  @override
  String get commonSave => 'Simpan';

  @override
  String get commonSaving => 'Menyimpan...';

  @override
  String get commonLoadFailed => 'Gagal memuat data';

  @override
  String get commonSaveFailed => 'Gagal menyimpan data';

  @override
  String get commonDelete => 'Hapus angka terakhir';

  @override
  String get commonLanguageId => 'Indonesia';

  @override
  String get commonLanguageEn => 'English';

  @override
  String get commonLanguageLabel => 'Bahasa';

  @override
  String get commonThemeLabel => 'Tema';

  @override
  String get commonThemeSystem => 'Ikuti sistem';

  @override
  String get commonThemeLight => 'Terang';

  @override
  String get commonThemeDark => 'Gelap';

  @override
  String get pairingTitle => 'Pasangkan tablet ini';

  @override
  String get pairingSubtitle =>
      'Masukkan kode dari dashboard Finnesia untuk menghubungkan tablet ini ke outlet Anda.';

  @override
  String get pairingDeviceNameLabel => 'Nama tablet';

  @override
  String get pairingDeviceNamePlaceholder => 'Kasir 1';

  @override
  String get pairingDeviceNameHint =>
      'Tampil di dashboard agar setiap tablet mudah dikenali.';

  @override
  String get pairingCodeLabel => 'Kode pairing';

  @override
  String get pairingCodeHint => 'Kode ada di dashboard Finnesia, menu Outlet.';

  @override
  String get pairingSubmit => 'Pasangkan';

  @override
  String get pairingSubmitting => 'Memasangkan…';

  @override
  String get pairingScanButton => 'Pindai QR';

  @override
  String get pairingScanTitle => 'Pindai QR pairing';

  @override
  String get pairingScanHint => 'Arahkan kamera ke QR di dashboard Finnesia.';

  @override
  String get pairingScanDenied =>
      'Kamera belum diizinkan. Izinkan akses kamera untuk aplikasi ini di Pengaturan, atau ketik kodenya.';

  @override
  String get pairingScanUnavailable =>
      'Kamera tidak bisa dipakai. Ketik kode pairing secara manual.';

  @override
  String get pairingInvalidCode => 'Kode terdiri dari 6 huruf atau angka.';

  @override
  String get pairingCodeRejected =>
      'Kode ini tidak dikenali, sudah dipakai, atau sudah kedaluwarsa. Buat kode baru di dashboard.';

  @override
  String get pairingUnavailable =>
      'Tidak bisa terhubung ke server. Periksa koneksi internet, lalu coba lagi.';

  @override
  String get pairingStorageFailed =>
      'Data tablet belum bisa disimpan. Coba lagi.';

  @override
  String get pairingDeviceLimitReached =>
      'Outlet ini sudah mencapai batas tablet kasir. Hapus salah satu tablet di dashboard, lalu coba lagi.';

  @override
  String pairingDeviceLimitReachedWithLimit(int limit) {
    return 'Outlet ini sudah mencapai batas $limit tablet kasir. Hapus salah satu tablet di dashboard, lalu coba lagi.';
  }

  @override
  String get loginTitle => 'Masuk';

  @override
  String get loginSubtitle =>
      'Masuk dengan akun Anda untuk mulai berjualan di outlet ini.';

  @override
  String get loginDeviceLabel => 'Perangkat';

  @override
  String get loginSubmit => 'Masuk';

  @override
  String get loginSubmitting => 'Menunggu login…';

  @override
  String get loginWaiting =>
      'Selesaikan login di browser yang terbuka. Halaman ini akan lanjut sendiri setelah selesai.';

  @override
  String get loginNotPaired =>
      'Perangkat ini belum dipasangkan. Pasangkan dulu sebelum masuk.';

  @override
  String get loginUnavailable =>
      'Belum bisa menghubungi server. Periksa koneksi lalu coba lagi.';

  @override
  String get loginExpired =>
      'Permintaan login sudah kedaluwarsa. Coba masuk lagi.';

  @override
  String get loginTimeout => 'Waktu login habis. Coba masuk lagi.';

  @override
  String get loginRetry => 'Coba lagi';

  @override
  String get loginResetButton => 'Reset perangkat';

  @override
  String get loginResetTitle => 'Reset perangkat?';

  @override
  String get loginResetDesc =>
      'Tablet ini akan dilepas dari outlet dan dihapus dari dashboard, lalu Anda perlu kode pairing baru untuk menyambungkannya lagi.';

  @override
  String loginResetHeldOrders(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count keranjang tertahan ikut dihapus.',
    );
    return '$_temp0';
  }

  @override
  String get loginResetConfirm => 'Ya, reset';

  @override
  String get loginResetCancel => 'Batal';

  @override
  String get loginResetServerFailed =>
      'Tablet sudah dilepas di sini, tapi server belum bisa dihubungi. Perangkat mungkin masih terdaftar di dashboard.';

  @override
  String get loginResetQueueBlocked =>
      'Reset belum bisa dilakukan: masih ada penjualan yang belum terkirim di tablet ini. Masuk lalu kirim dulu, atau buang di Penjualan tertunda, sebelum mereset.';

  @override
  String get menuTitle => 'Menu';

  @override
  String get menuBack => 'Kembali';

  @override
  String get menuAccountSection => 'Akun';

  @override
  String get menuSessionSection => 'Perangkat ini';

  @override
  String get menuCashierLabel => 'Kasir';

  @override
  String get menuUnknownUser => 'Tidak diketahui';

  @override
  String get menuDeviceLabel => 'Perangkat';

  @override
  String get menuOutletLabel => 'Outlet';

  @override
  String get menuShiftSection => 'Shift';

  @override
  String get menuNoShift => 'Tidak ada shift terbuka';

  @override
  String get menuShiftLoadFailed => 'Gagal memuat data shift.';

  @override
  String get menuOutletLoadFailed => 'Gagal memuat nama outlet.';

  @override
  String get menuSignOut => 'Keluar';

  @override
  String get menuSignOutTitle => 'Keluar dari akun ini?';

  @override
  String get menuSignOutDesc =>
      'Tablet tetap terpasang di outlet ini, jadi tidak perlu pairing ulang. Anda perlu masuk lagi untuk berjualan.';

  @override
  String get menuSignOutConfirm => 'Ya, keluar';

  @override
  String get menuSignOutFailed => 'Gagal mengeluarkan sesi. Coba lagi.';

  @override
  String menuSignOutBlocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Anda masih punya $count penjualan yang belum terkirim. Kirim dulu sebelum keluar.',
    );
    return '$_temp0';
  }

  @override
  String menuVersion(String version, String build) {
    return 'Versi $version ($build)';
  }

  @override
  String get menuVersionUnknown => 'Versi tidak diketahui';

  @override
  String get menuPrinterSection => 'Printer';

  @override
  String get menuPrinterNone => 'Belum ada printer';

  @override
  String get menuPrinterUnreadable => 'Printer tersimpan tidak bisa dibaca';

  @override
  String get menuPrinterPair => 'Sambungkan printer';

  @override
  String get menuPrinterChange => 'Ganti printer';

  @override
  String get menuPrinterForget => 'Lupakan printer';

  @override
  String get menuPrinterForgetTitle => 'Lupakan printer ini?';

  @override
  String get menuPrinterForgetDesc =>
      'Tablet tidak akan mencetak ke printer ini lagi sampai Anda menyambungkan printer.';

  @override
  String get menuPrinterForgetConfirm => 'Ya, lupakan';

  @override
  String get menuPrinterForgetFailed => 'Gagal melupakan printer. Coba lagi.';

  @override
  String get inspectorTitle => 'Inspector request';

  @override
  String get inspectorEmpty => 'Belum ada request yang tercatat.';

  @override
  String get inspectorClear => 'Hapus semua';

  @override
  String get inspectorRefresh => 'Muat ulang';

  @override
  String get inspectorRequestHeaders => 'Header request';

  @override
  String get inspectorRequestBody => 'Isi request';

  @override
  String get inspectorResponseHeaders => 'Header respons';

  @override
  String get inspectorResponseBody => 'Isi respons';

  @override
  String get menuOpen => 'Menu';

  @override
  String get contactQuickAddTitle => 'Tambah Pelanggan Baru';

  @override
  String get contactNameLabel => 'Nama Pelanggan';

  @override
  String get contactNamePlaceholder => 'Nama pelanggan...';

  @override
  String get contactPhoneLabel => 'No. Telepon / HP';

  @override
  String get contactEmailLabel => 'Email';

  @override
  String get contactCompanyLabel => 'Nama Perusahaan (opsional)';

  @override
  String get contactAddressLabel => 'Alamat';

  @override
  String get contactCreated => 'Pelanggan berhasil ditambahkan';

  @override
  String get printerPairTitle => 'Sambungkan Printer';

  @override
  String get printerPairDesc =>
      'Pastikan printer menyala, lalu pindai untuk mencarinya. Printer yang dipilih akan diingat tablet ini.';

  @override
  String get printerScanButton => 'Pindai printer';

  @override
  String get printerScanning => 'Memindai…';

  @override
  String get printerNoneFound =>
      'Tidak ada printer ditemukan. Pastikan printer menyala dan dalam jangkauan.';

  @override
  String get printerUnnamed => 'Tanpa nama';

  @override
  String get printerPairing => 'Menyambungkan…';

  @override
  String printerPaired(String name) {
    return 'Printer tersambung: $name';
  }

  @override
  String get printerPermissionDenied =>
      'Akses Bluetooth ditolak. Izinkan Bluetooth untuk Finnesia POS di Pengaturan, lalu coba lagi.';

  @override
  String get printerBluetoothOff =>
      'Bluetooth tablet sedang mati. Nyalakan Bluetooth lalu coba lagi.';

  @override
  String get printerScanFailed => 'Gagal memindai printer.';

  @override
  String get printerPairFailed => 'Gagal menyambungkan ke printer.';

  @override
  String get printerUnsupported =>
      'Tablet ini tidak punya Bluetooth yang bisa dipakai untuk printer.';

  @override
  String get printerSaveFailed =>
      'Printer tersambung, tetapi tablet gagal mengingatnya. Coba pilih lagi.';

  @override
  String get printerNotConnected =>
      'Printer belum tersambung. Nyalakan printer lalu coba lagi.';

  @override
  String get printerPrintFailed => 'Gagal mengirim ke printer.';

  @override
  String get printerPrintSuccess => 'Laporan terkirim ke printer';

  @override
  String get printerPrintShiftReport => 'Cetak Laporan';

  @override
  String get posActiveShift => 'Shift Aktif';

  @override
  String get posNoActiveShift => 'Tidak ada shift aktif';

  @override
  String get posShiftNumber => 'Nomor Shift';

  @override
  String get posOpenedAt => 'Dibuka Pada';

  @override
  String get posOpeningCash => 'Kas Awal';

  @override
  String get posTotalSales => 'Total Penjualan';

  @override
  String get posTotalTransactions => 'Total Transaksi';

  @override
  String get posExpectedCash => 'Kas Seharusnya';

  @override
  String get posShiftRequired => 'Shift Diperlukan';

  @override
  String get posShiftRequiredDesc =>
      'Anda harus membuka shift sebelum dapat bertransaksi.';

  @override
  String get posShiftAlreadyOpen => 'Shift Masih Terbuka';

  @override
  String get posShiftAlreadyOpenDesc =>
      'Sudah ada shift terbuka di outlet ini. Lanjutkan shift tersebut, atau tutup dulu sebelum memulai yang baru.';

  @override
  String get posShiftAlreadyOpenStaleDesc =>
      'Shift ini masih terbuka. Periksa dulu, lalu lanjutkan atau tutup shift tersebut.';

  @override
  String posContinueShift(String number) {
    return 'Lanjutkan Shift $number';
  }

  @override
  String get posShiftHeldByAnother => 'Shift Dipegang Kasir Lain';

  @override
  String posShiftHeldByAnotherDesc(String number, String cashier) {
    return 'Shift $number dibuka oleh $cashier dan belum ditutup. Minta kasir tersebut menutupnya.';
  }

  @override
  String posShiftHeldByAnotherNoOverride(String cashier) {
    return 'Minta $cashier menutup shiftnya, atau atasan yang memiliki izin Override Shift Kasir.';
  }

  @override
  String get posOverrideCloseShift => 'Tutup Shift (Override)';

  @override
  String posOverrideCloseNotice(String cashier) {
    return 'Anda akan menutup shift milik $cashier. Catatan wajib diisi.';
  }

  @override
  String get posOverrideNoteRequired =>
      'Menutup shift kasir lain wajib disertai catatan alasan';

  @override
  String get posUnknownCashier => 'Tidak diketahui';

  @override
  String get posOpenShift => 'Buka Shift';

  @override
  String get posOpenShiftSuccess => 'Shift berhasil dibuka';

  @override
  String get posCloseShift => 'Tutup Shift';

  @override
  String get posCloseShiftSuccess => 'Shift berhasil ditutup';

  @override
  String get posShiftSummary => 'Ringkasan Shift';

  @override
  String get posShiftDetail => 'Detail Shift';

  @override
  String get posShiftOpen => 'Shift Terbuka';

  @override
  String get posShiftClosed => 'Shift Tertutup';

  @override
  String get posClosedAt => 'Ditutup Pada';

  @override
  String get posOutlet => 'Outlet';

  @override
  String get posNotes => 'Catatan';

  @override
  String get posTransactions => 'Transaksi';

  @override
  String get posEmptyTransactions => 'Belum ada transaksi';

  @override
  String get posSalesByMethod => 'Penjualan per Metode';

  @override
  String get posShiftReportTitle => 'LAPORAN TUTUP SHIFT';

  @override
  String get posPrintedAt => 'Dicetak';

  @override
  String get receiptTitle => 'Struk Penjualan';

  @override
  String get receiptPrint => 'Cetak struk';

  @override
  String get receiptSent => 'Struk terkirim ke printer';

  @override
  String get receiptLoadFailed => 'Struk belum bisa dimuat. Coba lagi.';

  @override
  String get receiptPaymentMethod => 'Metode Pembayaran';

  @override
  String get receiptVoided => '*** TRANSAKSI DIBATALKAN ***';

  @override
  String get receiptNoItems => 'Tidak ada rincian barang';

  @override
  String receiptPaidBy(String method) {
    return 'Bayar ($method)';
  }

  @override
  String get posPaymentsByMethod => 'Pembayaran per Metode';

  @override
  String get posTotal => 'Total';

  @override
  String get posDepositSection => 'Setoran';

  @override
  String get posCashSalesLabel => 'Pembayaran Tunai';

  @override
  String get posTotalDeposit => 'Total Setoran';

  @override
  String get posNonCashPayments => 'Pembayaran Non Tunai';

  @override
  String get posNoNonCashPayments =>
      'Tidak ada pembayaran non tunai di shift ini';

  @override
  String get posProductsSoldTitle => 'Rincian Produk';

  @override
  String get posProductsSoldTotal => 'Total Rincian Produk';

  @override
  String get posCountedCash => 'Kas Dihitung';

  @override
  String get posVariance => 'Selisih';

  @override
  String get posVarianceNote => 'Catatan selisih wajib diisi bila ada selisih';

  @override
  String get posVarianceReason => 'Alasan Selisih';

  @override
  String get posShiftNotesPlaceholder => 'Catatan shift...';

  @override
  String get posCashier => 'Kasir';

  @override
  String get posLoading => 'Memuat...';

  @override
  String get posCashMovement => 'Mutasi Kas';

  @override
  String get posCashMovements => 'Mutasi Kas Laci';

  @override
  String get posNoCashMovements => 'Tidak ada mutasi kas';

  @override
  String get posCashIn => 'Kas Masuk';

  @override
  String get posCashOut => 'Kas Keluar';

  @override
  String get posCashDrop => 'Setor Kas';

  @override
  String get posAmount => 'Jumlah';

  @override
  String get posCashInTotal => 'Total Kas Masuk';

  @override
  String get posCashOutTotal => 'Total Kas Keluar';

  @override
  String get posCashMovementReason => 'Keterangan / Barang yang Dibeli';

  @override
  String get posCashMovementReasonPlaceholder => 'misal: beli galon air minum';

  @override
  String get posCashMovementAccount => 'Akun (opsional)';

  @override
  String get posCashMovementAccountRequired => 'Akun';

  @override
  String get posCashMovementProduct => 'Barang (opsional)';

  @override
  String get posCashMovementSelectProduct => '-- Pilih Barang --';

  @override
  String get posCashMovementNoProduct => 'Barang tidak ditemukan';

  @override
  String get posCashMovementSuccess => 'Mutasi kas berhasil dicatat';

  @override
  String get posSelectTenderAccount => 'Pilih akun kas/bank';

  @override
  String get posSearchTenderAccount => 'Cari akun...';

  @override
  String get posNoTenderAccount => 'Akun tidak ditemukan';

  @override
  String get posSearchProduct => 'Cari produk, SKU, atau barcode...';

  @override
  String get posAllCategories => 'Semua';

  @override
  String get posNoProducts => 'Tidak ada produk';

  @override
  String get posNoProductsDesc =>
      'Coba kata kunci lain atau pilih kategori lain';

  @override
  String get posCatalogLoadFailed =>
      'Gagal memuat katalog. Periksa koneksi lalu coba lagi.';

  @override
  String get posOutOfStock => 'Habis';

  @override
  String get posNotFound => 'Tidak ditemukan';

  @override
  String get posCart => 'Keranjang';

  @override
  String posItemCount(int count) {
    return '$count barang';
  }

  @override
  String get posCartEmpty => 'Keranjang kosong';

  @override
  String get posCartEmptyDesc =>
      'Scan barcode atau cari produk untuk menambah ke keranjang';

  @override
  String get posClearCart => 'Kosongkan';

  @override
  String get posClearCartConfirm => 'Kosongkan keranjang?';

  @override
  String get posClearCartConfirmDesc =>
      'Semua barang di keranjang akan dihapus.';

  @override
  String get posRemoveItem => 'Hapus Item';

  @override
  String get posQty => 'Qty';

  @override
  String get posSubtotal => 'Subtotal';

  @override
  String get posDiscount => 'Diskon';

  @override
  String get posDiscountPercent => 'Diskon (%)';

  @override
  String get posDiscountAmount => 'Diskon (Rp)';

  @override
  String get posLineDiscount => 'Diskon Baris';

  @override
  String get posBillDiscount => 'Diskon Nota';

  @override
  String get posTax => 'Pajak';

  @override
  String get posGrandTotal => 'Grand Total';

  @override
  String get posViewCart => 'Lihat Keranjang';

  @override
  String get posTransactionDetail => 'Detail Transaksi';

  @override
  String get posAddTransactionDetail => 'Tambah detail transaksi';

  @override
  String get posCustomer => 'Pelanggan';

  @override
  String get posNoCustomer => 'Tanpa Pelanggan';

  @override
  String get posSearchCustomer => 'Cari pelanggan...';

  @override
  String posAddContactNamed(String q) {
    return 'Tambah Kontak \"$q\"';
  }

  @override
  String get posCustomerMemo => 'Catatan Pelanggan';

  @override
  String get posCustomerMemoPlaceholder => 'misal: Budi, take away';

  @override
  String get posTableNumber => 'No. Meja';

  @override
  String get posTableNumberPlaceholder => 'misal: 12';

  @override
  String get posQueueNumber => 'No. Antrian';

  @override
  String get posQueueNumberPlaceholder => 'misal: 45';

  @override
  String get posHoldOrder => 'Tahan';

  @override
  String get posHoldLabel => 'Nama/Keterangan';

  @override
  String get posHoldLabelPlaceholder => 'mis. Bu Sri, meja 4';

  @override
  String get posHoldSuccess => 'Transaksi ditahan';

  @override
  String get posHeldOrders => 'Transaksi Ditahan';

  @override
  String get posNoHeldOrders => 'Tidak ada transaksi ditahan';

  @override
  String get posResumeOrder => 'Lanjutkan';

  @override
  String get posDropOrder => 'Buang';

  @override
  String get posPay => 'Bayar';

  @override
  String get posPaying => 'Memproses...';

  @override
  String get posPayment => 'Pembayaran';

  @override
  String get posAddTender => 'Tambah Metode';

  @override
  String get posRemoveTender => 'Hapus metode';

  @override
  String get posTenderMethodCASH => 'Tunai';

  @override
  String get posTenderMethodTRANSFER => 'Transfer';

  @override
  String get posTenderMethodEDC => 'EDC';

  @override
  String get posTenderMethodQRIS => 'QRIS';

  @override
  String get posTenderMethodKOMPLIMEN => 'Komplimen';

  @override
  String get posTenderAmount => 'Jumlah Pembayaran';

  @override
  String get posTenderReference => 'Memo';

  @override
  String get posCashTendered => 'Bayar';

  @override
  String get posExactAmount => 'Uang Pas';

  @override
  String get posPaidAmount => 'Terbayar';

  @override
  String get posRemaining => 'Sisa';

  @override
  String get posChangeDue => 'Kembalian';

  @override
  String get posConfirmPayment => 'Selesaikan';

  @override
  String get posTenderOverpaidNonCash =>
      'Pembayaran non-tunai tidak boleh melebihi total belanja. Kembalian hanya dari tunai.';

  @override
  String get posTenderEmptyCart => 'Keranjang masih kosong';

  @override
  String get posInsufficientCash => 'Uang kurang';

  @override
  String get posPaymentSuccess => 'Pembayaran berhasil';

  @override
  String get posChangeTitle => 'Kembalian';

  @override
  String get posNewSale => 'Transaksi Baru';

  @override
  String get posReceiptNumber => 'No. Transaksi';

  @override
  String get posReceiptTemporary => 'SEMENTARA';

  @override
  String get posQueuedRef => 'Kode';

  @override
  String get posOfflineNotSaved =>
      'Belum terkirim ke server. Penjualan sudah tersimpan di tablet ini dan akan dikirim otomatis begitu ada koneksi.';

  @override
  String get posCheckoutStorageFailed =>
      'Penjualan tidak bisa disimpan di tablet ini. Uang belum tercatat — jangan serahkan barang. Coba lagi.';

  @override
  String get queueTitle => 'Penjualan tertunda';

  @override
  String get queueSendNow => 'Kirim sekarang';

  @override
  String get queueEmpty => 'Semua penjualan sudah terkirim.';

  @override
  String get queueLoadFailed =>
      'Antrian tidak bisa dibaca. Periksa penyimpanan tablet ini, lalu coba lagi.';

  @override
  String get queueStatusPending => 'Menunggu';

  @override
  String get queueStatusFailed => 'Gagal';

  @override
  String get queueRetry => 'Ulangi';

  @override
  String get queueDiscard => 'Buang';

  @override
  String get queueDiscardTitle => 'Buang penjualan ini?';

  @override
  String get queueDiscardDesc =>
      'Barang sudah keluar dari toko. Membuang tanpa mengirim membuat catatan kas berkurang dari uang yang sebenarnya diterima.';

  @override
  String get menuQueueTitle => 'Penjualan tertunda';

  @override
  String menuQueueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count menunggu dikirim',
    );
    return '$_temp0';
  }

  @override
  String get menuQueueEmpty => 'Semua sudah terkirim.';

  @override
  String get posCheckoutRejected => 'Penjualan tidak tercatat';

  @override
  String get posPaymentFailed => 'Penjualan belum bisa dikirim. Coba lagi.';

  @override
  String get tillDetailAdd => 'Tambah detail transaksi';

  @override
  String tillDetailCustomer(String name) {
    return 'Pelanggan: $name';
  }

  @override
  String tillDetailMemo(String memo) {
    return 'Catatan: $memo';
  }

  @override
  String tillDetailTable(String number) {
    return 'Meja: $number';
  }

  @override
  String tillDetailQueue(String number) {
    return 'Antrian: $number';
  }

  @override
  String get tillDetailDone => 'Selesai';

  @override
  String get tillDetailSelectCustomer => 'Pilih pelanggan';

  @override
  String get tillDetailClearCustomer => 'Hapus pelanggan';

  @override
  String get tillDetailCustomerNone => 'Tidak ada pelanggan ditemukan.';

  @override
  String get tillDetailCustomerFailed =>
      'Belum bisa membaca daftar pelanggan. Periksa koneksi lalu coba lagi.';

  @override
  String get tillDetailCreateFailed =>
      'Pelanggan belum bisa disimpan. Coba lagi.';

  @override
  String get tillDetailCreateNoAnswer =>
      'Belum bisa menghubungi server. Periksa koneksi lalu coba lagi.';

  @override
  String get tillDetailNameRequired => 'Nama pelanggan belum diisi.';

  @override
  String get uiPrevious => 'Sebelumnya';

  @override
  String get uiNext => 'Berikutnya';

  @override
  String get menuShiftDetail => 'Detail shift';

  @override
  String get menuShiftHistory => 'Riwayat shift';

  @override
  String get shiftHistoryTitle => 'Riwayat Shift';

  @override
  String get shiftHistoryAll => 'Semua';

  @override
  String get shiftHistoryEmpty => 'Belum ada shift.';

  @override
  String get shiftHistoryLoadFailed =>
      'Riwayat shift belum bisa dimuat. Periksa koneksi, lalu coba lagi.';

  @override
  String get saleDetailTitle => 'Detail penjualan';

  @override
  String get saleDetailLoadFailed =>
      'Detail penjualan belum bisa dibaca. Periksa koneksi, lalu coba lagi.';

  @override
  String get saleDetailVoided => 'Penjualan ini dibatalkan.';

  @override
  String get saleDetailCashier => 'Kasir';

  @override
  String get saleDetailNoItems =>
      'Rincian barang tidak tersedia untuk penjualan ini.';

  @override
  String get saleDetailUnknownProduct => 'Barang tidak dikenal';

  @override
  String get saleDetailTax => 'Pajak';

  @override
  String get saleDetailPayments => 'Pembayaran';

  @override
  String get saleDetailTendered => 'Uang diterima';

  @override
  String get saleDetailNotes => 'Catatan';

  @override
  String get shiftDetailTitle => 'Detail shift';

  @override
  String get shiftDetailOpen => 'Terbuka';

  @override
  String get shiftDetailClosed => 'Ditutup';

  @override
  String get shiftDetailNone =>
      'Tidak ada shift yang terbuka. Buka shift dari layar kasir.';

  @override
  String shiftDetailHeldDesc(String number, String cashier) {
    return 'Shift $number dibuka oleh $cashier. Rinciannya hanya tampil untuk kasir itu, atau atasan dengan izin Override Shift Kasir.';
  }

  @override
  String get shiftDetailLoadFailed =>
      'Rincian shift belum bisa dibaca. Periksa koneksi, lalu coba lagi.';

  @override
  String get shiftDetailClosedAtLabel => 'Ditutup pada';

  @override
  String get shiftDetailOutletLabel => 'Outlet';

  @override
  String get shiftDetailFiguresTitle => 'Hitungan kas';

  @override
  String get shiftDetailTransactions => 'Jumlah transaksi';

  @override
  String get shiftDetailTotalSales => 'Total penjualan';

  @override
  String get shiftDetailOpeningCash => 'Modal awal';

  @override
  String get shiftDetailCashIn => 'Kas masuk';

  @override
  String get shiftDetailCashOut => 'Kas keluar';

  @override
  String get shiftDetailCashDrop => 'Setoran';

  @override
  String get shiftDetailCashOutAndDrop => 'Kas keluar dan setoran';

  @override
  String get shiftDetailExpectedCash => 'Kas yang seharusnya ada';

  @override
  String get shiftDetailCountedCash => 'Kas terhitung';

  @override
  String shiftDetailVarianceShort(String amount) {
    return 'Kurang $amount';
  }

  @override
  String shiftDetailVarianceOver(String amount) {
    return 'Lebih $amount';
  }

  @override
  String get shiftDetailVarianceNone => 'Pas';

  @override
  String get shiftDetailVarianceLabel => 'Selisih';

  @override
  String get shiftDetailByMethodTitle => 'Penjualan per metode';

  @override
  String get shiftDetailNoSales => 'Belum ada penjualan di shift ini.';

  @override
  String get shiftDetailNotes => 'Catatan';

  @override
  String get shiftDetailTabFigures => 'Ringkasan';

  @override
  String get shiftDetailTabSales => 'Transaksi';

  @override
  String get shiftDetailTabMovements => 'Mutasi kas';

  @override
  String get shiftDetailSaleVoided => 'Dibatalkan';

  @override
  String get shiftDetailMoreFailed =>
      'Belum bisa memuat lebih banyak. Ketuk untuk mencoba lagi.';

  @override
  String get shiftDetailNoMovements =>
      'Belum ada kas masuk atau keluar di shift ini.';

  @override
  String get closeShiftTitle => 'Tutup shift';

  @override
  String get closeShiftLoadFailed =>
      'Angka shift belum bisa dibaca. Periksa koneksi, lalu coba lagi.';

  @override
  String closeShiftOverrideNotice(String cashier) {
    return 'Anda menutup shift milik $cashier. Catatan wajib diisi.';
  }

  @override
  String get closeShiftNotesLabel => 'Catatan';

  @override
  String get closeShiftNoteNeededVariance =>
      'Drawer tidak sama dengan hitungan. Tulis alasannya sebelum menutup.';

  @override
  String get closeShiftNoteNeededOverride =>
      'Anda bukan pemegang shift ini. Tulis alasan menutupnya sebelum menutup.';

  @override
  String get closeShiftNoteOptional => 'Boleh dikosongkan';

  @override
  String get closeShiftButton => 'Tutup shift';

  @override
  String get closeShiftClosing => 'Menutup shift…';

  @override
  String get closeShiftDone => 'Shift ditutup.';

  @override
  String get closeShiftRefused => 'Shift belum bisa ditutup.';

  @override
  String get closeShiftUncertain =>
      'Belum ada jawaban pasti dari server, jadi shift mungkin sudah tertutup. Periksa dulu sebelum mencoba menutup lagi.';

  @override
  String shiftCloseBlockedByQueue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count penjualan di outlet ini belum terkirim. Ketuk untuk membuka Penjualan tertunda.',
    );
    return '$_temp0';
  }

  @override
  String get cashMovementTitle => 'Catat kas masuk atau keluar';

  @override
  String get cashMovementAmount => 'Jumlah';

  @override
  String get cashMovementReasonRequired => 'Alasan (wajib)';

  @override
  String get cashMovementReasonHint => 'Misalnya: beli galon air';

  @override
  String get cashMovementAccount => 'Akun';

  @override
  String get cashMovementAccountRequired => 'Akun (wajib)';

  @override
  String get cashMovementAccountNone => 'Pilih akun';

  @override
  String get cashMovementAccountSearch => 'Cari akun';

  @override
  String get cashMovementAccountEmpty => 'Akun tidak ditemukan.';

  @override
  String get cashMovementAccountFailed =>
      'Akun belum bisa dibaca. Periksa koneksi, lalu coba lagi.';

  @override
  String get cashMovementSettingsFailed =>
      'Pengaturan kas belum bisa dibaca, jadi catatan belum bisa disimpan. Periksa koneksi, lalu coba lagi.';

  @override
  String get cashMovementDone => 'Kas tercatat.';

  @override
  String get cashMovementRefused => 'Catatan kas belum bisa disimpan.';

  @override
  String get cashMovementUncertain =>
      'Belum ada jawaban pasti dari server, jadi catatan ini mungkin sudah tersimpan. Periksa daftar Mutasi kas sebelum mencoba lagi.';

  @override
  String get tillHold => 'Tahan';

  @override
  String get tillHoldTitle => 'Tahan keranjang';

  @override
  String get tillHoldNameLabel => 'Nama (boleh kosong)';

  @override
  String get tillHoldNameHint => 'Misalnya: Meja 4';

  @override
  String get tillHoldDone => 'Keranjang ditahan.';

  @override
  String get tillHoldNotStored =>
      'Keranjang belum bisa disimpan di tablet ini, jadi tidak ditahan. Isinya tetap di layar.';

  @override
  String get tillResumeNotStored =>
      'Keranjang yang sedang tampil belum bisa disimpan, jadi keranjang lain tidak dibuka. Isinya tetap di layar.';

  @override
  String get tillHeld => 'Ditahan';

  @override
  String tillHeldCount(int count) {
    return 'Ditahan ($count)';
  }

  @override
  String get heldTitle => 'Keranjang ditahan';

  @override
  String get heldEmpty => 'Tidak ada keranjang yang ditahan.';

  @override
  String get heldResume => 'Lanjutkan';

  @override
  String get heldDrop => 'Buang';

  @override
  String get heldDropTitle => 'Buang keranjang ini?';

  @override
  String heldDropDesc(String label) {
    return 'Isi keranjang $label akan hilang dan tidak bisa dikembalikan.';
  }

  @override
  String get updateReadyMessage =>
      'Pembaruan siap. Restart aplikasi untuk menerapkannya.';

  @override
  String get nativeUpdateReadyMessage => 'Versi baru siap dipasang.';

  @override
  String get nativeUpdateAction => 'Pasang';
}
