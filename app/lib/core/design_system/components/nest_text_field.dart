import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/components/nest_icon.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/radii.dart';
import 'package:nestling/core/design_system/tokens/shadows.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

/// Parent-mode text field with label, focus ring, and password toggle.
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
  });

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
      borderSide: BorderSide(color: tokens.danger),
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
          errorText: errorText,
          helperText: widget.helperText,
          helperStyle: NestType.caption(color: tokens.ink2),
          errorStyle: NestType.caption(color: tokens.danger)
              .copyWith(fontWeight: FontWeight.w600),
          filled: true,
          fillColor: tokens.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: NestSpacing.s4,
            vertical: 14,
          ),
          border: enabledBorder,
          enabledBorder: enabledBorder,
          focusedBorder: focusedBorder,
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
      ],
    );
  }
}
