/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pn_ui/src/widgets/top_notice.dart';
import 'package:pos/app/app_scope.dart';
import 'package:pos/app/finnesia_logo.dart';
import 'package:pos/bootstrap.dart';
import 'package:pos/device/device_reset.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/login/login_controller.dart';

/// S3: signs the cashier in, on a device that is already paired.
///
/// There is no password field, and nothing to type. Signing in happens in the system browser —
/// the OIDC session lives in its cookie jar and never in this app's — and this screen only opens
/// it and waits. That is why it is one button and a sentence, rather than a form.
///
/// The tenant's own name and logo are here, because pairing already fetched the branding: a
/// cashier at Toko Budi should not be signing in to something called Finnesia POS.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return ListenableBuilder(
      listenable: services.login,
      builder: (context, _) => _Body(controller: services.login),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.controller});

  final LoginController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final services = AppScope.of(context);
    final session = services.session.current;
    final branding = session?.branding;
    // Most tenants never configure branding, and the product name is the documented fallback
    // rather than an error path (the backend's `logo_url` is optional for the same reason).
    final appName = branding?.appName ?? l10n.appName;
    final logoUrl = branding?.logoUrl;

    final card = _Card(
      appName: appName,
      logoUrl: logoUrl,
      deviceName: session?.deviceName,
      controller: controller,
    );

    return Scaffold(
      body: SafeArea(
        // One column at every width. This screen has one button and two sentences; splitting it
        // into two panels would be a layout for the sake of a layout.
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: card,
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.appName,
    required this.logoUrl,
    required this.deviceName,
    required this.controller,
  });

  final String appName;
  final String? logoUrl;
  final String? deviceName;
  final LoginController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context).textTheme;
    final pn = context.pn;
    final problem = controller.problem;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Identity(appName: appName, logoUrl: logoUrl),
        const SizedBox(height: 24),
        Text(l10n.loginSubtitle, style: theme.bodyMedium),
        if (deviceName != null && deviceName!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _DeviceLine(label: l10n.loginDeviceLabel, name: deviceName!),
        ],
        const SizedBox(height: 24),
        if (controller.isSigningIn) ...[
          // A live region: the cashier looks up from the browser and needs to be told the app
          // is waiting for them, without having to hunt for it.
          Semantics(
            liveRegion: true,
            child: Text(l10n.loginWaiting, style: theme.bodyMedium),
          ),
          const SizedBox(height: 16),
        ],
        if (problem != null) ...[
          Semantics(
            liveRegion: true,
            child: Text(
              _messageOf(l10n, problem),
              style: theme.bodyMedium!.copyWith(color: pn.errorText),
            ),
          ),
          const SizedBox(height: 16),
        ],
        FilledButton(
          // Disabled while a login is out, and still drawn as the amber main button: the default
          // disabled look would grey out the words that say what is happening.
          style: FilledButton.styleFrom(
            disabledBackgroundColor: pn.accent,
            disabledForegroundColor: pn.onAccent,
          ),
          onPressed: controller.isSigningIn ? null : controller.signIn,
          child: controller.isSigningIn
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(l10n.loginSubmitting),
                  ],
                )
              : Text(problem == null ? l10n.loginSubmit : l10n.loginRetry),
        ),
        if (controller.isSigningIn) ...[
          const SizedBox(height: 8),
          // The way out of a login the cashier did not mean to start, or is signed in to the
          // wrong account for. Without it the only exit is five minutes of waiting, or killing
          // the app (`plan/ui/findings.md` F5).
          TextButton(
            onPressed: controller.cancel,
            child: Text(l10n.commonCancel),
          ),
        ],
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 8),
        Align(alignment: Alignment.centerRight, child: _ResetDeviceButton()),
      ],
    );
  }

  String _messageOf(L10n l10n, LoginProblem problem) => switch (problem) {
    LoginProblem.notPaired => l10n.loginNotPaired,
    LoginProblem.unavailable => l10n.loginUnavailable,
    LoginProblem.expired => l10n.loginExpired,
    LoginProblem.timeout => l10n.loginTimeout,
  };
}

