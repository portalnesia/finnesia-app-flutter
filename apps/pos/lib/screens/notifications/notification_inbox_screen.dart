/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pn_types/src/api/api_error.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/native/opener_port.dart';
import 'package:pn_types/src/native/push_messaging_port.dart';
import 'package:pn_types/src/notification.dart';
import 'package:pn_types/src/session.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/native/opener/active.dart' as browser;
import 'package:pos/notifications/notification_inbox_controller.dart';
import 'package:pos/notifications/push_lifecycle_controller.dart';
import 'package:pos/notifications/notification_link_policy.dart';
import 'package:pos/screens/common/paged_list.dart';
import 'package:pos/screens/common/screen_header.dart';
import 'package:pos/state/loadable.dart';
import 'package:pos/state/paged_loadable.dart';

/// The in-app notification inbox. The menu owns [controller] so its unread badge stays in sync.
class NotificationInboxScreen extends StatefulWidget {
  const NotificationInboxScreen({
    super.key,
    required this.controller,
    required this.session,
    this.opener,
    this.pushController,
    this.initialNotificationId,
    this.initialCompanyId,
  });

  final NotificationInboxController controller;
  final PosSession? session;
  final OpenerPort? opener;
  final PushLifecycleController? pushController;
  final String? initialNotificationId;
  final String? initialCompanyId;

  @override
  State<NotificationInboxScreen> createState() =>
      _NotificationInboxScreenState();
}

class _NotificationInboxScreenState extends State<NotificationInboxScreen> {
  late final NotificationLinkPolicy _linkPolicy = NotificationLinkPolicy(
    widget.session,
  );
  final Set<String> _markingRead = {};
  final Set<String> _selectedIds = {};
  bool _selectionMode = false;
  bool _markingBulkRead = false;
  String? _openingId;

  bool get _isBusy =>
      _openingId != null || _markingBulkRead || _markingRead.isNotEmpty;

  List<NotificationItem> get _loadedUnreadItems {
    final state = widget.controller.inbox.state;
    if (state is! Ready<PagedItems<NotificationItem>>) return const [];
    return state.data.items
        .where((item) => item.readAt == null)
        .toList(growable: false);
  }

