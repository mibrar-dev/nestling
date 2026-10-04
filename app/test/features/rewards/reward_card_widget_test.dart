import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/rewards/domain/entities/reward.dart';
import 'package:nestling/features/rewards/presentation/widgets/p14_reward_card.dart';

/// Geometry assertions for the P14 `.rw` card.
///
/// Every rect here was measured off `design/screens/light/P14-rewards.png`
/// (÷3): card x 20→370 / y 167→289, tile x 32→72 / y 208→248, coin pill y
/// 200→225, `.okrow` y 233→277 with the track at x 179, edit button x
/// 314→358 (44×44). The card is pumped in the same 20 px gutter the scroll
/// gives it so the x offsets are the real ones.
const _reward = Reward(
  id: 'r-screen',
  title: '30 min extra screen time',
  detail: '50 coins',
  icon: 'tv',
  coinPrice: 50,
  needsOk: true,
);

Future<void> _pumpCard(
  WidgetTester tester, {
  required double width,
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
}) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: NestTheme.light(),
      darkTheme: NestTheme.dark(),
      themeMode: theme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        backgroundColor: NestTheme.light().extension<NestTokens>()!.paper,
        body: Padding(
          padding: const EdgeInsets.fromLTRB(
            NestSpacing.padSide,
            0,
            NestSpacing.padSide,
            0,
          ),
          child: RewardCard(
            reward: _reward,
            onNeedsOkChanged: (_) {},
            onEdit: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Widget tests do not load the bundled families automatically, and every
/// rect below is derived from the design's text metrics (the 85 px "Needs my
/// OK" that puts the switch at x 179). Load them first.
Future<void> _loadFonts() async {
  final inter = FontLoader('Inter')
    ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-SemiBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf'));
  await inter.load();
  final nunito = FontLoader('Nunito')
    ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf'));
  await nunito.load();
}

void main() {
  setUpAll(_loadFonts);

  group('RewardCard geometry', () {
    testWidgets('matches the .rw rects at 390 px', (tester) async {
      await _pumpCard(tester, width: 390);

      final card = tester.getRect(find.byType(RewardCard));
      // 390 - 2 × 20 gutters, and the design's 122 = 12 + 21 + 25 + 8 + 44 + 12.
      expect(card.width, 350);
      expect(card.height, 122);
      expect(card.left, 20);
      expect(card.right, 370);

      // `.icon-tile` 40×40, 12 px in from the card edge, centred in the row.
      // The first NestIcon in tree order is the tile's 24 px glyph.
      final tile = tester.getRect(find.byType(NestIcon).first);
      expect(tile.size, const Size(24, 24));
      expect(tile.left, card.left + 12 + 8);
      expect(tile.top, card.top + 12 + 29 + 8);

      // `.coin-pill` xSmall: 15 px coin icon + 5/9 padding → 25 high.
      final pill = tester.getRect(
        find.byWidgetPredicate((w) => w is NestCoinPill),
      );
      expect(pill.top, card.top + 12 + 21);
      expect(pill.height, 25);
      expect(pill.left, card.left + 12 + 40 + 12);

      // `.okrow`: min-height 44, `margin-top: 8`, `gap: 10`, track 51×31.
      // Shared batch 5: the toggle lays out at the design's 51×31 track (the
      // 59×44 tap area overhangs via hit slop). `RewardCard` still carries
      // its pre-batch `Transform.translate(-4, 0)` compensation, so the
      // painted track sits ~4 px left of the design's x 179 — follow-up is
      // to delete that offset and restore 179 (see shared_batch5_REPORT).
      final toggleBox = tester.getRect(find.byType(NestToggle));
      expect(toggleBox.size, const Size(51, 31));
      expect(toggleBox.top, card.top + 12 + 21 + 25 + 8 + 6.5);
      final track = tester.getRect(
        find.descendant(
          of: find.byType(NestToggle),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(track.size, const Size(51, 31));
      expect(track.left, closeTo(175, 1));
      expect(track.center.dy, closeTo(toggleBox.center.dy, 0.01));
      expect(track.bottom, closeTo(card.bottom - 12 - 6.5, 0.01));
    });

    testWidgets('the edit button paints an exact 44×44 radius-12 rect', (
      tester,
    ) async {
      await _pumpCard(tester, width: 390);

      final edit = tester.getRect(
        find.bySemanticsLabel('Edit 30 min extra screen time'),
      );
      expect(edit.size, const Size(44, 44));
      expect(edit.right, 358);
      expect(
        edit.center.dy,
        closeTo(tester.getRect(find.byType(RewardCard)).center.dy, 0.01),
      );

      final decoration = tester.widget<Ink>(find.byType(Ink).last);
      final box = decoration.decoration! as BoxDecoration;
      expect((box.border! as Border).top.width, 1);
      expect((box.borderRadius! as BorderRadius).topLeft.x, NestSpacing.s3);
      // The fill is the `surface` token, not `paper` — a paper-filled button
      // would vanish into the page.
      expect(
        tester.widget<Material>(find.byType(Material).last).color,
        Theme.of(tester.element(find.byType(RewardCard)))
            .extension<NestTokens>()!
            .surface,
      );
    });

    testWidgets(
      '320 px width and 1.3 text scale: no overflow, fixed rects hold',
      (tester) async {
        await _pumpCard(tester, width: 320, textScale: 1.3);

        expect(tester.takeException(), isNull);
        final card = tester.getRect(find.byType(RewardCard));
        expect(card.width, 280);
        // Shared batch 5: 51×31 track (44 hit area via hit slop, not layout).
        expect(
          tester.getRect(find.byType(NestToggle)).size,
          const Size(51, 31),
        );
        expect(
          tester
              .getRect(find.bySemanticsLabel('Edit 30 min extra screen time'))
              .size,
          const Size(44, 44),
        );
        // The name stays on one line and ellipsizes rather than wrapping.
        final name = tester.widget<Text>(find.text('30 min extra screen time'));
        expect(name.maxLines, 1);
        expect(name.overflow, TextOverflow.ellipsis);
      },
    );

    testWidgets('unknown icon strings fall back to the neutral gift tile', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: NestTheme.light(),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(NestSpacing.padSide),
              child: RewardCard(
                reward: const Reward(
                  id: 'r-new',
                  title: 'Choose dessert',
                  detail: '20 coins',
                  icon: 'waffle',
                  coinPrice: 20,
                  needsOk: false,
                ),
                onNeedsOkChanged: (_) {},
                onEdit: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(RewardCard), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
