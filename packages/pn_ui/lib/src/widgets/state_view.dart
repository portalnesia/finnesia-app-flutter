/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';

/// What a screen shows instead of its data: still loading, nothing to show, or could not read.
///
/// Empty and failed are the same shape on purpose (a title, what to do about it, and an action if
/// there is one); only the words differ, and the words come from the caller. Every screen that
/// reads the server draws these before it draws the case where all went well.
class StateView extends StatelessWidget {
  const StateView({
    super.key,
    required String this.title,
    this.description,
    this.actionLabel,
    this.onAction,
  }) : loadingLabel = null;

  /// Still loading. [label] is shown and read aloud.
  const StateView.loading({super.key, required String label})
      : loadingLabel = label,
        title = null,
        description = null,
        actionLabel = null,
        onAction = null;

  final String? title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? loadingLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final loading = loadingLabel;

    // Scrollable, so a large text size on a landscape tablet cuts nothing off, least of all the
    // retry button.
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: loading != null
                ? [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(loading, style: theme.bodyLarge),
                  ]
                : [
                    Semantics(
                      header: true,
                      child: Text(
                        title!,
                        textAlign: TextAlign.center,
                        style: theme.titleLarge,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        description!,
                        textAlign: TextAlign.center,
                        style: theme.bodyLarge,
                      ),
                    ],
                    if (actionLabel != null && onAction != null) ...[
                      const SizedBox(height: 24),
                      FilledButton(
                          onPressed: onAction, child: Text(actionLabel!)),
                    ],
                  ],
          ),
        ),
      ),
    );
  }
}
