// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class L10nEn extends L10n {
  L10nEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Finnesia POS';

  @override
  String get shiftLoadFailed =>
      'Could not read the shift data. Check the connection and try again.';

  @override
  String get shiftRequiredTitle => 'Open a shift first';

  @override
  String get shiftRequiredDesc =>
      'Count the cash in the drawer and enter it as the opening cash before you start selling.';

  @override
  String get shiftOpeningCashLabel => 'Opening cash';

  @override
  String get shiftOpenButton => 'Open shift';

  @override
  String get shiftKeypadBackspace => 'Delete digit';

  @override
  String get shiftOpenUnavailable =>
      'Could not reach the server. Check the connection and try again.';

  @override
  String get shiftOpening => 'Opening shift…';

  @override
  String get shiftOpenTitle => 'Shift still open';

  @override
  String get shiftOpenDesc =>
      'A shift is already open at this outlet. Continue it to start selling.';

  @override
  String get shiftOpenStaleDesc =>
      'This shift is still open. Check the figures below before you continue it.';

  @override
  String get shiftNumberLabel => 'Shift number';

  @override
  String get shiftOpenedAtLabel => 'Opened';

  @override
  String get shiftCashierLabel => 'Cashier';

  @override
  String get shiftHeldTitle => 'Shift held by another cashier';

  @override
  String get shiftUnknownCashier => 'another cashier';

  @override
  String shiftContinue(String number) {
    return 'Continue shift $number';
  }

  @override
  String shiftHeldDesc(String number, String cashier) {
    return 'Shift $number was opened by $cashier and is still open. It has to be closed before you can sell at this outlet.';
  }

  @override
  String get tillSearchHint => 'Search a product or scan a barcode';

  @override
  String get tillCategoryAll => 'All';

  @override
  String get tillCatalogLoadFailed =>
      'Could not read the product list. Check the connection and try again.';

  @override
  String get tillNoProducts => 'No products';

  @override
  String get tillNoProductsDesc => 'Try another search or category.';

  @override
  String get tillOutOfStock => 'Out';

  @override
  String get tillCartTitle => 'Cart';

  @override
  String get tillCartEmpty => 'The cart is empty';

  @override
  String get tillCartEmptyDesc => 'Tap a product or scan a barcode to add it.';

  @override
  String get tillClearCart => 'Clear';

  @override
  String get tillClearTitle => 'Clear the cart?';

  @override
  String get tillClearDesc => 'Every item in the cart will be removed.';

  @override
  String get tillSubtotal => 'Subtotal';

  @override
  String get tillDiscount => 'Discount';

  @override
  String get tillTotal => 'Total';

  @override
  String get tillUndo => 'Undo';

  @override
  String get tillLookupFailed =>
      'Could not look that product up. Check the connection and try again.';

  @override
  String tillItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String tillQtyLess(String name) {
    return 'Decrease quantity of $name';
  }

  @override
  String tillQtyMore(String name) {
    return 'Increase quantity of $name';
  }

  @override
  String tillRemoveLine(String name) {
    return 'Remove $name';
  }

  @override
  String tillLineRemoved(String name) {
    return '$name removed';
  }

  @override
  String tillStatusCashier(String name) {
    return 'Cashier: $name';
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
      other: '$count not sent',
      one: '$count not sent',
    );
    return '$_temp0';
  }

  @override
  String tillStatusQueueFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count not sent, some failed',
      one: '$count not sent, one failed',
    );
    return '$_temp0';
  }

  @override
  String tillCodeNotFound(String code) {
    return 'No product with code $code.';
  }

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get bootFailed =>
      'The device data could not be opened. This tablet\'s pairing has not been removed. Try again.';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSaving => 'Saving...';

  @override
  String get commonLoadFailed => 'Failed to load data';

  @override
  String get commonSaveFailed => 'Failed to save data';

  @override
  String get commonDelete => 'Delete the last digit';

  @override
  String get commonLanguageId => 'Indonesia';

  @override
  String get commonLanguageEn => 'English';

  @override
  String get commonLanguageLabel => 'Language';

  @override
  String get commonThemeLabel => 'Theme';

  @override
  String get commonThemeSystem => 'Follow system';

  @override
  String get commonThemeLight => 'Light';

  @override
  String get commonThemeDark => 'Dark';

  @override
  String get pairingTitle => 'Pair this tablet';

  @override
  String get pairingSubtitle =>
      'Enter the code from your Finnesia dashboard to connect this tablet to your outlet.';

  @override
  String get pairingDeviceNameLabel => 'Tablet name';

  @override
  String get pairingDeviceNamePlaceholder => 'Register 1';

  @override
  String get pairingDeviceNameHint =>
      'Shown in the dashboard so each tablet is easy to tell apart.';

  @override
  String get pairingCodeLabel => 'Pairing code';

  @override
  String get pairingCodeHint =>
      'You can find the code in the Finnesia dashboard, under Outlet.';

  @override
  String get pairingSubmit => 'Pair';

  @override
  String get pairingSubmitting => 'Pairing…';

  @override
  String get pairingScanButton => 'Scan QR';

  @override
  String get pairingScanTitle => 'Scan pairing QR';

  @override
  String get pairingScanHint =>
      'Point the camera at the QR in the Finnesia dashboard.';

  @override
  String get pairingScanDenied =>
      'Camera access is off. Allow it for this app in Settings, or type the code.';

  @override
  String get pairingScanUnavailable =>
      'The camera cannot be used. Type the pairing code instead.';

  @override
  String get pairingInvalidCode => 'The code is 6 letters or digits.';

  @override
  String get pairingCodeRejected =>
      'This code was not recognized, has already been used, or has expired. Generate a new one in the dashboard.';

  @override
  String get pairingUnavailable =>
      'Could not reach the server. Check your internet connection and try again.';

  @override
  String get pairingStorageFailed =>
      'The tablet could not save its data. Try again.';

  @override
  String get pairingDeviceLimitReached =>
      'This outlet has reached its tablet limit. Delete one of the tablets on the dashboard, then try again.';

  @override
  String pairingDeviceLimitReachedWithLimit(int limit) {
    return 'This outlet has reached its limit of $limit cashier tablets. Delete one of them on the dashboard, then try again.';
  }

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginSubtitle =>
      'Sign in with your account to start selling at this outlet.';

  @override
  String get loginDeviceLabel => 'Device';

  @override
  String get loginSubmit => 'Sign in';

  @override
  String get loginSubmitting => 'Waiting for login…';

  @override
  String get loginWaiting =>
      'Finish signing in on the browser that just opened. This page continues on its own once you are done.';

  @override
  String get loginNotPaired =>
      'This device is not paired yet. Pair it before signing in.';

  @override
  String get loginUnavailable =>
      'Could not reach the server. Check the connection and try again.';

  @override
  String get loginExpired =>
      'That login request has expired. Try signing in again.';

  @override
  String get loginTimeout => 'The login timed out. Try signing in again.';

  @override
  String get loginRetry => 'Try again';

  @override
  String get loginResetButton => 'Reset device';

  @override
  String get loginResetTitle => 'Reset this device?';

  @override
  String get loginResetDesc =>
      'This tablet will be released from the outlet and removed from the dashboard, and you will need a new pairing code to connect it again.';

  @override
  String loginResetHeldOrders(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count held baskets will be deleted too.',
      one: '1 held basket will be deleted too.',
    );
    return '$_temp0';
  }

  @override
  String get loginResetConfirm => 'Yes, reset';

  @override
  String get loginResetCancel => 'Cancel';

  @override
  String get loginResetServerFailed =>
      'The tablet was released here, but the server could not be reached. It may still be listed in the dashboard.';

  @override
  String get loginResetQueueBlocked =>
      'Reset is not possible yet: this tablet still has a sale that has not been sent. Sign in and send it, or discard it in Pending sales, before resetting.';

  @override
  String get menuTitle => 'Menu';

  @override
  String get menuBack => 'Back';

  @override
  String get menuAccountSection => 'Account';

  @override
  String get menuSessionSection => 'This device';

  @override
  String get menuCashierLabel => 'Cashier';

  @override
  String get menuUnknownUser => 'Unknown';

  @override
  String get menuDeviceLabel => 'Device';

  @override
  String get menuOutletLabel => 'Outlet';

  @override
  String get menuShiftSection => 'Shift';

  @override
  String get menuNoShift => 'No shift open';

  @override
  String get menuShiftLoadFailed => 'Could not load the shift.';

  @override
  String get menuOutletLoadFailed => 'Could not load the outlet name.';

  @override
  String get menuSignOut => 'Sign out';

  @override
  String get menuSignOutTitle => 'Sign out of this account?';

  @override
  String get menuSignOutDesc =>
      'The tablet stays paired to this outlet, so there is no pairing to redo. You will need to sign in again to sell.';

  @override
  String get menuSignOutConfirm => 'Yes, sign out';

  @override
  String get menuSignOutFailed => 'Could not sign out. Try again.';

  @override
  String menuSignOutBlocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'You still have $count sales that have not been sent. Send them before signing out.',
      one:
          'You still have $count sale that has not been sent. Send it before signing out.',
    );
    return '$_temp0';
  }

  @override
  String menuVersion(String version, String build) {
    return 'Version $version ($build)';
  }

  @override
  String get menuVersionUnknown => 'Version unknown';

  @override
  String get menuPrinterSection => 'Printer';

  @override
  String get menuPrinterNone => 'No printer yet';

  @override
  String get menuPrinterUnreadable => 'The saved printer cannot be read';

  @override
  String get menuPrinterPair => 'Connect a printer';

  @override
  String get menuPrinterChange => 'Change printer';

  @override
  String get menuPrinterForget => 'Forget printer';

  @override
  String get menuPrinterForgetTitle => 'Forget this printer?';

  @override
  String get menuPrinterForgetDesc =>
      'The tablet will not print to this printer again until you connect one.';

  @override
  String get menuPrinterForgetConfirm => 'Yes, forget it';

  @override
  String get menuPrinterForgetFailed =>
      'Could not forget the printer. Try again.';

  @override
  String get inspectorTitle => 'Request inspector';

  @override
  String get inspectorEmpty => 'No requests recorded yet.';

  @override
  String get inspectorClear => 'Clear all';

  @override
  String get inspectorRefresh => 'Refresh';

  @override
  String get inspectorRequestHeaders => 'Request headers';

  @override
  String get inspectorRequestBody => 'Request body';

  @override
  String get inspectorResponseHeaders => 'Response headers';

  @override
  String get inspectorResponseBody => 'Response body';

  @override
  String get menuOpen => 'Menu';

  @override
  String get contactQuickAddTitle => 'Add New Customer';

  @override
  String get contactNameLabel => 'Customer Name';

  @override
  String get contactNamePlaceholder => 'Customer name...';

  @override
  String get contactPhoneLabel => 'Phone Number';

  @override
  String get contactEmailLabel => 'Email';

  @override
  String get contactCompanyLabel => 'Company Name (optional)';

  @override
  String get contactAddressLabel => 'Address';

  @override
  String get contactCreated => 'Customer added';

  @override
  String get printerPairTitle => 'Connect a Printer';

  @override
  String get printerPairDesc =>
      'Make sure the printer is on, then scan to find it. The printer you pick is remembered by this tablet.';

  @override
  String get printerScanButton => 'Scan for printers';

  @override
  String get printerScanning => 'Scanning…';

  @override
  String get printerNoneFound =>
      'No printer found. Make sure it is on and within range.';

  @override
  String get printerUnnamed => 'Unnamed';

  @override
  String get printerPairing => 'Connecting…';

  @override
  String printerPaired(String name) {
    return 'Printer connected: $name';
  }

  @override
  String get printerPermissionDenied =>
      'Bluetooth access is denied. Allow Bluetooth for Finnesia POS in Settings, then try again.';

  @override
  String get printerBluetoothOff =>
      'The tablet’s Bluetooth is off. Turn it on and try again.';

  @override
  String get printerScanFailed => 'Could not scan for printers.';

  @override
  String get printerPairFailed => 'Could not connect to the printer.';

  @override
  String get printerUnsupported =>
      'This tablet has no Bluetooth that can be used for a printer.';

  @override
  String get printerSaveFailed =>
      'The printer connected, but the tablet could not remember it. Try choosing it again.';

  @override
  String get printerNotConnected =>
      'No printer connected. Turn the printer on and try again.';

  @override
  String get printerPrintFailed => 'Could not send the report to the printer.';

  @override
  String get printerPrintSuccess => 'Report sent to the printer';

  @override
  String get printerPrintShiftReport => 'Print Report';

  @override
  String get posActiveShift => 'Active Shift';

  @override
  String get posNoActiveShift => 'No active shift';

  @override
  String get posShiftNumber => 'Shift Number';

  @override
  String get posOpenedAt => 'Opened At';

  @override
  String get posOpeningCash => 'Opening Cash';

  @override
  String get posTotalSales => 'Total Sales';

  @override
  String get posTotalTransactions => 'Total Transactions';

  @override
  String get posExpectedCash => 'Expected Cash';

  @override
  String get posShiftRequired => 'Shift Required';

  @override
  String get posShiftRequiredDesc =>
      'You have to open a shift before you can sell.';

  @override
  String get posShiftAlreadyOpen => 'Shift Still Open';

  @override
  String get posShiftAlreadyOpenDesc =>
      'A shift is already open at this outlet. Continue it, or close it before starting a new one.';

  @override
  String get posShiftAlreadyOpenStaleDesc =>
      'This shift is still open. Check it first, then continue or close it.';

  @override
  String posContinueShift(String number) {
    return 'Continue Shift $number';
  }

  @override
  String get posShiftHeldByAnother => 'Shift Held By Another Cashier';

  @override
  String posShiftHeldByAnotherDesc(String number, String cashier) {
    return 'Shift $number was opened by $cashier and has not been closed. Ask that cashier to close it.';
  }

  @override
  String posShiftHeldByAnotherNoOverride(String cashier) {
    return 'Ask $cashier to close their shift, or a supervisor with the Override Cashier Shift permission.';
  }

  @override
  String get posOverrideCloseShift => 'Close Shift (Override)';

  @override
  String posOverrideCloseNotice(String cashier) {
    return 'You are closing a shift held by $cashier. A note is required.';
  }

  @override
  String get posOverrideNoteRequired =>
      'Closing a shift held by another cashier requires a note explaining why';

  @override
  String get posUnknownCashier => 'Unknown';

  @override
  String get posOpenShift => 'Open Shift';

  @override
  String get posOpenShiftSuccess => 'Shift opened';

  @override
  String get posCloseShift => 'Close Shift';

  @override
  String get posCloseShiftSuccess => 'Shift closed';

  @override
  String get posShiftSummary => 'Shift Summary';

  @override
  String get posShiftDetail => 'Shift Detail';

  @override
  String get posShiftOpen => 'Shift Open';

  @override
  String get posShiftClosed => 'Shift Closed';

  @override
  String get posClosedAt => 'Closed At';

  @override
  String get posOutlet => 'Outlet';

  @override
  String get posNotes => 'Notes';

  @override
  String get posTransactions => 'Transactions';

  @override
  String get posEmptyTransactions => 'No transactions yet';

  @override
  String get posSalesByMethod => 'Sales by Method';

  @override
  String get posShiftReportTitle => 'SHIFT CLOSING REPORT';

  @override
  String get posPrintedAt => 'Printed';

  @override
  String get receiptTitle => 'Sales Receipt';

  @override
  String get receiptPrint => 'Print receipt';

  @override
  String get receiptSent => 'Receipt sent to the printer';

  @override
  String get receiptLoadFailed => 'The receipt could not be loaded. Try again.';

  @override
  String get receiptPaymentMethod => 'Payment Method';

  @override
  String get receiptVoided => '*** TRANSACTION VOIDED ***';

  @override
  String get receiptNoItems => 'No item details';

  @override
  String receiptPaidBy(String method) {
    return 'Paid ($method)';
  }

  @override
  String get posPaymentsByMethod => 'Payments by Method';

  @override
  String get posTotal => 'Total';

  @override
  String get posDepositSection => 'Deposit';

  @override
  String get posCashSalesLabel => 'Cash Payments';

  @override
  String get posTotalDeposit => 'Total Deposit';

  @override
  String get posNonCashPayments => 'Non-Cash Payments';

  @override
  String get posNoNonCashPayments => 'No non-cash payments in this shift';

  @override
  String get posProductsSoldTitle => 'Products Sold';

  @override
  String get posProductsSoldTotal => 'Products Sold Total';

  @override
  String get posCountedCash => 'Counted Cash';

  @override
  String get posVariance => 'Variance';

  @override
  String get posVarianceNote =>
      'A note is required when the drawer does not match';

  @override
  String get posVarianceReason => 'Variance Reason';

  @override
  String get posShiftNotesPlaceholder => 'Shift note...';

  @override
  String get posCashier => 'Cashier';

  @override
  String get posLoading => 'Loading...';

  @override
  String get posCashMovement => 'Cash Movement';

  @override
  String get posCashMovements => 'Drawer Movements';

  @override
  String get posNoCashMovements => 'No cash movements';

  @override
  String get posCashIn => 'Cash In';

  @override
  String get posCashOut => 'Cash Out';

  @override
  String get posCashDrop => 'Cash Drop';

  @override
  String get posAmount => 'Amount';

  @override
  String get posCashInTotal => 'Total Cash In';

  @override
  String get posCashOutTotal => 'Total Cash Out';

  @override
  String get posCashMovementReason => 'Note / Goods Bought';

  @override
  String get posCashMovementReasonPlaceholder => 'e.g. bought a water gallon';

  @override
  String get posCashMovementAccount => 'Account (optional)';

  @override
  String get posCashMovementAccountRequired => 'Account';

  @override
  String get posCashMovementProduct => 'Goods (optional)';

  @override
  String get posCashMovementSelectProduct => '-- Select Goods --';

  @override
  String get posCashMovementNoProduct => 'No goods found';

  @override
  String get posCashMovementSuccess => 'Cash movement recorded';

  @override
  String get posSelectTenderAccount => 'Select a cash/bank account';

  @override
  String get posSearchTenderAccount => 'Search account...';

  @override
  String get posNoTenderAccount => 'No account found';

  @override
  String get posSearchProduct => 'Search product, SKU, or barcode...';

  @override
  String get posAllCategories => 'All';

  @override
  String get posNoProducts => 'No products';

  @override
  String get posNoProductsDesc =>
      'Try another keyword or pick another category';

  @override
  String get posCatalogLoadFailed =>
      'Could not load the catalogue. Check the connection and try again.';

  @override
  String get posOutOfStock => 'Out';

  @override
  String get posNotFound => 'Not found';

  @override
  String get posCart => 'Cart';

  @override
  String posItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get posCartEmpty => 'Cart is empty';

  @override
  String get posCartEmptyDesc =>
      'Scan a barcode or search for a product to add it to the cart';

  @override
  String get posClearCart => 'Clear';

  @override
  String get posClearCartConfirm => 'Clear the cart?';

  @override
  String get posClearCartConfirmDesc =>
      'Everything in the cart will be removed.';

  @override
  String get posRemoveItem => 'Remove Item';

  @override
  String get posQty => 'Qty';

  @override
  String get posSubtotal => 'Subtotal';

  @override
  String get posDiscount => 'Discount';

  @override
  String get posDiscountPercent => 'Discount (%)';

  @override
  String get posDiscountAmount => 'Discount (Rp)';

  @override
  String get posLineDiscount => 'Line Discount';

  @override
  String get posBillDiscount => 'Bill Discount';

  @override
  String get posTax => 'Tax';

  @override
  String get posGrandTotal => 'Grand Total';

  @override
  String get posViewCart => 'View Cart';

  @override
  String get posTransactionDetail => 'Transaction Detail';

  @override
  String get posAddTransactionDetail => 'Add transaction detail';

  @override
  String get posCustomer => 'Customer';

  @override
  String get posNoCustomer => 'No Customer';

  @override
  String get posSearchCustomer => 'Search customer...';

  @override
  String posAddContactNamed(String q) {
    return 'Add contact \"$q\"';
  }

  @override
  String get posCustomerMemo => 'Customer Note';

  @override
  String get posCustomerMemoPlaceholder => 'e.g. Budi, take away';

  @override
  String get posTableNumber => 'Table No.';

  @override
  String get posTableNumberPlaceholder => 'e.g. 12';

  @override
  String get posQueueNumber => 'Queue No.';

  @override
  String get posQueueNumberPlaceholder => 'e.g. 45';

  @override
  String get posHoldOrder => 'Hold';

  @override
  String get posHoldLabel => 'Name/Note';

  @override
  String get posHoldLabelPlaceholder => 'e.g. Mrs Sri, table 4';

  @override
  String get posHoldSuccess => 'Order held';

  @override
  String get posHeldOrders => 'Held Orders';

  @override
  String get posNoHeldOrders => 'No held orders';

  @override
  String get posResumeOrder => 'Resume';

  @override
  String get posDropOrder => 'Drop';

  @override
  String get posPay => 'Pay';

  @override
  String get posPaying => 'Processing...';

  @override
  String get posPayment => 'Payment';

  @override
  String get posAddTender => 'Add Method';

  @override
  String get posRemoveTender => 'Remove method';

  @override
  String get posTenderMethodCASH => 'Cash';

  @override
  String get posTenderMethodTRANSFER => 'Transfer';

  @override
  String get posTenderMethodEDC => 'EDC';

  @override
  String get posTenderMethodQRIS => 'QRIS';

  @override
  String get posTenderMethodKOMPLIMEN => 'Complimentary';

  @override
  String get posTenderAmount => 'Payment Amount';

  @override
  String get posTenderReference => 'Memo';

  @override
  String get posCashTendered => 'Tendered';

  @override
  String get posExactAmount => 'Exact Amount';

  @override
  String get posPaidAmount => 'Paid';

  @override
  String get posRemaining => 'Remaining';

  @override
  String get posChangeDue => 'Change';

  @override
  String get posConfirmPayment => 'Complete';

  @override
  String get posTenderOverpaidNonCash =>
      'A non-cash payment cannot exceed the bill. Change only ever comes from cash.';

  @override
  String get posTenderEmptyCart => 'The cart is still empty';

  @override
  String get posInsufficientCash => 'Not enough money';

  @override
  String get posPaymentSuccess => 'Payment successful';

  @override
  String get posChangeTitle => 'Change';

  @override
  String get posNewSale => 'New Sale';

  @override
  String get posReceiptNumber => 'Sale No.';

  @override
  String get posReceiptTemporary => 'NOT SENT';

  @override
  String get posQueuedRef => 'Code';

  @override
  String get posOfflineNotSaved =>
      'Not sent to the server yet. The sale is saved on this tablet and will be sent automatically once there is a connection.';

  @override
  String get posCheckoutStorageFailed =>
      'The sale could not be saved on this tablet. Nothing has been recorded — do not hand over the goods. Try again.';

  @override
  String get queueTitle => 'Pending sales';

  @override
  String get queueSendNow => 'Send now';

  @override
  String get queueEmpty => 'Every sale has been sent.';

  @override
  String get queueLoadFailed =>
      'The queue could not be read. Check this tablet\'s storage, then try again.';

  @override
  String get queueStatusPending => 'Waiting';

  @override
  String get queueStatusFailed => 'Failed';

  @override
  String get queueRetry => 'Retry';

  @override
  String get queueDiscard => 'Discard';

  @override
  String get queueDiscardTitle => 'Discard this sale?';

  @override
  String get queueDiscardDesc =>
      'The goods have already left the shop. Discarding it without sending leaves the drawer short of what was actually received.';

  @override
  String get menuQueueTitle => 'Pending sales';

  @override
  String menuQueueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count waiting to send',
      one: '$count waiting to send',
    );
    return '$_temp0';
  }

  @override
  String get menuQueueEmpty => 'Every sale has been sent.';

  @override
  String get posCheckoutRejected => 'The sale was not recorded';

  @override
  String get posPaymentFailed => 'The sale could not be sent. Try again.';

  @override
  String get tillDetailAdd => 'Add transaction detail';

  @override
  String tillDetailCustomer(String name) {
    return 'Customer: $name';
  }

  @override
  String tillDetailMemo(String memo) {
    return 'Note: $memo';
  }

  @override
  String tillDetailTable(String number) {
    return 'Table: $number';
  }

  @override
  String tillDetailQueue(String number) {
    return 'Queue: $number';
  }

  @override
  String get tillDetailDone => 'Done';

  @override
  String get tillDetailSelectCustomer => 'Select customer';

  @override
  String get tillDetailClearCustomer => 'Clear customer';

  @override
  String get tillDetailCustomerNone => 'No customer found.';

  @override
  String get tillDetailCustomerFailed =>
      'The customer list could not be read. Check the connection and try again.';

  @override
  String get tillDetailCreateFailed =>
      'The customer could not be saved. Try again.';

  @override
  String get tillDetailCreateNoAnswer =>
      'The server could not be reached. Check the connection and try again.';

  @override
  String get tillDetailNameRequired => 'The customer name is still empty.';

  @override
  String get uiPrevious => 'Previous';

  @override
  String get uiNext => 'Next';

  @override
  String get menuShiftDetail => 'Shift detail';

  @override
  String get menuShiftHistory => 'Shift history';

  @override
  String get shiftHistoryTitle => 'Shift History';

  @override
  String get shiftHistoryAll => 'All';

  @override
  String get shiftHistoryEmpty => 'No shifts yet.';

  @override
  String get shiftHistoryLoadFailed =>
      'The shift history could not be loaded. Check the connection and try again.';

  @override
  String get saleDetailTitle => 'Sale detail';

  @override
  String get saleDetailLoadFailed =>
      'The sale could not be read. Check the connection and try again.';

  @override
  String get saleDetailVoided => 'This sale was voided.';

  @override
  String get saleDetailCashier => 'Cashier';

  @override
  String get saleDetailNoItems => 'The goods for this sale are not available.';

  @override
  String get saleDetailUnknownProduct => 'Unknown item';

  @override
  String get saleDetailTax => 'Tax';

  @override
  String get saleDetailPayments => 'Payments';

  @override
  String get saleDetailTendered => 'Received';

  @override
  String get saleDetailNotes => 'Notes';

  @override
  String get shiftDetailTitle => 'Shift detail';

  @override
  String get shiftDetailOpen => 'Open';

  @override
  String get shiftDetailClosed => 'Closed';

  @override
  String get shiftDetailNone => 'No shift is open. Open one from the till.';

  @override
  String shiftDetailHeldDesc(String number, String cashier) {
    return 'Shift $number was opened by $cashier. Its details are only shown to that cashier, or to a supervisor with the Override Cashier Shift permission.';
  }

  @override
  String get shiftDetailLoadFailed =>
      'The shift could not be read. Check the connection and try again.';

  @override
  String get shiftDetailClosedAtLabel => 'Closed at';

  @override
  String get shiftDetailOutletLabel => 'Outlet';

  @override
  String get shiftDetailFiguresTitle => 'Cash count';

  @override
  String get shiftDetailTransactions => 'Transactions';

  @override
  String get shiftDetailTotalSales => 'Total sales';

  @override
  String get shiftDetailOpeningCash => 'Opening cash';

  @override
  String get shiftDetailCashIn => 'Cash in';

  @override
  String get shiftDetailCashOut => 'Cash out';

  @override
  String get shiftDetailCashDrop => 'Cash drop';

  @override
  String get shiftDetailCashOutAndDrop => 'Cash out and drops';

  @override
  String get shiftDetailExpectedCash => 'Expected cash';

  @override
  String get shiftDetailCountedCash => 'Counted cash';

  @override
  String shiftDetailVarianceShort(String amount) {
    return 'Short $amount';
  }

  @override
  String shiftDetailVarianceOver(String amount) {
    return 'Over $amount';
  }

  @override
  String get shiftDetailVarianceNone => 'Exact';

  @override
  String get shiftDetailVarianceLabel => 'Variance';

  @override
  String get shiftDetailByMethodTitle => 'Sales by method';

  @override
  String get shiftDetailNoSales => 'No sales in this shift yet.';

  @override
  String get shiftDetailNotes => 'Notes';

  @override
  String get shiftDetailTabFigures => 'Summary';

  @override
  String get shiftDetailTabSales => 'Sales';

  @override
  String get shiftDetailTabMovements => 'Cash movements';

  @override
  String get shiftDetailSaleVoided => 'Voided';

  @override
  String get shiftDetailMoreFailed => 'Could not load more. Tap to try again.';

  @override
  String get shiftDetailNoMovements => 'No cash in or out in this shift yet.';

  @override
  String get closeShiftTitle => 'Close shift';

  @override
  String get closeShiftLoadFailed =>
      'The shift figures could not be read. Check the connection and try again.';

  @override
  String closeShiftOverrideNotice(String cashier) {
    return 'You are closing a shift held by $cashier. A note is required.';
  }

  @override
  String get closeShiftNotesLabel => 'Note';

  @override
  String get closeShiftNoteNeededVariance =>
      'The drawer does not match the count. Write the reason before closing.';

  @override
  String get closeShiftNoteNeededOverride =>
      'This is not your shift. Write why you are closing it before closing.';

  @override
  String get closeShiftNoteOptional => 'Optional';

  @override
  String get closeShiftButton => 'Close shift';

  @override
  String get closeShiftClosing => 'Closing shift…';

  @override
  String get closeShiftDone => 'Shift closed.';

  @override
  String get closeShiftRefused => 'The shift could not be closed.';

  @override
  String get closeShiftUncertain =>
      'There was no clear answer from the server, so the shift may already be closed. Check before trying to close it again.';

  @override
  String shiftCloseBlockedByQueue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count sales at this outlet have not been sent. Tap to open Pending sales.',
      one:
          '$count sale at this outlet has not been sent. Tap to open Pending sales.',
    );
    return '$_temp0';
  }

  @override
  String get cashMovementTitle => 'Record cash in or out';

  @override
  String get cashMovementAmount => 'Amount';

  @override
  String get cashMovementReasonRequired => 'Reason (required)';

  @override
  String get cashMovementReasonHint => 'For example: bought a water gallon';

  @override
  String get cashMovementAccount => 'Account';

  @override
  String get cashMovementAccountRequired => 'Account (required)';

  @override
  String get cashMovementAccountNone => 'Pick an account';

  @override
  String get cashMovementAccountSearch => 'Search accounts';

  @override
  String get cashMovementAccountEmpty => 'No account found.';

  @override
  String get cashMovementAccountFailed =>
      'The accounts could not be read. Check the connection and try again.';

  @override
  String get cashMovementSettingsFailed =>
      'The cash settings could not be read, so this cannot be saved yet. Check the connection and try again.';

  @override
  String get cashMovementDone => 'Cash recorded.';

  @override
  String get cashMovementRefused => 'The cash movement could not be saved.';

  @override
  String get cashMovementUncertain =>
      'There was no clear answer from the server, so this may already be saved. Check the cash movements list before trying again.';

  @override
  String get tillHold => 'Hold';

  @override
  String get tillHoldTitle => 'Hold this basket';

  @override
  String get tillHoldNameLabel => 'Name (optional)';

  @override
  String get tillHoldNameHint => 'For example: Table 4';

  @override
  String get tillHoldDone => 'Basket held.';

  @override
  String get tillHoldNotStored =>
      'The basket could not be saved on this tablet, so it was not held. It is still on the screen.';

  @override
  String get tillResumeNotStored =>
      'The basket on the screen could not be saved, so the other one was not opened. It is still on the screen.';

  @override
  String get tillHeld => 'Held';

  @override
  String tillHeldCount(int count) {
    return 'Held ($count)';
  }

  @override
  String get heldTitle => 'Held baskets';

  @override
  String get heldEmpty => 'No baskets are held.';

  @override
  String get heldResume => 'Resume';

  @override
  String get heldDrop => 'Discard';

  @override
  String get heldDropTitle => 'Discard this basket?';

  @override
  String heldDropDesc(String label) {
    return 'The contents of basket $label will be lost and cannot be recovered.';
  }

  @override
  String get updateReadyMessage => 'Update ready. Restart the app to apply it.';

  @override
  String get nativeUpdateReadyMessage => 'New version ready to install.';

  @override
  String get nativeUpdateAction => 'Install';
}
