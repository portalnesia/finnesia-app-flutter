/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/widgets.dart';
import 'package:pos/native/scanner/scanner_port.dart';

/// A [ScannerPort] with no camera: a test decides what it "reads".
///
/// Lives in `lib/` so every test in the app can use the same one
/// (`.claude/rules/native-ports.md` §2.3).
class FakeScanner implements ScannerPort {
  /// What [isAvailable] answers. A test sets it to `false` to be a platform with no scanner.
  @override
  bool isAvailable = true;

  final _failure = ValueNotifier<ScannerFailure?>(null);
  void Function(String code)? _onCode;

  /// How many camera views were put on screen: a view that never opened is a scan button that
  /// did nothing.
  int viewsBuilt = 0;

  /// Whether a view is on screen now. Closing the view is what turns the real camera off.
  bool get isShowing => _onCode != null;

  /// The camera "reads" [code]. Throws when no view is showing, so a test cannot scan into the
  /// void and still pass.
  void read(String code) {
    final onCode = _onCode;
    if (onCode == null) throw StateError('no camera view is showing');
    onCode(code);
  }

  /// The camera "cannot start": the view swaps to the caller's failure content.
  void fail(ScannerFailure failure) => _failure.value = failure;

  @override
  Widget buildView({
    required void Function(String code) onCode,
    required Widget Function(BuildContext context, ScannerFailure failure)
    failureBuilder,
  }) {
    viewsBuilt++;
    return _FakeView(
      scanner: this,
      onCode: onCode,
      failureBuilder: failureBuilder,
    );
  }
}

class _FakeView extends StatefulWidget {
  const _FakeView({
    required this.scanner,
    required this.onCode,
    required this.failureBuilder,
  });

  final FakeScanner scanner;
  final void Function(String code) onCode;
  final Widget Function(BuildContext context, ScannerFailure failure)
  failureBuilder;

  @override
  State<_FakeView> createState() => _FakeViewState();
}

class _FakeViewState extends State<_FakeView> {
  @override
  void initState() {
    super.initState();
    widget.scanner._onCode = widget.onCode;
  }

  @override
  void dispose() {
    widget.scanner._onCode = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ScannerFailure?>(
    valueListenable: widget.scanner._failure,
    builder: (context, failure, _) => failure == null
        ? const SizedBox.expand()
        : widget.failureBuilder(context, failure),
  );
}
