/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pn_ui/src/theme/tokens.dart';

/// A short code drawn as one cell per character, over ONE real text field.
///
/// The cells are the look. The field is what a keyboard, a paste, an IME and a screen reader all
/// talk to, so the text lives in one place and is read as one thing, "Kode pairing", not as six
/// unrelated boxes. The field's own text is transparent and it has no cursor: the cell that takes
/// the next character is outlined instead.
///
/// [filter] decides what an edit becomes: it gets what the field would hold and what it held
/// before, and returns the value to keep (return `previous` to refuse the edit). The screen owns
/// the rule (capitals, no separators, a length), so the same rule that tests the code also shapes
/// its input.
class SegmentedCodeField extends StatefulWidget {
  const SegmentedCodeField({
    super.key,
    required this.length,
    required this.value,
    required this.filter,
    required this.onChanged,
    required this.label,
    this.onSubmitted,
    this.hasError = false,
    this.enabled = true,
    this.autofocus = false,
  });

  final int length;
  final String value;
  final String Function(String raw, String previous) filter;
  final ValueChanged<String> onChanged;

  /// The keyboard's Done, or Enter on a physical one.
  final VoidCallback? onSubmitted;

  /// What a screen reader says for the field.
  final String label;

  /// Draws the cells in the error colour. The words of the error are the caller's to show.
  final bool hasError;
  final bool enabled;
  final bool autofocus;

  @override
  State<SegmentedCodeField> createState() => _SegmentedCodeFieldState();
}

class _SegmentedCodeFieldState extends State<SegmentedCodeField> {
  late final _controller = TextEditingController(text: widget.value);
  final _focus = FocusNode();

  static const _gap = 8.0;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(SegmentedCodeField old) {
    super.didUpdateWidget(old);
    if (_controller.text != widget.value) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active =
        _focus.hasFocus ? widget.value.length.clamp(0, widget.length - 1) : -1;

    return ConstrainedBox(
      // Six cells of 56 and the gaps: wider than that and they stop looking like a code.
      constraints: BoxConstraints(
        maxWidth: widget.length * PnTouch.primary + (widget.length - 1) * _gap,
      ),
      child: Stack(
        children: [
          ExcludeSemantics(
            child: Row(
              children: [
                for (var i = 0; i < widget.length; i++) ...[
                  if (i > 0) const SizedBox(width: _gap),
                  Expanded(child: _cell(context, i, focused: i == active)),
                ],
              ],
            ),
          ),
          Positioned.fill(
            child: Semantics(
              label: widget.label,
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                enabled: widget.enabled,
                autofocus: widget.autofocus,
                inputFormatters: [
                  TextInputFormatter.withFunction((old, next) {
                    final text = widget.filter(next.text, old.text);
                    return TextEditingValue(
                      text: text,
                      selection: TextSelection.collapsed(offset: text.length),
                    );
                  }),
                ],
                onChanged: widget.onChanged,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => widget.onSubmitted?.call(),
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                enableSuggestions: false,
                showCursor: false,
                style: const TextStyle(color: Colors.transparent),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  counterText: '',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(BuildContext context, int index, {required bool focused}) {
    final pn = context.pn;
    final color =
        widget.hasError ? pn.errorText : (focused ? pn.focus : pn.outline);
    final char = index < widget.value.length ? widget.value[index] : '';

    return Container(
      key: const ValueKey('code-cell'),
      height: PnTouch.primary,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: pn.surface,
        borderRadius: BorderRadius.circular(PnRadius.control),
        border: Border.all(color: color, width: focused ? 2 : 1),
      ),
      child: Text(
        char,
        style: Theme.of(context).textTheme.titleLarge!.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
