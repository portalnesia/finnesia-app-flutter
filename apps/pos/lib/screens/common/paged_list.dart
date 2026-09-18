/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pn_ui/src/widgets/state_view.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/state/loadable.dart';
import 'package:pos/state/paged_loadable.dart';

/// A list read a page at a time, in its three states: loading, failed (with a way to try again),
/// and the rows, which ask for the next page as the end comes near.
///
/// Words are passed in ([failedTitle], [emptyTitle], [moreFailedLabel]) so each list says what it
/// is a list of (`style.md` §7.1).
class PagedListPane<T> extends StatelessWidget {
  const PagedListPane({
    super.key,
    required this.source,
    required this.itemBuilder,
    required this.failedTitle,
    required this.emptyTitle,
    required this.moreFailedLabel,
    this.listKey,
  });

  final PagedLoadable<T> source;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String failedTitle;
  final String emptyTitle;

  /// Said at the end of the list when the next page could not be read; tapping it asks again.
  final String moreFailedLabel;
  final Key? listKey;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return ListenableBuilder(
      listenable: source,
      builder: (context, _) => switch (source.state) {
        Loading() => StateView.loading(label: l10n.commonLoading),
        // The server's own sentence when it refused, [failedTitle] when nobody answered. A list
        // under a subscription that has ended is refused with 402 on every read, and telling a
        // cashier to check the connection would send them after a problem only the owner can fix.
        Failed(:final error) => StateView(
          title: failedReadText(error, failedTitle),
          actionLabel: l10n.commonRetry,
          onAction: source.load,
        ),
        Ready(:final data) when data.items.isEmpty => StateView(
          title: emptyTitle,
        ),
        Ready(:final data) => _list(context, data),
      },
    );
  }

  Widget _list(BuildContext context, PagedItems<T> data) {
    final pn = context.pn;
    final theme = Theme.of(context).textTheme;
    final hasFooter = data.loadingMore || data.moreError != null;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Near the end, ask for the next page. Not after it failed: that waits for a tap, or
        // every scroll frame would ask again. Read from the source and not from [data]: a scroll
        // notification can arrive between the failure and the rebuild that shows it, and [data] is
        // still the list from before.
        final now = source.state;
        if (now is Ready<PagedItems<T>> &&
            now.data.moreError == null &&
            notification.metrics.extentAfter < 600) {
          source.loadMore();
        }
        return false;
      },
      child: ListView.builder(
        key: listKey,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: data.items.length + (hasFooter ? 1 : 0),
        itemBuilder: (context, i) {
          if (i < data.items.length) return itemBuilder(context, data.items[i]);
          if (data.loadingMore) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          // Reached only when the footer is the failed-next-page row: `hasFooter` is true and it
          // is not loading. The reason the server gave is worth showing here too — a next page
          // refused for the same reason as the first one is the same problem, said once.
          final error = data.moreError;
          return InkWell(
            onTap: source.loadMore,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  error == null
                      ? moreFailedLabel
                      : failedReadText(error, moreFailedLabel),
                  textAlign: TextAlign.center,
                  style: theme.bodyMedium!.copyWith(color: pn.errorText),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
