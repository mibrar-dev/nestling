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
      // ONE 44px row: fixed 44px slots on both sides keep the title
      // centred on a single line no matter what the action holds. The
      // action text clips (never wraps) inside its 44px slot.
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: NestDevice.tapParent),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: NestSpacing.s3),
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
                    if (compactTitle == null) {
                      return const Spacer();
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
              SizedBox(
                width: NestDevice.tapParent,
                child: trailing ?? _compactAction(),
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
                child: Text(
                  label,
                  style: NestType.buttonLabel(color: tokens.leaf),
                  // Fixed 44px slot in the compact bar: clip, never wrap
                  // (documented exception to the no-ellipsis rule).
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
