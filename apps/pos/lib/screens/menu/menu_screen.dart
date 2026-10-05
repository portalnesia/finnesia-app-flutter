/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pn_pos/src/pos_pending_sale_store.dart';
import 'package:pn_types/src/api/environment.dart';
import 'package:pn_types/src/native/app_info_port.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:pn_types/src/pos_shift.dart';
import 'package:pn_types/src/session.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pn_ui/src/widgets/ledger_row.dart';
import 'package:pn_ui/src/widgets/top_notice.dart';
import 'package:pos/app/app_scope.dart';
import 'package:pos/bootstrap.dart';
import 'package:pos/branding/company_avatar.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/menu/menu_controller.dart';
import 'package:pos/native/http/active.dart';
import 'package:pos/screens/common/pickers.dart';
import 'package:pos/screens/common/screen_header.dart';
import 'package:pos/screens/menu/inspector_screen.dart';
import 'package:pos/queue/queue_sync.dart';
import 'package:pos/screens/menu/printer_card.dart';
import 'package:pos/screens/queue/pending_sales_screen.dart';
import 'package:pos/screens/shift/shift_history_screen.dart';
import 'package:pos/screens/shift/shift_screen.dart';
import 'package:pos/state/loadable.dart';

/// S14: everything the till is not.
///
/// Reached from the till's top bar rather than sitting in front of the till: a cashier's first
/// act is to sell, and this is where they go when they are not selling (`menu-page.tsx`).
///
/// **Signing out is the only action here that changes the device's state**, and it is the reason
/// this screen exists before the rest of C10. `clearToken` keeps the pairing: the tablet stays
/// registered to its outlet, and the next cashier only has to sign in. Nothing on this screen
/// unpairs — that is Reset Perangkat, and it lives on the login screen where an unpaired device
/// belongs.
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  MenuScreenController? _controller;
  void Function()? _unsubscribe;
  Future<AppVersion?>? _version;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Once: the services do not change for the life of the screen, and the reads do not depend
    // on anything that changes while it is open.
    final services = AppScope.of(context);
    _controller ??= MenuScreenController(
      client: services.client,
      outletId: services.session.current?.outletId ?? '',
    )..load();
    // The profile is completed from the server when the session cannot name the cashier, which is
    // what a browser login leaves behind (see `MenuScreenController.profile`).
    _controller!.loadProfile(services.session.current?.user);

    // Subscribed, not read once: this screen is a pushed route, and the gate rebuilds *underneath*
    // it. Without this, signing out clears the session and swaps `home` to the login screen while
    // the Menu keeps covering it — the cashier is logged out and still looking at the Menu.
    _unsubscribe ??= services.session.subscribe(_onSessionChanged);

    // Asked once, not on every rebuild: the build does not change while the screen is open.
    _version ??= services.appInfo.version();
  }

  /// Leaves when the credential this screen was opened for is gone.
  ///
  /// The test is "no session token", not "no session": signing out keeps the pairing and writes
  /// the session back without its token (`SessionHolder.clearToken`), so a null check would never
  /// fire. It is the same shape `gateDestination` reads to decide the cashier belongs on the
  /// login screen, which is what keeps the two from disagreeing.
  ///
  /// A rotated token writes a session that still has one, so a screen that closed on any change
  /// at all would shut itself mid-shift. A device re-paired elsewhere has no token either, and
  /// closing this screen is right there too.
  void _onSessionChanged(PosSession? next) {
    if (!mounted) return;
    if (next != null && next.sessionToken.isNotEmpty) return;
    // `maybePop` and not `pop`: the route may already be going away — a double tap, or a reset
    // from somewhere else — and popping a route that is not there throws.
    Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _unsubscribe?.call();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller!;
    final l10n = L10n.of(context);
    final services = AppScope.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: l10n.menuTitle,
              trailing: const CompanyAvatar(),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: controller,
                // A fixed handful of cards, so nothing is gained by building them lazily, and a
                // lazy list leaves the ones below the fold unbuilt: the sign-out button would not
                // exist for a screen reader until it was scrolled to.
                builder: (context, _) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    // A `ListView` stretched its children; a `Column` centres and shrinks them.
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AccountCard(
                        controller: controller,
                        session: services.session.current,
                      ),
                      const SizedBox(height: 12),
                      _DeviceCard(controller: controller),
                      const SizedBox(height: 12),
                      const _Card(child: PrinterCard()),
                      const SizedBox(height: 12),
                      _QueueCard(sync: services.queueSync),
                      const SizedBox(height: 12),
                      _ChoiceCard(
                        label: l10n.commonLanguageLabel,
                        child: const LanguagePicker(),
                      ),
                      const SizedBox(height: 12),
                      _ChoiceCard(
                        label: l10n.commonThemeLabel,
                        child: const ThemePicker(),
                      ),
                      const SizedBox(height: 20),
                      _SignOutButton(services: services),
                      const SizedBox(height: 16),
                      _VersionLine(version: _version!),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A card: a surface, not a control, so it is the softer of the two radii (`tokens.dart`).
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final pn = context.pn;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: pn.surface,
        borderRadius: BorderRadius.circular(PnRadius.surface),
        border: Border.all(color: pn.border),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

/// Who is signed in and which tablet this is.
///
/// The cashier row is always drawn, never conditional on the name: a session whose profile
/// carried no name used to leave the card with no cashier row at all, which reads as "nobody is
/// signed in" rather than "unknown" (`menu-page.tsx`).
///
/// The name comes from [MenuScreenController.profile] rather than straight from the session,
/// because a browser login stores a profile with an id and nothing else — see that getter.
class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.controller, required this.session});

  final MenuScreenController controller;
  final PosSession? session;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final user = controller.profile;
    final name = user?.name;
    final identity = (name != null && name.isNotEmpty) ? name : user?.email;
    final deviceName = session?.deviceName;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.menuAccountSection,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          LedgerRow(
            label: l10n.menuCashierLabel,
            value: (identity != null && identity.isNotEmpty)
                ? identity
                : l10n.menuUnknownUser,
          ),
          if (deviceName != null && deviceName.isNotEmpty) ...[
            const SizedBox(height: 8),
            LedgerRow(label: l10n.menuDeviceLabel, value: deviceName),
          ],
        ],
      ),
    );
  }
}