  bool get _allUnreadSelected {
    final unreadItems = _loadedUnreadItems;
    return unreadItems.isNotEmpty &&
        unreadItems.every((item) => _selectedIds.contains(item.id));
  }

  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.loadInbox());
    final notificationId = widget.initialNotificationId;
    if (notificationId != null && notificationId.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(
            _openNotificationId(notificationId, widget.initialCompanyId),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: l10n.notificationInboxTitle,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: _isBusy ? null : _toggleSelectionMode,
                    child: Text(
                      _selectionMode
                          ? l10n.notificationCancelSelection
                          : l10n.notificationSelect,
                    ),
                  ),
                  if (!_selectionMode)
                    TextButton.icon(
                      onPressed: _isBusy ? null : _markAllRead,
                      icon: _markingBulkRead
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.mark_email_read_outlined),
                      label: Text(l10n.notificationMarkAllRead),
                    ),
                ],
              ),
            ),
            if (widget.pushController != null)
              _PushPermissionPrompt(controller: widget.pushController!),
            if (_selectionMode)
              ListenableBuilder(
                listenable: widget.controller.inbox,
                builder: (context, _) => _selectionToolbar(context, l10n),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: PagedListPane<NotificationItem>(
                  source: widget.controller.inbox,
                  failedTitle: l10n.notificationInboxLoadFailed,
                  emptyTitle: l10n.notificationInboxEmpty,
                  moreFailedLabel: l10n.notificationInboxMoreFailed,
                  listKey: const Key('notification-inbox-list'),
                  itemBuilder: (context, item) =>
                      _notificationRow(context, item),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notificationRow(BuildContext context, NotificationItem item) {
    final theme = Theme.of(context).textTheme;
    final pn = context.pn;
    final isUnread = item.readAt == null;
    final isSelected = _selectedIds.contains(item.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(PnRadius.surface),
        onTap: _rowTap(item),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isUnread) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 6, right: 8),
                            child: Icon(
                              Icons.circle,
                              size: 8,
                              color: pn.brandInk,
                            ),
                          ),
                        ],
                        Expanded(
                          child: Text(
                            item.title,
                            style: theme.titleSmall?.copyWith(
                              fontWeight: isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (isUnread && _selectionMode)
                Checkbox(
                  key: Key('notification-select-${item.id}'),
                  value: isSelected,
                  onChanged: _isBusy
                      ? null
                      : (selected) => _setSelected(item, selected),
                )
              else if (isUnread)
                IconButton(
                  tooltip: L10n.of(context).notificationMarkRead,
                  onPressed: _isBusy ? null : () => _markRead(item),
                  icon: _markingRead.contains(item.id)
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.mark_email_read_outlined),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectionToolbar(BuildContext context, L10n l10n) {
    final unreadItems = _loadedUnreadItems;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          CheckboxListTile(
            key: const Key('notification-select-all'),
            value: _allUnreadSelected,
            onChanged: unreadItems.isEmpty || _isBusy ? null : _selectAll,
            title: Text(l10n.notificationSelectAll),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.notificationSelectedCount(_selectedIds.length),
                ),
              ),
              FilledButton.icon(
                onPressed: _selectedIds.isEmpty || _isBusy
                    ? null
                    : _markSelectedRead,
                icon: _markingBulkRead
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.mark_email_read_outlined),
                label: Text(l10n.notificationMarkSelectedRead),
              ),
            ],
          ),
        ],
      ),
    );
  }

  VoidCallback? _rowTap(NotificationItem item) {
    if (_isBusy || _selectionMode) return null;
    return () => _openItem(item);
  }

  void _toggleSelectionMode() {
    if (_isBusy) return;
    setState(() {
      _selectionMode = !_selectionMode;
      _selectedIds.clear();
    });
  }

  void _selectAll(bool? selected) {
    if (selected == null || _isBusy) return;
    final ids = _loadedUnreadItems.map((item) => item.id).toList();
    setState(() {
      if (selected) {
        _selectedIds.addAll(ids);
      } else {
        _selectedIds.removeAll(ids);
      }
    });
  }

  void _setSelected(NotificationItem item, bool? selected) {
    if (selected == null || _isBusy) return;
    setState(() {
      if (selected) {
        _selectedIds.add(item.id);
      } else {
        _selectedIds.remove(item.id);
      }
    });
  }

  Future<void> _openItem(NotificationItem item) => _open(
    operationId: item.id,
    request: () => widget.controller.open(item),
    fallbackItem: item,
  );

  Future<void> _openNotificationId(String notificationId, String? companyId) =>
      _open(
        operationId: notificationId,
        request: () =>
            widget.controller.openById(notificationId, companyId: companyId),
      );

  Future<void> _open({
    required String operationId,
    required Future<NotificationOpenResponse> Function() request,
    NotificationItem? fallbackItem,
  }) async {
    if (_openingId != null) return;
    setState(() => _openingId = operationId);
    final l10n = L10n.of(context);
    try {
      // The endpoint authorizes/resolves the destination and marks the recipient read. Do not
      // navigate or display a CTA until this request has completed successfully.
      final response = await request();
      if (!mounted) return;

      final link = response.link.trim();
      if (link.isNotEmpty) {
        final destination = _linkPolicy.resolveDestination(link);
        if (destination == null) {
          _showMessage(l10n.notificationLinkUnavailable);
          return;
        }
        await _openDestination(destination);
        return;
      }

      final announcement = response.item ?? fallbackItem;
      if (announcement == null) {
        _showMessage(l10n.notificationAnnouncementUnavailable);
      } else {
        await _showAnnouncement(announcement);
      }
    } on ApiError catch (error) {
      if (mounted) {
        _showMessage(failedReadText(error, l10n.notificationOpenFailed));
      }
    } on TransportException {
      if (mounted) _showMessage(l10n.notificationOpenFailed);
    } finally {
      if (mounted) setState(() => _openingId = null);
    }
  }

  Future<void> _showAnnouncement(NotificationItem item) async {
    final l10n = L10n.of(context);
    final safeButtons = <({NotificationItemButton button, Uri uri})>[];
    for (final button in item.buttons) {
      final uri = _linkPolicy.resolveDestination(button.link);
      if (uri != null) safeButtons.add((button: button, uri: uri));
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          item.title.isEmpty ? l10n.notificationAnnouncementTitle : item.title,
        ),
        content: Text(item.body),
        actions: [
          for (final entry in safeButtons)
            _announcementAction(dialogContext, entry.button, entry.uri),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonClose),
          ),
        ],
      ),
    );
  }

  Widget _announcementAction(
    BuildContext dialogContext,
    NotificationItemButton button,
    Uri destination,
  ) {
    void open() {
      Navigator.of(dialogContext).pop();
      unawaited(_openDestination(destination));
    }

    final child = Text(button.label);
    return switch (button.style.toLowerCase()) {
      'primary' => FilledButton(onPressed: open, child: child),
      'secondary' || 'outline' => OutlinedButton(onPressed: open, child: child),
      _ => TextButton(onPressed: open, child: child),
    };
  }

  Future<void> _openDestination(Uri destination) async {
    final l10n = L10n.of(context);
    final systemBrowser = widget.opener ?? browser.opener;
    try {
      await systemBrowser.openUrl(destination.toString());
    } on OpenerException {
      if (mounted) _showMessage(l10n.notificationOpenFailed);
    }
  }

  Future<void> _markRead(NotificationItem item) async {
    setState(() => _markingRead.add(item.id));
    final l10n = L10n.of(context);
    try {
      await widget.controller.markRead(item);
    } on ApiError catch (error) {
      if (mounted) {
        _showMessage(failedReadText(error, l10n.notificationMarkReadFailed));
      }
    } on TransportException {
      if (mounted) _showMessage(l10n.notificationMarkReadFailed);
    } finally {
      if (mounted) setState(() => _markingRead.remove(item.id));
    }
  }

  Future<void> _markSelectedRead() async {
    final selectedItems = _loadedUnreadItems
        .where((item) => _selectedIds.contains(item.id))
        .toList(growable: false);
    if (selectedItems.isEmpty) return;
    final l10n = L10n.of(context);
    final confirmed = await _confirmBulkMarkRead(
      title: l10n.notificationMarkSelectedRead,
      message: l10n.notificationMarkSelectedConfirm(selectedItems.length),
    );
    if (!confirmed || !mounted) return;
    await _markBulkRead(() => widget.controller.markReadItems(selectedItems));
  }

  Future<void> _markAllRead() async {
    final l10n = L10n.of(context);
    final confirmed = await _confirmBulkMarkRead(
      title: l10n.notificationMarkAllRead,
      message: l10n.notificationMarkAllConfirm,
    );
    if (!confirmed || !mounted) return;
    await _markBulkRead(widget.controller.markAllRead);
  }

  Future<bool> _confirmBulkMarkRead({
    required String title,
    required String message,
  }) async {
    final l10n = L10n.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.notificationConfirmMarkRead),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _markBulkRead(Future<void> Function() request) async {
    if (_isBusy) return;
    setState(() => _markingBulkRead = true);
    final l10n = L10n.of(context);
    try {
      await request();
      if (!mounted) return;
      setState(() {
        _selectionMode = false;
        _selectedIds.clear();
      });
    } on ApiError catch (error) {
      if (mounted) {
        _showMessage(
          failedReadText(error, l10n.notificationMarkBulkReadFailed),
        );
      }
    } on TransportException {
      if (mounted) _showMessage(l10n.notificationMarkBulkReadFailed);
    } finally {
      if (mounted) setState(() => _markingBulkRead = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PushPermissionPrompt extends StatelessWidget {
  const _PushPermissionPrompt({required this.controller});

  final PushLifecycleController controller;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<PushAuthorizationStatus>(
        valueListenable: controller.authorizationStatus,
        builder: (context, status, _) {
          if (status.canReceivePush ||
              status == PushAuthorizationStatus.unsupported) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => unawaited(controller.requestPermission()),
                icon: const Icon(Icons.notifications_active_outlined),
                label: Text(L10n.of(context).notificationEnablePush),
              ),
            ),
          );
        },
      );
}
