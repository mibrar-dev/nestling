import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

class _TypeRow {
  const new(this.spec, this.sample, this.style);

  final String spec;
  final String sample;
  final TextStyle Function(NestTextStyles) style;
}

/// Type scale catalogue: parent (Inter) + display/kid (Nunito).
///
/// Mirrors section 2 of `design/html-source/design-system.html`.
class GalleryType extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final text = context.nestText;
    final rows = <_TypeRow>[
      _TypeRow(
        'display 34/40 Nunito 900',
        'Chores that feel like a game',
        (t) => t.display,
      ),
      _TypeRow('h1 28/34 Nunito 900', 'Good morning, Sarah', (t) => t.h1),
      _TypeRow('h2 22/28 Nunito 800', "Today's quests", (t) => t.h2),
      _TypeRow('h3 18/24 Nunito 800', 'Pip is a Fledgling', (t) => t.h3),
      _TypeRow(
        'body 16/24 Inter 400',
        'Nestling turns family jobs into quests.',
        (t) => t.body,
      ),
      _TypeRow(
        'body-s 15/22 Inter',
        'Sat 4 Oct · £2.50 · Made in the UK',
        (t) => t.bodySmall,
      ),
      _TypeRow(
        'caption 13/18 Inter',
        'No ads, ever · Cancel anytime',
        (t) => t.caption,
      ),
      _TypeRow('money tabular-nums', '£12.50 · £4.20 · £24.99', (t) => t.money),
      _TypeRow(
        'kid-body 18/26 Nunito 700',
        "Let's do some quests!",
        (t) => t.kidBody,
      ),
      _TypeRow(
        'kid-title 28/34 Nunito 900',
        "Who's playing?",
        (t) => t.kidTitle,
      ),
      _TypeRow(
        'kid-hero 40/44 Nunito 900',
        'Brilliant, Maya!',
        (t) => t.kidHero,
      ),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final row in rows) ...[
          Text(
            row.spec,
            style: NestType.caption(color: context.nest.ink3),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(row.sample, style: row.style(text), softWrap: true),
          const SizedBox(height: NestSpacing.s2),
        ],
      ],
    );
  }
}
