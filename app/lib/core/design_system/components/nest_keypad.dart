import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/components/nest_icon.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

class NestKeypad extends StatelessWidget {
  const new({
    required this.onKey,
    required this.onDelete,
    super.key,
    this.kid = false,
    this.deleteSemanticLabel = 'Delete',
  });

  final ValueChanged<String> onKey;
  final VoidCallback onDelete;
  final bool kid;
  final String deleteSemanticLabel;

  @override
  Widget build(BuildContext context) {
    // Explicit rows (not a GridView): keys 72, column gap 24, row gap 16.
    // Nothing in this tree clips, so key shadows always paint in full.
    // (SPACING_SPEC quotes grid gap 10 / padding 8-24-0; the K02/P17
    // renders this fixes measure 24px columns / 16px rows.)
    const rows = <List<String>>[
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['blank', '0', 'delete'],
    ];
    return Padding(
      padding: const EdgeInsets.all(NestSpacing.s2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var r = 0; r < rows.length; r++) ...[
            if (r > 0) const SizedBox(height: NestSpacing.s4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var c = 0; c < 3; c++) ...[
                  if (c > 0) const SizedBox(width: NestSpacing.s6),
                  _cell(rows[r][c]),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _cell(String slot) {
    if (slot == 'blank') {
      return const ExcludeSemantics(
        child: SizedBox(
          width: NestDevice.tapKid + NestSpacing.s4,
          height: NestDevice.tapKid + NestSpacing.s4,
        ),
      );
    }
    if (slot == 'delete') {
      return _Key(
        digit: slot,
        onTap: onDelete,
        kid: kid,
        deleteSemanticLabel: deleteSemanticLabel,
      );
    }
    return _Key(
      digit: slot,
      onTap: () => onKey(slot),
      kid: kid,
      deleteSemanticLabel: deleteSemanticLabel,
    );
  }
}

class NestPinDots extends StatelessWidget {
  const new({required this.total, required this.filled, super.key});

  final int total;
  final int filled;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final borderWidth = context.nestKid.borderWidth;
    return Semantics(
      label: '$filled of $total entered',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: NestSpacing.s2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            for (var i = 0; i < total; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: NestSpacing.s3),
              SizedBox(
                width: 18,
                height: 18,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < filled ? tokens.ink : tokens.surface,
                    border: Border.all(color: tokens.ink, width: borderWidth),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const new({
    required this.digit,
    required this.onTap,
    required this.kid,
    required this.deleteSemanticLabel,
  });

  final String digit;
  final VoidCallback onTap;
  final bool kid;
  final String deleteSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final borderWidth = context.nestKid.borderWidth;
    final isDelete = digit == 'delete';

    final TextStyle keyStyle;
    if (kid) {
      keyStyle = NestType.buttonKid(color: tokens.ink).copyWith(fontSize: 26);
    } else {
      keyStyle = NestType.bodyStrong(color: tokens.ink)
          .copyWith(fontSize: 26, height: 32 / 26, fontWeight: FontWeight.w600);
    }

    final Widget keyChild;
    if (isDelete) {
      keyChild = NestIcon(NestIcons.backspace, size: 28, color: tokens.ink);
    } else {
      keyChild = Text(
        digit,
        style: keyStyle,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Semantics(
      button: true,
      label: isDelete ? deleteSemanticLabel : 'Digit $digit',
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: Ink(
              width: NestDevice.tapKid + NestSpacing.s4,
              height: NestDevice.tapKid + NestSpacing.s4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tokens.surface,
                // Shadows read dirty on dark: 1px line border, no shadow.
                border: kid
                    ? Border.all(color: tokens.ink, width: borderWidth)
                    : (tokens.isDark ? Border.all(color: tokens.line) : null),
                boxShadow: tokens.isDark
                    ? null
                    : (kid ? tokens.kidShadow : tokens.cardShadow),
              ),
              child: Center(child: keyChild),
            ),
          ),
        ),
      ),
    );
  }
}
