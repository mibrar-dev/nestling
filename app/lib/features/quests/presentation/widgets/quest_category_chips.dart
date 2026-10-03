import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_filter_chip.dart';

/// P10 category filter row — `.chipscroll`.
///
/// A horizontal `SingleChildScrollView`, NOT a [NestChipWrap]: the row never
/// wraps, it scrolls, and each pill is already 44 high (`QuestFilterChip`),
/// so there is no 44 px hit area to preserve — and a wrapping chip row would
/// be wrong here because the design scrolls horizontally. The design bleeds the row past
/// the 20 px side gutters (`margin: 0 -20px; padding: 0 20px 4px`) so the
/// chips run to the screen edges — hence the negative gutter on the scroll
/// view and the 20 px inner padding, with 4 px of bottom padding for the
/// scroll row's own box.
class QuestCategoryChips extends StatelessWidget {
  const QuestCategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    // The design bleeds this row past the 20 px side gutters
    // (`.chipscroll { margin: 0 -20px; padding: 0 20px 4px }`), so the
    // list applies no gutter to it and the scroll view carries the 20 px
    // edge padding itself.
    final scroll = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        NestSpacing.padSide,
        0,
        NestSpacing.padSide,
        NestSpacing.s1,
      ),
      child: Row(
        children: <Widget>[
          for (var i = 0; i < categories.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: NestSpacing.s2),
            QuestFilterChip(
              key: ValueKey<String>('quest-filter-chip-${categories[i]}'),
              label: categories[i],
              selected: categories[i] == selected,
              onTap: () => onSelected(categories[i]),
            ),
          ],
        ],
      ),
    );

    // `.chipscroll { mask-image: linear-gradient(to right, var(--ink)
    // calc(100% - 24px), transparent 100%) }` — the design PNG shows `Pets`
    // fading out at the right edge. `dstIn` keeps the painted chips and fades
    // their alpha over the last 24 px of the VIEWPORT (not of the content), so
    // the mask stays put while the row scrolls, exactly like the CSS.
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => LinearGradient(
        colors: const <Color>[Colors.black, Colors.black, Colors.transparent],
        stops: <double>[0, 1 - 24 / bounds.width, 1],
      ).createShader(bounds),
      child: scroll,
    );
  }
}
