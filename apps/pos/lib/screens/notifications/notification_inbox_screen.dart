/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:pn_types/src/api/api_error.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/native/opener_port.dart';
import 'package:pn_types/src/native/push_messaging_port.dart';
import 'package:pn_types/src/notification.dart';
import 'package:pn_types/src/session.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pn_ui/src/theme/palette.dart';
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
    final subtitle = item.subtitle;
    final preview = subtitle == null || subtitle.isEmpty ? item.body : subtitle;
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
                      preview,
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

  // The announcement detail mirrors the web dialog (notification-detail-dialog.tsx): image, then
  // the body, then the CTAs, with only "Close" in the action row.
  Future<void> _showAnnouncement(NotificationItem item) async {
    final l10n = L10n.of(context);
    // The web's filter: a label to show and a link that passes its href check.
    final buttons = [
      for (final button in item.buttons)
        if (button.label.trim().isNotEmpty)
          if (_linkPolicy.resolveAction(button.link) case final action?)
            (button: button, action: action),
    ];
    final image = _linkPolicy.resolveMedia(item.image ?? '')?.toString();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: Text(
          item.title.isEmpty ? l10n.notificationAnnouncementTitle : item.title,
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (image != null && image.isNotEmpty) ...[
                _announcementImage(dialogContext, item, image),
                const SizedBox(height: 16),
              ],
              _announcementBody(dialogContext, item),
              if (buttons.isNotEmpty) ...[
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in buttons)
                      _announcementAction(
                        dialogContext,
                        entry.button,
                        entry.action,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonClose),
          ),
        ],
      ),
    );
  }

  /// An in-app link leaves the dialog, as router navigation does on the web. An external one
  /// opens beside it, as a new tab would, and the dialog stays.
  void _followAction(
    BuildContext dialogContext,
    ({Uri uri, bool inApp}) action,
  ) {
    if (action.inApp) Navigator.of(dialogContext).pop();
    unawaited(_openDestination(action.uri));
  }

  /// The content image: full width, at most 320 high, contained in its 4:3 or 3:4 box. A tap
  /// opens it full screen with the title and summary as its caption, like the web's lightbox.
  Widget _announcementImage(
    BuildContext dialogContext,
    NotificationItem item,
    String url,
  ) {
    final pn = dialogContext.pn;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 320),
        child: AspectRatio(
          aspectRatio: item.imageRatio == '4:3' ? 4 / 3 : 3 / 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              onTap: () => _showImageViewer(dialogContext, item, url),
              child: Image.network(
                url,
                fit: BoxFit.contain,
                semanticLabel: item.title,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: pn.surfaceMuted,
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: pn.inkMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showImageViewer(
    BuildContext dialogContext,
    NotificationItem item,
    String url,
  ) {
    final subtitle = item.subtitle;
    final caption = subtitle == null || subtitle.isEmpty ? item.body : subtitle;
    final textTheme = Theme.of(dialogContext).textTheme;
    // A photo viewer is black in both themes, so its text and controls are white in both.
    unawaited(
      showDialog<void>(
        context: dialogContext,
        builder: (viewerContext) => Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  maxScale: 4,
                  child: Center(
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      semanticLabel: item.title,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white70,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  child: ColoredBox(
                    color: Colors.black54,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          if (caption.isNotEmpty)
                            Text(
                              caption,
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: SafeArea(
                  child: IconButton(
                    tooltip: L10n.of(viewerContext).commonClose,
                    color: Colors.white,
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(viewerContext).pop(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _announcementBody(BuildContext dialogContext, NotificationItem item) {
    final theme = Theme.of(dialogContext);
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurface,
    );
    final html = item.bodyHtml;
    // Text keeps the body's newlines, which is what `whitespace-pre-wrap` does on the web.
    if (html == null || html.isEmpty) return Text(item.body, style: textStyle);

    final pn = dialogContext.pn;
    return HtmlWidget(
      '<div class="$_bodyRootClass">${_keepSoftBreaks(html)}</div>',
      factoryBuilder: _RawHrefWidgetFactory.new,
      customStylesBuilder: (element) => _webBodyStyles(
        element.localName,
        pn,
        theme.colorScheme.onSurface,
        spaced:
            (element.parent?.classes.contains(_bodyRootClass) ?? false) &&
            element.nextElementSibling != null,
      ),
      customWidgetBuilder: (element) {
        // Notification HTML never permits images; do not let malformed payloads load remote media.
        if (element.localName == 'img') return const SizedBox.shrink();
        return null;
      },
      onTapUrl: (url) {
        final action = _linkPolicy.resolveAction(url);
        if (action != null) _followAction(dialogContext, action);
        return true;
      },
      textStyle: textStyle?.copyWith(height: 1.625),
    );
  }

  Widget _announcementAction(
    BuildContext dialogContext,
    NotificationItemButton button,
    ({Uri uri, bool inApp}) action,
  ) {
    final pn = dialogContext.pn;
    void open() => _followAction(dialogContext, action);
    final child = Text(button.label);
    // The web's CTA_VARIANT. A style it does not know gets its default button, the primary one.
    return switch (button.style) {
      'secondary' => FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: pn.secondary,
          foregroundColor: pn.onSecondary,
        ),
        onPressed: open,
        child: child,
      ),
      'error' => FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: pn.error,
          foregroundColor: pn.onError,
        ),
        onPressed: open,
        child: child,
      ),
      'outline' => OutlinedButton(onPressed: open, child: child),
      'ghost' => TextButton(onPressed: open, child: child),
      _ => FilledButton(onPressed: open, child: child),
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

const _bodyRootClass = 'pn-notification-body';

/// Goldmark writes a soft line break inside a paragraph as a bare newline, which the web keeps
/// with `whitespace-pre-wrap` on `p`. The HTML renderer collapses whitespace, so those newlines
/// become `<br>`, inside paragraphs only: between blocks a newline is just markup layout.
String _keepSoftBreaks(String html) => html.replaceAllMapped(
  RegExp(r'<p>([\s\S]*?)</p>'),
  (match) => '<p>${match[1]!.replaceAll('\n', '<br>')}</p>',
);

/// The web dialog's Tailwind classes on the body, as CSS the HTML renderer understands.
/// [spaced] is `space-y-2`: Tailwind 4 puts the gap under every top-level block but the last.
/// Nested blocks have no margin, as after Tailwind's reset.
Map<String, String>? _webBodyStyles(
  String? tag,
  PnPalette pn,
  Color ink, {
  required bool spaced,
}) {
  final block = {'margin': spaced ? '0 0 8px 0' : '0'};
  Map<String, String> heading(int px) => {
    ...block,
    'font-size': '${px}px',
    'font-weight': '600',
  };
  return switch (tag) {
    'p' => block,
    'h1' => heading(20),
    'h2' => heading(18),
    'h3' => heading(16),
    'h4' => heading(14),
    'ul' || 'ol' => {...block, 'padding-left': '24px'},
    'li' => {'margin': '0'},
    'blockquote' => {
      ...block,
      'padding-left': '12px',
      'border-left': '2px solid ${_css(pn.border)}',
      'color': _css(pn.inkMuted),
    },
    'pre' => {
      ...block,
      'padding': '8px',
      'background-color': _css(pn.surfaceMuted),
    },
    'code' => {'background-color': _css(pn.surfaceMuted)},
    'hr' => {'margin': '16px 0'},
    'strong' => {'font-weight': '600'},
    // The web link keeps the body colour and is told apart by its underline.
    'a' => {'color': _css(ink), 'text-decoration': 'underline'},
    _ => null,
  };
}

String _css(Color color) =>
    'rgba(${(color.r * 255).round()}, ${(color.g * 255).round()}, '
    '${(color.b * 255).round()}, ${color.a})';

/// Hands `onTapUrl` the href as the server wrote it. The default factory resolves it first, and
/// without a base URL it turns `//host/path` into an HTTPS link and drops `/path` altogether, so
/// the web's link rules could not tell the two apart.
class _RawHrefWidgetFactory extends WidgetFactory {
  @override
  String? urlFull(String url) => url.isEmpty ? null : url;
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