/// Where this tablet is pointed and which drawer is open.
///
/// The outlet is a read, not a picker: pairing locked it, so there is nothing to choose
/// (`menu-page.tsx`).
class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.controller});

  final MenuScreenController controller;

  @override
  Widget build(BuildContext context) {
    // `outlet` and `shift` are their own `Loadable`s, each a `ChangeNotifier` of its own — and
    // `MenuScreenController` never forwards their notifications (it only calls its own
    // `notifyListeners` from `loadProfile`). The screen's outer `ListenableBuilder(listenable:
    // controller)` therefore never rebuilds when either read finishes on its own: the request
    // completes (200, visible in the inspector), the state moves to `Ready`, and the card keeps
    // showing "Memuat..." until something unrelated happens to rebuild the tree. Listening here,
    // directly, is the same pattern `shift_screen.dart` already uses for its own `Loadable`s.
    return ListenableBuilder(
      listenable: Listenable.merge([controller.outlet, controller.shift]),
      builder: (context, _) => _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final l10n = L10n.of(context);
    final pn = context.pn;
    final theme = Theme.of(context).textTheme;

    // The outlet: its name, why it could not be read, or nothing yet. `null` is not an error
    // here — a session with no outlet asks for nothing and gets nothing.
    final outlet = switch (controller.outlet.state) {
      Ready(:final data) => data?.name,
      Failed(:final error) => failedReadText(error, l10n.menuOutletLoadFailed),
      Loading() => null,
    };
    final shiftState = controller.shift.state;
    final shift = switch (shiftState) {
      Ready(:final data) => data,
      Failed(:final error) => failedReadText(error, l10n.menuShiftLoadFailed),
      Loading() => null,
    };

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.menuSessionSection, style: theme.titleSmall),
          const SizedBox(height: 12),
          LedgerRow(
            label: l10n.menuOutletLabel,
            value: outlet ?? l10n.commonLoading,
          ),
          const SizedBox(height: 8),
          // A failed read is not "no shift is open": that would tell a cashier their drawer is
          // shut while it is not. `shift_gate_screen.dart` makes the same distinction — and a
          // read that has not answered yet is a third thing again, not a silent "no shift"
          // either: on a slow connection that wrong claim can sit on screen for a long time.
          if (shift is String)
            Text(shift, style: theme.bodyMedium!.copyWith(color: pn.errorText))
          else
            LedgerRow(
              label: l10n.menuShiftSection,
              value: switch (shift) {
                final POSShift s => s.number,
                _ when shiftState is Loading => l10n.commonLoading,
                _ => l10n.menuNoShift,
              },
            ),
          // Only for a shift that is known to be open: a failed read is not one, and there is
          // nothing to open for "no shift".
          if (shift is POSShift) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: PnTouch.min,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ShiftScreen()),
                ),
                child: Text(l10n.menuShiftDetail),
              ),
            ),
          ],
          // Always, and not only with a drawer open: the shifts already closed are what it is for,
          // and a report for one of them should not have to wait for a shift to be open.
          const SizedBox(height: 8),
          SizedBox(
            height: PnTouch.min,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ShiftHistoryScreen(),
                ),
              ),
              child: Text(l10n.menuShiftHistory),
            ),
          ),
        ],
      ),
    );
  }
}

/// A label beside a control that fills what is left of the row.
///
/// A [Wrap] and not a [Row]: the theme picker has three named choices, and at 600 dp with the
/// text at 1.3× a row of them beside the label overflows by 200 px. Wrapped, the control takes
/// its own line when it has to and the row is unchanged when it does not.
/// The offline queue, from wherever the cashier is — not only from the status strip item, which
/// is only there while something is queued (`plan/offline-queue/README.md` §7). Always shown,
/// the way "Riwayat shift" is: a way in, whether or not there is anything to see right now.
class _QueueCard extends StatelessWidget {
  const _QueueCard({required this.sync});

