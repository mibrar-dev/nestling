import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';

import 'test_harness.dart';

void main() {
  group('NestCard', () {
    testWidgets('three variants in light and dark', (tester) async {
      await pumpBothModes(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const NestCard(child: _Body('Standard')),
            const SizedBox(height: 12),
            const NestCard(
              variant: NestCardVariant.inset,
              child: _Body('Inset'),
            ),
            const SizedBox(height: 12),
            NestCard(
              variant: NestCardVariant.hero,
              child: Text(
                'Hero',
                style: NestType.h3(color: NestColors.dark.onHero),
              ),
            ),
          ],
        ),
      );
    });

    testWidgets('tap fires on tappable cards', (tester) async {
      var tapped = 0;
      await pumpNest(
        tester,
        NestCard(child: const _Body('Tap'), onTap: () => tapped++),
      );
      await tester.tap(find.byType(NestCard));
      expect(tapped, 1);
    });
  });

  group('NestList', () {
    testWidgets('rows ellipsize and meet 56px', (tester) async {
      await pumpBothModes(
        tester,
        NestList(
          children: [
            NestListRow(
              title: 'A very long quest title that must truncate with ellipsis',
              subtitle: 'A very long subtitle that must also truncate',
              leadingAsset: NestIcons.bin,
              tint: NestTileTint.leaf,
              trailing: const _Body('+ Add'),
              onTap: () {},
            ),
            NestListRow(
              title: 'Pocket money',
              subtitle: '£3.00/week',
              leadingAsset: NestIcons.poundCoin,
              tint: NestTileTint.coin,
              onTap: () {},
            ),
          ],
        ),
        surface: const Size(320, 568),
        textScale: 1.3,
      );
      final row = tester.getSize(find.byType(NestListRow).first);
      expect(row.height, greaterThanOrEqualTo(56));
    });
  });

  group('NestAvatar', () {
    testWidgets('sizes and colours', (tester) async {
      await pumpBothModes(
        tester,
        const Row(
          children: [
            NestAvatar(initial: 'M', size: NestAvatarSize.s32),
            NestAvatar(initial: 'L'),
            NestAvatar(initial: 'S', size: NestAvatarSize.s64),
            NestAvatar(initial: 'J', size: NestAvatarSize.s96),
          ],
        ),
      );
      final sizes = [32.0, 44.0, 64.0, 96.0];
      for (var i = 0; i < 4; i++) {
        expect(
          tester.getSize(find.byType(NestAvatar).at(i)),
          Size(sizes[i], sizes[i]),
        );
      }
    });
  });

  group('coin, money, progress, badge', () {
    testWidgets('render in light and dark', (tester) async {
      await pumpBothModes(
        tester,
        const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                NestCoinPill(amount: '120'),
                SizedBox(width: 8),
                NestCoinPill(amount: '1.2k', size: NestCoinPillSize.large),
                SizedBox(width: 8),
                NestBadgeCount(count: 3),
              ],
            ),
            SizedBox(height: 12),
            NestMoney(amount: 4.2),
            SizedBox(height: 12),
            NestProgress(fraction: 0.62),
            SizedBox(height: 12),
            NestProgress(fraction: 0.7, kid: true),
          ],
        ),
      );
      expect(tester.getSize(find.byType(NestProgress).first).height, 8);
      expect(tester.getSize(find.byType(NestProgress).at(1)).height, 16);
      expect(find.text('£4.20'), findsOneWidget);
    });

    testWidgets('pill sizes: standard, small and large', (tester) async {
      await pumpNest(
        tester,
        const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NestCoinPill(amount: '120'),
            SizedBox(height: 8),
            NestCoinPill(amount: '15', size: NestCoinPillSize.small),
            SizedBox(height: 8),
            NestCoinPill(amount: '1.2k', size: NestCoinPillSize.large),
          ],
        ),
      );
      // Default height is 36: the 20px coin icon dominates the 16px
      // label inside 2x8 padding, per components.css geometry.
      expect(tester.getSize(find.byType(NestCoinPill).first).height, 36);
      expect(
        tester.getSize(find.byType(NestCoinPill).at(2)).height,
        greaterThan(32),
      );
    });

    testWidgets('no overflow at 320 wide and textScale 1.3', (tester) async {
      await pumpBothModes(
        tester,
        const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NestCoinPill(amount: '12345'),
            SizedBox(height: 12),
            NestMoney(amount: 1234.56),
            SizedBox(height: 12),
            NestProgress(fraction: 1.2, kid: true),
          ],
        ),
        surface: const Size(320, 568),
        textScale: 1.3,
      );
    });
  });

  group('NestEmptyState', () {
    testWidgets('renders art, title, message and action', (tester) async {
      await pumpBothModes(
        tester,
        SingleChildScrollView(
          child: NestEmptyState(
            art: SvgPicture.asset(
              NestlingIllustrations.pipStage1,
              width: 160,
              height: 160,
              placeholderBuilder: (context) => const SizedBox.shrink(),
            ),
            title: 'Your nest is quiet',
            message: 'Add your first quest.',
            action: NestButton(label: 'Add a quest', onPressed: () {}),
          ),
        ),
      );
      expect(find.text('Your nest is quiet'), findsOneWidget);
    });
  });

  group('quest cards', () {
    testWidgets('parent card with toggle check', (tester) async {
      var done = false;
      await pumpBothModes(
        tester,
        StatefulBuilder(
          builder: (context, setState) => NestQuestCard(
            title: 'A very long quest title that must truncate to one line',
            meta: 'Maya · 15 coins',
            trailing: const NestCoinPill(amount: '15'),
            done: done,
            onToggled: (next) => setState(() => done = next),
            onTap: () {},
          ),
        ),
        surface: const Size(320, 568),
        textScale: 1.3,
      );
      // Parent check: 28px visual ring, 44px hit area via padding.
      expect(tester.getSize(find.bySemanticsLabel('Mark done')).height, 44);
    });

    testWidgets('kid card toggles to done', (tester) async {
      var done = false;
      await pumpNest(
        tester,
        StatefulBuilder(
          builder: (context, setState) => NestKidQuestCard(
            title: 'Tidy your bedroom',
            coinAmount: '15',
            done: done,
            onToggled: (next) => setState(() => done = next),
          ),
        ),
      );
      // The check's label merges into the tappable card node
      // ('Tidy your bedroom\n15 coins\nMark done'), so tap the check's
      // InkWell directly: it is the second InkWell under the card
      // (the card's own no-op InkWell comes first).
      final check = find
          .descendant(
            of: find.byType(NestKidQuestCard),
            matching: find.byType(InkWell),
          )
          .at(1);
      expect(check, findsOneWidget);
      expect(tester.getSize(check).height, greaterThanOrEqualTo(56));
      await tester.tap(check);
      await tester.pumpAndSettle();
      expect(done, isTrue);
    });
  });

  group('NestPetStage', () {
    testWidgets('renders pip with speech in light and dark', (tester) async {
      await pumpBothModes(
        tester,
        const SingleChildScrollView(
          child: NestPetStage(speech: "Let's do some quests!", pipSize: 160),
        ),
      );
      expect(find.text("Let's do some quests!"), findsOneWidget);
    });
  });

  group('NestSectionLabel and NestPagerDots', () {
    testWidgets('header semantics and dots', (tester) async {
      var page = 0;
      await pumpBothModes(
        tester,
        StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const NestSectionLabel(label: "Today's quests"),
              NestPagerDots(
                count: 3,
                index: page,
                onDotTapped: (next) => setState(() => page = next),
              ),
            ],
          ),
        ),
      );
      expect(find.text("TODAY'S QUESTS"), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Go to page 3'));
      await tester.pumpAndSettle();
      expect(page, 2);
    });
  });
}

class _Body extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, maxLines: 1, overflow: TextOverflow.ellipsis);
  }
}
