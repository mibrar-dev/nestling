import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

/// Parent-tab page title (`.ptitle` in the HTML).
///
/// Exact CSS metrics (`P10-quest-library.html:3`, `P12-money.html:3`,
/// `P16-settings.html:3`, `P13-payout.html:16`):
/// `font-display 900 28/34`, `padding-top: 8px`, ink colour. No
/// `text-wrap: balance`, so this is a plain [Text] (the BALANCED HEADINGS
/// rule does not reach it).
///
/// The 8 px top padding is the title's own (`.scroll`'s first child gets no
/// `> * + *` gap). Side gutters come from the surrounding scroll view
/// (`.scroll { padding: 0 20px }`), so this widget carries no horizontal
/// padding — place it directly in a guttered [ListView] or wrap it in a
/// 20 px horizontal [Padding] when the parent has none (P13 dimmed ledger).
class NestPageTitle extends StatelessWidget {
  const new({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: NestSpacing.s2),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: NestType.h1(color: context.nest.ink),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
