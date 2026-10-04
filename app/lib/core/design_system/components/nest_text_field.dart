import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/components/nest_icon.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/radii.dart';
import 'package:nestling/core/design_system/tokens/shadows.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

/// Parent-mode text field with label, focus ring, and password toggle.
///
/// Setting [NestTextField.errorText] paints the invalid state: a 2 px danger
/// border on the field plus a gutter-aligned error row below it (never the
/// indented Material slot) announced through a live region. The error
/// replaces the helper, matching Material's error-wins behaviour.
///
/// The `.search` geometry (P10 quest library) lives in
/// [NestTextField.search]: a 54-high flex row — 16 px side padding, a 24 px
/// icon, a 10 px gap, then the input — so the glyph sits at field x+16 and
/// the hint at x+50. Do not fake it with `prefixIcon`: Material's default
/// `prefixIconConstraints` floor that slot at 48 px and push the hint to
/// x+64.
class NestTextField extends StatefulWidget {
  const new({
    super.key,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixIcon,
    this.enabled = true,
    this.maxLines = 1,
  }) : search = false,
       semanticLabel = null;

  /// Search slot matching `.search` in `design/html-source/...`: `flex,
  /// gap:10px, padding:4px 16px, min-height:52px` with a 24 px icon, rendered
  /// as a 54-high border box (`box-sizing: border-box`: 4 + 44 + 4 content
  /// plus 1 px borders).
  ///
  /// Layout is a plain [Row] (no [InputDecoration] prefix slot), so the
  /// icon keeps its 24 px size at field x+16 and [hintText] starts at x+50.
  /// [label], [helperText], [errorText], [obscureText], [suffixIcon] and
  /// [prefixIcon] do not apply to this variant.
  const NestTextField.search({
    super.key,
    this.hintText,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.enabled = true,
    this.semanticLabel,
  }) : label = null,
       helperText = null,
       errorText = null,
       obscureText = false,
       maxLines = 1,
       suffixIcon = null,
       prefixIcon = null,
       search = true;

  final String? label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool enabled;
  final int maxLines;

  /// When true (the [NestTextField.search] constructor) the widget renders
  /// the `.search` row instead of the labelled field.
  final bool search;

  /// Accessible name for the search variant (e.g. `Search quest ideas`).
  /// The labelled constructor uses [label] instead.
  final String? semanticLabel;

  @override
  State<NestTextField> createState() => _NestTextFieldState();
}

class _NestTextFieldState extends State<NestTextField> {
  FocusNode? _ownedNode;
  late bool _obscured;

  FocusNode get _effectiveNode => widget.focusNode ?? _ownedNode!;

