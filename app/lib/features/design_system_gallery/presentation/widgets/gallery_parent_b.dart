import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart';

/// Parent components, part 2: avatars, pills, money, progress, badges,
/// quest cards, chrome (nav, tabs, bottom CTA, FAB, lock, pager).
class GalleryParentB extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NestSectionLabel(
          key: ValueKey('ds-section-avatars'),
          label: 'Avatars',
        ),
        const SizedBox(height: NestSpacing.s2),
        const Row(
          children: [
            NestAvatar(
              initial: 'M',
              size: NestAvatarSize.s32,
              color: NestAvatarColor.lilac,
            ),
            SizedBox(width: NestSpacing.s2),
            NestAvatar(initial: 'L', color: NestAvatarColor.peach),
            SizedBox(width: NestSpacing.s2),
            NestAvatar(
              initial: 'S',
              size: NestAvatarSize.s64,
              color: NestAvatarColor.sky,
            ),
            SizedBox(width: NestSpacing.s2),
            NestAvatar(
              initial: 'J',
              size: NestAvatarSize.s96,
              color: NestAvatarColor.leaf,
            ),
          ],
        ),
        const SizedBox(height: NestSpacing.s4),
        const NestSectionLabel(
          key: ValueKey('ds-section-coin-money-progress'),
          label: 'Coin · Money · Progress · Badge',
        ),
        const SizedBox(height: NestSpacing.s2),
        const Row(
          children: [
            NestCoinPill(amount: '120'),
            SizedBox(width: NestSpacing.s2),
            NestCoinPill(amount: '1.2k'),
            SizedBox(width: NestSpacing.s2),
            NestBadgeCount(count: 3),
          ],
        ),
        const SizedBox(height: NestSpacing.s3),
        const NestMoney(amount: 4.2),
        const SizedBox(height: NestSpacing.s3),
        const NestProgress(fraction: 0.62),
        const SizedBox(height: NestSpacing.s2),
        Text(
          '62% · £15.50 of £24.99',
          style: NestType.caption(color: tokens.ink2),
        ),
        const SizedBox(height: NestSpacing.s4),
        const NestSectionLabel(
          key: ValueKey('ds-section-quest-cards'),
          label: 'Quest cards',
        ),
        const SizedBox(height: NestSpacing.s2),
        const _QuestDemo(),
        const SizedBox(height: NestSpacing.s4),
        const NestSectionLabel(
          key: ValueKey('ds-section-nav-bars'),
          label: 'Nav bars',
        ),
        const SizedBox(height: NestSpacing.s2),
        NestNavBar(title: 'Reward shop', compact: true, onBack: () {}),
        NestNavBar(
          title: 'Today',
          trailing: NestIconButton(
            icon: NestIcons.plus,
            semanticLabel: 'Add',
            backgroundColor: Colors.transparent,
            foregroundColor: context.nest.leaf,
            borderColor: Colors.transparent,
            onPressed: () {},
          ),
        ),
        const SizedBox(height: NestSpacing.s4),
        const NestSectionLabel(
          key: ValueKey('ds-section-tab-bar'),
          label: 'Tab bar',
        ),
        const SizedBox(height: NestSpacing.s2),
        const _TabDemo(),
        const SizedBox(height: NestSpacing.s4),
        const NestSectionLabel(
          key: ValueKey('ds-section-bottom-cta'),
          label: 'Bottom CTA',
        ),
        const SizedBox(height: NestSpacing.s2),
        NestBottomCta(
          caption: 'Children never need an email.',
          child: NestButton(label: 'Continue', onPressed: () {}),
        ),
        const SizedBox(height: NestSpacing.s4),
        const NestSectionLabel(
          key: ValueKey('ds-section-fab-lock-pager'),
          label: 'FAB · Lock · Pager',
        ),
        const SizedBox(height: NestSpacing.s2),
        Wrap(
          spacing: NestSpacing.s3,
          runSpacing: NestSpacing.s3,
          children: [
            NestFab(label: 'New quest', icon: NestIcons.plus, onPressed: () {}),
            NestLockButton(onPressed: () {}),
            NestLockButton(large: false, onPressed: () {}),
          ],
        ),
        const SizedBox(height: NestSpacing.s3),
        const _PagerDemo(),
      ],
    );
  }
}

class _QuestDemo extends StatefulWidget {
  const new();

  @override
  State<_QuestDemo> createState() => _QuestDemoState();
}

class _QuestDemoState extends State<_QuestDemo> {
  bool done = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NestQuestCard(
          title: 'Hoover the stairs',
          meta: 'Weekly · Before tea',
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.nest.skyTint,
              borderRadius: BorderRadius.circular(NestSpacing.s3),
            ),
            alignment: Alignment.center,
            child: NestIcon(NestIcons.hoover, color: context.nest.sky),
          ),
          trailing: const NestCoinPill(amount: '20'),
          onTap: () {},
        ),
        const SizedBox(height: NestSpacing.s3),
        NestQuestCard(
          title: 'Put the bins out',
          meta: 'Maya · 15 coins',
          done: done,
          onToggled: (next) => setState(() => done = next),
          onTap: () {},
        ),
      ],
    );
  }
}

class _TabDemo extends StatefulWidget {
  const new();

  @override
  State<_TabDemo> createState() => _TabDemoState();
}

class _TabDemoState extends State<_TabDemo> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return NestTabBar(
      items: const [
        NestTabItem(label: 'Today', icon: NestIcons.home),
        NestTabItem(label: 'Quests', icon: NestIcons.quests),
        NestTabItem(label: 'Money', icon: NestIcons.money),
        NestTabItem(label: 'Family', icon: NestIcons.family),
      ],
      currentIndex: index,
      onTap: (next) => setState(() => index = next),
    );
  }
}

class _PagerDemo extends StatefulWidget {
  const new();

  @override
  State<_PagerDemo> createState() => _PagerDemoState();
}

class _PagerDemoState extends State<_PagerDemo> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return NestPagerDots(
      count: 3,
      index: index,
      onDotTapped: (next) => setState(() => index = next),
    );
  }
}
