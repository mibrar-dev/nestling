import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/components/nest_icon.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

/// How wide the keypad grid may grow.
///
/// Mirrors CSS: `.keypad` fills its parent as a block-level grid, but
/// shrink-wraps to its max-content width inside a centred flex column.
enum NestKeypadFit {
  /// Grid fills the parent width; the 3 columns split it equally.
  /// P17 gate card (block-level `.keypad` in the 302px card content box).
  stretch,

  /// Grid shrink-wraps to [NestKeypad.contentWidth] and centres.
  /// K02 PIN (`.k2-body{align-items:center}` shrink-wraps the grid to its
  /// max-content width inside the 350px scroll content box).
  shrinkWrap,
}

class NestKeypad extends StatelessWidget {
  const new({
    required this.onKey,
    required this.onDelete,
    super.key,
    this.kid = false,
    this.deleteSemanticLabel = 'Delete',
    this.fit = NestKeypadFit.stretch,
  });

  /// CSS `.keypad` max-content width: 3x72 keys + 2x10 gaps + 2x24 padding.
  static const double contentWidth =
      (NestDevice.tapKid + NestSpacing.s4) * 3 +
      NestSpacing.gap10 * 2 +
      NestSpacing.s6 * 2;

  final ValueChanged<String> onKey;
  final VoidCallback onDelete;
  final bool kid;
  final String deleteSemanticLabel;
  final NestKeypadFit fit;

  @override
  Widget build(BuildContext context) {
    // CSS `.keypad` (components.css:193): grid, `repeat(3, 1fr)`, 10px gaps,
    // padding 8px 24px 0, 72px keys centred in their cells. Expanded cells
    // reproduce the 1fr columns at any parent width, so P17 (302px card
    // content -> 88px pitch) and K02 (284px shrink-wrapped -> 82px pitch)
    // both fall out of the width the parent provides — verified against
    // design/screens/light/P17-parental-gate.png (keys 71-143/159-231/
    // 247-319, centres 107/195/283) and K02-pin.png (77-149/159-231/
    // 241-313, centres 113/195/277).
    // Nothing in this tree clips, so key shadows always paint in full.
    const rows = <List<String>>[
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['blank', '0', 'delete'],
    ];
    Widget grid = Padding(
      padding: const EdgeInsets.only(
        top: NestSpacing.s2,
        left: NestSpacing.s6,
        right: NestSpacing.s6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var r = 0; r < rows.length; r++) ...[
            if (r > 0) const SizedBox(height: NestSpacing.gap10),
            Row(
              children: [
                for (var c = 0; c < 3; c++) ...[
                  if (c > 0) const SizedBox(width: NestSpacing.gap10),
                  Expanded(child: Center(child: _cell(rows[r][c]))),
                ],
              ],
            ),
          ],
        ],
      ),
    );
    if (fit == NestKeypadFit.shrinkWrap) {
      grid = Align(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: contentWidth),
          child: grid,
        ),
      );
    }
    return grid;
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
