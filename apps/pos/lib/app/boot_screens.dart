/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pos/app/finnesia_logo.dart';
import 'package:pos/l10n/app_localizations.dart';

/// The logo, and [child] under it, centred and scrollable: at a large text size the failure
/// message can be taller than a landscape tablet, and clipping it would hide the retry.
class _BootLayout extends StatelessWidget {
  const _BootLayout({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FinnesiaLogo(
                  width: 240,
                  semanticLabel: L10n.of(context).appName,
                ),
                const SizedBox(height: 32),
                child,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Shown while the app reads what it needs to start.
class BootScreen extends StatelessWidget {
  const BootScreen({super.key});

  @override
  Widget build(BuildContext context) => _BootLayout(
    child: CircularProgressIndicator(
      semanticsLabel: L10n.of(context).commonLoading,
    ),
  );
}

/// Shown when the device's storage could not be opened.
///
/// It says so in a sentence and offers a retry, and does not send the cashier to pair: the
/// session may well be there, and only the Keystore cannot open it right now (`bootstrap`).
class BootFailedScreen extends StatelessWidget {
  const BootFailedScreen({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return _BootLayout(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.bootFailed,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
        ],
      ),
    );
  }
}
