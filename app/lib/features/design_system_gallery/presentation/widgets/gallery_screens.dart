import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nestling/core/design_system/design_system.dart';

/// Screen previews: real compositions built only from design-system widgets.
///
/// Compare against `design/screens/light/P08-today.png` and
/// `design/screens/light/K03-kid-home.png` (divide PNG px by 3 for logical
/// px). Each preview is a full-bleed band at the ambient screen width with
/// the screen's own 20px side padding inside — no frames, no nested cards —
/// so content gets the real 350px width at 390, exactly like the designs.
class GalleryScreens extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: NestSpacing.padSide),
          child: Text(
            'P08 · Today',
            style: NestType.caption(color: tokens.ink2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: NestSpacing.s2),
        const KeyedSubtree(
          key: ValueKey('ds-section-screens-p08'),
          child: _TodayPreview(),
        ),
        const SizedBox(height: NestSpacing.s6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: NestSpacing.padSide),
          child: Text(
            'K03 · Kid home',
            style: NestType.caption(color: tokens.ink2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: NestSpacing.s2),
        const KeyedSubtree(
          key: ValueKey('ds-section-screens-k03'),
          child: _KidHomePreview(),
        ),
      ],
    );
  }
}

/// P08 Today, from DS widgets only: greet + actions, banner, 2 child cards,
/// section title, Maya/Leo quest groups with status chips.
class _TodayPreview extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return ColoredBox(
      color: tokens.paper,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              NestSpacing.padSide,
              NestSpacing.s2,
              NestSpacing.padSide,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good morning, Sarah',
                        style: NestType.h2(color: tokens.ink).copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.22,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Sat 4 Oct · Happy week: 4 days',
                        style: NestType.bodySmall(color: tokens.ink2)
                            .copyWith(fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: NestSpacing.s2),
                NestIconButton(
                  icon: NestIcons.plus,
                  semanticLabel: 'New quest',
                  backgroundColor: tokens.leaf,
                  foregroundColor: tokens.surface,
                  borderColor: Colors.transparent,
                  onPressed: () {},
                ),
                const SizedBox(width: NestSpacing.s2),
                const NestAvatar(initial: 'S', color: NestAvatarColor.leaf),
              ],
            ),
          ),
          const SizedBox(height: NestSpacing.s4),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: NestSpacing.padSide,
            ),
            child: Container(
              padding: const EdgeInsets.all(NestSpacing.s4),
              decoration: BoxDecoration(
                color: tokens.leafTint,
                borderRadius: NestRadii.allL,
                boxShadow: tokens.cardShadow,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '3 quests waiting for your thumbs-up',
                          style: NestType.bodyStrong(color: tokens.leafInk),
                          maxLines: 3,
                        ),
                        Text(
                          'Maya and Leo did brilliantly yesterday',
                          style: NestType.caption(color: tokens.leafInk)
                              .copyWith(fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: NestSpacing.s3),
                  NestButton(
                    label: 'Review',
                    minHeight: 44,
                    fullWidth: false,
                    fontSize: 15,
                    horizontalPadding: 18,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: NestSpacing.s4),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: NestSpacing.padSide,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final colW = (constraints.maxWidth - 10) / 2;
                return Row(
                  children: [
                    SizedBox(
                      width: colW,
                      child: const _P08ChildCard(
                        avatarColor: NestAvatarColor.lilac,
                        initial: 'M',
                        name: 'Maya',
                        sub: '4 of 6 quests',
                        pip: NestlingIllustrations.pipStage3,
                        progress: 0.67,
                        coins: '120',
                      ),
                    ),
                    const SizedBox(width: NestSpacing.gap10),
                    SizedBox(
                      width: colW,
                      child: const _P08ChildCard(
                        avatarColor: NestAvatarColor.peach,
                        initial: 'L',
                        name: 'Leo',
                        sub: '2 of 4 quests',
                        pip: NestlingIllustrations.pipStage2,
                        progress: 0.5,
                        coins: '45',
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: NestSpacing.s4),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: NestSpacing.padSide,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Today's quests",
                    style: NestType.h3(color: tokens.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {},
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: NestSpacing.s1,
                        ),
                        child: Center(
                          child: Text(
                            'See all',
                            style: NestType.chipLabel(color: tokens.leaf),
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: NestSpacing.s4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: NestSpacing.padSide),
            child: NestSectionLabel(label: 'Maya · 9'),
          ),
          const SizedBox(height: NestSpacing.s2),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: NestSpacing.padSide,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NestQuestCard(
                  title: 'Empty the dishwasher',
                  metaChips: [
                    const NestCoinPill(
                      amount: '15',
                      size: NestCoinPillSize.xSmall,
                    ),
                    Text(
                      '· Daily',
                      style: NestType.caption(color: tokens.ink2),
                    ),
                    _StatusChip(
                      label: 'Needs a look',
                      background: tokens.coinTint,
                      foreground: tokens.coinInk,
                    ),
                  ],
                  leading: _Tile(
                    asset: NestIcons.dishwasher,
                    bg: tokens.skyTint,
                    fg: tokens.sky,
                  ),
                  onTap: () {},
                ),
                const SizedBox(height: NestSpacing.s4),
                NestQuestCard(
                  title: 'Reading – 20 minutes',
                  metaChips: [
                    const NestCoinPill(
                      amount: '10',
                      size: NestCoinPillSize.xSmall,
                    ),
                    Text(
                      '· Daily',
                      style: NestType.caption(color: tokens.ink2),
                    ),
                    _StatusChip(
                      label: 'To do',
                      background: tokens.surface2,
                      foreground: tokens.ink2,
                    ),
                  ],
                  leading: _Tile(
                    asset: NestIcons.book,
                    bg: tokens.lilacTint,
                    fg: tokens.lilac,
                  ),
                  onTap: () {},
                ),
                const SizedBox(height: NestSpacing.s4),
                NestQuestCard(
                  title: 'Put the bins out',
                  metaChips: [
                    const NestCoinPill(
                      amount: '15',
                      size: NestCoinPillSize.xSmall,
                    ),
                    Text(
                      '· Weekly · Sat',
                      style: NestType.caption(color: tokens.ink2),
                    ),
                    _StatusChip(
                      label: 'Approved ✓',
                      background: tokens.leafTint,
                      foreground: tokens.leafInk,
                    ),
                  ],
                  leading: _Tile(
                    asset: NestIcons.bin,
                    bg: tokens.leafTint,
                    fg: tokens.leafInk,
                  ),
                  trailing: const NestCoinPill(
                    amount: '15',
                    size: NestCoinPillSize.xSmall,
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: NestSpacing.s4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: NestSpacing.padSide),
            child: NestSectionLabel(label: 'Leo · 6'),
          ),
          const SizedBox(height: NestSpacing.s2),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              NestSpacing.padSide,
              0,
              NestSpacing.padSide,
              NestSpacing.s8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NestQuestCard(
                  title: 'Make your bed',
                  metaChips: [
                    const NestCoinPill(
                      amount: '5',
                      size: NestCoinPillSize.xSmall,
                    ),
                    Text(
                      '· Daily',
                      style: NestType.caption(color: tokens.ink2),
                    ),
                    _StatusChip(
                      label: 'Needs a look',
                      background: tokens.coinTint,
                      foreground: tokens.coinInk,
                    ),
                  ],
                  leading: _Tile(
                    asset: NestIcons.bed,
                    bg: tokens.peachTint,
                    fg: tokens.aPeach,
                  ),
                  onTap: () {},
                ),
                const SizedBox(height: NestSpacing.s4),
                NestQuestCard(
                  title: 'Feed Biscuit the cat',
                  metaChips: [
                    const NestCoinPill(
                      amount: '5',
                      size: NestCoinPillSize.xSmall,
                    ),
                    Text(
                      '· Daily',
                      style: NestType.caption(color: tokens.ink2),
                    ),
                    _StatusChip(
                      label: 'To do',
                      background: tokens.surface2,
                      foreground: tokens.ink2,
                    ),
                  ],
                  leading: _Tile(
                    asset: NestIcons.coinSparkle,
                    bg: tokens.coinTint,
                    fg: tokens.coinInk,
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),
          NestTabBar(
            items: const [
              NestTabItem(label: 'Today', icon: NestIcons.home),
              NestTabItem(label: 'Quests', icon: NestIcons.quests),
              NestTabItem(label: 'Money', icon: NestIcons.money),
              NestTabItem(label: 'Family', icon: NestIcons.family),
            ],
            currentIndex: 0,
            onTap: (_) {},
          ),
        ],
      ),
    );
  }
}

/// K03 kchip: 32px leaf-tint pill, Nunito 800 15px.
class _KChip extends StatelessWidget {
  const new({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: NestSpacing.s3),
      decoration: BoxDecoration(
        color: tokens.leafTint,
        borderRadius: NestRadii.allPill,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: NestType.kidBody(color: tokens.leafInk)
            .copyWith(fontSize: 15, height: 1),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// P08 status chip: 26px pill, 12px bold.
class _StatusChip extends StatelessWidget {
  const new({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    // No alignment/Center/Row(min) here: inside a Wrap run those expand
    // the pill to the full run width. The tall line-height centres the
    // label vertically while the pill keeps its intrinsic width; maxLines
    // still guards tight contexts against overflow errors.
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: NestSpacing.gap10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: NestRadii.allPill,
      ),
      child: Text(
        label,
        style: NestType.chipSmall(color: foreground).copyWith(height: 26 / 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _P08ChildCard extends StatelessWidget {
  const new({
    required this.avatarColor,
    required this.initial,
    required this.name,
    required this.sub,
    required this.pip,
    required this.progress,
    required this.coins,
  });

  final NestAvatarColor avatarColor;
  final String initial;
  final String name;
  final String sub;
  final String pip;
  final double progress;
  final String coins;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return NestCard(
      padding: const EdgeInsets.all(NestSpacing.gap14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NestAvatar(
                initial: initial,
                size: NestAvatarSize.s32,
                color: avatarColor,
              ),
              const SizedBox(width: NestSpacing.s2),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: NestType.h3(color: tokens.ink)
                          .copyWith(fontSize: 17, height: 22 / 17),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      sub,
                      style: NestType.caption(color: tokens.ink2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: NestSpacing.gap6),
          Center(
            child: SvgPicture.asset(
              pip,
              width: 72,
              height: 72,
              placeholderBuilder: (context) =>
                  const SizedBox(width: 72, height: 72),
            ),
          ),
          const SizedBox(height: NestSpacing.gap2),
          NestProgress(fraction: progress),
          const SizedBox(height: NestSpacing.gap10),
          NestCoinPill(amount: coins),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const new({required this.asset, required this.bg, required this.fg});

  final String asset;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(NestSpacing.s3),
      ),
      alignment: Alignment.center,
      child: NestIcon(asset, color: fg),
    );
  }
}

/// K03 kid home, from DS widgets only: avatar header, pet stage, quest cards,
/// dock.
class _KidHomePreview extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return KidScope(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          NestSpacing.padSide,
          NestSpacing.s1,
          NestSpacing.padSide,
          NestSpacing.s6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const NestAvatar(
                  initial: 'M',
                  size: NestAvatarSize.s64,
                  color: NestAvatarColor.lilac,
                ),
                const SizedBox(width: NestSpacing.s2),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi Maya!',
                        style: NestType.h2(color: tokens.ink).copyWith(
                          fontWeight: FontWeight.w900,
                          height: 26 / 22,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '3 done today',
                        style: NestType.kidBody(color: tokens.ink2)
                            .copyWith(fontSize: 15, height: 20 / 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: NestSpacing.s2),
                const NestCoinPill(amount: '120'),
                const SizedBox(width: NestSpacing.gap10),
                NestLockButton(onPressed: () {}, semanticLabel: 'Grown-ups'),
              ],
            ),
            const SizedBox(height: NestSpacing.s2),
            const NestPetStage(speech: "Let's do some quests!", pipSize: 120),
            const SizedBox(height: NestSpacing.s3),
            Row(
              children: [
                NestIcon(NestIcons.heart, size: 26, color: tokens.coin),
                const SizedBox(width: NestSpacing.s2),
                NestIcon(NestIcons.heart, size: 26, color: tokens.coin),
                const SizedBox(width: NestSpacing.s2),
                NestIcon(NestIcons.heart, size: 26, color: tokens.coin),
                const SizedBox(width: NestSpacing.s2),
                NestIcon(NestIcons.heart, size: 26, color: tokens.coin),
                const SizedBox(width: NestSpacing.s2),
                NestIcon(NestIcons.heartOutline, size: 26, color: tokens.ink3),
                const SizedBox(width: NestSpacing.s2),
                Expanded(
                  child: Text(
                    'Pip is happy today',
                    style: NestType.kidBody(color: tokens.ink2)
                        .copyWith(fontSize: 15, height: 20 / 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: NestSpacing.s3),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Today's quests",
                    style: NestType.kidTitle(color: tokens.ink)
                        .copyWith(fontSize: 22, height: 28 / 22),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: NestSpacing.s3,
                    vertical: NestSpacing.s2,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.leafTint,
                    borderRadius: NestRadii.allPill,
                  ),
                  child: Text(
                    '3 of 6 done',
                    style: NestType.kidBody(color: tokens.leafInk)
                        .copyWith(fontSize: 15, height: 1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: NestSpacing.s2),
            const NestProgress(fraction: 0.5, kid: true),
            const SizedBox(height: NestSpacing.s3),
            NestKidQuestCard(
              title: 'Empty the dishwasher',
              icon: _KidTile(asset: NestIcons.dishwasher, bg: tokens.skyTint),
              metaChip: const _KChip(label: 'Waiting for Mum'),
              done: true,
            ),
            const SizedBox(height: NestSpacing.s3),
            NestKidQuestCard(
              title: 'Reading – 20 minutes',
              icon: _KidTile(asset: NestIcons.book, bg: tokens.lilacTint),
              coinAmount: '+10',
            ),
            const SizedBox(height: NestSpacing.s3),
            NestKidQuestCard(
              title: 'Tidy your bedroom',
              icon: _KidTile(asset: NestIcons.basket, bg: tokens.peachTint),
              coinAmount: '+15',
            ),
            const SizedBox(height: NestSpacing.s3),
            Row(
              children: [
                Expanded(
                  child: NestKidButton(
                    label: 'Pip',
                    icon: NestIcon(NestIcons.pipFace, color: tokens.onAccent),
                    color: NestKidButtonColor.lilac,
                    minHeight: 66,
                    axis: Axis.vertical,
                    gap: NestSpacing.s1,
                    fontSize: 17,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: NestSpacing.gap6,
                    ),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: NestSpacing.s2),
                Expanded(
                  child: NestKidButton(
                    label: 'Shop',
                    icon: NestIcon(NestIcons.bag, color: tokens.onWarm),
                    color: NestKidButtonColor.coin,
                    minHeight: 66,
                    axis: Axis.vertical,
                    gap: NestSpacing.s1,
                    fontSize: 17,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: NestSpacing.gap6,
                    ),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: NestSpacing.s2),
                Expanded(
                  child: NestKidButton(
                    label: 'My jar',
                    icon: NestIcon(NestIcons.jar, color: tokens.onLeaf),
                    minHeight: 66,
                    axis: Axis.vertical,
                    gap: NestSpacing.s1,
                    fontSize: 17,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: NestSpacing.gap6,
                    ),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KidTile extends StatelessWidget {
  const new({required this.asset, required this.bg});

  final String asset;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: bg, borderRadius: NestRadii.allM),
      alignment: Alignment.center,
      child: NestIcon(asset, size: 28, color: context.nest.ink),
    );
  }
}