/// Who the cashier is signing in to: the tenant's logo when it has one, the Finnesia logo when
/// it does not (`dto/pos.go`: "Empty means the default Finnesia logo").
class _Identity extends StatelessWidget {
  const _Identity({required this.appName, required this.logoUrl});

  final String appName;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final url = logoUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (url == null || url.isEmpty)
          FinnesiaLogo(width: 240, semanticLabel: appName)
        else
          // Plain Image.network, not a cached loader: one image, fetched once, from the tenant's
          // own branding config. A cache library for a single logo would be a dependency for
          // nothing.
          Image.network(
            url,
            height: 40,
            // The tenant's own logo, so it is content rather than decoration: a screen reader
            // should say whose logo it is.
            semanticLabel: appName,
            errorBuilder: (context, _, _) =>
                FinnesiaLogo(width: 240, semanticLabel: appName),
          ),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          child: Text(appName, style: theme.headlineMedium),
        ),
        const SizedBox(height: 4),
        Text(L10n.of(context).loginTitle, style: theme.titleMedium),
      ],
    );
  }
}

class _DeviceLine extends StatelessWidget {
  const _DeviceLine({required this.label, required this.name});

  final String label;
  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final pn = context.pn;
    return Row(
      children: [
        Text(label, style: theme.bodySmall!.copyWith(color: pn.inkMuted)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: theme.bodyMedium,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// The escape hatch for a tablet paired to the wrong outlet. Without it the only way out is
/// clearing the app's data.
///
/// It now releases the device on the server too, and it can do that from here precisely because
/// the call needs no user session: the device token is the only credential
/// (`plan/pos-device-registry/01-kontrak-aplikasi-android.md` §3.4). That is also why the button
/// lives on this screen rather than in the Menu — this is the position the contract describes,
/// a cashier who is already logged out.
class _ResetDeviceButton extends StatelessWidget {
  const _ResetDeviceButton();

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final services = AppScope.of(context);

    return OutlinedButton(
      onPressed: () => _confirm(context, l10n, services),
      child: Text(l10n.loginResetButton),
    );
  }

  Future<void> _confirm(
    BuildContext context,
    L10n l10n,
    AppServices services,
  ) async {
    // Said before it is lost: a parked basket is a customer who is coming back.
    final held = (await services.holdStore.readAll()).length;
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.loginResetTitle),
        content: Text(
          held == 0
              ? l10n.loginResetDesc
              : '${l10n.loginResetDesc}\n\n${l10n.loginResetHeldOrders(held)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.loginResetCancel),
          ),
          // Destructive, so it is the filled one and the cancel is the quiet one: the safe
          // choice should be the easier one to hit.
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.loginResetConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final outcome = await resetDevice(services.deviceResetDeps);

    // Clearing the session is what unpairs the device, and the gate moves to pairing by itself
    // because it reads the session. Nothing here navigates.
    switch (outcome) {
      case DeviceResetOutcome.done:
        break;
      case DeviceResetOutcome.serverFailed:
        // Read after the await, and checked before use: the screen is gone by now in the
        // ordinary case (the gate already swapped it), and a message cannot be shown on a tree
        // that is not there. `services.session.clear()` also rebuilds this widget, so the
        // context can be defunct even while the route is alive.
        if (!context.mounted) return;
        showTopNotice(context, message: l10n.loginResetServerFailed);
      case DeviceResetOutcome.queueNotEmpty:
        // Nothing was touched (`resetDevice` refuses before it clears anything), so the
        // cashier is still on this screen and can sign in to deal with the queue.
        if (!context.mounted) return;
        showTopNotice(context, message: l10n.loginResetQueueBlocked);
    }
  }
}
