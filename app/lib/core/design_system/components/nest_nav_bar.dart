import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/components/nest_icon.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

class NestNavBar extends StatelessWidget {
  const new({
    super.key,
    this.title,
    this.compact = false,
    this.onBack,
    this.backSemanticLabel = 'Back',
    this.actionLabel,
    this.onAction,
    this.trailing,
  });

  final String? title;
  final bool compact;
  final VoidCallback? onBack;
  final String backSemanticLabel;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  /// Compact-bar trailing slot content (null = empty 44px spacer).
  Widget? _compactAction() {
    final label = actionLabel;
    if (label == null) {
      return null;
    }
    return _NavActionButton(label: label, onTap: onAction);
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      // `.nav-bar.compact` (components.css): min-height 52, padding
      // `4px 12px 12px`, 44px back button. With border-box sizing the
      // rendered bar is 4 + 44 + 12 = 60 high, so the chevron centres at
      // status (47) + 4 + 22 = 73 and the scroll title below lands at the
      // design y. The leading slot stays a fixed 44 (back button or the
      // `.nav-gap` spacer); the trailing slot is content-sized with a 44
      // minimum (P02: the `Skip` text action is ~64 wide and must fit, not
      // ellipsize). Slots whose content fits 44 render identically.
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            NestSpacing.s3,
            NestSpacing.s1,
            NestSpacing.s3,
            NestSpacing.s3,
          ),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: NestDevice.tapParent,
                child: onBack != null
                    ? _NavBackButton(
                        onBack: onBack!,
                        semanticLabel: backSemanticLabel,
                      )
                    : null,
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final compactTitle = title;
                    if (compactTitle == null || compactTitle.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      compactTitle,
                      style: NestType.navCompact(color: context.nest.ink),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: NestDevice.tapParent,
                ),
                // Empty slot keeps the 44-wide `.nav-gap` spacer with no
                // height of its own (a back-less, action-less bar still
                // resolves to the 52 minimum); content sizes the slot.
                child:
                    trailing ??
                    _compactAction() ??
                    const SizedBox(width: NestDevice.tapParent),
              ),
            ],
          ),
        ),
      );
    }
    final titleText = title;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              NestSpacing.s3,
              NestSpacing.s2,
              NestSpacing.s3,
              0,
            ),
            child: Row(
              children: <Widget>[
                if (onBack != null)
                  _NavBackButton(
                    onBack: onBack!,
                    semanticLabel: backSemanticLabel,
                  ),
                const Spacer(),
                trailing ??
                    (actionLabel != null
                        ? _NavActionButton(label: actionLabel!, onTap: onAction)
                        : const SizedBox.shrink()),
              ],
            ),
          ),
          if (titleText != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                titleText,
                style: NestType.h1(color: context.nest.ink),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
            ),
        ],
      ),
    );
  }
}

class _NavBackButton extends StatelessWidget {
  const new({required this.onBack, required this.semanticLabel});

  final VoidCallback onBack;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Semantics(
      button: true,
      label: semanticLabel,
      onTap: onBack,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(NestSpacing.s3),
        child: InkWell(
          borderRadius: BorderRadius.circular(NestSpacing.s3),
          onTap: onBack,
          child: SizedBox(
            width: NestDevice.tapParent,
            height: NestDevice.tapParent,
            child: Center(child: NestIcon(NestIcons.back, color: tokens.ink)),
          ),
        ),
      ),
    );
  }
}

class _NavActionButton extends StatelessWidget {
  const new({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Semantics(
      button: true,
      label: label,
      enabled: onTap != null,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: NestDevice.tapParent,
          minWidth: NestDevice.tapParent,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: NestSpacing.s3),
              child: Center(
                // One announcement: the outer `Semantics(label:)` owns it.
                child: ExcludeSemantics(
                  child: Text(
                    label,
                    style: NestType.buttonLabel(color: tokens.leaf),
                    // Content-sized compact slot (P02): fit, never wrap
                    // (documented exception to the no-ellipsis rule).
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