  final QueueSync sync;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context).textTheme;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListenableBuilder(
            listenable: sync,
            builder: (context, _) {
              final total = sync.pendingCount + sync.failedCount;
              return Text(
                total > 0 ? l10n.menuQueueCount(total) : l10n.menuQueueEmpty,
                style: theme.bodyMedium,
              );
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: PnTouch.min,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PendingSalesScreen(),
                ),
              ),
              child: Text(l10n.menuQueueTitle),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          child,
        ],
      ),
    );
  }
}

/// Signing out, behind a confirmation.
///
/// It says what actually happens — the pairing stays — because the sentence is the only place a
/// cashier can learn that they will not have to pair the tablet again (`style.md` §5).
class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return SizedBox(
      height: PnTouch.primary,
      child: FilledButton(
        onPressed: () => _confirm(context, l10n),
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.onError,
        ),
        child: Text(l10n.menuSignOut),
      ),
    );
  }

  Future<void> _confirm(BuildContext context, L10n l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.menuSignOutTitle),
        content: Text(l10n.menuSignOutDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          // Destructive, so it is the filled one and Cancel is the quiet one: the safe choice
          // should be the easier one to hit.
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.menuSignOutConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // D-Q1: the server attributes a sale to whoever is authenticated when it is sent, not to
    // whoever typed it, so a sale this cashier rang up must be sent (or discarded) by them
    // before they sign out — otherwise it is recorded against whoever signs in next
    // (`plan/offline-queue/README.md` §6).
    final cashierId = services.session.current?.user?.id;
    if (cashierId != null) {
      final count = await _ownQueueCount(services.pendingSaleStore, cashierId);
      if (count == null || count > 0) {
        if (!context.mounted) return;
        showTopNotice(
          context,
          // `null` means the queue could not be read at all — never treated as empty
          // (`pos_pending_sale_store.dart`), so this reuses the same sentence S17 shows for it.
          message: count == null
              ? l10n.queueLoadFailed
              : l10n.menuSignOutBlocked(count),
          actionLabel: l10n.menuQueueTitle,
          onAction: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const PendingSalesScreen()),
          ),
        );
        return;
      }
    }

    try {
      // The pairing stays: only the credential goes.
      await services.session.clearToken();
      // The gate has already moved to the login screen by now — it reads the session, and this
      // screen is subscribed to the same holder, so it takes itself off the top. Nothing to do
      // here, and nothing to navigate to: the gate owns where the app goes, and this screen only
      // owns whether it is still in the way.
    } on StoreException {
      // The token is gone from memory even when the disk write failed, so the gate has already
      // moved. Saying so is better than a silent nothing (`security.md` §5: no swallow).
      //
      // Through the overlay, not a SnackBar: the ScaffoldMessenger this was captured from
      // belongs to the screen the gate is about to replace, and a message shown through it can
      // be torn down with the screen it was meant to outlive.
      if (context.mounted) {
        showTopNotice(context, message: l10n.menuSignOutFailed);
      }
    }
  }
}

/// How many queued sales belong to [cashierId] — the D-Q1 guard for signing out.
///
/// `null` when the queue could not be read at all, which the caller treats as blocking too: an
/// unreadable queue is never an empty one (`pos_pending_sale_store.dart`).
Future<int?> _ownQueueCount(PendingSaleStore store, String cashierId) async {
  try {
    final all = await store.readAll();
    return all.where((sale) => sale.cashierId == cashierId).length;
  } on PendingSaleStoreException {
    return null;
  }
}

/// Which build this is, so a cashier reporting a problem can say what they are running.
///
/// "Unknown" and not a blank when the platform cannot say: a missing line reads as a screen that
/// did not finish loading.
///
/// In a debug app, tapping it seven times opens the request inspector (README §14.3). Hidden on
/// purpose and gated by `isDebugApp`, not by the endpoint choice: that choice exists only before
/// pairing, and this screen is reached after it. In a release build there is nothing to open.
class _VersionLine extends StatefulWidget {
  const _VersionLine({required this.version});

  final Future<AppVersion?> version;

  @override
  State<_VersionLine> createState() => _VersionLineState();
}

class _VersionLineState extends State<_VersionLine> {
  static const _taps = 7;

  // ponytail: a plain count with no time window; it resets when the screen closes.
  var _tapped = 0;

  void _onTap() {
    if (!isDebugApp) return;
    if (++_tapped < _taps) return;
    _tapped = 0;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InspectorScreen(inspector: requestInspector),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return FutureBuilder<AppVersion?>(
      future: widget.version,
      builder: (context, snapshot) {
        // Nothing while it is being read: a flash of "unknown" would be a lie for a frame.
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final known = snapshot.data;
        // Opaque, with a full-size target: no ripple, since a hidden control must not look like one.
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _onTap,
          child: SizedBox(
            height: PnTouch.min,
            child: Center(
              child: Text(
                known == null
                    ? l10n.menuVersionUnknown
                    : l10n.menuVersion(known.version, known.build),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall!
                    .copyWith(color: context.pn.inkMuted),
              ),
            ),
          ),
        );
      },
    );
  }
}
