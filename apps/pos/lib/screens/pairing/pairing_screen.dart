/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pn_types/src/api/environment.dart';
import 'package:pn_types/src/pairing_code.dart';
import 'package:pn_ui/src/layout/window_class.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pn_ui/src/widgets/segmented_code_field.dart';
import 'package:pos/app/app_scope.dart';
import 'package:pos/app/finnesia_logo.dart';
import 'package:pos/device/device_identity.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/pairing/pairing_controller.dart';
import 'package:pos/preferences/app_preferences.dart';
import 'package:pos/screens/pairing/scan_dialog.dart';

/// S2: pairs this tablet with an outlet, before anyone is signed in.
///
/// Beside the form on a wide screen and above it on a narrow one: the logo and what to do are on
/// the left, the fields on the right, and both fit whatever the tablet is turned to.
class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  PairingController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Once: the services do not change for the life of the screen, and the controller reads the
    // pairing dependencies through them when it sends, so an endpoint picked here is honoured.
    final services = AppScope.of(context);
    _controller ??= PairingController(
      () => services.pairingDeps,
      analytics: services.analytics,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller!;
    final header = _Header(l10n: L10n.of(context));
    final form = ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _Form(controller: controller),
    );

    return Scaffold(
      body: SafeArea(
        child: context.windowClass == WindowClass.compact
            ? _Scroll(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _LanguagePicker(),
                    const SizedBox(height: 16),
                    header,
                    const SizedBox(height: 32),
                    form,
                  ],
                ),
              )
            : Row(
                children: [
                  Expanded(
                    child: ColoredBox(
                      color: context.pn.surfaceMuted,
                      child: _Scroll(child: header),
                    ),
                  ),
                  Expanded(
                    child: _Scroll(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _LanguagePicker(),
                          const SizedBox(height: 32),
                          form,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Centres [child] in the room it has, and scrolls when it is taller: a large text size on a
/// landscape tablet must not cut the button off.
class _Scroll extends StatelessWidget {
  const _Scroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: child,
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.l10n});

  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FinnesiaLogo(width: 240, semanticLabel: l10n.appName),
        const SizedBox(height: 32),
        Semantics(
          header: true,
          child: Text(l10n.pairingTitle, style: theme.headlineMedium),
        ),
        const SizedBox(height: 8),
        Text(l10n.pairingSubtitle, style: theme.bodyLarge),
      ],
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker();

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final language = AppScope.of(context).language;
    return Align(
      alignment: Alignment.centerRight,
      // Here because there is no menu yet: a tablet set up in the wrong language would have no
      // way to change it before pairing and signing in.
      child: ListenableBuilder(
        listenable: language,
        builder: (context, _) => SegmentedButton<AppLanguage>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: AppLanguage.id,
              label: Text(l10n.commonLanguageId),
            ),
            ButtonSegment(
              value: AppLanguage.en,
              label: Text(l10n.commonLanguageEn),
            ),
          ],
          selected: {language.value},
          onSelectionChanged: (picked) => language.select(picked.single),
        ),
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({required this.controller});

  final PairingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context).textTheme;
    final pn = context.pn;
    final services = AppScope.of(context);
    final problem = controller.problem;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          maxLength: deviceNameMax,
          decoration: InputDecoration(
            labelText: l10n.pairingDeviceNameLabel,
            hintText: l10n.pairingDeviceNamePlaceholder,
            helperText: l10n.pairingDeviceNameHint,
            helperMaxLines: 2,
            counterText: '',
          ),
          textInputAction: TextInputAction.next,
          onChanged: controller.setDeviceName,
        ),
        const SizedBox(height: 24),
        Text(l10n.pairingCodeLabel, style: theme.labelLarge),
        const SizedBox(height: 8),
        SegmentedCodeField(
          length: pairingCodeLength,
          value: controller.code,
          filter: applyPairingCodeInput,
          onChanged: controller.setCode,
          onSubmitted: controller.submit,
          label: l10n.pairingCodeLabel,
          hasError: problem != null,
          enabled: !controller.isSubmitting,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.pairingCodeHint,
          style: theme.bodySmall!.copyWith(color: pn.inkMuted),
        ),
        // Only where there is a camera scanner: on Windows the plugin has no implementation, and
        // a button that opens a view which throws is worse than no button (R-26).
        if (services.scanner.isAvailable) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: controller.isSubmitting
                ? null
                : () => showScanDialog(
                    context,
                    scanner: services.scanner,
                    controller: controller,
                  ),
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(l10n.pairingScanButton),
          ),
        ],
        if (problem != null) ...[
          const SizedBox(height: 16),
          // A live region: a screen reader says it when it appears, without the cashier having
          // to find it. It is words, not only red.
          Semantics(
            liveRegion: true,
            child: Text(
              _messageOf(l10n, problem),
              style: theme.bodyMedium!.copyWith(color: pn.errorText),
            ),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          // Disabled while a request is out, and still drawn as the amber main button: the
          // default disabled look would grey out the words that say what is happening.
          style: FilledButton.styleFrom(
            disabledBackgroundColor: pn.accent,
            disabledForegroundColor: pn.onAccent,
          ),
          onPressed: controller.isSubmitting ? null : controller.submit,
          child: controller.isSubmitting
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(l10n.pairingSubmitting),
                  ],
                )
              : Text(l10n.pairingSubmit),
        ),
        // Debug builds only, and only before pairing: after it the host is the session host
        // (`canPickEndpoint`). It is names and a host, not prose, and no cashier sees it.
        if (services.canPickEndpoint) ...[
          const SizedBox(height: 32),
          Text(services.pairingDeps.canonicalHost, style: theme.bodySmall),
          const SizedBox(height: 8),
          SegmentedButton<EndpointEnvironment>(
            showSelectedIcon: false,
            segments: [
              for (final env in EndpointEnvironment.values)
                ButtonSegment(value: env, label: Text(env.name)),
            ],
            selected: {services.endpoint},
            onSelectionChanged: (picked) =>
                services.chooseEndpoint(picked.single),
          ),
        ],
      ],
    );
  }

  String _messageOf(L10n l10n, PairingProblem problem) => switch (problem) {
    PairingProblem.invalidCode => l10n.pairingInvalidCode,
    PairingProblem.codeRejected => l10n.pairingCodeRejected,
    PairingProblem.unavailable => l10n.pairingUnavailable,
    PairingProblem.storage => l10n.pairingStorageFailed,
    // The one message that names the number, and the only one whose fix is somewhere other than
    // this screen. Without the number from the server, the generic wording is used rather than
    // a placeholder: "batas tablet" is still actionable, "batas {limit} tablet" is not.
    PairingProblem.deviceLimitReached =>
      controller.deviceLimit == null
          ? l10n.pairingDeviceLimitReached
          : l10n.pairingDeviceLimitReachedWithLimit(controller.deviceLimit!),
  };
}
