/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pn_ui/src/widgets/top_notice.dart';

/// A screen with the app theme and a button that shows a notice, which is how every caller uses
/// this.
Widget rig({
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
  Duration? duration,
}) {
  late BuildContext ctx;
  return MaterialApp(
    theme: pnTheme(Brightness.light),
    home: Scaffold(
      body: Builder(
        builder: (context) {
          ctx = context;
          return const SizedBox.expand();
        },
      ),
    ),
    builder: (context, child) {
      // Shown on the first frame after mount, so the test drives it the way a tap would.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ctx.mounted) {
          showTopNotice(
            ctx,
            message: message,
            actionLabel: actionLabel,
            onAction: onAction,
            duration: duration ?? const Duration(seconds: 4),
          );
        }
      });
      return child!;
    },
  );
}

/// Runs the clock forward in frames, which is what a real screen does.
Future<void> elapse(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 100);
  for (var i = 0; i < total.inMilliseconds ~/ step.inMilliseconds; i++) {
    await tester.pump(step);
  }
}

void main() {
  testWidgets('says what happened', (tester) async {
    await tester.pumpWidget(rig(message: 'Nasi dihapus'));
    await tester.pump();

    expect(find.text('Nasi dihapus'), findsOneWidget);
  });

  testWidgets('leaves on its own, even with an action', (tester) async {
    await tester.pumpWidget(
      rig(
        message: 'Nasi dihapus',
        actionLabel: 'Urungkan',
        onAction: () {},
      ),
    );
    await tester.pump();
    expect(find.text('Nasi dihapus'), findsOneWidget);

    // The whole reason this helper exists: a plain `SnackBar` with a `SnackBarAction` never
    // leaves in this framework version (measured: still there after 12 s against a 4 s
    // duration, while the same bar without an action was gone). This one is closed by its own
    // clock, so the wait below must find nothing.
    await elapse(tester, const Duration(seconds: 6));

    expect(find.text('Nasi dihapus'), findsNothing);
  });

  testWidgets('leaves on its own when it has no action either', (tester) async {
    await tester.pumpWidget(rig(message: 'Kode tidak ditemukan'));
    await tester.pump();

    await elapse(tester, const Duration(seconds: 6));

    expect(find.text('Kode tidak ditemukan'), findsNothing);
  });

  testWidgets('does not sit over the bottom of the screen', (tester) async {
    // 800x600, the size the bug was measured at: the default SnackBar this replaces covered
    // `Rect.fromLTRB(0.0, 552.0, 800.0, 600.0)`, which is where Pay lives.
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(rig(message: 'Nasi dihapus'));
    await tester.pump();

    final rect = tester.getRect(find.text('Nasi dihapus'));
    expect(
      rect.bottom,
      lessThan(600 - 200),
      reason: 'the notice must stay clear of the bottom action area',
    );
    expect(rect.top, greaterThanOrEqualTo(0));
  });

  testWidgets('runs the action, and then goes away', (tester) async {
    var undone = false;
    await tester.pumpWidget(
      rig(
        message: 'Nasi dihapus',
        actionLabel: 'Urungkan',
        onAction: () => undone = true,
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Urungkan'));
    // The action runs at once; the notice then fades out and removes itself.
    expect(undone, isTrue);

    await elapse(tester, const Duration(milliseconds: 500));

    // Dismissed rather than lingering after it has been used.
    expect(find.text('Nasi dihapus'), findsNothing);
  });

  testWidgets('a second notice replaces the first', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        theme: pnTheme(Brightness.light),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );

    showTopNotice(ctx, message: 'Nasi dihapus');
    await tester.pump();
    showTopNotice(ctx, message: 'Teh dihapus');
    await tester.pump();

    // Two stacked bars would cover the catalogue, and the older one is about something that
    // already happened.
    expect(find.text('Teh dihapus'), findsOneWidget);
    expect(find.text('Nasi dihapus'), findsNothing);
  });

  // The notice leaves on its own, but a cashier who has read it should not have to wait it out,
  // and it sits over the catalogue. Swiping up is the gesture the platform already uses to
  // dismiss this kind of bar.
  testWidgets('a swipe up takes it away', (tester) async {
    await tester.pumpWidget(rig(message: 'Nasi dihapus'));
    await tester.pump();
    expect(find.text('Nasi dihapus'), findsOneWidget);

    await tester.drag(find.text('Nasi dihapus'), const Offset(0, -80));
    await tester.pumpAndSettle();

    expect(find.text('Nasi dihapus'), findsNothing);
  });

  // A drag that does not go anywhere is a slipped thumb, not a dismissal: the notice must come
  // back, or a cashier brushing the screen would lose the undo they were reaching for.
  testWidgets('a small drag does not take it away', (tester) async {
    await tester.pumpWidget(rig(message: 'Nasi dihapus'));
    await tester.pump();

    await tester.drag(find.text('Nasi dihapus'), const Offset(0, -8));
    await tester.pumpAndSettle();

    expect(find.text('Nasi dihapus'), findsOneWidget);
  });

  // A side drag must not dismiss either: the gesture is "up", and nothing else.
  testWidgets('a sideways drag does not take it away', (tester) async {
    await tester.pumpWidget(rig(message: 'Nasi dihapus'));
    await tester.pump();

    await tester.drag(find.text('Nasi dihapus'), const Offset(-200, 0));
    await tester.pumpAndSettle();

    expect(find.text('Nasi dihapus'), findsOneWidget);
  });

  testWidgets('dismissing by swipe runs no action', (tester) async {
    var undone = false;
    await tester.pumpWidget(
      rig(
        message: 'Nasi dihapus',
        actionLabel: 'Urungkan',
        onAction: () => undone = true,
      ),
    );
    await tester.pump();

    await tester.drag(find.text('Nasi dihapus'), const Offset(0, -80));
    await tester.pumpAndSettle();

    // Swiping says "I have read this", not "undo it". Undoing a removal by accident would put
    // a line back that the cashier deliberately took out.
    expect(undone, isFalse);
    expect(find.text('Nasi dihapus'), findsNothing);
  });
}