  void _onFocusChanged() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
    if (widget.focusNode == null) {
      _ownedNode = FocusNode();
    }
    _effectiveNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant NestTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      final oldEffective = oldWidget.focusNode ?? _ownedNode;
      oldEffective?.removeListener(_onFocusChanged);
      if (widget.focusNode == null && _ownedNode == null) {
        _ownedNode = FocusNode();
      }
      _effectiveNode.addListener(_onFocusChanged);
    }
  }

  /// `.search` row (P10): `flex, gap:10px, padding:4px 16px,
  /// min-height:52px` with a 24 px icon — glyph at field x+16, hint at x+50.
  ///
  /// A plain [Row], not an [InputDecoration] prefix slot: Material centres
  /// the prefix glyph and floors it at 48 px, which lands the icon at x+13
  /// at best. Two framework quirks are compensated below, both pinned by
  /// `shared_batch4_test.dart`:
  ///
  /// * A [TextField] is a scrollable, so it expands to its max height —
  ///   the input gets a fixed 44 px box (the design's `input
  ///   min-height:44px`) with [TextAlignVertical.center] instead of a
  ///   minimum, or the row stretches to the parent.
  /// * The editable's text origin sits 4 px inside the decoration content
  ///   box (measured, stable across border/filled variants), so the
  ///   decoration carries `left: -4` and the rendered hint starts exactly
  ///   at the design's gap edge (16 + 24 + 10 = x+50).
  ///
  /// The hint (painted by the decorator, not the editable) ignores
  /// [TextAlignVertical]: with a tight 44 px slot and no vertical padding
  /// it sits at the top of the slot. The decoration therefore also carries
  /// 10 px vertical padding — (44 − 24) / 2 around the 24 px Inter 16/24
  /// line box — so the hint and the typed text both centre in the slot.
  ///
  /// Box model: the design is `border-box`, so 54 px is the TOTAL including
  /// the 1 px border: 4 + 44 + 4 + 2 × 1.
  Widget _buildSearch(BuildContext context, NestTokens tokens, FocusNode node) {
    final row = Container(
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.symmetric(
        vertical: NestSpacing.s1,
        horizontal: NestSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: NestRadii.allM,
        border: Border.all(color: node.hasFocus ? tokens.leaf : tokens.line),
        boxShadow: node.hasFocus
            ? NestShadows.focusRing(tokens.leafTint, tokens.leaf)
            : null,
      ),
      child: Row(
        children: <Widget>[
          NestIcon(NestIcons.search, color: tokens.ink3),
          const SizedBox(width: NestSpacing.gap10),
          Expanded(
            child: SizedBox(
              height: 44,
              child: TextField(
                controller: widget.controller,
                focusNode: node,
                enabled: widget.enabled,
                onChanged: widget.onChanged,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                textAlignVertical: TextAlignVertical.center,
                style: NestType.body(color: tokens.ink),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: NestType.body(color: tokens.ink3),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  isDense: true,
                  // Cancels the editable's built-in 4 px text inset (see
                  // above) so the hint starts at the gap edge; the 10 px
                  // vertical padding centres the 24 px hint/ink line box in
                  // the 44 px slot ((44 - 24) / 2).
                  contentPadding: const EdgeInsets.only(
                    left: -4,
                    top: NestSpacing.gap10,
                    bottom: NestSpacing.gap10,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    final semanticLabel = widget.semanticLabel;
    if (semanticLabel == null) return row;
    return Semantics(label: semanticLabel, textField: true, child: row);
  }

  @override
  void dispose() {
    _effectiveNode.removeListener(_onFocusChanged);
    _ownedNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final node = _effectiveNode;
    final errorText = widget.errorText;

    if (widget.search) return _buildSearch(context, tokens, node);

    final Widget? suffix;
    final customSuffix = widget.suffixIcon;
    if (customSuffix != null) {
      suffix = customSuffix;
    } else if (widget.obscureText) {
      suffix = SizedBox(
        width: NestDevice.tapParent,
        height: NestDevice.tapParent,
        child: IconButton(
          padding: EdgeInsets.zero,
          tooltip: _obscured ? 'Show password' : 'Hide password',
          style: IconButton.styleFrom(
            minimumSize: const Size(NestDevice.tapParent, NestDevice.tapParent),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(NestSpacing.s3),
            ),
          ),
          onPressed: () => setState(() => _obscured = !_obscured),
          icon: NestIcon(NestIcons.eye, color: tokens.ink2),
        ),
      );
    } else {
      suffix = null;
    }

    final enabledBorder = OutlineInputBorder(
      borderRadius: NestRadii.allM,
      borderSide: BorderSide(color: tokens.line),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: NestRadii.allM,
      borderSide: BorderSide(color: tokens.leaf),
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: NestRadii.allM,
      // Invalid inputs carry a heavier danger border (design-system error
      // state: 2 px danger token on the field itself).
      borderSide: BorderSide(color: tokens.danger, width: 2),
    );

    final field = Container(
      decoration: BoxDecoration(
        borderRadius: NestRadii.allM,
        boxShadow: node.hasFocus && errorText == null
            ? NestShadows.focusRing(tokens.leafTint, tokens.leaf)
            : null,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: node,
        enabled: widget.enabled,
        obscureText: _obscured,
        onChanged: widget.onChanged,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        maxLines: widget.obscureText ? 1 : widget.maxLines,
        style: NestType.body(color: tokens.ink),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: NestType.body(color: tokens.ink3),
          // No `errorText` here by design (P03 §5): Material lays the
          // decoration error out on the field's content box (indented
          // ~20px), while the design's `.field` is a column where label,
          // input, helper and error share one gutter — the error renders
          // as a gutter-aligned row below the input instead. When an error
          // is present it also replaces the helper, matching Material's
          // error-wins behaviour.
          helperText: errorText == null ? widget.helperText : null,
          helperStyle: NestType.caption(color: tokens.ink2),
          filled: true,
          fillColor: tokens.surface,
          // Design `.field input`: `border 1px` + `padding 0 16px`, so text
          // starts 17 px from the field's left edge. Material's editable
          // origin sits ~4 px inside the decoration content box (same fix as
          // the search variant's `left: -4`), so the decoration carries 12
          // px — 12 + 4 + 1 border = 17 — not 16 (which rendered 20).
          contentPadding: const EdgeInsets.symmetric(
            horizontal: NestSpacing.s3,
            vertical: 14,
          ),
          border: errorText == null ? enabledBorder : errorBorder,
          enabledBorder: errorText == null ? enabledBorder : errorBorder,
          focusedBorder: errorText == null ? focusedBorder : errorBorder,
          errorBorder: errorBorder,
          focusedErrorBorder: errorBorder,
          prefixIcon: widget.prefixIcon,
          suffixIcon: suffix,
        ),
      ),
    );

    final label = widget.label;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label,
            style: NestType.fieldLabel(color: tokens.ink2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
        ],
        if (label != null)
          Semantics(label: label, textField: true, child: field)
        else
          field,
        // Gutter-aligned error row (P03 §5): same x as the label above,
        // never the indented decoration slot. A live region (P03 §8, as
        // Material's own error row was) so assistive tech announces the
        // validation message the moment it appears; the inner text stays
        // excluded so the message is announced exactly once.
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Semantics(
            liveRegion: true,
            label: errorText,
            child: ExcludeSemantics(
              child: Text(
                errorText,
                style: NestType.caption(color: tokens.danger)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
