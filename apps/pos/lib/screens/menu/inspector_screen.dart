/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pos/branding/company_avatar.dart';
import 'package:pos/http/inspector/request_inspector.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/screens/common/screen_header.dart';

/// What the app sent and what came back, for whoever is debugging it (README §14).
///
/// Everything on it was redacted when it was recorded, so this screen only shows it.
class InspectorScreen extends StatefulWidget {
  const InspectorScreen({super.key, required this.inspector});

  final RequestInspector inspector;

  @override
  State<InspectorScreen> createState() => _InspectorScreenState();
}

class _InspectorScreenState extends State<InspectorScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final entries = widget.inspector.entries;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: l10n.inspectorTitle,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The list is a snapshot taken at build: a request made while it is open shows
                  // up when asked for, and not by moving the rows under a finger.
                  IconButton(
                    tooltip: l10n.inspectorRefresh,
                    icon: const Icon(Icons.refresh),
                    onPressed: () => setState(() {}),
                  ),
                  IconButton(
                    tooltip: l10n.inspectorClear,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => setState(widget.inspector.clear),
                  ),
                  // Wrapped rather than replaced: these two actions stay, and the avatar sits
                  // at the far end of the same row.
                  const CompanyAvatar(),
                ],
              ),
            ),
            Expanded(
              child: entries.isEmpty
                  ? Center(child: Text(l10n.inspectorEmpty))
                  : ListView(
                      children: [
                        // Latest first: what a person debugging wants is what just happened.
                        for (final e in entries.reversed)
                          _RequestTile(entry: e),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One request: the line, and when opened everything recorded of it.
class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.entry});

  final InspectedRequest entry;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final e = entry;
    return ExpansionTile(
      title: Text(e.url),
      // No status when nothing answered: what went wrong is the useful part then.
      subtitle: Text('${e.method} · ${e.statusCode ?? e.error}'),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _Block(l10n.inspectorRequestHeaders, _lines(e.requestHeaders)),
        if (e.requestBody != null)
          _Block(l10n.inspectorRequestBody, _pretty(e.requestBody)),
        if (e.responseHeaders != null)
          _Block(l10n.inspectorResponseHeaders, _lines(e.responseHeaders!)),
        if (e.responseBody != null)
          _Block(l10n.inspectorResponseBody, _pretty(e.responseBody)),
      ],
    );
  }
}

/// A labelled piece of text that can be selected, since what it is for is being copied out.
class _Block extends StatelessWidget {
  const _Block(this.label, this.text);

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.titleSmall),
          const SizedBox(height: 4),
          SelectableText(text, style: theme.bodySmall),
        ],
      ),
    );
  }
}

String _lines(Map<String, String> headers) =>
    headers.entries.map((h) => '${h.key}: ${h.value}').join('\n');

String _pretty(Object? body) {
  try {
    return const JsonEncoder.withIndent('  ').convert(body);
  } on JsonUnsupportedObjectError {
    // A body that is not JSON (text, an HTML error page) is shown as it is.
    return '$body';
  }
}
