import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart';

/// `.k11-week`: `padding: 14px 12px` (`K11-badges.html:31`).
const EdgeInsets _cardPadding = EdgeInsets.symmetric(
  horizontal: NestSpacing.s3,
  vertical: NestSpacing.gap14,
);

/// `.k11-dot`: 38 px circle (`K11-badges.html:33`).
const double _dotMax = 38;

/// `.k11-day span` and `.k11-dot svg`: Nunito 14/18 w800 letter, 22 glyph.
const double _letterFontSize = 14;
const double _letterLineHeight = 18;
const double _glyphSize = 22;

/// `.k11-days { gap: 4px }` (`K11-badges.html:32`).
const double _dayGap = NestSpacing.s1;

/// `.k11-day span` letters, Monday first (`K11-badges.html:52-58`).
const List<String> _dayLetters = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];

/// K11 copy that the week card owns. `1_plan.md` §c: the design's line with
/// the live happy-day count; the singular (1) and zero (invented, kid voice)
/// variants keep the same voice.
abstract final class HappyWeekCopy {
  const HappyWeekCopy._();

  /// `.k11-why` why-line. The Design draws `4 happy days this week — Pip
  /// hasn’t stopped singing.` (em dash U+2014, curly ’ U+2019); `n` comes
  /// from the child row, never from the design. Clamped to the seven days
  /// the card can draw (K11-BUG-1): the schema documents 0..7 but enforces
  /// no upper bound, so a stored 8 must read as 7, never “8 happy days”.
  static String why(int happyDays) {
    final n = happyDays.clamp(0, 7);
    if (n <= 0) return 'Let’s make today a happy day!';
    final days = n == 1 ? 'day' : 'days';
    return '$n happy $days this week — Pip hasn’t stopped singing.';
  }
}

/// The K11 happy-week card — `.k11-week` (`K11-badges.html:31`): `surface`
/// fill, 3 px ink border, `--r-l` 24, `--sh-kid` 6 px, `padding: 14px 12px`.
///
/// Seven Mon–Sun dots with the letter under each: the first [happyDays] are
/// filled leaf with an on-leaf check, the rest are surface with an ink-2
/// ring (the design's positive framing — never a lost streak). The dots
/// shrink with the card at narrow widths (`1_plan.md` §e: 38 at 390, ~33 at
/// 320), so a 320 px device never overflows.
class HappyWeekCard extends StatelessWidget {
  const HappyWeekCard({required this.happyDays, super.key});

  /// Happy days this week, 0…7 (the child row's stored count).
  final int happyDays;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final kid = context.nestKid;
    // K11-BUG-1: the stored count is documented 0..7 but the schema enforces
    // no upper bound — clamp to the seven days the card draws before using
    // it for the dots or the why-line, so a stored 8 fills seven dots and
    // reads “7 happy days”, never an impossible “8 happy days”.
    final days = happyDays.clamp(0, 7);
    return Container(
      padding: _cardPadding,
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: NestRadii.allL,
        border: Border.all(color: tokens.ink, width: kid.borderWidth),
        boxShadow: tokens.kidShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              // `min(38, (w − 6×4) / 7)`: the CSS `flex:1` slots with 4 px
              // gaps but a fixed 38 px dot overflow a 320 px-wide card.
              final dot = math.min(
                _dotMax,
                (constraints.maxWidth - _dayGap * 6) / 7,
              );
              return Row(
                spacing: _dayGap,
                children: <Widget>[
                  for (var i = 0; i < _dayLetters.length; i++)
                    Expanded(
                      child: _DayColumn(
                        letter: _dayLetters[i],
                        on: i < days,
                        dot: dot,
                      ),
                    ),
                ],
              );
            },
          ),
          // `.k11-why { margin-top: 12px }` (`K11-badges.html:36`).
          const SizedBox(height: NestSpacing.s3),
          Text(
            HappyWeekCopy.why(days),
            style: NestType.kidCaption(color: tokens.ink2),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// One `.k11-day` column: the dot and its letter, 4 px apart.
class _DayColumn extends StatelessWidget {
  const _DayColumn({required this.letter, required this.on, required this.dot});

  final String letter;
  final bool on;
  final double dot;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: _dayGap,
      children: <Widget>[
        Container(
          width: dot,
          height: dot,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? tokens.leaf : tokens.surface,
            border: Border.all(
              color: tokens.ink,
              width: context.nestKid.borderWidth,
            ),
          ),
          child: Center(
            child: ExcludeSemantics(
              child: NestIcon(
                on ? NestIcons.check : NestIcons.circle,
                size: _glyphSize,
                color: on ? tokens.onLeaf : tokens.ink2,
              ),
            ),
          ),
        ),
        Text(
          letter,
          style: NestType.kidCaption(color: tokens.ink).copyWith(
            fontSize: _letterFontSize,
            height: _letterLineHeight / _letterFontSize,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
